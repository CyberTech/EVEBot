/*
    Agents class

    Object to contain members related to agents.

    -- GliderPro

*/

objectdef obj_AgentList
{
	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Agents.xml"
	variable string SET_NAME1 = "${Me.Name} Agents"
	variable string SET_NAME2 = "${Me.Name} Research Agents"
	variable iterator agentIterator
	variable iterator researchAgentIterator

	method Initialize()
	{
		LavishSettings[${This.SET_NAME1}]:Remove
		LavishSettings[${This.SET_NAME2}]:Remove

		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME1}]:GetSettingIterator[This.agentIterator]
		if !${This.agentIterator:First(exists)}
		{
			Logger:Log["obj_AgentList: Found no agents"]
		}
		LavishSettings[${This.SET_NAME2}]:GetSettingIterator[This.researchAgentIterator]
		if !${This.agentIterator:First(exists)}
		{
			Logger:Log["obj_AgentList: Found no research agents"]
		}
		Logger:Log["obj_AgentList: Initialized.", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME1}]:Remove
		LavishSettings[${This.SET_NAME2}]:Remove
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
				Logger:Log["DEBUG: Last mission for ${This.researchAgentIterator.Key} was completed at ${lastCompletionTime} on ${lastCompletionTime.Date}."]
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
	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Mission Blacklist.xml"
	variable string SET_NAME = "${Me.Name} Mission Blacklist"
	variable iterator levelIterator

	method Initialize()
	{
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME}]:GetSetIterator[This.levelIterator]
		Logger:Log["obj_MissionBlacklist: Initialized.", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
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

		;Logger:Log["DEBUG: obj_MissionBlacklist: Searching for ${levelString} mission blacklist...", LOG_DEBUG]

		if ${This.levelIterator:First(exists)}
		{
			do
			{
				if ${levelString.Equal[${This.levelIterator.Key}]}
				{
					Logger:Log["DEBUG: obj_MissionBlacklist: Searching ${levelString} mission blacklist for ${mission}...", LOG_DEBUG]

					variable iterator missionIterator

					This.levelIterator.Value:GetSettingIterator[missionIterator]
					if ${missionIterator:First(exists)}
					{
						do
						{
							if ${mission.Equal[${missionIterator.Key}]}
							{
								Logger:Log["DEBUG: obj_MissionBlacklist: ${mission} is blacklisted!", LOG_DEBUG]
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
	variable string BUTTON_REQUEST_MISSION = "Request Mission"
	variable string BUTTON_VIEW_MISSION = "View Mission"
	variable string BUTTON_BUY_DATACORES = "Buy Datacores"
	variable string BUTTON_ACCEPT_MISSION = "Accept"
	variable string BUTTON_DECLINE_MISSION = "Decline"
	variable string BUTTON_COMPLETE_MISSION = "Complete Mission"
	variable string BUTTON_QUIT_MISSION = "Quit Mission"
	variable string BUTTON_CLOSE_MISSION = "Close"

	variable string AgentName
	variable string MissionDetails
	variable int RetryCount = 0
	variable obj_AgentList AgentList
	variable obj_MissionBlacklist MissionBlacklist
	variable set skipList

    method Initialize()
    {
		This.skipList:Clear
    	if ${This.AgentList.agentIterator:First(exists)}
    	{
    		;This:SetActiveAgent[${This.AgentList.FirstAgent}]
    		This:PickAgent
    		Logger:Log["obj_Agents: Initialized", LOG_MINOR]
    	}
    	else
    	{
			Logger:Log["obj_Agents: Initialized (No Agents Found)", LOG_MINOR]
		}
    }

	method Shutdown()
	{
	}

	member:int AgentIndex()
	{
		return ${EVE.Agent[${This.ActiveAgent}].Index}
	}

	member:int AgentID()
	{
		return ${Config.Agents.AgentID[${This.AgentName}]}
	}

	method SetActiveAgent(string name)
	{
		Logger:Log["obj_Agents: SetActiveAgent ${name}"]

		if ${Config.Agents.AgentIndex[${name}]} > 0
		{
			Logger:Log["obj_Agents: SetActiveAgent: Found agent data. (${Config.Agents.AgentIndex[${name}]})"]
			This.AgentName:Set[${name}]
		}
		else
		{
			variable int agentIndex = 0
			agentIndex:Set[${EVE.Agent[${name}].Index}]
			if (${agentIndex} <= 0)
			{
				Logger:Log["obj_Agents: ERROR!  Cannot get Index for Agent ${name}.", LOG_CRITICAL]
				This.AgentName:Set[""]
			}
			else
			{
				This.AgentName:Set[${name}]
				Logger:Log["obj_Agents: Updating agent data for ${name} ${agentIndex}"]
				Config.Agents:SetAgentIndex[${name},${agentIndex}]
				Config.Agents:SetAgentID[${name},${EVE.Agent[${agentIndex}].ID}]
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
		return ${Station.DockedAtStation[${EVE.Agent[${This.AgentIndex}].StationID}]}
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
								Logger:Log["obj_Agents: rVal = ${rVal}"]
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

	/*
		1) Check for offered (but unaccepted) missions
		2) Check the agent list for the first valid agent
	*/
	method PickAgent()
	{
		variable index:agentmission amIndex
		variable iterator MissionInfo

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[MissionInfo]

		Logger:Log["obj_Agents: DEBUG: Active/Offered Missions:  ${amIndex.Used}", LOG_DEBUG]
		if ${MissionInfo:First(exists)}
		{
			do
			{
				Logger:Log["obj_Agents: DEBUG: This.AgentID = ${This.AgentID}"]
				Logger:Log["obj_Agents: DEBUG: MissionInfo.AgentID = ${MissionInfo.Value.AgentID}"]
				Logger:Log["obj_Agents: DEBUG: MissionInfo.State = ${MissionInfo.Value.State}"]
				Logger:Log["obj_Agents: DEBUG: MissionInfo.Type = ${MissionInfo.Value.Type}"]
				if ${MissionInfo.Value.State} == 1
				{
					variable bool isLowSec
					isLowSec:Set[${Missions.MissionCache.LowSec[${MissionInfo.Value.AgentID}]}]

					if (!${Config.Missioneer.AvoidLowSec} || \
						(${Config.Missioneer.AvoidLowSec} && !${isLowSec})) && \
						!${MissionBlacklist.IsBlacklisted[${EVE.Agent[id,${MissionInfo.Value.AgentID}].Level},"${MissionInfo.Value.Name}"]}
					{
						if (${MissionInfo.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions}) || \
							(${MissionInfo.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} || \
							(${MissionInfo.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} || \
							(${MissionInfo.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions})
						{
							This:SetActiveAgent[${EVE.Agent[id,${MissionInfo.Value.AgentID}].Name}]
							return
						}
					}

					/* if we get here the mission is not acceptable */
					variable time lastDecline
					lastDecline:Set[${Config.Agents.LastDecline[${EVE.Agent[id,${MissionInfo.Value.AgentID}].Name}]}]
					Logger:Log["obj_Agents: DEBUG: lastDecline = ${lastDecline}"]
					lastDecline.Hour:Inc[4]
					lastDecline:Update
					if ${lastDecline.Timestamp} >= ${Time.Timestamp}
					{
						Logger:Log["obj_Agents: DEBUG: Skipping mission to avoid standing loss: ${MissionInfo.Value.Name}"]
						skipList:Add[${MissionInfo.Value.AgentID}]
						continue
					}
				}
			}
			while ${MissionInfo:Next(exists)}
		}

		/* if we get here none of the missions in the journal are valid */
		variable string agentName
		agentName:Set[${This.AgentList.NextAvailableResearchAgent}]
		while ${agentName.NotEqual["NULL"]}
		{
			if ${skipList.Contains[${Config.Agents.AgentID[${agentName}]}]} == FALSE
			{
				Logger:Log["obj_Agents: DEBUG: Setting agent to ${agentName}"]
				This:SetActiveAgent[${agentName}]
				return
			}
			else
			{
				Logger:Log["obj_Agents: DEBUG: Skipping research agent ${agentName}, in skiplist", LOG_DEBUG]
			}
			agentName:Set[${This.AgentList.NextAvailableResearchAgent}]
		}

		if ${This.AgentList.agentIterator:First(exists)}
		{
			do
			{
				if ${skipList.Contains[${Config.Agents.AgentID[${This.AgentList.agentIterator.Key}]}]} == FALSE
				{
					Logger:Log["obj_Agents: Choosing agent ${This.AgentList.agentIterator.Key}"]
					This:SetActiveAgent[${This.AgentList.agentIterator.Key}]
					return
				}
				else
				{
					Logger:Log["obj_Agents: DEBUG: Skipping agent ${This.AgentList.agentIterator.Key}, in skiplist", LOG_DEBUG]
				}
			}
			while ${This.AgentList.agentIterator:Next(exists)}
			; If we fall thru to here, everything was in the skiplist.
			EVEBot:Pause["obj_Agents.PickAgent: ERROR: Script paused. All defined agents are in skiplist."]
		}
		else
		{
			EVEBot:Pause["obj_Agents.PickAgent: ERROR: Script paused. No non-research agents defined."]
		}

		/* we should never get here */
		EVEBot:Pause["obj_Agents.PickAgent: ERROR: Script paused. No Agents defined, or none available"]
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
								Logger:Log["obj_Agents: rVal = ${rVal}"]
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
					isLowSec:Set[${Missions.MissionCache.LowSec[${amIterator.Value.AgentID}]}]

					if (!${Config.Missioneer.AvoidLowSec} || \
						(${Config.Missioneer.AvoidLowSec} && !${isLowSec})) && \
						!${MissionBlacklist.IsBlacklisted[${EVE.Agent[id,${MissionInfo.Value.AgentID}].Level},"${MissionInfo.Value.Name}"]}
					{
						if (${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions}) || \
							(${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} || \
							(${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} || \
							(${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions})
						{
							if ${Missions.MissionCache.Name[${amIterator.Value.AgentID}].Equal[${amIterator.Value.Name}]}
							{
								return TRUE
							}
							else
							{
								Missions.MissionCache:AddMission[${amIterator.Value.AgentID},${amIterator.Value.Name}]
								return TRUE
							}

						}
					}
				}
			}
			while ${amIterator:Next(exists)}
		}

		return FALSE
	}

	function MoveToPickup()
	{
		variable string stationName
		stationName:Set[${EVEDB_Stations.StationName[${Me.StationID}]}]
		Logger:Log["obj_Agents: DEBUG: stationName = ${stationName}"]

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
			Logger:Log["obj_Agents.MoveToPickup: ERROR!  Not Docked."]
			call This.WarpToPickupStation
		}
	}

	function MoveToDropOff()
	{
		variable string stationName
		stationName:Set[${EVEDB_Stations.StationName[${Me.StationID}]}]
		Logger:Log["obj_Agents: DEBUG: stationName = ${stationName}"]

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
			Logger:Log["obj_Agents.MoveToDropOff: ERROR!  Not Docked."]
			call This.WarpToDropOffStation
		}
		if !${Station.Docked}
		{
			Logger:Log["obj_Agents.MoveToDropOff: ERROR!  Not Docked."]
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
							Logger:Log["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["objective.source"]}
							{
								if ${Station.Docked}
								{
									if ${mbIterator.Value.ID} > 0 && ${mbIterator.Value.ID} == ${Me.StationID}
									{
										Logger:Log["${LogPrefix} - FlyToBookmarkID: Already in station ${Me.Station.ID}:${Me.Station.Name}"]
										return
									}
									call Station.Undock
								}
								call Ship.TravelToSystem ${mbIterator.Value.SolarSystemID}
								wait 50
								call Station.DockAtStation ${mbIterator.Value.ID}
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
							Logger:Log["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["objective.destination"]}
							{
								if ${Station.Docked}
								{
									if ${mbIterator.Value.ID} > 0 && ${mbIterator.Value.ID} == ${Me.StationID}
									{
										Logger:Log["${LogPrefix} - FlyToBookmarkID: Already in station ${Me.Station.ID}:${Me.Station.Name}"]
										return
									}
									call Station.Undock
								}
								call Ship.TravelToSystem ${mbIterator.Value.SolarSystemID}
								wait 50
								call Station.DockAtStation ${mbIterator.Value.ID}
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
			;Logger:Log["obj_Agents: DEBUG: Agent Name -> Index = ${This.AgentIndex} = ${EVE.Agent[${This.AgentName}].Index}"]
			;Logger:Log["obj_Agents: DEBUG: Agent Index->Name = ${EVE.Agent[${This.AgentIndex}].Name}"]
			;Logger:Log["obj_Agents: DEBUG: Agent Name->System  = ${Universe[${EVE.Agent[${This.AgentName}].Solarsystem}].ID}"]
			;Logger:Log["obj_Agents: DEBUG: agent Index->System = ${Universe[${EVE.Agent[${This.AgentIndex}].Solarsystem}].ID}"]
			;Logger:Log["obj_Agents: DEBUG: agentStation = ${EVE.Agent[${This.AgentIndex}].StationID}"]
			call Ship.TravelToSystem ${Universe[${EVE.Agent[${This.AgentIndex}].Solarsystem}].ID}
			wait 50
			call Station.DockAtStation ${EVE.Agent[${This.AgentIndex}].StationID}
		}
	}

	function MissionDetails()
	{
		EVEWindow[ByCaption, "Journal"]:Close

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
			Logger:Log["obj_Agents: ERROR: Did not find mission!  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				Logger:Log["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

		RetryCount:Set[0]

		Logger:Log["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.Name = ${amIterator.Value.Name}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.ExpirationTime = ${amIterator.Value.ExpirationTime.DateAndTime}", LOG_DEBUG]

		; Opens the details window for the mission
		amIterator.Value:GetDetails
		wait 50
		variable obj_MissionParser MissionParser

		if ${EVEWindow[ByCaption, "Mission journal - ${This.ActiveAgent}"](exists)}
		{
			; The embedded quotes look odd here, but this is required to escape the comma that exists in the caption and in the resulting html.
			MissionParser.MissionDetails:Set["${EVEWindow[ByCaption,"Mission journal - ${This.ActiveAgent}"].HTML.Escape}"]
			EVEWindow[ByCaption, "Mission journal - ${This.ActiveAgent}"]:Close
		}
		else
		{
			Logger:Log["obj_Agents: ERROR: Mission details window was not found: `Mission journal - ${This.ActiveAgent}` for ${amIterator.Value.Name}", LOG_CRITICAL]
			Logger:Log["obj_Agents: DEBUG: amIterator.Value.Name.Escape = ${amIterator.Value.Name.Escape}"]
			return
		}

		MissionParser.MissionExpiresHex:Set[${amIterator.Value.ExpirationTime.AsInt64.Hex}]
		MissionParser.MissionName:Set[${amIterator.Value.Name}]
		MissionParser:SaveCacheFile

		Missions.MissionCache:AddMission[${amIterator.Value.AgentID},"${amIterator.Value.Name}"]
		Missions.MissionCache:SetFactionID[${amIterator.Value.AgentID},${MissionParser.FactionID}]
		Missions.MissionCache:SetTypeID[${amIterator.Value.AgentID},${MissionParser.TypeID}]
		Missions.MissionCache:SetVolume[${amIterator.Value.AgentID},${MissionParser.Volume}]
		Missions.MissionCache:SetLowSec[${amIterator.Value.AgentID},${MissionParser.IsLowSec}]
	}

	function UpdateAgentDialogue()
	{

	}

	function:bool CheckButtonExists(string buttontext)
	{
		; Logger:Log["obj_Agents: Looking for button '${buttontext}'"]
		variable int Count
		for (Count:Set[1] ; ${Count}<=${EVEWindow[byCaption, Agent Conversation].NumButtons} ; Count:Inc)
		{
			if ${EVEWindow[byCaption, Agent Conversation].Button[${Count}].Text.Equal[${buttontext}]}
			{
				return TRUE
			}
		}
		return FALSE
	}

	function PressButton(string buttontext)
	{
		Logger:Log["obj_Agents: Pressing button '${buttontext}'"]
		do
		{
			EVEWindow[byCaption, Agent Conversation].Button[${buttontext}]:Press
			wait 50
			call This.CheckButtonExists "${buttontext}"
		}
		while ${Return}
	}

	function UpdateLocatorAgent()
	{
		call This.CheckButtonExists "${This.BUTTON_REQUEST_MISSION}"
		if ${Return}
		{
			Logger:Log["obj_Agents: May be a research agent or locator agent, attempting to view mission..."]
			call PressButton "${This.BUTTON_REQUEST_MISSION}"
		}
		else
		{
			call This.CheckButtonExists "${This.BUTTON_VIEW_MISSION}"
			if ${Return}
			{
				Logger:Log["obj_Agents: May be a research agent or locator agent, attempting to view mission..."]
				call PressButton "${This.BUTTON_VIEW_MISSION}"
			}
		}
	}

	function RequestMission()
	{
		Logger:Log["obj_Agents:RequestMission: Starting conversation with agent ${This.ActiveAgent}."]
		EVE.Agent[${This.AgentIndex}]:StartConversation
		do
		{
			Logger:Log["obj_Agents:RequestMission: Waiting for conversation window..."]
			wait 50
		}
		while !${EVEWindow[byCaption, Agent Conversation](exists)}

		call This.UpdateLocatorAgent

		call This.CheckButtonExists "${This.BUTTON_ACCEPT_MISSION}"
		if !${Return}
		{
			Logger:Log["obj_Agents: ERROR: No mission from agent! Maybe finished the daily mission from researcher agent. Switching agents...", LOG_CRITICAL]
			EVEWindow[ByCaption, "Agent Conversation - ${This.ActiveAgent}"]:Close
			This.skipList:Add[${EVE.Agent[${This.AgentIndex}].ID}]
			return
		}

		EVE:Execute[OpenJournal]
		wait 50

		EVEWindow[ByCaption, "Journal"]:Close

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
			Logger:Log["obj_Agents: ERROR: Did not find mission!  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				Logger:Log["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

		RetryCount:Set[0]

		Logger:Log["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.Name = ${amIterator.Value.Name}", LOG_DEBUG]
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.ExpirationTime = ${amIterator.Value.ExpirationTime.DateAndTime}", LOG_DEBUG]

		; Opens the details window for the mission
		amIterator.Value:GetDetails
		wait 50
		variable obj_MissionParser MissionParser

		; Note - if this starts to fail, see MissionParser:UpdateCaption & MissionParser.Caption instead of amIterator.Value.Name for the window.
		if ${EVEWindow[ByCaption,"Mission journal - ${This.ActiveAgent}"](exists)}
		{
			; The embedded quotes look odd here, but this is required to escape the comma that exists in the caption and in the resulting html.
			MissionParser.MissionDetails:Set["${EVEWindow[ByCaption,"Mission journal - ${This.ActiveAgent}"].HTML.Escape}"]
			EVEWindow[ByCaption, "Mission journal - ${This.ActiveAgent}"]:Close
		}
		else
		{
			Logger:Log["obj_Agents: ERROR: Mission details window was not found: `Mission journal - ${This.ActiveAgent}` for ${amIterator.Value.Name}", LOG_CRITICAL]
			Logger:Log["obj_Agents: DEBUG: amIterator.Value.Name.Escape = ${amIterator.Value.Name.Escape}"]
			return
		}

		MissionParser.MissionExpiresHex:Set[${amIterator.Value.ExpirationTime.AsInt64.Hex}]
		MissionParser.MissionName:Set[${amIterator.Value.Name}]
		MissionParser:SaveCacheFile

		Missions.MissionCache:AddMission[${amIterator.Value.AgentID}, "${amIterator.Value.Name}"]
		Missions.MissionCache:SetFactionID[${amIterator.Value.AgentID}, ${MissionParser.FactionID}]
		Missions.MissionCache:SetTypeID[${amIterator.Value.AgentID}, ${MissionParser.TypeID}]
		Missions.MissionCache:SetVolume[${amIterator.Value.AgentID}, ${MissionParser.Volume}]
		Missions.MissionCache:SetLowSec[${amIterator.Value.AgentID}, ${MissionParser.IsLowSec}]

		variable time lastDecline
		lastDecline:Set[${Config.Agents.LastDecline[${This.AgentName}]}]
		lastDecline.Hour:Inc[4]
		lastDecline:Update

		if ${Config.Missioneer.AvoidLowSec} && ${MissionParser.IsLowSec}
		{
			if ${lastDecline.Timestamp} >= ${Time.Timestamp}
			{
				Logger:Log["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
				This:SetActiveAgent[${This.AgentList.NextAgent}]
				return
			}
			else
			{
				call This.PressButton "${This.BUTTON_DECLINE_MISSION}"
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				Logger:Log["obj_Agents: Declined low-sec mission."]
				Config:Save[]
			}
		}
		elseif ${MissionBlacklist.IsBlacklisted[${EVE.Agent[id,${amIterator.Value.AgentID}].Level},"${amIterator.Value.Name}"]} == TRUE
		{
			if ${lastDecline.Timestamp} >= ${Time.Timestamp}
			{
				Logger:Log["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
				call ChatIRC.Say "${Me.Name}: Can't decline blacklisted mission, changing agent."
				This:SetActiveAgent[${This.AgentList.NextAgent}]
				return
			}
			else
			{
				call This.PressButton "${This.BUTTON_DECLINE_MISSION}"
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				Logger:Log["obj_Agents: Declined blacklisted mission."]
				call ChatIRC.Say "${Me.Name}: Declined blacklisted mission."
				Config:Save[]
			}
		}
		elseif ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Courier mission from agent ${This.AgentID}", LOG_DEBUG]
			call This.PressButton "${This.BUTTON_ACCEPT_MISSION}"
		}
		elseif ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Trade mission from agent ${This.AgentID}", LOG_DEBUG]
			call This.PressButton "${This.BUTTON_ACCEPT_MISSION}"
		}
		elseif ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Mining mission from agent ${This.AgentID}", LOG_DEBUG]
			call This.PressButton "${This.BUTTON_ACCEPT_MISSION}"
		}
		elseif ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Kill mission from agent ${This.AgentID}", LOG_DEBUG]
			call This.PressButton "${This.BUTTON_ACCEPT_MISSION}"
		}
		else
		{
			if ${lastDecline.Timestamp} >= ${Time.Timestamp}
			{
				Logger:Log["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
				This:SetActiveAgent[${This.AgentList.NextAgent}]
				return
			}
			else
			{
				call This.PressButton "${This.BUTTON_DECLINE_MISSION}"
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				Logger:Log["obj_Agents: Declined mission."]
				Config:Save[]
			}
		}

		Logger:Log["Waiting for mission dialog to update...", LOG_DEBUG]
		wait 60

		EVEWindow[ByCaption, "Journal"]:Close
		EVEWindow[ByCaption, "Agent Conversation - ${This.ActiveAgent}"]:Close
	}

	function TurnInMission()
	{
		Inventory:Close

		Logger:Log["obj_Agents:TurnInMission: Starting conversation with agent ${This.ActiveAgent}."]
		EVE.Agent[${This.AgentIndex}]:StartConversation
		do
		{
			Logger:Log["obj_Agents:TurnInMission: Waiting for conversation window..."]
			wait 10
		}
		while !${EVEWindow[byCaption, Agent Conversation].NumButtons} > 0

		call This.UpdateLocatorAgent

		Logger:Log["Completing Mission..."]
		call This.PressButton "${This.BUTTON_COMPLETE_MISSION}"

		Logger:Log["Waiting for mission dialog to update..."]
		wait 60

		EVEWindow[ByCaption, "Journal"]:Close
		EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close

		;variable int Waiting = 1200
		;if ${Math.Rand[2]} == 0 && ${Config.Common.Randomize}
		;{
		;	Waiting:Set[${Math.Rand[18000]:Inc[2400]}]
		;}
		;Logger:Log["Delaying ${Math.Calc[${Waiting}/10/60]} minutes before next mission request"]
		;wait ${Waiting} ${EVEBot.Paused}
	}

	function QuitMission()
	{
		echo "CANNOT COMPLETE MISSION - QUIT MISSION OR COMPLETE IT MANUALLY"
		EVEBot:Pause["obj_Agents:QuitMission - CANNOT COMPLETE MISSION - QUIT MISSION OR COMPLETE IT MANUALLY"]
		return

		Logger:Log["obj_Agents:QuitMission: Starting conversation with agent ${This.ActiveAgent}."]
		EVE.Agent[${This.AgentIndex}]:StartConversation
		do
		{
			Logger:Log["obj_Agents:QuitMission: Waiting for conversation window..."]
			wait 10
		}
		while !${EVEWindow[byCaption, Agent Conversation].NumButtons} > 0

		call This.PressButton "${This.BUTTON_QUIT_MISSION}"

		; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
		Logger:Log["Waiting for agent dialog to update..."]
		wait 60

		EVEWindow[ByCaption, "Journal"]:Close
		EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	}
}
