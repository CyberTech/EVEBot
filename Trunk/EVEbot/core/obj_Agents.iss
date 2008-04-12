/*
    Agents class
    
    Object to contain members related to agents.
    
    -- GliderPro
    
*/

objectdef obj_Agents
{
	variable int AgentID = 0
	variable int AgentIndex = 0
	variable string AgentName
	variable string MissionDetails
	
    method Initialize()
    {
        UI:UpdateConsole["obj_Agents: Initialized", LOG_MINOR]
    }

	method Shutdown()
	{
	}
	
	method SetActiveAgent(string name)
	{
	    This.AgentIndex:Set[${Agent[${name}].Index}]
	    if (${This.AgentIndex} <= 0)
	    {
	        UI:UpdateConsole["obj_Agents: ERROR!  Cannot get Index for Agent ${name}.", LOG_CRITICAL]
			This.AgentName:Set[""]
	    }
		else
		{
			This.AgentName:Set[${name}]	
			This.AgentID:Set[${Agent[${This.AgentIndex}].ID}]
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
								rVal:Set[${rVal.Right[${Math.Calc[${rVal.Length}-${pos}+3]}]}]
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
								rVal:Set[${rVal.Right[${Math.Calc[${rVal.Length}-${pos}+3]}]}]
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
		UI:UpdateConsole["obj_Agents: DEBUG: Me.Station.Name = ${Me.Station.Name}"]	
		; yes this sucks but Me.Station is returning NULL
		;if ${Me.Station.Name.NotEqual[${This.PickupStation}]}
		;{		
			call This.WarpToPickupStation
		;}
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
			UI:UpdateConsole["obj_Agents: ERROR: Did not find expected dialog!  Aborting...", LOG_CRITICAL]
			EVEBot.ReturnToStation:Set[TRUE]
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
			UI:UpdateConsole["obj_Agents: ERROR: Did not find mission!  Aborting...", LOG_CRITICAL]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]	
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]	
		UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]	
		
		UI:UpdateConsole["obj_Agents: Saving mission detials."]
		dsIndex.Get[3]:Say[${This.AgentID}]
        do
        {
		    UI:UpdateConsole["Waiting for mission details to update..."]
            wait 10
        }
        while !${EVEWindow[ByCaption,"${amIterator.Value.Name}"](exists)}        
	    wait 10
	    UI:UpdateConsole["mission details (${EVEWindow[ByCaption,"${amIterator.Value.Name}"].HTML.Length} bytes)"]
	    This.MissionDetails:Set[${EVEWindow[ByCaption,"${amIterator.Value.Name}"].HTML}]
		EVEWindow[ByCaption,"${amIterator.Value.Name}"]:Close
	    wait 10			
		EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	    wait 10
	    
	    UI:UpdateConsole["mission details (${This.MissionDetails.Length} bytes)"]
		
		variable file logFile = "./config/logs/${Me.Name}-missions.log"
		logFile:Open
		logFile:Write["[${Time.Time24}] obj_Agents: ${This.MissionDetails} *****"]
		logFile:Close
		
		variable bool bAcceptMission = FALSE
		if ${This.MissionDetails.Find["warning"]} > 0
		{
			UI:UpdateConsole["obj_Agents: Declining dangerous mission."]
			bAcceptMission:Set[FALSE]
		}
		elseif ${This.MissionDetails.Find["killmission.png"]} > 0
		{
			UI:UpdateConsole["obj_Agents: WARNING: Declining combat mission!", LOG_CRITICAL]
			bAcceptMission:Set[FALSE]
		}
		else
		{			
			UI:UpdateConsole["obj_Agents: Accepting courier mission."]
			bAcceptMission:Set[TRUE]
		}
		
		Agent[${This.AgentIndex}]:StartConversation
        do
        {
			UI:UpdateConsole["obj_Agents: Waiting for conversation window..."]
            wait 10
        }
        while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}        
		
	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIterator:First(exists)}
		{
	        dsIterator.Value:Say[${This.AgentID}]
		}
		
	    UI:UpdateConsole["Waiting for agent dialog to update..."]
	    wait 60
		UI:UpdateConsole["${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"]

	    Agent[${This.AgentIndex}]:DoGetDialogResponses[dsIndex]
	    dsIndex:GetIterator[dsIterator]
	    
		if ${dsIndex.Used} != 3
		{
			UI:UpdateConsole["obj_Agents: ERROR: Did not find expected dialog!  Aborting...", LOG_CRITICAL]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}
		
		if ${bAcceptMission}
		{
			dsIndex.Get[1]:Say[${This.AgentID}]
		}
		else
		{			
			dsIndex.Get[2]:Say[${This.AgentID}]
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
}
