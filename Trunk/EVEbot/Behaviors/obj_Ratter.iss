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
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	variable obj_Combat Combat
	
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		BotModules:Insert["Ratter"]
		This.CurrentState:Set["IDLE"]

		;; call the combat object's init routine
		This.Combat:Initialize
		;; set the combat "mode"
		This.Combat:SetMode["AGGRESSIVE"]

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

	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
			This:SetState[]

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
		
		;; call the combat frame action code
		This.Combat:Pulse
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]		
	}

	/* NOTE: The order of these if statements is important!! */
	
	;; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> *  
	method SetState()
	{
		/* Combat module handles all fleeing states now */
		switch ${This.CurrentState}
		{
			case IDLE
				This.CurrentState:Set["MOVE"]
				break
			default
				break
		}
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
	    		    
		;UI:UpdateConsole["DEBUG: ${This.CurrentState}"]
		switch ${This.CurrentState}
		{
			case MOVE
				call This.Move
				break
			case PCCHECK
				call This.PlayerCheck
				break
			case FIGHT
				call This.Fight
				break
		}	
	}
	
	function Move()
	{
		if ${Social.IsSafe}
		{
			Ship:Deactivate_Weapons		
			call Belts.WarpTo
			; This will reset target information about the belt 
			; (its needed for chaining)
			Targets:ResetTargets
			; Reload just before targeting everything, the ship
			; has been through warp so we're sure that no weapons are still
			; active
			Ship:Reload_Weapons[TRUE]
		}
		
		This.CurrentState:Set["PCCHECK"]
	}
	
	function PlayerCheck()
	{
		if !${Targets.PC}
		{
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			This.CurrentState:Set["MOVE"]
		}
	}
	
	function Fight()
	{	/* combat logic */	
		;; just handle targetting, obj_Combat does the rest
		if ${Targets.TargetNPCs} && ${Social.IsSafe}
		{
			if ${Targets.SpecialTargetPresent}
			{
				UI:UpdateConsole["Special spawn detected!"]
				call Sound.PlayDetectSound
				; Wait 5 seconds
				wait 50
			}
		}
		else
		{
			This.CurrentState:Set["IDLE"]		
		}
	}
}
