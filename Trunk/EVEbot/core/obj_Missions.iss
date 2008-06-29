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

	member:settingsetref MissionRef(string timestamp)
	{
		return ${This.MissionsRef.FindSet[${timestamp}]}
	}
	
	method AddMission(string timestamp, int agentID, string name)
	{
		This.MissionsRef:AddSet[${timestamp}]
		This.MissionRef[${timestamp}]:AddSetting[AgentID,${agentID}]
		This.MissionRef[${timestamp}]:AddSetting[Name,"${name}"]
	}
	
	member:int FactionID(string timestamp)
	{
		return ${This.MissionRef[${timestamp}].FindSetting[FactionID,0]}
	}
	
	method SetFactionID(string timestamp, int factionID)
	{
		if !${This.MissionsRef.FindSet[${timestamp}](exists)}
		{
			This.MissionsRef:AddSet[${timestamp}]
		}
		
		This.MissionRef[${timestamp}]:AddSetting[FactionID,${factionID}]
	}	

	member:int TypeID(string timestamp)
	{
		return ${This.MissionRef[${timestamp}].FindSetting[TypeID,0]}
	}
	
	method SetTypeID(string timestamp, int typeID)
	{
		if !${This.MissionsRef.FindSet[${timestamp}](exists)}
		{
			This.MissionsRef:AddSet[${timestamp}]
		}
		
		This.MissionRef[${timestamp}]:AddSetting[TypeID,${typeID}]
	}	

	member:int Volume(string timestamp)
	{
		return ${This.MissionRef[${timestamp}].FindSetting[Volume,0]}
	}
	
	method SetVolume(string timestamp, float volume)
	{
		if !${This.MissionsRef.FindSet[${timestamp}](exists)}
		{
			This.MissionsRef:AddSet[${timestamp}]
		}
		
		This.MissionRef[${timestamp}]:AddSetting[Volume,${volume}]
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
						call This.RunCourierMission
					}					
					elseif ${amIterator.Value.Type.Find[Trade](exists)}
					{
						call This.RunTradeMission
					}
					elseif ${amIterator.Value.Type.Find[Mining](exists)}
					{
						call This.RunMiningMission
					}					
					elseif ${amIterator.Value.Type.Find[Encounter](exists)}
					{
						call This.RunCombatMission
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
	
	function RunCourierMission()
	{
		UI:UpdateConsole["obj_Missions: MoveToPickup"]
		call Agents.MoveToPickup
		UI:UpdateConsole["obj_Missions: TransferCargoToShip"]
		wait 100
		call Cargo.TransferCargoToShip
		UI:UpdateConsole["obj_Missions: MoveToDropOff"]
		call Agents.MoveToDropOff
		wait 100
		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}
	
	function RunTradeMission()
	{
		UI:UpdateConsole["obj_Missions: ERROR!  Trade missions are not supported!"]
		Script:Pause
	}

	function RunMiningMission()
	{
		UI:UpdateConsole["obj_Missions: ERROR!  Mining missions are not supported!"]
		Script:Pause
	}

	function RunCombatMission()
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
