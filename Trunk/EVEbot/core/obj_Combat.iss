 #ifndef __OBJ_COMBAT__
 #define __OBJ_COMBAT__

/*
		The combat object

		The obj_Combat object is a bot-support module designed to be used
		with EVEBOT.  It provides a common framework for combat decissions
		that the various bot modules can call.

		USAGE EXAMPLES
		--------------

		objectdef obj_Miner
		{
				variable string SVN_REVISION = "$Rev$"
				variable int Version

				variable obj_Combat Combat

				method Initialize()
				{
						;; bot module initialization
						;; ...
						;; ...
						;; call the combat object's init routine
						This.Combat:Initialize
						;; set the combat "mode"
						This.Combat:SetMode["DEFENSIVE"]
				}

				method Pulse()
				{
						if ${EVEBot.Paused}
								return
						if !${Config.Common.BotMode.Equal[Miner]}
								return
						;; bot module frame action code
						;; ...
						;; ...
						;; call the combat frame action code
						This.Combat:Pulse
				}

				function ProcessState()
				{
						if !${Config.Common.BotMode.Equal[Miner]}
								return

						; call the combat object state processing
						call This.Combat.ProcessState

						; see if combat object wants to
						; override bot module state.
						if ${This.Combat.Override}
								return

						; process bot module "states"
						switch ${This.CurrentState}
						{
								;; ...
								;; ...
						}
				}
		}

		COMBAT OBJECT "MODES"
		---------------------

				* DEFENSIVE -- If under attack (by NPCs) AND damage taken exceeds threshold, fight back
				* AGGRESSIVE -- If hostile NPC is targeted, destroy it
				* TANK      -- Maintain defenses but attack nothing

				NOTE: The combat object will activate and maintain your "tank" in all modes.
							It will also manage any enabled "flee" state.

		-- GliderPro
*/

objectdef obj_Combat
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable bool   Override
	variable string CombatMode
	variable string CurrentState
	variable bool   Fled

	method Initialize()
	{
		This.CurrentState:Set["IDLE"]
		This.Fled:Set[FALSE]
		Event[OnFrame]:AttachAtom[This:Pulse]

		UI:UpdateConsole["obj_Combat: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				This:SetState
			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method SetState()
	{
		if ${Me.InStation} == TRUE
		{
			This.CurrentState:Set["INSTATION"]
			return
		}

		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["FLEE"]
			return
		}

		if ${Me.GetTargets} > 0
		{
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			This.CurrentState:Set["IDLE"]
		}
	}

	method SetMode(string newMode)
	{
		This.CombatMode:Set[${newMode}]
	}

	member:string Mode()
	{
		return ${This.CombatMode}
	}

	member:bool Override()
	{
		return ${This.Override}
	}

	function ProcessState()
	{
		This.Override:Set[FALSE]

		if ${This.CurrentState.NotEqual["INSTATION"]}
		{
			if ${_Me.ToEntity.IsWarpScrambled}
			{
				; TODO - we need to quit if a red warps in while we're scrambled -- cybertech
				UI:UpdateConsole["Warp Scrambled: Ignoring System Status"]
			}
			elseif !${Social.IsSafe}
			{
				call This.Flee
				This.Override:Set[TRUE]
			}

			if (!${Ship.IsAmmoAvailable} &&  ${Config.Combat.RunOnLowAmmo})
			{
				; TODO - what to do about being warp scrambled in this case?
				call This.Flee
				This.Override:Set[TRUE]
			}

			This:CheckTank
		}

		switch ${This.CurrentState}
		{
			case INSTATION
				if ${Social.IsSafe}
				{
					call Station.Undock
				}
				break
			case IDLE
				break
			case FLEE
				call This.Flee
				This.Override:Set[TRUE]
				break
			case FIGHT
				call This.Fight
				break
		}
	}

	function Fight()
	{
		if ${Config.Common.BotMode.Equal[Ratter]}
		{
			Ship:Deactivate_Cloak
			while ${Ship.IsCloaked}
			{
				waitframe
			}

			; Reload the weapons -if- ammo is below 30% and they arent firing
			Ship:Reload_Weapons[FALSE]

			Ship:Activate_StasisWebs
			Ship:Activate_TargetPainters

			if ${Me.ActiveTarget.Distance} > ${Ship.OptimalWeaponRange}
			{
				UI:UpdateConsole["Active target out of range!!"]
			}
			else
			{
				Ship:Activate_Weapons
			}


			Ship.Drones:SendDrones
		}
	}

	function Flee()
	{
		This.Fled:Set[TRUE]

		if ${Config.Combat.RunToStation}
		{
			call This.FleeToStation
		}
		else
		{
			call This.FleeToSafespot
		}
	}

	function FleeToStation()
	{
		if !${Station.Docked}
		{
			call Station.Dock
		}
	}

	function FleeToSafespot()
	{
		if ${Safespots.AtSafespot}
		{
			if !${Ship.IsCloaked}
			{
				Ship:Activate_Cloak[]
			}
		}
		else
		{
			; Are we at the safespot and not warping?
			if ${_Me.ToEntity.Mode} != 3
			{
				call Safespots.WarpToNext
				wait 30
			}
		}
	}

	method CheckTank()
	{
		/* this shouldn't be here. just temporary moved here after removal of ManageTank into Defense thread. */
		if ${Me.GetTargetedBy} > 0
		{
			/* We have aggro now, yay! Let's launch some drones */
			if ${Config.Combat.LaunchCombatDrones} && \
				${Ship.Drones.DronesInSpace} == 0 && \
				!${Ship.InWarp} && !${This.Fled}
			{
				Ship.Drones:LaunchAll[]
			}
		}

		if ${This.Fled}
		{
			/* don't leave the "fled" state until we regen */
			if (${_MyShip.ArmorPct} < 50 || \
				(${_MyShip.ShieldPct} < 80 && ${Config.Combat.MinimumShieldPct} > 0) || \
				${_MyShip.CapacitorPct} < 80 )
			{
					This.CurrentState:Set["FLEE"]
			}
			else
			{
					This.Fled:Set[FALSE]
					This.CurrentState:Set["IDLE"]
			}
		}
		elseif (${_MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct}  || \
				${_MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct} || \
				${_MyShip.CapacitorPct} < ${Config.Combat.MinimumCapPct})
		{
			UI:UpdateConsole["Armor is at ${_MyShip.ArmorPct.Int}%: ${MyShip.Armor.Int}/${MyShip.MaxArmor.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${_MyShip.ShieldPct.Int}%: ${MyShip.Shield.Int}/${MyShip.MaxShield.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Cap is at ${_MyShip.CapacitorPct.Int}%: ${MyShip.Capacitor.Int}/${MyShip.MaxCapacitor.Int}", LOG_CRITICAL]

			if !${Config.Combat.RunOnLowTank}
			{
				UI:UpdateConsole["Run On Low Tank Disabled: Fighting", LOG_CRITICAL]
			}
			elseif ${_Me.ToEntity.IsWarpScrambled}
			{
				UI:UpdateConsole["Warp Scrambled: Fighting", LOG_CRITICAL]
			}
			else
			{
				UI:UpdateConsole["Fleeing due to defensive status", LOG_CRITICAL]
				This.CurrentState:Set["FLEE"]
			}
		}
	}
}

#endif /* __OBJ_COMBAT__ */