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
	
	member:string CourierPickUp()
	{
		variable string rVal = ""
		
		variable int pos
		
		pos:Set[${This.MissionDetails.Find["Pickup Location"]}]
		
		if ${pos} > 0 
		{
			UI:UpdateConsole["obj_Agents: ${This.MissionDetails.Mid[${pos},50]}"]
		}
		
		return ${rVal}
	}
	
	member:string CourierDropOff()
	{
		variable string rVal = ""
		
		variable int pos
		
		pos:Set[${This.MissionDetails.Find["Drop-off Location"]}]
		
		if ${pos} > 0 
		{
			UI:UpdateConsole["obj_Agents: ${This.MissionDetails.Mid[${pos},50]}"]
		}
		
		return ${rVal}
	}
	
	member:string CourierItem()
	{
		variable string rVal = ""
		
		UI:UpdateConsole["obj_Agents: ${This.MissionDetails}"]
		
		return ${rVal}
	}
	
	member:int CourierItemQty()
	{
		variable int rVal = 0
				
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
				UI:UpdateConsole["obj_Agents: DEBUG: This.AgentID = ${This.AgentID}"]	
				UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]	
				UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]	
				UI:UpdateConsole["obj_Agents: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]	
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
		UI:UpdateConsole["obj_Agents: ${This.CourierPickUp}"]
	}
	
	function MoveToDropOff()
	{
		UI:UpdateConsole["obj_Agents: ${This.CourierDropOff}"]	
	}
	
	function MoveTo()
	{
		if !${This.InAgentStation}
		{
			if ${Station.Docked}
			{
				call Station.Undock
			}
			call Ship.TravelToSystem ${Universe[${Agent[${This.AgentIndex}].Solarsystem}].ID}
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
	    This.MissionDetails:Set[${EVEWindow[ByCaption,"${amIterator.Value.Name}"].HTML}]
		EVEWindow[ByCaption,"${amIterator.Value.Name}"]:Close
	    wait 10			
		EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"]:Close
	    wait 10
	    
	    UI:UpdateConsole["mission details (${This.MissionDetails.Length} bytes)"]
		
		redirect -append "./config/logs/${Me.Name}-missions.log" echo "[${Time.Time24}] obj_Agents: ${This.MissionDetails} *****"		
		
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
}
