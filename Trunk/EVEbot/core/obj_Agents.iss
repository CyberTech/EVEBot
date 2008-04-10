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
				if ${amIterator.Value.AgentID} == ${This.AgentID}
				{
					return TRUE
				}
			}  
			while ${amIterator:Next(exists)}
		}
		
		return FALSE
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
	
	
/*
variable(script) int Avenid_Voohah_ID

function main()
{
    variable index:dialogstring DialogStrings
    variable int DialogStringsCount
    variable int i = 1

    ; I'm interested in getting a mission from "Avenid Voohah".  The Agent TLO works best with ID#s instead of names since it can retrieve an agent with an 
    ; ID# directly instead of having to search through.  So, let's store her ID# for use as we go along.
    Avenid_Voohah_ID:Set[${Agent[Avenid Voohah].ID}]
    if (${Avenid_Voohah_ID} <= 0)
    {
        echo "There was a problem getting the ID# for the agent you requested.
        return
    }
    
    ; First, let's make sure I'm in the same station with her (and that we're in a station in the first place.)
    if (!${Me.InStation})
    {
        echo "You're not in a station, dumb ass."
        return
    }
    if (${Me.StationID} != ${Agent[id,${Avenid_Voohah_ID}].StationID})
    {
        echo "You need to be in the same station with the agent with which you wish to converse.
        return
    }
    
    ; Start conversation (unless you're already talking to him/her)
    if (!${EVEWindow[ByCaption,Agent Conversation - ${Agent[id,${Avenid_Voohah_ID}].Name}](exists)})
    {
        Agent[id,${Avenid_Voohah_ID}]:StartConversation
        ; Wait until the window appears
        do
        {
            echo "waiting for conversation window..."
            wait 5
        }
        while !${EVEWindow[ByCaption,Agent Conversation - ${Agent[id,${Avenid_Voohah_ID}].Name}](exists)}        
    } 

    ; display what she said:
    echo "${Agent[id,${Avenid_Voohah_ID}].Name} :: ${Agent[id,${Avenid_Voohah_ID}].Dialog}"
    
    ; display your dialog options
    DialogStringsCount:Set[${Agent[id,${Avenid_Voohah_ID}].GetDialogResponses[DialogStrings]}]
    echo "- ${DialogStringsCount} responses available:"
    do
    {
        echo "-- ${i}. ${DialogStrings.Get[${i}].Text}"
    }
    while ${i:Inc} <= ${DialogStringsCount}
    
    ; Now, I want to say "Can you give me some work" 
    i:Set[1]
    do
    {
        if (${DialogStrings.Get[${i}].Text.Find[Can you give me some work]} > 0)
        {
            DialogStrings.Get[${i}]:Say[${Avenid_Voohah_ID}]
            break
        }
    }
    while ${i:Inc} <= ${DialogStringsCount}    
    
    ; Now wait a couple of seconds and then get the new dialog options...and so forth.  The "Wait" needed may differ from person to person.
    echo "waiting for agent dialog to update..."
    wait 20
    echo "${Agent[id,${Avenid_Voohah_ID}].Name} :: ${Agent[id,${Avenid_Voohah_ID}].Dialog}"
    DialogStrings:Clear
    DialogStringsCount:Set[${Agent[id,${Avenid_Voohah_ID}].GetDialogResponses[DialogStrings]}]
    echo "- ${DialogStringsCount} responses available:"
    i:Set[1]
    do
    {
        echo "-- ${i}. ${DialogStrings.Get[${i}].Text}"
    }
    while ${i:Inc} <= ${DialogStringsCount}

    ; ETC...ETC....
    
    ; After you're all done, close the window with EVEWindow[ByCaption,Agent Conversation - ${Agent[id,${Avenid_Voohah_ID}]:Close
}
*/	
	; Request missions until we get a courier mission
	function RequestCourierMission()
	{
		This:StartConversation 
    
		echo "${Agent[${This.AgentIndex}].Name} :: ${Agent[${This.AgentIndex}].Dialog}"

	}
	
	method StartConversation()
	{
	    if (!${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)})
	    {
			UI:UpdateConsole["obj_Agents: Starting conversation with agent ${This.ActiveAgent}."]
	        Agent[${This.AgentIndex}]:StartConversation
	        do
	        {
	            wait 5
	        }
	        while !${EVEWindow[ByCaption,"Agent Conversation - ${This.ActiveAgent}"](exists)}        
	    } 
	}
}
