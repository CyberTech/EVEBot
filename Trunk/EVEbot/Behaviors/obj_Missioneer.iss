/*
	The missioneer object
	
	The obj_Missioneer object is the main bot module for the
	mission running bot.
	
	-- GliderPro	
*/

objectdef obj_Missioneer
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	method Initialize()
	{
		BotModules:Insert["Missioneer"]
		UI:UpdateConsole["obj_Missioneer: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}
	
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		This.CurrentState:Set["Unknown"]
	}

	function ProcessState()
	{
		switch ${This.CurrentState}
		{
		}	
	}
}

