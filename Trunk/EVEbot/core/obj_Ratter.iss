/*
	The ratter object
	
	The obj_Ratter object is a bot module designed to be used with 
	EVEBOT.  The ratter bot will warp from belt to belt and wtfbbqpwn
	any NPC ships it finds.
	
	-- GliderPro	
*/
objectdef obj_Ratter
{
	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable int FrameCounter
	
	method Initialize()
	{
		This:SetupEvents[]
		BotModules:Insert["Ratter"]
		
		UI:UpdateConsole["obj_Ratter: Initialized"]
	}

	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Ratter]}
		{
			return
		}
		FrameCounter:Inc

		variable int IntervalInSeconds = 2
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			This:SetState[]
			FrameCounter:Set[0]
		}
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]		
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]

		/* override any events setup by the base class */
		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	
	
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		This.CurrentState:Set["IDLE"]
	}

	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{				
	    /* don't do anything if we aren't in Ratter bot mode! */
		if !${Config.Common.BotModeName.Equal[Ratter]}
		{
			return
		}
	    
		switch ${This.CurrentState}
		{
			case IDLE
				break
			case ABORT
				break
			case BASE
				break
			case TRANSPORT
				break
			case CARGOFULL
				break
		}	
	}
}
