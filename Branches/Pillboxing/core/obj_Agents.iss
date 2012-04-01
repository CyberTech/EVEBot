/*
    Agents class

    Object to contain members related to agents.

    -- GliderPro

*/

objectdef obj_AgentList
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Agents.xml"
	variable string SET_NAME1 = "${Me.Name} Agents"
	variable string SET_NAME2 = "${Me.Name} Research Agents"
	variable iterator agentIterator
	variable iterator researchAgentIterator

	method Initialize()
	{
		if ${LavishSettings[${This.SET_NAME1}](exists)}
		{
			LavishSettings[${This.SET_NAME1}]:Clear
		}
		if ${LavishSettings[${This.SET_NAME2}](exists)}
		{
			LavishSettings[${This.SET_NAME2}]:Clear
		}
		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME1}]:GetSettingIterator[This.agentIterator]
		if !${This.agentIterator:First(exists)}
		{
			UI:UpdateConsole["obj_AgentList: Found no agents"]
		}
		LavishSettings[${This.SET_NAME2}]:GetSettingIterator[This.researchAgentIterator]
		UI:UpdateConsole["obj_AgentList: Initialized.", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME1}]:Clear
		LavishSettings[${This.SET_NAME2}]:Clear
	}

	member:string FirstAgent()
	{
		if ${This.agentIterator:First(exists)}
		{
			return ${This.agentIterator.Key}
		}

		return NULL
	}

	member:string NextAgent()
	{
		if ${This.agentIterator:Next(exists)}
		{
			return ${This.agentIterator.Key}
		}
		elseif ${This.agentIterator:First(exists)}
		{
			return ${This.agentIterator.Key}
		}

		return NULL
	}

	member:string ActiveAgent()
	{
		return ${This.agentIterator.Key}
	}

	member:string NextAvailableResearchAgent()
	{
		if ${This.researchAgentIterator.Key.Length} > 0
		{
			do
			{
				variable time lastCompletionTime
				lastCompletionTime:Set[${Config.Agents.LastCompletionTime[${This.researchAgentIterator.Key}]}]
				UI:UpdateConsole["DEBUG: Last mission for ${This.researchAgentIterator.Key} was completed at ${lastCompletionTime} on ${lastCompletionTime.Date}."]
				lastCompletionTime.Hour:Inc[24]
				lastCompletionTime:Update
				if ${lastCompletionTime.Timestamp} < ${Time.Timestamp}
				{
					return ${This.researchAgentIterator.Key}
				}
			}
			while ${This.researchAgentIterator:Next(exists)}
			This.researchAgentIterator:First
		}

		return NULL
	}
}

objectdef obj_MissionBlacklist
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Mission Blacklist.xml"
	variable string SET_NAME = "${Me.Name} Mission Blacklist"
	variable iterator levelIterator

	method Initialize()
	{
		if ${LavishSettings[${This.SET_NAME}](exists)}
		{
			LavishSettings[${This.SET_NAME}]:Clear
		}
		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME}]:GetSetIterator[This.levelIterator]
		UI:UpdateConsole["obj_MissionBlacklist: Initialized.", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Clear
	}

	member:bool IsBlacklisted(int level, string mission)
	{
		variable string levelString

		switch ${level}
		{
			case 1
				levelString:Set["Level One"]
				break
			case 2
				levelString:Set["Level Two"]
				break
			case 3
				levelString:Set["Level Three"]
				break
			case 4
				levelString:Set["Level Four"]
				break
			case 5
				levelString:Set["Level Five"]
				break
			default
				levelString:Set["Level One"]
				break
		}

		UI:UpdateConsole["DEBUG: obj_MissionBlacklist: Searching for ${levelString} mission blacklist..."]

		if ${This.levelIterator:First(exists)}
		{
			do
			{
				if ${levelString.Equal[${This.levelIterator.Key}]}
				{
					UI:UpdateConsole["DEBUG: obj_MissionBlacklist: Searching ${levelString} mission blacklist for ${mission}..."]

					variable iterator missionIterator

					This.levelIterator.Value:GetSettingIterator[missionIterator]
					if ${missionIterator:First(exists)}
					{
						do
						{
							if ${mission.Equal[${missionIterator.Key}]}
							{
								UI:UpdateConsole["DEBUG: obj_MissionBlacklist: ${mission} is blacklisted!"]
								return TRUE
							}
						}
						while ${missionIterator:Next(exists)}
					}
				}
			}
			while ${This.levelIterator:Next(exists)}
		}

		return FALSE
	}
}

