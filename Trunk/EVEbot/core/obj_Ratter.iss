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
		elseif !${Ship.IsAmmoAvailable}
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
		UI:UpdateConsole["obj_Ratter: DEBUG: RunAway"]
	
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
			UI:UpdateConsole["obj_Ratter: DEBUG: At safespot.  Cloaking..."]
			Ship:Deactivate_Hardeners[]
			;Modules:ActivateCloak[TRUE]
			
			; Wait 1 minute, there was hostiles so who cares how long we wait
			wait 600
		}
	}

	function Fight()
	{	/* combat logic */
	
		UI:UpdateConsole["obj_Ratter: DEBUG: Fight"]
		; Before opening fire, lets see if there are any friendlies here
		if !${Targets.PC}
		while ${Targets.TargetNPCs} && ${Social.IsSafe}
		{
		
			if ${Targets.SpecialTargetPresent}
			{
				UI:UpdateConsole["Special spawn detected!"]
				call Sound.PlayDetectSound
			}
		
			; Make sure our hardeners are running
			Ship:Activate_Hardeners[]
			
			; Reload the weapons -if- ammo is below 30% and they arent firing
			Ship:Reload_Weapons[FALSE]

			; Activate the weapons, the modules class checks if there's a target
			Ship:Activate_Weapons
			
			; Wait 2 seconds
			wait 20
		}
	
		Ship:Deactivate_Weapons
		
		if ${Social.IsSafe}
		{
			call Belts.WarpTo
			; This will reset target information about the belt 
			; (its needed for chaining)
			Targets:ResetTargets
			; Reload just before targeting everything, the ship
			; has been through warp so we're sure that no weapons are still
			; active
			Ship:Reload_Weapons[TRUE]
		}
	}
}
