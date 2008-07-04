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
	variable string SET_NAME = "${Me.Name} Agents"
	variable iterator agentIterator
	
	method Initialize()
	{
		if ${LavishSettings[${This.SET_NAME}](exists)}
		{
			LavishSettings[${This.SET_NAME}]:Clear
		}
		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME}]:GetSettingIterator[This.agentIterator]
		UI:UpdateConsole["obj_AgentList: Initialized", LOG_MINOR]
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
}

objectdef obj_Agents
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string AgentName
	variable string MissionDetails
	variable int RetryCount = 0
	variable obj_AgentList AgentList
	
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
		return ${Config.Agents.AgentIndex[${This.AgentName}]}
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

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]
		skipList:Clear
		
		UI:UpdateConsole["obj_Agents: DEBUG: amIndex.Used = ${amIndex.Used}"]	
		if ${amIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Agents: DEBUG: This.AgentID = ${This.AgentID}"]	
				UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]	
				UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]	
				UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]	
				if ${amIterator.Value.State} == 1
				{
					variable time lastDecline
					lastDecline:Set[${Config.Agents.LastDecline[${Agent[id,${amIterator.Value.AgentID}]}]}]
					UI:UpdateConsole["obj_Agents: DEBUG: lastDecline = ${lastDecline}"]	
					lastDecline.Hour:Inc[4]
					lastDecline:Update
					if ${lastDecline.Timestamp} >= ${Time.Timestamp}
					{
						UI:UpdateConsole["obj_Agents: DEBUG: Skipping mission to avoid standing loss: ${amIterator.Value.Name}"]	
						skipList:Add[${amIterator.Value.AgentID}]
						continue
					}

					if ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == FALSE
					{
						UI:UpdateConsole["obj_Agents: DEBUG: Skipping courier mission: ${amIterator.Value.Name}"]	
						continue
					}
					
					if ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == FALSE
					{
						UI:UpdateConsole["obj_Agents: DEBUG: Skipping trade mission: ${amIterator.Value.Name}"]	
						continue
					}
					
					if ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == FALSE
					{
						UI:UpdateConsole["obj_Agents: DEBUG: Skipping mining mission: ${amIterator.Value.Name}"]	
						continue
					}
					
					if ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == FALSE
					{
						UI:UpdateConsole["obj_Agents: DEBUG: Skipping combat mission: ${amIterator.Value.Name}"]	
						continue
					}
										
					/* if we get here the mission is valid */
					This:SetActiveAgent[${Agent[id,${amIterator.Value.AgentID}]}]
					return
				}
			}  
			while ${amIterator:Next(exists)}
		}
		
		/* if we get here none of the missions in the journal are valid */
		if ${This.AgentList.agentIterator:First(exists)}
		{
			do
			{
				if ${skipList.Contains[${Config.Agents.AgentID[${This.AgentList.agentIterator.Key}]}]} == FALSE
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
	
	member:bool LowSecRoute()
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
							mbIterator.Value:SetDestination
				        	variable index:int ap_path
				        	EVE:DoGetToDestinationPath[ap_path]
				        	variable iterator ap_path_iterator
				        	ap_path:GetIterator[ap_path_iterator]
				        	
							UI:UpdateConsole["obj_Agents: ${mbIterator.Value.Label} is ${ap_path.Used} jumps away."]
							if ${ap_path_iterator:First(exists)}
							{
								do
								{
									UI:UpdateConsole["obj_Agents: ${ap_path_iterator.Value} ${Universe[${ap_path_iterator.Value}]} (${Universe[${ap_path_iterator.Value}].Security})"]
							        if ${ap_path_iterator.Value} > 0 && ${Universe[${ap_path_iterator.Value}].Security} <= 0.45
							        {	/* avoid low-sec */
										UI:UpdateConsole["obj_Agents: Low-Sec route found"]
										return TRUE
							        }
								}
								while ${ap_path_iterator:Next(exists)}
							}		
							
						} 
						while ${mbIterator:Next(exists)}
					}
				}
			}  
			while ${amIterator:Next(exists)}
		}		
		
		return FALSE
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

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		;;UI:UpdateConsole["obj_Agents: DEBUG: amIndex.Used = ${amIndex.Used}"]	
		if ${amIterator:First(exists)}
		{
			do
			{
				;UI:UpdateConsole["obj_Agents: DEBUG: This.AgentID = ${This.AgentID}"]	
				;UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]	
				;UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]	
				;UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]	
				if ${amIterator.Value.AgentID} == ${This.AgentID} && ${amIterator.Value.State} > 1
				{
					return TRUE
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
	}
	
	function MoveToDropOff()
	{
		UI:UpdateConsole["obj_Agents: DEBUG: Me.Station.Name = ${Me.Station.Name}"]	
		; yes this sucks but Me.Station is returning NULL
		;if ${Me.Station.Name.NotEqual[${This.DropOffStation}]}
		;{		
			call This.WarpToDropOffStation
		;}
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
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]	
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
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]	
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
			;UI:UpdateConsole["obj_Agents: DEBUG: agentSystem = ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}"]
			;UI:UpdateConsole["obj_Agents: DEBUG: agentStation = ${Agent[${This.AgentIndex}].StationID}"]
			call Ship.TravelToSystem ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}
			wait 50
			call Station.DockAtStation ${Agent[${This.AgentIndex}].StationID}
		}
	}
	
	function RequestMission()
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
	    
	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIterator:First(exists)}
		{
			; Assume the first item is the "ask for work" item.
			; This may break if you have agents with locator services.
	        dsIterator.Value:Say[${This.AgentID}]
		}
		
	    ; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
	    UI:UpdateConsole["Waiting for agent dialog to update..."]
	    wait 60
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIndex.Used} != 3
		{
			UI:UpdateConsole["obj_Agents: ERROR: Did not find expected dialog!  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				UI:UpdateConsole["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

	    wait 10
		
		EVE:Execute[OpenJournal]
		wait 50
		EVE:Execute[CmdCloseActiveWindow]
		wait 50

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
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Expires = ${amIterator.Value.Expires.DateAndTime}"]	
		
		amIterator.Value:GetDetails
		wait 50
		variable string details
		details:Set["${EVEWindow[ByCaption,${amIterator.Value.Name}].HTML.Escape}"]
		UI:UpdateConsole["obj_Agents: DEBUG: HTML.Length = ${EVEWindow[ByCaption,${amIterator.Value.Name}].HTML.Length}"]
		EVE:Execute[CmdCloseActiveWindow]
		UI:UpdateConsole["obj_Agents: DEBUG: details.Length = ${details.Length}"]	
		
		variable file detailsFile
		detailsFile:SetFilename["./config/logs/${amIterator.Value.Expires.AsInt64.Hex} ${amIterator.Value.Name}.html"]
		if ${detailsFile:Open(exists)}
		{
			detailsFile:Write["${details.Escape}"]
		}
		detailsFile:Close
		
		Missions.MissionCache:AddMission[${amIterator.Value.AgentID},"${amIterator.Value.Name}"]

		variable int factionID = 0
		variable int left = 0
		variable int right = 0
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

		if ${amIterator.Value.Type.Find[Courier](exists)} && ${Config.Missioneer.RunCourierMissions} == TRUE
		{
			dsIndex.Get[1]:Say[${This.AgentID}]
		}		
		elseif ${amIterator.Value.Type.Find[Trade](exists)} && ${Config.Missioneer.RunTradeMissions} == TRUE
		{
			dsIndex.Get[1]:Say[${This.AgentID}]
		}		
		elseif ${amIterator.Value.Type.Find[Mining](exists)} && ${Config.Missioneer.RunMiningMissions} == TRUE
		{
			dsIndex.Get[1]:Say[${This.AgentID}]
		}		
		elseif ${amIterator.Value.Type.Find[Encounter](exists)} && ${Config.Missioneer.RunKillMissions} == TRUE
		{
			dsIndex.Get[1]:Say[${This.AgentID}]
		}						
		else
		{
			variable time lastDecline
			lastDecline:Set[${Config.Agents.LastDecline[${This.AgentName}]}]
			lastDecline.Hour:Inc[4]
			lastDecline:Update
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
			}
		}

	    UI:UpdateConsole["Waiting for mission dialog to update..."]
	    wait 60
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

		EVE:Execute[OpenJournal]
		wait 50
		EVE:Execute[CmdCloseActiveWindow]
		wait 50

    	EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	}

	; Request missions until we get a courier mission
	function RequestCourierMission()
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
	    
	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIterator:First(exists)}
		{
			; Assume the first item is the "ask for work" item.
			; This may break if you have agents with locator services.
	        dsIterator.Value:Say[${This.AgentID}]
		}
		
	    ; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
	    UI:UpdateConsole["Waiting for agent dialog to update..."]
	    wait 60
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIndex.Used} != 3
		{
			UI:UpdateConsole["obj_Agents: ERROR: Did not find expected dialog!  Will retry...", LOG_CRITICAL]
			RetryCount:Inc
			if ${RetryCount} > 4
			{
				UI:UpdateConsole["obj_Agents: ERROR: Retry count exceeded!  Aborting...", LOG_CRITICAL]
				EVEBot.ReturnToStation:Set[TRUE]
			}
			return
		}

	    wait 10
		
		EVE:Execute[OpenJournal]
		wait 50
		EVE:Execute[CmdCloseActiveWindow]
		wait 50

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
		
		;; evewindow.HTML is highly unstable.  DO NOT USE!!
		
		if ${amIterator.Value.Type.Equal[courier]}
		{
			dsIndex.Get[1]:Say[${This.AgentID}]
		}
		else
		{
			variable time lastDecline
			lastDecline:Set[${Config.Agents.LastDecline[${This.AgentName}]}]
			lastDecline.Hour:Inc[4]
			lastDecline:Update
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
			}
		}

	    UI:UpdateConsole["Waiting for mission dialog to update..."]
	    wait 60
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
	    
	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIterator:First(exists)}
		{
			; Assume the first item is the "turn in mission" item.
	        dsIterator.Value:Say[${This.AgentID}]
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
	    
	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
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
