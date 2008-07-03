/*
    Missions class
    
    Object to contain members related to missions.
    
    -- GliderPro
    
*/

objectdef obj_MissionCache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${Me.Name} Mission Cache.xml"
	variable string SET_NAME = "Missions"
	
	method Initialize()
	{
		LavishSettings[MissionCache]:Clear
		LavishSettings:AddSet[MissionCache]
		LavishSettings[MissionCache]:AddSet[${This.SET_NAME}]
		LavishSettings[MissionCache]:Import[${This.CONFIG_FILE}]
		UI:UpdateConsole["obj_MissionCache: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[MissionCache]:Export[${This.CONFIG_FILE}]
		LavishSettings[MissionCache]:Clear
	}

	member:settingsetref MissionsRef()
	{
		return ${LavishSettings[MissionCache].FindSet[${This.SET_NAME}]}
	}

	member:settingsetref MissionRef(int agentID)
	{
		return ${This.MissionsRef.FindSet[${agentID}]}
	}
	
	method AddMission(int agentID, string name)
	{
		This.MissionsRef:AddSet[${agentID}]
		This.MissionRef[${agentID}]:AddSetting[Name,"${name}"]
	}
	
	member:int FactionID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[FactionID,0]}
	}
	
	method SetFactionID(int agentID, int factionID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}
		
		This.MissionRef[${agentID}]:AddSetting[FactionID,${factionID}]
	}	

	member:int TypeID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[TypeID,0]}
	}
	
	method SetTypeID(int agentID, int typeID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}
		
		This.MissionRef[${agentID}]:AddSetting[TypeID,${typeID}]
	}	

	member:int Volume(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[Volume,0]}
	}
	
	method SetVolume(int agentID, float volume)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}
		
		This.MissionRef[${agentID}]:AddSetting[Volume,${volume}]
	}	

}

