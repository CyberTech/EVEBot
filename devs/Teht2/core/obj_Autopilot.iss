/*
	Autopilot Class
	
	This class will contain funtions for navigating space.  It is intended
	to support a bot class that has traveling functions.
	
	-- GliderPro
*/

objectdef obj_Autopilot
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	variable int       Destination
	variable int       IsLowSecRoute
	variable index:int Path
	variable iterator  PathIterator


	method Initialize()
	{
		This.IsLowSecRoute:Set[-999]
		UI:UpdateConsole["obj_Autopilot: Initialized", LOG_MINOR]
	}

	/* 	
		Given an entity (or character) ID determine if that item
		is in the current system.
	*/
	member:bool IsEntityLocal(int64 id)
	{
		return FALSE
	}
	
	/*
		Given a system ID set the autopilot destination to that system.
	*/
	method SetDestination(int64 id)
	{
		if ${id.Equal[${This.Destination}]}
		{
			return
		}
		
		UI:UpdateConsole["obj_Autopilot: Setting destination to ${Universe[${id}]}"]
		This.Destination:Set[${id}]
		Universe[${id}]:SetDestination
		This.IsLowSecRoute:Set[-999]
	}
	
	/*
		Return TRUE if there are low-sec systems in our route.
	*/
	member:bool LowSecRoute()
	{
		if ${This.IsLowSecRoute} == -999
		{
	
	    	EVE:GetToDestinationPath[This.Path]
	    	This.Path:GetIterator[This.PathIterator]
	    	
			;;UI:UpdateConsole["obj_Autopilot: DEBUG: ${Universe[${This.Destination}]} is ${This.Path.Used} jumps away."]
			if ${This.PathIterator:First(exists)}
			{
				do
				{
					;;UI:UpdateConsole["obj_Autopilot: DEBUG: ${This.PathIterator.Value} ${Universe[${This.PathIterator.Value}]} (${Universe[${This.PathIterator.Value}].Security})"]
			        if ${This.PathIterator.Value} > 0 && ${Universe[${This.PathIterator.Value}].Security} <= 0.45
			        {
						UI:UpdateConsole["obj_Autopilot: Low-Sec system found"]
						This.IsLowSecRoute:Set[TRUE]
						break
			        }
				}
				while ${This.PathIterator:Next(exists)}
			}		
		}
			
		return ${This.IsLowSecRoute}
	}

	/*
		Return the system ID for the next system in the autopilot path.
	*/
	member:int NextSystemEnroute()
	{
	}

	/*
		Return the next stargate (entity ID) for the next stargate
		in the autopilot path.
	*/
	member:int NextStargateEnroute()
	{
	}
}