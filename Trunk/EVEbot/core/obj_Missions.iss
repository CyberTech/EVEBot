/*
    Missions class
    
    Object to contain members related to missions.
    
    -- GliderPro
    
*/

objectdef obj_Missions
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

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
		UI:UpdateConsole["obj_Missions: ERROR!  Combat missions are not supported!"]
		Script:Pause
	}
}
