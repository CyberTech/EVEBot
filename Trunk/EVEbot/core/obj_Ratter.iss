/*
	The ratter object
	
	The obj_Ratter object is a bot module designed to be used with 
	EVEBOT.  The ratter bot will warp from belt to belt and wtfbbqpwn
	any NPC ships it finds.
	
	-- GliderPro	
*/

#include obj_Combat.iss

objectdef obj_Ratter
{
	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable int FrameCounter
	variable obj_Combat Combat
	
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		BotModules:Insert["Ratter"]

		;; call the combat object's init routine
		This.Combat:Initialize
		;; set the combat "mode"
		This.Combat:SetMode["AGRESSIVE"]

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
		
		;; call the combat frame action code
		This.Combat:Pulse
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]		
	}

	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		/* Combat module handles all fleeing states now */
		This.CurrentState:Set["FIGHT"]
	}

	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{				
	    /* don't do anything if we aren't in Ratter bot mode! */
		if !${Config.Common.BotModeName.Equal[Ratter]}
			return
	    
		; call the combat object state processing
		call This.Combat.ProcessState
		
		; see if combat object wants to 
		; override bot module state.
		if ${This.Combat.Override}
			return
	    		    
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
