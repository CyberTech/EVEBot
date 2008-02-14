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
		if !${Social.IsSafe}
			This.CurrentState:Set["SAFESPOT"]
		elseif !${Ship.IsSafe}
			This.CurrentState:Set["SAFESPOT"]
		else
			This.CurrentState:Set["FIGHT"]
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
			case SAFESPOT
				call This.RunAway
				break
			case FIGHT
				call This.Fight
				break
		}	
	}
	
	function RunAway()
	{
		; Are we at the safespot and not warping?
		if !${Safespot.IsAtSafespot} && ${Me.ToEntity.Mode} != 3
		{
			; Turn off the shield booster
			;Modules:ActivateShieldBooster[FALSE]
		
			call Safespots.WarpTo
			
			; Wait 3 seconds
			wait 30
		}
		
		if ${Safespots.IsAtSafespot}
		{
			wait 60
			;Modules:ActivateCloak[TRUE]
			
			; Wait 1 minute, there was hostiles so who cares how long we wait
			wait 600
		}
	}
	
	function Fight()
	{	/* combat logic */
	
		; Are we at the belt and not warping?
		if !${Belts.IsAtBelt} && ${Me.ToEntity.Mode} != 3
		{
			; Turn off the shield booster
			;Modules:ActivateShieldBooster[FALSE]
		
			call Belts.WarpTo
			
			; Wait 3 seconds
			wait 30
		}		
	}
}
