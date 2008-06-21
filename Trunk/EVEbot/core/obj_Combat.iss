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
		if ${Me.InStation} == TRUE
		{
	  		This.CurrentState:Set["INSTATION"]
	  		return
		}
		
		if ${Me.GetTargets(exists)} && ${Me.GetTargets} > 0
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
			if ${Me.ToEntity.IsWarpScrambled}
			{
				; TODO - we need to quit if a red warps in while we're scrambled -- cybertech
				UI:UpdateConsole["Warp Scrambled: Ignoring System Status"]
			}
			else
			{
				if !${Social.IsSafe} && ${Me.ToEntity.IsWarpScrambled}
				{
					call This.Flee
					This.Override:Set[TRUE]
				}
			}
			
			if (!${Ship.IsAmmoAvailable} &&  ${Config.Combat.RunOnLowAmmo})
			{
				; TODO - what to do about being warp scrambled in this case?
				call This.Flee
				This.Override:Set[TRUE]
			}
			call This.ManageTank
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
		Ship:Activate_StasisWebs
		Ship:Activate_Weapons
		Ship.Drones:SendDrones
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
			if ${Me.ToEntity.Mode} != 3
			{
				call Safespots.WarpTo
				wait 30
			}			
		}
	}

	method CheckTank(float ArmorPct, float ShieldPct, float CapacitorPct)
	{
		if ${This.Fled}
		{
			/* don't leave the "fled" state until we regen */
			if (${ArmorPct} < 50 || \
				(${ShieldPct} < 80 && ${Config.Combat.MinimumShieldPct} > 0) || \
				${CapacitorPct} < 80 )
			{
					This.CurrentState:Set["FLEE"]
			}
			else
			{
					This.Fled:Set[FALSE]
					This.CurrentState:Set["IDLE"]
			}
		}
		elseif (${ArmorPct} < ${Config.Combat.MinimumArmorPct}  || \
				${ShieldPct} < ${Config.Combat.MinimumShieldPct} || \
				${CapacitorPct} < ${Config.Combat.MinimumCapPct})
		{
			UI:UpdateConsole["Armor is at ${ArmorPct.Int}%: ${Me.Ship.Armor.Int}/${Me.Ship.MaxArmor.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${ShieldPct.Int}%: ${Me.Ship.Shield.Int}/${Me.Ship.MaxShield.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Cap is at ${CapacitorPct.Int}%: ${Me.Ship.Capacitor.Int}/${Me.Ship.MaxCapacitor.Int}", LOG_CRITICAL]
			
			if !${Config.Combat.RunOnLowTank}
			{
				UI:UpdateConsole["Run On Low Tank Disabled: Fighting", LOG_CRITICAL]
			}
			elseif ${Me.ToEntity.IsWarpScrambled}
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
		variable int Counter
		variable float ArmorPct
		variable float ShieldPct
		variable float CapacitorPct

		call Ship.ShieldPct
		ShieldPct:Set[${Return}]

		call Ship.ArmorPct
		ArmorPct:Set[${Return}]

		call Ship.CapacitorPct
		CapacitorPct:Set[${Return}]

		;UI:UpdateConsole["DEBUG: Combat ${ArmorPct} ${ShieldPct} ${CapacitorPct}"]

		if (${ArmorPct} == -1 || ${ShieldPct} == -1 || ${CapacitorPct} == -1)
		{
			/* If any of these are -1, then the ship member timed out trying to retrieve
				a valid value. Don't exit here, let the modules activate even if needless,
				we'll be running anyway
			*/
			if !${This.Fled} && !${Me.ToEntity.IsWarpScrambled}
			{
				This.CurrentState:Set["FLEE"]
			}
		}

		if ${ArmorPct} < 100
		{
			/* Turn on armor reps, if you have them 
				Armor reps do not rep right away -- they rep at the END of the cycle.
				To counter this we start the rep as soon as any damage occurs.
			*/
			Ship:Activate_Armor_Reps[]
		}
		elseif ${ArmorPct} > 98
		{
			Ship:Deactivate_Armor_Reps[]
		}

		if ${ShieldPct} < 85 || ${Config.Combat.AlwaysShieldBoost}
		{   /* Turn on the shield booster, if present */
			Ship:Activate_Shield_Booster[]
		}
		elseif ${ShieldPct} > 95 && !${Config.Combat.AlwaysShieldBoost}
		{
			Ship:Deactivate_Shield_Booster[]
		}

		if ${CapacitorPct} < 20
		{   /* Turn on the cap booster, if present */
			Ship:Activate_Cap_Booster[]
		}
		elseif ${CapacitorPct} > 80
		{
			Ship:Deactivate_Cap_Booster[]
		}

		; Active shield (or armor) hardeners
		; If you don't have hardeners this code does nothing.
		if ${Me.GetTargetedBy} > 0
		{
			Ship:Activate_Hardeners[]

			/* We have aggro now, yay! Let's launch some drones */
			if ${Config.Combat.LaunchCombatDrones} && \
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

		This:CheckTank[${ArmorPct},${ShieldPct},${CapacitorPct}]
	}
}

#endif /* __OBJ_COMBAT__ */