objectdef obj_Agents
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string AgentName
	variable string MissionDetails
	variable int RetryCount = 0
	variable obj_AgentList AgentList
	variable obj_MissionBlacklist MissionBlacklist

    method Initialize()
    {
    	if ${This.AgentList.agentIterator:First(exists)}
    	{
    		This:SetActiveAgent[${This.AgentList.FirstAgent}]
    		UI:UpdateConsole["obj_Agents: Initialized", LOG_MINOR]
    	}
    	else
    	{
			UI:UpdateConsole["obj_Agents: Initialized (No Agents Found)", LOG_MINOR]
		}
    }

	method Shutdown()
	{
	}

	member:int AgentIndex()
	{
		return ${Agent[${This.ActiveAgent}].Index}
	}

	member:int AgentID()
	{
		return ${Config.Agents.AgentID[${This.AgentName}]}
	}

	method SetActiveAgent(string name)
	{
		UI:UpdateConsole["obj_Agents: SetActiveAgent ${name}"]

		if ${Config.Agents.AgentIndex[${name}]} > 0
		{
			UI:UpdateConsole["obj_Agents: SetActiveAgent: Found agent data. (${Config.Agents.AgentIndex[${name}]})"]
			This.AgentName:Set[${name}]
		}
		else
		{
			variable int agentIndex = 0
			agentIndex:Set[${Agent[${name}].Index}]
		    if (${agentIndex} <= 0)
		    {
		        UI:UpdateConsole["obj_Agents: ERROR!  Cannot get Index for Agent ${name}.", LOG_CRITICAL]
				This.AgentName:Set[""]
		    }
			else
			{
				This.AgentName:Set[${name}]
				UI:UpdateConsole["obj_Agents: Updating agent data for ${name} ${agentIndex}."]
				Config.Agents:SetAgentIndex[${name},${agentIndex}]
				Config.Agents:SetAgentID[${name},${Agent[${agentIndex}].ID}]
				Config.Agents:SetLastDecline[${name},0]
			}
		}
	}

	member:string ActiveAgent()
	{
		return ${This.AgentName}
	}
 
	member:bool InAgentStation() 
	{
		return ${Station.DockedAtStation[${Agent[${This.AgentIndex}].StationID}]}
	}

	member:string PickupStation()
	{
		variable string rVal = ""

	    variable index:agentmission amIndex
	    variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

	    EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]	
	
		if ${amIterator:First(exists)}	
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["objective.source"]}
							{
								variable int pos
								rVal:Set[${mbIterator.Value.Label}]
								pos:Set[${rVal.Find[" - "]}]
								rVal:Set[${rVal.Right[${Math.Calc[${rVal.Length}-${pos}-2]}]}]
								UI:UpdateConsole["obj_Agents: rVal = ${rVal}"]
								break
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}

				if ${rVal.Length} > 0
				{
					break
				}
			}
			while ${amIterator:Next(exists)}
		}


		return ${rVal}
	}

	/*  1) Check for offered (but unaccepted) missions
	 *  2) Check the agent list for the first valid agent
	 */
	method PickAgent()
	{
	    variable index:agentmission amIndex
		variable iterator amIterator
		variable set skipList
		variable time lastDecline
		lastDecline:Set[${Config.Agents.LastDecline[${This.AgentName}]}]
		lastDecline.Hour:Inc[4]
		lastDecline:Update
		;echo "${lastDecline.Timestamp} - ${Time.Timestamp}"
		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]
		;UI:UpdateConsole["obj_Agents: DEBUG: amIndex.Used = ${amIndex.Used}"]
		if ${This.AgentList.agentIterator:First(exists)}
		{
			do
			{
				if ${amIterator:First(exists)}
				{
					do
					{

							;UI:UpdateConsole["obj_Agents: DEBUG: This.AgentID = ${This.AgentID}"]
							;UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]
							;UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]
							;UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]
							if ${amIterator.Value.State} == 1
							{					
								if ${MissionBlacklist.IsBlacklisted[${Agent[id,${amIterator.Value.AgentID}].Level},"${amIterator.Value.Name}"]} == FALSE
								{
									variable bool isLowSec
									variable bool avoidLowSec
									isLowSec:Set[${Missions.MissionCache.LowSec[${amIterator.Value.AgentID}]}]
				
									if ${isLowSec} == FALSE
									{

										if ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
										{
											This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}]}]
											return
										}

										if ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
										{
											This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}]}]
											return
										}

										if ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
										{
											This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}]}]
											return
										}

										if ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
										{
											;UI:UpdateConsole["Setting ActiveAgent to ${Agent[id,${amIterator.Value.AgentID}].Name}"]
											This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}].Name}]
											return
										}
								}
							}
							else
							{
								/* if we get here the mission is not acceptable */
								lastDecline:Set[${Config.Agents.LastDecline[${Agent[id,${amIterator.Value.AgentID}]}]}]
								UI:UpdateConsole["obj_Agents: DEBUG: lastDecline = ${lastDecline}"]
								lastDecline.Hour:Inc[4]
								lastDecline:Update
								;echo "${Math.Calc[${lastDecline.Timestamp} - ${Time.Timestamp}]}"
								if ${lastDecline.Timestamp} >= ${Time.Timestamp}
								{
									UI:UpdateConsole["obj_Agents: DEBUG: Skipping mission to avoid standing loss: ${amIterator.Value.Name}"]
									skipList:Add[${amIterator.Value.AgentID}]
								}
								;else
								;{
								;	if ${Agent[id,${amIterator.Value.AgentID}].Name.Equal[${This.AgentList.agentIterator.Key}]}
								;	{
								;		UI:UpdateConsole["Looks like agent ${Agent[id,${amIterator.Value.AgentID}].Name}'s mission can be declined. Setting Active Agent."]
								;		This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}].Name}]
								;		return
								;	}
								;}
							}
						}
					}
					while ${amIterator:Next(exists)}
				}
			}
			while ${This.AgentList.agentIterator:Next(exists)}

		}
		else
		{
			UI:UpdateConsole["No agents found in agent list, please check you have a valid agent list in the config folder."]
		}

		/* if we get here none of the missions in the journal are valid */
		variable string agentName
		agentName:Set[${This.AgentList.NextAvailableResearchAgent}]
		while ${agentName.NotEqual["NULL"]}
		{
			if ${skipList.Contains[${Config.Agents.AgentID[${agentName}]}]} == FALSE
			{
				UI:UpdateConsole["obj_Agents: DEBUG: Setting agent to ${agentName}"]
				This:SetActiveAgent[${agentName}]
				return
			}
			agentName:Set[${This.AgentList.NextAvailableResearchAgent}]
		}

		

		if ${This.AgentList.agentIterator:First(exists)}
		{
			do
			{
				if ${skipList.Contains[${Config.Agents.AgentID[${This.AgentList.agentIterator.Key}]}]} == FALSE && !${This.AgentList.agentIterator.Key.Equal[${This.AgentName}]}
				{
					UI:UpdateConsole["obj_Agents: DEBUG: Setting agent to ${This.AgentList.agentIterator.Key}"]
					This:SetActiveAgent[${This.AgentList.agentIterator.Key}]
					return
				}
			}
			while ${This.AgentList.agentIterator:Next(exists)}
		}
		/* we should never get here */
		UI:UpdateConsole["obj_Agents.PickAgent: DEBUG: Script paused."]
		Script:Pause
	}

	member:string DropOffStation()
	{
		variable string rVal = ""

	    variable index:agentmission amIndex
	    variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

	    EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["objective.destination"]}
							{
								variable int pos
								rVal:Set[${mbIterator.Value.Label}]
								pos:Set[${rVal.Find[" - "]}]
								rVal:Set[${rVal.Right[${Math.Calc[${rVal.Length}-${pos}-2]}]}]
								UI:UpdateConsole["obj_Agents: rVal = ${rVal}"]
								break
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}

				if ${rVal.Length} > 0
				{
					break
				}
			}
			while ${amIterator:Next(exists)}
		}


		return ${rVal}
	}

	member:bool HaveMission()
	{
	    variable index:agentmission amIndex
		variable iterator amIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.State} > 1
				{
						variable bool isLowSec
						variable bool avoidLowSec
						isLowSec:Set[${Missions.MissionCache.LowSec[${amIterator.Value.AgentID}]}]
						avoidLowSec:Set[${Config.Missioneer.AvoidLowSec}]
						if ${avoidLowSec} == FALSE || (${avoidLowSec} == TRUE && ${isLowSec} == FALSE)
						{
							if ${This.AgentID} != ${amIterator.Value.AgentID}
							{
								This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}].Name}]
							}
							if ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
							{
								return TRUE
							}

							if ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
							{
								return TRUE
							}

							if ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
							{
								return TRUE
							}

							if ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
							{
								return TRUE
							}
						}
				}
			}
			while ${amIterator:Next(exists)}
		}
		;We can only come to this point if we have no accepted missions
	/*	if ${amIterator:First(exists)}
		{
			;iterate though agent missions
			do
			{
				if ${This.AgentList.agentIterator:First(exists)}
				{
					;iterate through agents in our agent list
					do
					{
						lastDecline:Set[${Config.Agents.LastDecline[${This.AgentList.agentIterator.Key}]}]
						;UI:UpdateConsole["obj_Agents: DEBUG: lastDecline = ${lastDecline}"]
						lastDecline.Hour:Inc[4]
						lastDecline:Update
						;echo "${Math.Calc[${lastDecline.Timestamp} - ${Time.Timestamp}]}"
						if ${This.AgentList.agentIterator.Key.Equal[${Agent[id,${amIterator.Value.AgentID}].Name}]} && ${lastDecline.Timestamp} <= ${Time.Timestamp} && \
						${This.AgentList.agentIterator.Key.Equal[${This.AgentName}]}
						{
							UI:UpdateConsole["WE can move back an agent."]
							return FALSE
						}

					}
					while ${This.AgentList.agentIterator:Next(exists)}
 				}
			}
			while ${amIterator:Next(exists)}
		} */
		/*
		if ${This.AgentList.agentIterator:First(exists)}
		{
			do
			{
				amIndex:RemoveByQuery[${LavishScript.CreateQuery[AgentID != ${Agent[name,${This.AgentList.agentIterator.Key}].ID}]}]
				amIndex:Collapse
				if ${amIndex.Used} == 0 
				{
					if !${This.AgentName.Equal[${This.AgentList.agentIterator.Key}]}
					{
						UI:UpdateConsole["We have an agent without a mission, setting this to active agent"]
						This:SetActiveAgent[${This.AgentList.agentIterator.Key}]
						return FALSE
					}
					else
					{
						return FALSE
					}
				}

			}
			while ${This.AgentList.agentIterator:Next(exists)}
		}
		This:PickAgent */
		return FALSE
	}

	member:string MissionName()
	{
	    variable index:agentmission amIndex
		variable iterator amIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.State} > 1 && ${amIterator.Value.AgentID.Equal[This.AgentID]} 
				{
						variable bool isLowSec
						variable bool avoidLowSec
						isLowSec:Set[${Missions.MissionCache.LowSec[${amIterator.Value.AgentID}]}]
						avoidLowSec:Set[${Config.Missioneer.AvoidLowSec}]
						if ${avoidLowSec} == FALSE || (${avoidLowSec} == TRUE && ${isLowSec} == FALSE)
						{
							if ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
							{
								return ${amIterator.Name}
							}

							if ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
							{
								return ${amIterator.Name}
							}

							if ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
							{
								return ${amIterator.Name}
							}

							if ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
							{
								return ${amIterator.Name}
							}
						}
				}
			}
			while ${amIterator:Next(exists)}
		}

		return NULL
	}








	function MoveToPickup()
	{
		variable string stationName
		stationName:Set[${EVEDB_Stations.StationName[${Me.StationID}]}]
		UI:UpdateConsole["obj_Agents: DEBUG: stationName = ${stationName}"]

		if ${stationName.Length} > 0
		{	
			if ${stationName.NotEqual[${This.PickupStation}]}
			{
				call This.WarpToPickupStation
			}
		}
		else
		{
			call This.WarpToPickupStation
		}

		; sometimes Ship.WarpToBookmark fails so make sure we are docked
		if !${Station.Docked}
		{
			UI:UpdateConsole["obj_Agents.MoveToPickup: ERROR!  Not Docked."]
			call This.WarpToPickupStation
		}
	}

	function MoveToDropOff()
	{
		variable string stationName
		stationName:Set[${EVEDB_Stations.StationName[${Me.StationID}]}]
		UI:UpdateConsole["obj_Agents: DEBUG: stationName = ${stationName}"]

		if ${stationName.Length} > 0
		{
			if ${stationName.NotEqual[${This.DropOffStation}]}
			{
				call This.WarpToDropOffStation
			}
		}
		else
		{
			call This.WarpToDropOffStation
		}

		; sometimes Ship.WarpToBookmark fails so make sure we are docked
		if !${Station.Docked}
		{
			UI:UpdateConsole["obj_Agents.MoveToDropOff: ERROR!  Not Docked."]
			call This.WarpToDropOffStation
		}
		if !${Station.Docked}
		{
			UI:UpdateConsole["obj_Agents.MoveToDropOff: ERROR!  Not Docked."]
			call This.WarpToDropOffStation
		}
	}

	function WarpToPickupStation()
	{
	    variable index:agentmission amIndex
	    variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

	    EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["objective.source"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value.ID}
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

	function WarpToDropOffStation()
	{
	    variable index:agentmission amIndex
	    variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

	    EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["objective.destination"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value.ID}
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

	function MoveTo()
	{
		if !${This.InAgentStation}
		{
			if ${Station.Docked}
			{
				call Station.Undock
			}
			;UI:UpdateConsole["obj_Agents: DEBUG: Agent Name -> Index = ${This.AgentIndex} = ${Agent[${This.AgentName}].Index}"]
			;UI:UpdateConsole["obj_Agents: DEBUG: Agent Index->Name = ${Agent[${This.AgentIndex}].Name}"]
			;UI:UpdateConsole["obj_Agents: DEBUG: Agent Name->System  = ${Universe[${Agent[${This.AgentName}].Solarsystem}].ID}"]
			;UI:UpdateConsole["obj_Agents: DEBUG: agent Index->System = ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}"]
			;UI:UpdateConsole["obj_Agents: DEBUG: agentStation = ${Agent[${This.AgentIndex}].StationID}"]
			call Ship.TravelToSystem ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}
			wait 50
			call Station.DockAtStation ${Agent[${This.AgentIndex}].StationID}
		}
	}

	function MissionDetails()
	{

	    variable index:agentmission amIndex
		variable iterator amIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					break
				}
			}
			while ${amIterator:Next(exists)}
		}

		if !${amIterator.Value(exists)}
		{
			UI:UpdateConsole["obj_Agents: ERROR: Did not find mission!  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				UI:UpdateConsole["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

		RetryCount:Set[0]

		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Name = ${amIterator.Value.Name}"]
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.ExpirationTime = ${amIterator.Value.ExpirationTime.DateAndTime}"]

		amIterator.Value:GetDetails
		variable string details
		variable string caption
		variable int left = 0
		variable int right = 0
		caption:Set["Mission Journal - ${This.ActiveAgent}"]
		left:Set[${caption.Escape.Find["u2013"]}]

		if ${left} > 0
		{
			UI:UpdateConsole["obj_Agents: WARNING: Mission name contains u2013"]
			UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Name.Escape = ${amIterator.Value.Name.Escape}"]

			caption:Set["${caption.Escape.Right[${Math.Calc[${caption.Escape.Length} - ${left} - 5]}]}"]

			UI:UpdateConsole["obj_Agents: DEBUG: caption.Escape = ${caption.Escape}"]
		}

		while !${EVEWindow[ByCaption,"${caption}"](exists)}
		{
			UI:UpdateConsole["obj_Agents: ERROR: Mission details window was not found!"]
			wait 10
		}
		; The embedded quotes look odd here, but this is required to escape the comma that exists in the caption and in the resulting html.
		details:Set["${EVEWindow[ByCaption,"${caption}"].HTML.Escape}"]

		UI:UpdateConsole["obj_Agents: DEBUG: HTML.Length = ${EVEWindow[ByCaption,${caption}].HTML.Length}"]
		UI:UpdateConsole["obj_Agents: DEBUG: details.Length = ${details.Length}"]

		EVE:Execute[CmdCloseActiveWindow]

		variable file detailsFile
		detailsFile:SetFilename["./config/logs/${amIterator.Value.ExpirationTime.AsInt64.Hex} ${amIterator.Value.Name.Replace[",",""]}.html"]
		if ${detailsFile:Open(exists)}
		{
			detailsFile:Write["${details.Escape}"]
		}
		detailsFile:Close

		Missions.MissionCache:AddMission[${amIterator.Value.AgentID},"${amIterator.Value.Name}"]

		variable int factionID = 0
		left:Set[${details.Escape.Find["<img src=\\\"factionlogo:"]}]
		if ${left} > 0
		{
			;UI:UpdateConsole["obj_Agents: DEBUG: Found \"factionlogo\" at ${left}."]
			left:Inc[23]
			;UI:UpdateConsole["obj_Agents: DEBUG: Found \"factionlogo\" at ${left}."]
			;UI:UpdateConsole["obj_Agents: DEBUG: factionlogo substring = ${details.Escape.Mid[${left},16]}"]
			right:Set[${details.Escape.Mid[${left},16].Find["\" "]}]
			if ${right} > 0
			{
				right:Dec[2]
				;UI:UpdateConsole["obj_Agents: DEBUG: left = ${left}"]
				;UI:UpdateConsole["obj_Agents: DEBUG: right = ${right}"]
				;UI:UpdateConsole["obj_Agents: DEBUG: string = ${details.Escape.Mid[${left},${right}]}"]
				factionID:Set[${details.Escape.Mid[${left},${right}]}]
				UI:UpdateConsole["obj_Agents: DEBUG: factionID = ${factionID}"]
			}
			else
			{
				UI:UpdateConsole["obj_Agents: ERROR: Did not find end of \"factionlogo\"!"]
			}
		}
		else
		{
			UI:UpdateConsole["obj_Agents: DEBUG: Did not find \"factionlogo\".  Rouge Drones???"]
		}

		Missions.MissionCache:SetFactionID[${amIterator.Value.AgentID},${factionID}]

		variable int typeID = 0
		left:Set[${details.Escape.Find["<img src=\\\"typeicon:"]}]
		if ${left} > 0
		{
			;UI:UpdateConsole["obj_Agents: DEBUG: Found \"typeicon\" at ${left}."]
			left:Inc[20]
			;UI:UpdateConsole["obj_Agents: DEBUG: typeicon substring = ${details.Escape.Mid[${left},16]}"]
			right:Set[${details.Escape.Mid[${left},16].Find["\" "]}]
			if ${right} > 0
			{
				right:Dec[2]
				;UI:UpdateConsole["obj_Agents: DEBUG: left = ${left}"]
				;UI:UpdateConsole["obj_Agents: DEBUG: right = ${right}"]
				;UI:UpdateConsole["obj_Agents: DEBUG: string = ${details.Escape.Mid[${left},${right}]}"]
				typeID:Set[${details.Escape.Mid[${left},${right}]}]
				UI:UpdateConsole["obj_Agents: DEBUG: typeID = ${typeID}"]
			}
			else
			{
				UI:UpdateConsole["obj_Agents: ERROR: Did not find end of \"typeicon\"!"]
			}
		}
		else
		{
			UI:UpdateConsole["obj_Agents: DEBUG: Did not find \"typeicon\".  No cargo???"]
		}

		Missions.MissionCache:SetTypeID[${amIterator.Value.AgentID},${typeID}]

		variable float volume = 0

		right:Set[${details.Escape.Find["msup3"]}]
		if ${right} > 0
		{
			;UI:UpdateConsole["obj_Agents: DEBUG: Found \"msup3\" at ${right}."]
			right:Dec
			left:Set[${details.Escape.Mid[${Math.Calc[${right}-16]},16].Find[" ("]}]
			if ${left} > 0
			{
				left:Set[${Math.Calc[${right}-16+${left}+1]}]
				right:Set[${Math.Calc[${right}-${left}]}]
				;UI:UpdateConsole["obj_Agents: DEBUG: left = ${left}"]
				;UI:UpdateConsole["obj_Agents: DEBUG: right = ${right}"]
				;UI:UpdateConsole["obj_Agents: DEBUG: string = ${details.Escape.Mid[${left},${right}]}"]
				volume:Set[${details.Escape.Mid[${left},${right}]}]
				UI:UpdateConsole["obj_Agents: DEBUG: volume = ${volume}"]
			}
			else
			{
				UI:UpdateConsole["obj_Agents: ERROR: Did not find number before \"msup3\"!"]
			}
		}
		else
		{
			UI:UpdateConsole["obj_Agents: DEBUG: Did not find \"msup3\".  No cargo???"]
		}

		Missions.MissionCache:SetVolume[${amIterator.Value.AgentID},${volume}]

   		variable bool isLowSec = FALSE
		left:Set[${details.Escape.Find["(Low Sec Warning!)"]}]
        right:Set[${details.Escape.Find["(The route generated by current autopilot settings contains low security systems!)"]}]
		if ${left} > 0 || ${right} > 0
		{
            UI:UpdateConsole["obj_Agents: DEBUG: left = ${left}"]
            UI:UpdateConsole["obj_Agents: DEBUG: right = ${right}"]
			isLowSec:Set[TRUE]
			UI:UpdateConsole["obj_Agents: DEBUG: isLowSec = ${isLowSec}"]
		}
		Missions.MissionCache:SetLowSec[${amIterator.Value.AgentID},${isLowSec}]


  }

	function RequestMission()
	{
		variable index:dialogstring dsIndex
		variable iterator dsIterator

		if ${Agent[${This.AgentIndex}].Division.Equal["R&D"]}
		{
			UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: R&D agents not supported after patch. OWNED!"]
			return
		}

		EVE:Execute[CmdCloseAllWindows]
		EVE:Execute[OpenJournal]
		wait 20

		UI:UpdateConsole["obj_Agents: Starting conversation with agent ${This.ActiveAgent}."]
		Agent[${This.AgentIndex}]:StartConversation
		do
		{
			UI:UpdateConsole["obj_Agents: Waiting for conversation window..."]
			wait 100
		}
		while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}

		;; The dialog caption fills in long before the details do.
		;; Wait for dialog strings to become valid before proceeding.
		variable int WaitCount
		Agent[${This.AgentIndex}]:GetDialogResponses[dsIndex]
		while ${dsIndex.Used} == 0
		{
			UI:UpdateConsole["Waiting for responses from agent to populate."]
			wait 10
		}
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]
	    Agent[${This.AgentIndex}]:GetDialogResponses[dsIndex]
	    if ${dsIndex.Used.Equal[2]} && ${dsIndex[1].Text.Find["View"]} > 0 || ${dsIndex[1].Text.Find["Request"]} > 0
	    {
	    	UI:UpdateConsole["obj_Agents: Locator Agent detected, selecting view mission button."]
	    	dsIndex[1]:Say[${This.AgentID}]	
	    	while ${dsIndex.Used.Equal[2]}
	    	{
	    		UI:UpdateConsole["Waiting for locator agent conversation to update."]
	    		Agent[${This.AgentIndex}]:GetDialogResponses[dsIndex]
	    		wait 20
	    	}
	    }
	    dsIndex:GetIterator[dsIterator]
		if ${dsIndex.Used} != 3
		{
			UI:UpdateConsole["obj_Agents: ERROR: Did not find expected dialog! Found ${dsIndex.Used} responses.  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				UI:UpdateConsole["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

	    wait 10


	    variable index:agentmission amIndex
		variable iterator amIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					break
				}
			}
			while ${amIterator:Next(exists)}
		}

		if !${amIterator.Value(exists)}
		{
			UI:UpdateConsole["obj_Agents: ERROR: Did not find mission!  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{	
				UI:UpdateConsole["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

		RetryCount:Set[0]
		call This.MissionDetails
		isLowSec:Set[${Missions.MissionCache.LowSec[${amIterator.Value.AgentID}]}]
		variable time lastDecline
		lastDecline:Set[${Config.Agents.LastDecline[${This.AgentName}]}]
		lastDecline.Hour:Inc[4]
		lastDecline:Update
		if ${isLowSec}
		{
			UI:UpdateConsole["LowSec Mission found: DANGER! DANGER! DANGER!"]
		}
		if ${isLowSec} && ${Config.Missioneer.AvoidLowSec} == TRUE
		{
			if ${lastDecline.Timestamp} >= ${Time.Timestamp}
			{
				UI:UpdateConsole["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
				This:SetActiveAgent[${This.AgentList.NextAgent}]
				return
			}
			else
			{
				dsIndex.Get[2]:Say[${This.AgentID}]
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				UI:UpdateConsole["obj_Agents: Declined low-sec mission."]
				Config:Save[]
			}
		}
		elseif ${MissionBlacklist.IsBlacklisted[${Agent[id,${amIterator.Value.AgentID}].Level},"${amIterator.Value.Name}"]} == TRUE
		{
			if ${lastDecline.Timestamp} >= ${Time.Timestamp}
			{
				UI:UpdateConsole["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
				call ChatIRC.Say "${Me.Name}: Can't decline blacklisted mission, changing agent."
				This:SetActiveAgent[${This.AgentList.NextAgent}]
				return
			}
			else
			{
				dsIndex.Get[2]:Say[${This.AgentID}]
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				UI:UpdateConsole["obj_Agents: Declined blacklisted mission."]
				call ChatIRC.Say "${Me.Name}: Declined blacklisted mission."
				Config:Save[]
			}
		}
			if ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
			{
				UI:UpdateConsole["Saying ${dsIndex[1].Text}"]
				dsIndex[1]:Say[${This.AgentID}]
			}
			elseif ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
			{
				UI:UpdateConsole["Saying ${dsIndex[1].Text}"]
				dsIndex[1]:Say[${This.AgentID}]
			}
			elseif ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
			{
				UI:UpdateConsole["Saying ${dsIndex[1].Text}"]
				dsIndex[1]:Say[${This.AgentID}]
			}
			elseif ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
			{
				UI:UpdateConsole["Saying ${dsIndex[1].Text}"]
				dsIndex[1]:Say[${This.AgentID}]
			}
			else
			{
				if ${lastDecline.Timestamp} >= ${Time.Timestamp}
				{
					UI:UpdateConsole["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
					This:SetActiveAgent[${This.AgentList.NextAgent}]
					return
				}
				else
				{
					dsIndex.Get[2]:Say[${This.AgentID}]
					Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
					UI:UpdateConsole["obj_Agents: Declined mission."]
					Config:Save[]
				}
			}



	  ; UI:UpdateConsole["Waiting for mission dialog to update..."]	
	    wait 60
	    if ${Agent[${This.AgentIndex}].Dialog.Length]} <= 4
	    {
	    	UI:UpdateConsole["Null dialog found, this is a bug, and I don't know what to do about it."]
	    }
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVE:Execute[CmdCloseActiveWindow]
		wait 50
    	EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	}

	function TurnInMission()
	{
		EVE:Execute[CmdCloseAllWindows]
		wait 50

		UI:UpdateConsole["obj_Agents: Starting conversation with agent ${This.ActiveAgent}."]\
		Agent[${This.ActiveAgent}]:StartConversation 
        do
        {
			UI:UpdateConsole["obj_Agents: Waiting for conversation window..."]
			Agent[${This.ActiveAgent}]:StartConversation
            wait 10
        }
        while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}

		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

	    ; display your dialog options
	    variable index:dialogstring dsIndex
	    variable iterator dsIterator

	    Agent[${This.AgentIndex}]:GetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]

		if ${dsIterator:First(exists)}
		{
			if ${dsIterator.Value.Text.Find[Complete]}
			{
				; Assume the first item is the "turn in mission" item.
		        dsIterator.Value:Say[${This.AgentID}]
				Config.Agents:SetLastCompletionTime[${This.AgentName},${Time.Timestamp}]
			}
		}

	    ; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
	    UI:UpdateConsole["Waiting for agent dialog to update..."]
	    wait 60
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVE:Execute[CmdCloseActiveWindow]
		wait 50
		Relay all Event[ToSalvage]:Execute
	}

	function QuitMission()
	{
		EVE:Execute[CmdCloseAllWindows]
		wait 50

		UI:UpdateConsole["obj_Agents: Starting conversation with agent ${This.ActiveAgent}."]
		Agent[${This.AgentIndex}]:StartConversation
        do
        {
			UI:UpdateConsole["obj_Agents: Waiting for conversation window..."]
            wait 10
        }
        while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}

		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

	    ; display your dialog options
	    variable index:dialogstring dsIndex
	    variable iterator dsIterator

	    Agent[${This.AgentIndex}]:GetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]

		if ${dsIndex.Used} == 2
		{
			; Assume the second item is the "quit mission" item.
	        dsIndex.Get[2]:Say[${This.AgentID}]
		}

	    ; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
	    UI:UpdateConsole["Waiting for agent dialog to update..."]
	    wait 60
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVE:Execute[CmdCloseActiveWindow]
		wait 50

    	EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	}
}
