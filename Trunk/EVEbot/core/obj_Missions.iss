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
		UI:UpdateConsole["obj_MissionCache.TypeID: DEBUG ${agentID} ${This.MissionRef[${agentID}].Name}"]
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
				UI:UpdateConsole["obj_Missions: DEBUG: This.AgentID = ${This.AgentID}"]	
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
		variable bool allDone = FALSE
		do
		{
			UI:UpdateConsole["obj_Missions: MoveToPickup"]
			call Agents.MoveToPickup
			UI:UpdateConsole["obj_Missions: TransferCargoToShip"]
			wait 50
			call Cargo.TransferHangarItemToShip ${Missions.MissionCache.TypeID[${agentID}]}
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
		variable index:item hsIndex
		variable iterator   hsIterator
		variable string     shipName
		
		if ${Station.Docked}
		{
			shipName:Set[${Me.Ship}]
			if ${shipName.NotEqual[${Config.Missioneer.CombatShip}]}
			{			
				Me.Station:DoGetHangarShips[hsIndex]
				hsIndex:GetIterator[hsIterator]
				
				if ${hsIterator:First(exists)}
				{
					do
					{
						if ${hsIterator.Value.GivenName.Equal[${Config.Missioneer.CombatShip}]}
						{
							UI:UpdateConsole["obj_Missions: Switching to ship named ${hsIterator.Value.GivenName}."]
							hsIterator.Value:MakeActive
							break
						}
					}
					while ${hsIterator:Next(exists)}
				}
			}
		}		
		else
		{
			UI:UpdateConsole["obj_Missions.RunCombatMission: ERROR Did not start docked!"]
			Script:Pause
		}
		UI:UpdateConsole["obj_Missions: ERROR!  Combat missions are not supported!"]
		Script:Pause
	}	
}
