/*
	The ratter object

	The obj_Ratter object is a bot module designed to be used with
	EVEBOT.  The ratter bot will warp from belt to belt and wtfbbqpwn
	any NPC ships it finds.

	-- GliderPro
*/

objectdef obj_Ratter
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	variable obj_Combat Combat

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		BotModules:Insert["Ratter"]

		; Startup in fight mode, so that it checks current belt for rats, if we happen to be in one.
		This.CurrentState:Set["FIGHT"]
		Targets:ResetTargets
		;; call the combat object's init routine
		This.Combat:Initialize
		;; set the combat "mode"
		This.Combat:SetMode["AGGRESSIVE"]

		UI:UpdateConsole["obj_Ratter: Initialized", LOG_MINOR]
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

	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
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
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
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
			call Belts.WarpToNextBelt
			; This will reset target information about the belt
			; (its needed for chaining)
			Targets:ResetTargets
			; Reload just before targeting everything, the ship
			; has been through warp so we're sure that no weapons are still
			; active
			Ship:Reload_Weapons[TRUE]
		}

		; Wait for the rats to warp into the belt. Reports are between 10 and 20 seconds.
		variable int Count
		for (Count:Set[0] ; ${Count}<=30 ; Count:Inc)
		{
			if ${Targets.PC} || ${Targets.NPC} || !${Social.IsSafe}
			{
				break
			}
			wait 10
		}

		if (${Count} > 1)
		{
			; If we had to wait for rats, Wait another second to try to let them get into range/out of warp
			wait 10
		}
		call This.PlayerCheck

		Count:Set[0]
		while (${Count:Inc} < 10) && ${Social.IsSafe} && !${Targets.PC} && ${Targets.NPC}
		{
			wait 10
		}
	}

	function PlayerCheck()
	{
		if !${Targets.PC} && ${Targets.NPC}
		{
			UI:UpdateConsole["PlayerCheck - Fight"]
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			UI:UpdateConsole["PlayerCheck - Move"]
			This.CurrentState:Set["MOVE"]
		}
	}

	function Fight()
	{	/* combat logic */
		;; just handle targetting, obj_Combat does the rest
		Ship:Activate_SensorBoost

		if ${Targets.TargetNPCs} && ${Social.IsSafe}
		{
			if ${Targets.SpecialTargetPresent}
			{
				UI:UpdateConsole["Special spawn Detected!", LOG_CRITICAL]
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