objectdef obj_Missions
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	variable obj_MissionCache MissionCache
	variable obj_Combat Combat

    method Initialize()
    {
   		UI:UpdateConsole["obj_Missions: Initialized", LOG_MINOR]
    }

	method Shutdown()
	{
	}
	
	function RunMission()
	{
	    variable index:agentmission amIndex
		variable iterator amIterator

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]
		
		UI:UpdateConsole["obj_Missions: DEBUG: amIndex.Used = ${amIndex.Used}"]	
		if ${amIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]	
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]	
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]	
				if ${amIterator.Value.State} == 2
				{
					if ${amIterator.Value.Type.Find[Courier](exists)}
					{
						call This.RunCourierMission ${amIterator.Value.AgentID}
					}					
					elseif ${amIterator.Value.Type.Find[Trade](exists)}
					{
						call This.RunTradeMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Mining](exists)}
					{
						call This.RunMiningMission ${amIterator.Value.AgentID}
					}					
					elseif ${amIterator.Value.Type.Find[Encounter](exists)}
					{
						call This.RunCombatMission ${amIterator.Value.AgentID}
					}
					else
					{
						UI:UpdateConsole["obj_Missions: ERROR!  Unknown mission type!"]
						Script:Pause
					}
				}
			}  
			while ${amIterator:Next(exists)}
		}
	}
	
	function RunCourierMission(int agentID)
	{
	   if ${This.MissionCache[${agentID}].Volume} > ${Config.Missioneer.SmallHaulerLimit}
	   {
		   call Ship.ActivateShip "${Config.Missioneer.LargeHauler}"
      }		   
      else
	   {
		   call Ship.ActivateShip "${Config.Missioneer.SmallHauler}"
      }		   

		variable bool allDone = FALSE
		do
		{
			UI:UpdateConsole["obj_Missions: MoveToPickup"]
			call Agents.MoveToPickup
			UI:UpdateConsole["obj_Missions: TransferCargoToShip"]
			wait 50
			call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
			allDone:Set[${Cargo.LastTransferComplete}]
			UI:UpdateConsole["obj_Missions: MoveToDropOff"]
			call Agents.MoveToDropOff
			wait 50
			call Cargo.TransferCargoToHangar			
			wait 50
		}
		while !${allDone}
		
		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}
	
	function RunTradeMission(int agentID)
	{
		UI:UpdateConsole["obj_Missions: ERROR!  Trade missions are not supported!"]
		Script:Pause
	}

	function RunMiningMission(int agentID)
	{
		UI:UpdateConsole["obj_Missions: ERROR!  Mining missions are not supported!"]
		Script:Pause
	}

	function RunCombatMission(int agentID)
	{
		call Ship.ActivateShip "${Config.Missioneer.CombatShip}"
		wait 10
		call This.WarpToEncounter ${agentID}
		wait 50
		
		UI:UpdateConsole["obj_Missions: DEBUG: ${Ship.Type} (${Ship.TypeID})"]		
		switch ${Ship.TypeID}
		{
			case TYPE_PUNISHER
				call This.PunisherCombat ${agentID}
				break
			case TYPE_HAWK
				call This.HawkCombat ${agentID}
				break
			case TYPE_KESTREL
				call This.KestrelCombat ${agentID}
				break
			default
				UI:UpdateConsole["obj_Missions: WARNING!  Unknown Ship Type."]
				call This.DefaultCombat ${agentID}
				break
		}

		call This.WarpToHomeBase ${agentID}
		wait 50
		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}	
	
	function DefaultCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}
	
	function PunisherCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}
	
	function HawkCombat(int agentID)
	{
		wait 100
		while ${This.TargetNPCs} && ${Social.IsSafe}
		{
			This.Combat:SetState
			call This.Combat.ProcessState
			wait 10
		}
	}
	
	function KestrelCombat(int agentID)
	{
		wait 100
		while (${This.TargetNPCs} || ${This.TargetStructures[${agentID}]}) && ${Social.IsSafe}
		{
			This.Combat:SetState
			call This.Combat.ProcessState
			wait 10
		}		
	}
	
	function WarpToEncounter(int agentID)
	{
	    variable index:agentmission amIndex
	    variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

	    EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["dungeon"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value}
								return
							}
						} 
						while ${mbIterator:Next(exists)}
					}
				}
			}  
			while ${amIterator:Next(exists)}
		}
	}
	
	function WarpToHomeBase(int agentID)
	{
	    variable index:agentmission amIndex
	    variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

	    EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]	
							if ${mbIterator.Value.LocationType.Equal["agenthomebase"]} || \
							   ${mbIterator.Value.LocationType.Equal["objective"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value}
								return
							}
						} 
						while ${mbIterator:Next(exists)}
					}
				}
			}  
			while ${amIterator:Next(exists)}
		}
	}
	
	member:bool TargetStructures(int agentID)
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

      UI:UpdateConsole["DEBUG: TargetStructures"]
      
		if ${Me.Ship.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
		}
		
		EVE:DoGetEntities[Targets, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
		   do
		   {
            if ${Me.GetTargetedBy} > 0 && ${Target.Value.IsLockedTarget}
            {
				   Target.Value:UnlockTarget
            }
			   elseif ${This.SpecialStructure[${agentID},${Target.Value.Name}]} && \
			     !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			   {
			      variable int OrbitDistance
			      OrbitDistance:Set[${Math.Calc[${Me.Ship.MaxTargetRange}*0.40/1000].Round}]
			      OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
			      Target.Value:Orbit[${OrbitDistance}]

				   if ${Me.GetTargets(exists)} && ${Me.GetTargets} < ${Ship.MaxLockedTargets}
				   {
					   UI:UpdateConsole["Locking ${Target.Value.Name}"]
					   Target.Value:LockTarget
				   }
			   }
				
			   ; Set the return value so we know we have targets
			   HasTargets:Set[TRUE]
		   }
		   while ${Target:Next(exists)}
      }
      		
		return ${HasTargets}
	}

	member:bool TargetNPCs()
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

		if ${Me.Ship.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
		}
		
		EVE:DoGetEntities[Targets, CategoryID, CATEGORYID_ENTITY]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
		   do
		   {
            switch ${Target.Value.GroupID} 
            {
               case GROUP_LARGECOLLIDABLEOBJECT
               case GROUP_LARGECOLLIDABLESHIP
               case GROUP_LARGECOLLIDABLESTRUCTURE
                  continue

               default               
                  break
            }
            
			   if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			   {
				   if ${Me.GetTargets(exists)} && ${Me.GetTargets} < ${Ship.MaxLockedTargets}
				   {
					   UI:UpdateConsole["Locking ${Target.Value.Name}"]
					   Target.Value:LockTarget
				   }
			   }
				
			   ; Set the return value so we know we have targets
			   HasTargets:Set[TRUE]
		   }
		   while ${Target:Next(exists)}
      }
      		
		if ${HasTargets} && ${Me.ActiveTarget(exists)}
		{
			variable int OrbitDistance
			OrbitDistance:Set[${Math.Calc[${Me.Ship.MaxTargetRange}*0.40/1000].Round}]
			OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
			Me.ActiveTarget:Orbit[${OrbitDistance}]
		}
		
		return ${HasTargets}
	}

   member:bool SpecialStructure(int agentID, string name)
   {
      if ${This.MissionCache.Name[${agentID}](exists)}   
      {
         if ${This.MissionCache.Name.Equal["avenge a fallen comrade"]} && \
            ${name.Equal["habitat"]}
         {
            return TRUE
         }
         ; elseif {...}
         ; etc...         
      }
      
      return FALSE
   }
}
