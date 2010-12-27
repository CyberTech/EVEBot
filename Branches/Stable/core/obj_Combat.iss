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
						if !${Config.Common.BotModeName.Equal[Miner]}
								return
						;; bot module frame action code
						;; ...
						;; ...
						;; call the combat frame action code
						This.Combat:Pulse
				}

				function ProcessState()
				{
						if !${Config.Common.BotModeName.Equal[Miner]}
								return

						; call the combat object state processing
						call This.Combat.ProcessState

						; see if combat object wants to
						; override bot module state.
						if ${This.Combat.Fled}
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

	variable string CombatMode
	variable string CurrentState = "IDLE"
	variable bool   Fled = FALSE

	method Initialize()
	{
		UI:UpdateConsole["obj_Combat: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:SetState

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method SetState()
	{
		if ${_Me.InStation} == TRUE
		{
	  		This.CurrentState:Set["INSTATION"]
	  		return
		}

		if ${Ship.IsPod}
		{
			UI:UpdateConsole["Warning: We're in a pod, running"]
			This.CurrentState:Set["FLEE"]
			return
		}

		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["FLEE"]
			return
		}

		if ${_Me.GetTargets} > 0
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

	function ProcessState()
	{
		if ${This.CurrentState.NotEqual["INSTATION"]}
		{
			if ${_Me.ToEntity.IsWarpScrambled}
			{
				; TODO - we need to quit if a red warps in while we're scrambled -- cybertech
				UI:UpdateConsole["Warp Scrambled: Ignoring System Status"]
			}
			elseif !${Social.IsSafe}
			{
				UI:UpdateConsole["Debug: Fleeing: Local isn't safe"]
				call This.Flee
				return
			}
			elseif (!${Ship.IsAmmoAvailable} && ${Config.Combat.RunOnLowAmmo})
			{
				UI:UpdateConsole["Debug: Fleeing: Low ammo"]
				; TODO - what to do about being warp scrambled in this case?		
				call This.Flee
				return
			}
			call This.ManageTank
		}

		UI:UpdateConsole["Debug: Combat: This.Fled = ${This.Fled} This.CurrentState = ${This.CurrentState} Social.IsSafe = ${Social.IsSafe}"]

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
				break
			case FIGHT
				call This.Fight
				break
		}
	}

	function Fight()
	{
		Ship:Deactivate_Cloak
		while ${Ship.IsCloaked}
		{
			waitframe
		}
		;Ship:Offline_Cloak
		;Ship:Online_Salvager

		; Reload the weapons -if- ammo is below 30% and they arent firing
		Ship:Reload_Weapons[FALSE]

		; Activate the weapons, the modules class checks if there's a target (no it doesn't - ct)
		Ship:Activate_TargetPainters
		Ship:Activate_StasisWebs
		Ship:Activate_Weapons
		Ship.Drones:SendDrones
	}

	function Flee()
	{
		This.CurrentState:Set["FLEE"]
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
		if ${Safespots.IsAtSafespot}
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
				call Safespots.WarpTo
				wait 30
			}
		}
	}

	method CheckTank()
	{
		if ${This.Fled}
		{
			/* don't leave the "fled" state until we regen */
			if (${_Me.Ship.ArmorPct} < 50 || \
				(${_Me.Ship.ShieldPct} < 80 && ${Config.Combat.MinimumShieldPct} > 0) || \
				${_Me.Ship.CapacitorPct} < 80 )
			{
					This.CurrentState:Set["FLEE"]
					UI:UpdateConsole["Debug: Staying in Flee State: Armor: ${_Me.Ship.ArmorPct} Shield: ${_Me.Ship.ShieldPct} Cap: ${_Me.Ship.CapacitorPct}", LOG_DEBUG]
			}
			else
			{
					This.Fled:Set[FALSE]
					This.CurrentState:Set["IDLE"]
			}
		}
		elseif (${_Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct}  || \
				${_Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct} || \
				${_Me.Ship.CapacitorPct} < ${Config.Combat.MinimumCapPct})
		{
			UI:UpdateConsole["Armor is at ${_Me.Ship.ArmorPct.Int}%: ${Me.Ship.Armor.Int}/${Me.Ship.MaxArmor.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${_Me.Ship.ShieldPct.Int}%: ${Me.Ship.Shield.Int}/${Me.Ship.MaxShield.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Cap is at ${_Me.Ship.CapacitorPct.Int}%: ${Me.Ship.Capacitor.Int}/${Me.Ship.MaxCapacitor.Int}", LOG_CRITICAL]

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

	function ManageTank()
	{
		if ${_Me.Ship.ArmorPct} < 100
		{
			/* Turn on armor reps, if you have them
				Armor reps do not rep right away -- they rep at the END of the cycle.
				To counter this we start the rep as soon as any damage occurs.
			*/
			Ship:Activate_Armor_Reps[]
		}
		elseif ${_Me.Ship.ArmorPct} > 98
		{
			Ship:Deactivate_Armor_Reps[]
		}

		if ${_Me.Ship.ShieldPct} < 85 || ${Config.Combat.AlwaysShieldBoost}
		{   /* Turn on the shield booster, if present */
			Ship:Activate_Shield_Booster[]
		}
		elseif ${_Me.Ship.ShieldPct} > 95 && !${Config.Combat.AlwaysShieldBoost}
		{
			Ship:Deactivate_Shield_Booster[]
		}

		if ${_Me.Ship.CapacitorPct} < 20
		{   /* Turn on the cap booster, if present */
			Ship:Activate_Cap_Booster[]
		}
		elseif ${_Me.Ship.CapacitorPct} > 80
		{
			Ship:Deactivate_Cap_Booster[]
		}

		; Active shield (or armor) hardeners
		; If you don't have hardeners this code does nothing.
		if ${_Me.GetTargetedBy} > 0
		{
			Ship:Activate_Hardeners[]

			/* We have aggro now, yay! Let's launch some drones */
			if !${This.Fled} && ${Config.Combat.LaunchCombatDrones} && \
				${Ship.Drones.DronesInSpace} == 0 && \
				!${Ship.InWarp}
			{
				Ship.Drones:LaunchAll[]
			}
		}
		else
		{
			Ship:Deactivate_Hardeners[]
		}

		This:CheckTank
	}
}

#endif /* __OBJ_COMBAT__ */