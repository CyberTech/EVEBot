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

	;; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> LOOT -> DROP -> *
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

		;UI:UpdateConsole["Debug: Ratter: This.Combat.Fled = ${This.Combat.Fled} This.CurrentState = ${This.CurrentState} Social.IsSafe = ${Social.IsSafe}"]

		; see if combat object wants to
		; override bot module state.
		if ${This.Combat.Fled}
			return

		switch ${This.CurrentState}
		{
			case MOVE
				call This.Move
				break
			case FIGHT
				call This.Fight
				break
			case LOOT
				call This.Loot
				break
			case DROP
				call This.Drop
				break
		}
	}

	function Move()
	{
		if ${Social.IsSafe}
		{
			Ship:Deactivate_Weapons
			Ship:Deactivate_Tracking_Computer
			Ship:Deactivate_ECCM
			if !${Config.Combat.AnomalyAssistMode}
			{
				call Belts.WarpToNextBelt ${Config.Combat.WarpRange}
			}

			; This will reset target information about the belt
			; (its needed for chaining)
			Targets:ResetTargets
		}

		; Wait for the rats to warp into the belt. Reports are between 10 and 20 seconds.
		variable int Count
		for (Count:Set[0] ; ${Count}<=17 ; Count:Inc)
		{
			if ((${Config.Combat.AnomalyAssistMode} && (${Targets.NPC} || !${Social.IsSafe})) || \
				(!${Config.Combat.AnomalyAssistMode} && (${Targets.PC} || ${Targets.NPC} || !${Social.IsSafe})))
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
		if ${Config.Combat.AnomalyAssistMode}
		{
			while (${Count:Inc} < 10) && ${Social.IsSafe} && ${Targets.NPC}
			{
				wait 10
			}
		}
		else
		{
			while (${Count:Inc} < 10) && ${Social.IsSafe} && !${Targets.PC} && ${Targets.NPC}
			{
				wait 10
			}
		}
	}

	function PlayerCheck()
	{
		if ((${Config.Combat.AnomalyAssistMode} && ${Targets.NPC}) || \
			(!${Config.Combat.AnomalyAssistMode} && (!${Targets.PC} && ${Targets.NPC})))
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
		Ship:Activate_Tracking_Computer
		Ship:Activate_ECCM
 

		if ${Targets.TargetNPCs} && ${Social.IsSafe}
		{
			if ${Targets.SpecialTargetPresent}
			{
				UI:UpdateConsole["Special spawn Detected - ${Targets.m_SpecialTargetName}!", LOG_CRITICAL]
				call Sound.PlayDetectSound
				; Wait 5 seconds
				wait 50
			}
		}
		else
		{
			if ${Config.Combat.LootMyKills}
			{
				This.CurrentState:Set["LOOT"]
			}
			else
			{
				This.CurrentState:Set["IDLE"]
			}
		}
	}

	function Loot()
	{
		variable index:entity Wrecks
		variable iterator     Wreck
		variable index:item   Items
		variable iterator     Item
		variable index:int64  ItemsToMove
		variable float        TotalVolume = 0
		variable float        ItemVolume = 0
		variable int QuantityToMove

		EVE:QueryEntities[Wrecks, "GroupID = GROUP_WRECK && Distance <= WARP_RANGE"]
		Wrecks:GetIterator[Wreck]
		if ${Wreck:First(exists)}
		{
			do
			{
				if ${Wreck.Value(exists)} && \
					!${Wreck.Value.IsWreckEmpty} && \
					${Wreck.Value.HaveLootRights} && \
					${Targets.IsSpecialTargetToLoot[${Wreck.Value.Name}]}
				{
					call Ship.Approach ${Wreck.Value.ID} LOOT_RANGE
					if ((${Config.Combat.AnomalyAssistMode} && ${Targets.NPC}) || \
						(!${Config.Combat.AnomalyAssistMode} && (!${Targets.PC} && ${Targets.NPC})))
					{
						This.CurrentState:Set["FIGHT"]
						break
					}
					Wreck.Value:OpenCargo
					wait 10
					call Ship.OpenCargo
					wait 10
					Wreck.Value:GetCargo[Items]
					UI:UpdateConsole["obj_Ratter: DEBUG:  Wreck contains ${Items.Used} items.", LOG_DEBUG]

					Items:GetIterator[Item]
					if ${Item:First(exists)}
					{
						do
						{
							UI:UpdateConsole["obj_Ratter: Found ${Item.Value.Quantity} x ${Item.Value.Name} - ${Math.Calc[${Item.Value.Quantity} * ${Item.Value.Volume}]}m3"]
							if (${Item.Value.Quantity} * ${Item.Value.Volume}) > ${Ship.CargoFreeSpace}
							{
								/* Move only what will fit, minus 1 to account for CCP rounding errors. */
								QuantityToMove:Set[${Ship.CargoFreeSpace} / ${Item.Value.Volume} - 1]
								if ${QuantityToMove} <= 0
								{
								UI:UpdateConsole["ERROR: obj_Ratter: QuantityToMove = ${QuantityToMove}!"]
								This.CurrentState:Set["DROP"]
								break
								}
							}
							else
							{
								QuantityToMove:Set[${Item.Value.Quantity}]
							}
			
							UI:UpdateConsole["obj_Ratter: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Item.Value.Volume}]}m3"]
							if ${QuantityToMove} > 0
							{
								Item.Value:MoveTo[MyShip,${QuantityToMove}]
								wait 30
							}
			
							if ${Ship.CargoFull}
							{
								UI:UpdateConsole["DEBUG: obj_Ratter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
								This.CurrentState:Set["DROP"]
								break
							}
						}
						while ${Item:Next(exists)}
					}
				}
				call Ship.CloseCargo
				if ${Ship.CargoFull}
				{
					UI:UpdateConsole["DEBUG: obj_Ratter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
					This.CurrentState:Set["DROP"]
					break
				}
			}
			while ${Wreck:Next(exists)}
		}

		if ${This.CurrentState.Equal["LOOT"]}
		{
		  This.CurrentState:Set["IDLE"]
		}
	}

	function Drop()
	{
		call Station.Dock
		wait 100
		call Cargo.TransferCargoToHangar
		wait 100
		; need to restock ammo here
		This.CurrentState:Set["IDLE"]
	}
}
