/*
    Agents class

    Object to contain members related to agents.

    -- GliderPro

*/
#define AGENTRESPONSEINDEX_ACCEPT 1
#define AGENTRESPONSEINDEX_DECLINE 2
#define AGENTRESPONSEINDEX_DELAY 3
#define AGENTRESPONSEINDEX_COMPLETE_MISSION 1
#define AGENTRESPONSEINDEX_QUIT_MISSION 2
#define AGENTRESPONSEINDEX_CLOSE 3

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
		LavishSettings[${This.SET_NAME1}]:Remove
		LavishSettings[${This.SET_NAME2}]:Remove

		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME1}]:GetSettingIterator[This.agentIterator]
		LavishSettings[${This.SET_NAME2}]:GetSettingIterator[This.researchAgentIterator]
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
	variable string SVN_REVISION = "$Rev$"
	variable int Version

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

		Logger:Log["DEBUG: obj_MissionBlacklist: Searching for ${levelString} mission blacklist...", LOG_DEBUG]

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
	variable string BUTTON_COMPLETE_MISSION = "Complete Mission"

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
		return ${Config.Agents.AgentIndex[${This.AgentName}]}
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
			agentIndex:Set[${Agent[${name}].Index}]
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

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
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
		variable set skipList

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[MissionInfo]
		skipList:Clear

		Logger:Log["obj_Agents: DEBUG: amIndex.Used = ${amIndex.Used}"]
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
						!${MissionBlacklist.IsBlacklisted[${Agent[id,${MissionInfo.Value.AgentID}].Level},"${MissionInfo.Value.Name}"]}
					{
						if (${MissionInfo.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions}) || \
							(${MissionInfo.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} || \
							(${MissionInfo.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} || \
							(${MissionInfo.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions})
						{
							This:SetActiveAgent[${Agent[id,${MissionInfo.Value.AgentID}]}]
							return
						}
					}

					/* if we get here the mission is not acceptable */
					variable time lastDecline
					lastDecline:Set[${Config.Agents.LastDecline[${Agent[id,${MissionInfo.Value.AgentID}]}]}]
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
			agentName:Set[${This.AgentList.NextAvailableResearchAgent}]
		}

		if ${This.AgentList.agentIterator:First(exists)}
		{
			do
			{
				if ${skipList.Contains[${Config.Agents.AgentID[${This.AgentList.agentIterator.Key}]}]} == FALSE
				{
					Logger:Log["obj_Agents: DEBUG: Setting agent to ${This.AgentList.agentIterator.Key}"]
					This:SetActiveAgent[${This.AgentList.agentIterator.Key}]
					return
				}
			}
			while ${This.AgentList.agentIterator:Next(exists)}
		}

		/* we should never get here */
		Logger:Log["obj_Agents.PickAgent: DEBUG: Script paused."]
		Script:Pause
	}

	member:string DropOffStation()
	{
		variable string rVal = ""

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
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
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

		EVE:DoGetAgentMissions[amIndex]
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
						!${MissionBlacklist.IsBlacklisted[${Agent[id,${MissionInfo.Value.AgentID}].Level},"${MissionInfo.Value.Name}"]}
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
	}

	function WarpToPickupStation()
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
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							Logger:Log["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["objective.source"]}
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

	function WarpToDropOffStation()
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
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							Logger:Log["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["objective.destination"]}
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

	function MoveTo()
	{
		if !${This.InAgentStation}
		{
			if ${Station.Docked}
			{
				call Station.Undock
			}

			;Logger:Log["obj_Agents: DEBUG: agentSystem (byname) = ${Universe[${Agent[${This.AgentName}].Solarsystem}].ID}"]
			;Logger:Log["obj_Agents: DEBUG: agentSystem = ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}"]
			;Logger:Log["obj_Agents: DEBUG: agentStation = ${Agent[${This.AgentIndex}].StationID}"]
			call Ship.TravelToSystem ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}
			wait 50
			call Station.DockAtStation ${Agent[${This.AgentIndex}].StationID}
		}
	}

	function MissionDetails()
	{
		EVE:Execute[OpenJournal]
		wait 50
		EVEWindow[ByCaption, "Journal"]:Close

		variable index:agentmission amIndex
		variable iterator amIterator

		EVE:DoGetAgentMissions[amIndex]
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
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.Expires = ${amIterator.Value.Expires.DateAndTime}", LOG_DEBUG]

		; Opens the details window for the mission
		amIterator.Value:GetDetails
		wait 50
		variable obj_MissionParser MissionParser

		if ${EVEWindow[ByCaption,"${amIterator.Value.Name}"](exists)}
		{
			; The embedded quotes look odd here, but this is required to escape the comma that exists in the caption and in the resulting html.
			MissionParser.MissionDetails:Set["${EVEWindow[ByCaption,"${amIterator.Value.Name}"].HTML.Escape}"]
			EVEWindow[ByCaption, "${amIterator.Value.Name}"]:Close
		}
		else
		{
			Logger:Log["obj_Agents: ERROR: Mission details window was not found: ${amIterator.Value.Name}", LOG_CRITICAL]
			Logger:Log["obj_Agents: DEBUG: amIterator.Value.Name.Escape = ${amIterator.Value.Name.Escape}"]
			return
		}

		MissionParser.MissionExpiresHex:Set[${amIterator.Value.Expires.AsInt64.Hex}]
		MissionParser.MissionName:Set[${amIterator.Value.Name}]
		MissionParser:SaveCacheFile

		Missions.MissionCache:AddMission[${amIterator.Value.AgentID},"${amIterator.Value.Name}"]
		Missions.MissionCache:SetFactionID[${amIterator.Value.AgentID},${MissionParser.FactionID}]
		Missions.MissionCache:SetTypeID[${amIterator.Value.AgentID},${MissionParser.TypeID}]
		Missions.MissionCache:SetVolume[${amIterator.Value.AgentID},${MissionParser.Volume}]
		Missions.MissionCache:SetLowSec[${amIterator.Value.AgentID},${MissionParser.IsLowSec}]
	}

	function RequestMission()
	{
		variable index:dialogstring dsIndex
		variable iterator dsIterator

		Logger:Log["obj_Agents:RequestMission: Starting conversation with agent ${This.ActiveAgent}."]
		Agent[${This.AgentIndex}]:StartConversation
		do
		{
			Logger:Log["obj_Agents:RequestMission: Waiting for conversation window..."]
			wait 10
		}
		while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}

		Logger:Log["obj_Agents: Retrieving Dialog Responses"]
		;; The dialog caption fills in long before the details do.
		;; Wait for dialog strings to become valid before proceeding.
		variable int WaitCount
		for( WaitCount:Set[0]; ${WaitCount} < 6; WaitCount:Inc )
		{
			wait 20
			if ${dsIndex.Used} > 0
			{
				break
			}
			Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
		}
		dsIndex:GetIterator[dsIterator]

		Logger:Log["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		/* Fix for locator agents that also have missions, by Stealthy */
		if (${dsIterator:First(exists)})
		{
			Logger:Log["obj_Agents: Checking agent responses...", LOG_DEBUG]
			do
			{
				Logger:Log["obj_Agents: dsIterator.Value.Text: ${dsIterator.Value.Text}"]

				if ${dsIterator.Value.Text.Find["${This.BUTTON_BUY_DATACORES}"]}
				{
					Logger:Log["obj_Agents: Agent has no mission available, trying next agent"]
					This:SetActiveAgent[${This.AgentList.NextAgent}]
					return
				}

				if (${dsIterator.Value.Text.Find["${This.BUTTON_VIEW_MISSION}"]} || ${dsIterator.Value.Text.Find["${This.BUTTON_REQUEST_MISSION}"]})
				{
					Logger:Log["obj_Agents: May be a locator agent, attempting to view mission..."]
					dsIterator.Value:Say[${This.AgentID}]
					;Logger:Log["obj_Agents: Waiting for dialog to update..."]
					wait 100
					Logger:Log["obj_Agents: Refreshing Dialog Responses"]
					Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
					dsIndex:GetIterator[dsIterator]
					break
				}
			}
			while (${dsIterator:Next(exists)})
		}

		if ${dsIndex.Used} != 3
		{
			Logger:Log["obj_Agents: ERROR: Did not find expected dialog! (Response count is ${dsIndex.Used} Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				Logger:Log["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			EVEWindow[ByCaption, "Agent Conversation - ${This.ActiveAgent}"]:Close
			return
		}

		EVE:Execute[OpenJournal]
		wait 50
		
		EVEWindow[ByCaption, "Journal"]:Close

		variable index:agentmission amIndex
		variable iterator amIterator

		EVE:DoGetAgentMissions[amIndex]
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
		Logger:Log["obj_Agents: DEBUG: amIterator.Value.Expires = ${amIterator.Value.Expires.DateAndTime}", LOG_DEBUG]

		; Opens the details window for the mission
		amIterator.Value:GetDetails
		wait 50
		variable obj_MissionParser MissionParser

		; Note - if this starts to fail, see MissionParser:UpdateCaption & MissionParser.Caption instead of amIterator.Value.Name for the window.
		if ${EVEWindow[ByCaption,"${amIterator.Value.Name}"](exists)}
		{
			; The embedded quotes look odd here, but this is required to escape the comma that exists in the caption and in the resulting html.
			MissionParser.MissionDetails:Set["${EVEWindow[ByCaption,"${amIterator.Value.Name}"].HTML.Escape}"]
			EVEWindow[ByCaption, "${amIterator.Value.Name}"]:Close
		}
		else
		{
			Logger:Log["obj_Agents: ERROR: Mission details window was not found: ${amIterator.Value.Name}", LOG_CRITICAL]
			Logger:Log["obj_Agents: DEBUG: amIterator.Value.Name.Escape = ${amIterator.Value.Name.Escape}"]
			return
		}

		MissionParser.MissionExpiresHex:Set[${amIterator.Value.Expires.AsInt64.Hex}]
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
				dsIndex.Get[AGENTRESPONSEINDEX_DECLINE]:Say[${This.AgentID}]
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				Logger:Log["obj_Agents: Declined low-sec mission."]
				Config:Save[]
			}
		}
		elseif ${MissionBlacklist.IsBlacklisted[${Agent[id,${amIterator.Value.AgentID}].Level},"${amIterator.Value.Name}"]} == TRUE
		{
			if ${lastDecline.Timestamp} >= ${Time.Timestamp}
			{
				Logger:Log["obj_Agents: ERROR: You declined a mission less than four hours ago!  Switching agents...", LOG_CRITICAL]
				This:SetActiveAgent[${This.AgentList.NextAgent}]
				return
			}
			else
			{
				dsIndex.Get[AGENTRESPONSEINDEX_DECLINE]:Say[${This.AgentID}]
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				Logger:Log["obj_Agents: Declined blacklisted mission."]
				Config:Save[]
			}
		}
		elseif ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Courier mission from agent ${This.AgentID}", LOG_DEBUG]
			dsIndex.Get[AGENTRESPONSEINDEX_ACCEPT]:Say[${This.AgentID}]
		}
		elseif ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Trade mission from agent ${This.AgentID}", LOG_DEBUG]
			dsIndex.Get[AGENTRESPONSEINDEX_ACCEPT]:Say[${This.AgentID}]
		}
		elseif ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Mining mission from agent ${This.AgentID}", LOG_DEBUG]
			dsIndex.Get[AGENTRESPONSEINDEX_ACCEPT]:Say[${This.AgentID}]
		}
		elseif ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
		{
			Logger:Log["obj_Agents: Accepting Kill mission from agent ${This.AgentID}", LOG_DEBUG]
			dsIndex.Get[AGENTRESPONSEINDEX_ACCEPT]:Say[${This.AgentID}]
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
				dsIndex.Get[AGENTRESPONSEINDEX_DECLINE]:Say[${This.AgentID}]
				Config.Agents:SetLastDecline[${This.AgentName},${Time.Timestamp}]
				Logger:Log["obj_Agents: Declined mission."]
				Config:Save[]
			}
		}

		Logger:Log["Waiting for mission dialog to update..."]
		wait 60
		Logger:Log["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVEWindow[ByCaption, "Journal"]:Close
		EVEWindow[ByCaption, "Agent Conversation - ${This.ActiveAgent}"]:Close
	}

	function TurnInMission()
	{
		Logger:Log["obj_Agents:TurnInMission: Starting conversation with agent ${This.ActiveAgent}."]
		Agent[${This.AgentIndex}]:StartConversation

		do
		{
			Logger:Log["obj_Agents:TurnInMission: Waiting for conversation window..."]
			wait 10
		}
		while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}

		Logger:Log["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		; display your dialog options
		variable index:dialogstring dsIndex
		variable iterator dsIterator
		Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
		dsIndex:GetIterator[dsIterator]

		if (${dsIterator:First(exists)})
		{
			do
			{
				Logger:Log["obj_Agents:TurnInMission dsIterator.Value.Text: ${dsIterator.Value.Text}"]
				if (${dsIterator.Value.Text.Find["View Mission"]})
				{
					dsIterator.Value:Say[${This.AgentID}]
					Config.Agents:SetLastCompletionTime[${This.AgentName},${Time.Timestamp}]
					break
				}
			}
			while (${dsIterator:Next(exists)})
		}

		; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
		Logger:Log["obj_Agents:TurnInMission: Waiting for agent dialog to update..."]
		wait 60
		Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
		dsIndex:GetIterator[dsIterator]
		Logger:Log["Completing Mission..."]
		dsIndex.Get[AGENTRESPONSEINDEX_COMPLETE_MISSION]:Say[${This.AgentID}]

		Logger:Log["Waiting for mission dialog to update..."]
		wait 60
		Logger:Log["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVEWindow[ByCaption, "Journal"]:Close
		EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
		
		variable int Waiting = 1200
		if ${Math.Rand[2]} == 0 && ${Config.Common.Randomize}
		{
			Waiting:Set[${Math.Rand[18000]:Inc[2400]}]
		}
		Logger:Log["Delaying ${Math.Calc[${Waiting}/10/60]} minutes before next mission request"]
		wait ${Waiting} ${EVEBot.Paused}
	}

	function QuitMission()
	{
		echo "CANNOT COMPLETE MISSION - QUIT MISSION OR COMPLETE IT MANUALLY"
		Logger:Log["obj_Agents:QuitMission - CANNOT COMPLETE MISSION - QUIT MISSION OR COMPLETE IT MANUALLY"]
		EVEBot:Pause
		return

		Logger:Log["obj_Agents:QuitMission: Starting conversation with agent ${This.ActiveAgent}."]
		Agent[${This.AgentIndex}]:StartConversation
		do
		{
			Logger:Log["obj_Agents:QuitMission: Waiting for conversation window..."]
			wait 10
		}
		while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}

		Logger:Log["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		; display your dialog options
		variable index:dialogstring dsIndex
		variable iterator dsIterator

		Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
		dsIndex:GetIterator[dsIterator]

		if ${dsIndex.Used} == 2
		{
			; Assume the second item is the "quit mission" item.
			dsIndex.Get[AGENTRESPONSEINDEX_QUIT_MISSION]:Say[${This.AgentID}]
		}

		; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
		Logger:Log["Waiting for agent dialog to update..."]
		wait 60
		Logger:Log["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVEWindow[ByCaption, "Journal"]:Close
		EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	}
}
