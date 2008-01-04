/*
	Autopilot Class
	
	This class will contain funtions for navigating space.  It is intended
	to support a bot class that has traveling functions.
	
	-- GliderPro

	HISTORY
	------------------------------------------
	10AUG2007 - Initial release of class template
*/

objectdef obj_Autopilot
{
	method Initialize()
	{
		UI:UpdateConsole["obj_Autopilot: Initialized"]
	}

	/* 	
		Given an entity (or character) ID determine if that item
		is in the current system.
	*/
	member bool IsEntityLocal(int id)
	{
		return FALSE
	}
	
	/*
		Given a system ID set the autopilot destination to that system.
	*/
	method SetDestination(int id)
	{
	}
	
	/*
		Return the system ID for the next system in the autopilot path.
	*/
	member int NextSystemEnroute()
	{
	}

	/*
		Return the next stargate (entity ID) for the next stargate
		in the autopilot path.
	*/
	member int NextStargateEnroute()
	{
	}
}