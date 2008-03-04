/*
    Agents class
    
    Object to contain members related to agents.
    
    -- GliderPro
    
*/

objectdef obj_Agents
{
	variable int AgentID = 0
	
    method Initialize()
    {
        UI:UpdateConsole["obj_Agents: Initialized"]
    }

	method Shutdown()
	{
	}
	
	method SetActiveAgent(string name)
	{
	    This.AgentID:Set[${Agent[${name}].ID}]
	    if (${This.AgentID} <= 0)
	    {
	        UI:UpdateConsole["obj_Agents: ERROR!  Cannot get Agent ID for ${name}."]
	    }
	}
	
	member:bool InAgentStation()
	{
		variable bool rVal = TRUE
		if !${Me.InStation(exists)} 
		{
			rVal:Set[FALSE]
		}
	    elseif !${Me.InStation}
	    {
			rVal:Set[FALSE]
	    }
	    elseif (${Me.StationID} != ${Agent[id,${This.AgentID}].StationID})
	    {
			rVal:Set[FALSE]
	    }
		return ${rVal}
	}
}
