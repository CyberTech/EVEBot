#include ..\core\defines.iss
/*
	Defense Thread

	This thread handles ship _defense_.

	No offensive actions occur in this thread.

	-- CyberTech

*/

objectdef obj_Defense
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable bool Hide = FALSE
	variable string HideReason
	variable bool Hiding = FALSE
	variable index:entity TargetingMe

	variable obj_EntityCache DefenseCache

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["Thread: obj_Defense: Initialized", LOG_MINOR]
		if ${DefenseCache.PulseIntervalInSeconds} != 9999
		{
			DefenseCache:SetUpdateFrequency[9999]
		}
		DefenseCache:UpdateSearchParams["Unused","CategoryID,CATEGORYID_ENTITY,radius,60000"]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			Script:End
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${EVEBot.SessionValid} && ${This.Running}
			{
				This:CheckWarpScramble
				This:TakeDefensiveAction[]
				This:CheckTankMinimums[]
				This:CheckLocal[]

				if ${Config.Combat.RunIfTargetJammed} && ${Targeting.IsTargetingJammed}
				{
					This:RunAway["Unable to evade sensor jamming"]
				}
				elseif ${This.Hide} && ${This.HideReason.Equal["Unable to evade sensor jamming"]} && !${Targeting.IsTargetJammed}
				{
					This:ReturnToDuty
				}

				if ${EVEBot.ReturnToStation}
				{
					This:RunAway["ReturnToStation is true - legacy code somewhere!"]
				}

				if !${This.Hide} && ${This.Hiding} && ${This.TankReady} && ${Social.IsSafe}
				{
					UI:UpdateConsole["Thread: obj_Defense: No longer hiding"]
					This.Hiding:Set[FALSE]
				}

			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
	
	method CheckWarpScramble()
	{
		if ${_Me.IsWarpScrambled}
		{
			if ${DefenseCache.Entities.Used} == 0
			{
				if ${DefenseCache.PulseIntervalInSeconds} != 1
				{
					DefenseCache:SetUpdateFrequency[1]
				}
			}
			else
			{
				DefenseCache.Entities:GetIterator[DefenseCache.EntityIterator]
				if ${DefenseCache.EntityIterator:First(exists)}
				{
					do
					{
						if !${Targeting.IsMandatoryQueued[${DefenseCache.EntityIterator.Value.ID}]} && \
							${DefenseCache.EntityIterator.Value.IsWarpScramblingMe}
						{
							;method Queue(int EntityID, int Priority, int TargetType, bool Mandatory=FALSE, bool Blocker=FALSE)
							UI:UpdateConsole["Defense: Targeting warp scrambling rat ${DefenseCache.EntityIterator.Value.Name} ${DefenseCache.EntityIterator.Value.TypeID}!",LOG_CRITICAL]
							Targeting:Queue[${DefenseCache.EntityIterator.Value.ID},0,${DefenseCache.EntityIterator.Value.TypeID},TRUE]
						}
					}
					while ${DefenseCache.EntityIterator:Next(exists)}
				}
			}
		}
		else
		{
			if ${DefenseCache.PulseIntervalInSeconds} != 9999
			{
				DefenseCache:SetUpdateFrequency[9999]
			}
		}
	}

	method CheckTankMinimums()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${Ship.IsCloaked} || !${Me.InSpace}
		{
			return
		}

		if ${Ship.IsPod}
		{
			This:RunAway["We're in a pod! Run Away! Run Away!"]
		}

		if (${_MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct}  || \
			${_MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct} || \
			${_MyShip.CapacitorPct} < ${Config.Combat.MinimumCapPct} && ${Config.Combat.RunOnLowCap})
		{
			UI:UpdateConsole["Armor is at ${_MyShip.ArmorPct.Int}%: ${MyShip.Armor.Int}/${MyShip.MaxArmor.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${_MyShip.ShieldPct.Int}%: ${MyShip.Shield.Int}/${MyShip.MaxShield.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Cap is at ${_MyShip.CapacitorPct.Int}%: ${MyShip.Capacitor.Int}/${MyShip.MaxCapacitor.Int}", LOG_CRITICAL]

			if !${Config.Combat.RunOnLowTank}
			{
				UI:UpdateConsole["Running on low tank is disabled", LOG_CRITICAL]
			}
			elseif ${_Me.ToEntity.IsWarpScrambled}
			{
				UI:UpdateConsole["Warp scrambled, can't run", LOG_CRITICAL]
			}
			elseif ${_MyShip.CapacitorPct} < ${Config.Combat.MinimumCapPct} && ${Config.Combat.RunOnLowCap}
			{
				This:RunAway["Low Capacitor"]
				return
			}
			else
			{
				This:RunAway["Defensive Status"]
				return
			}
		}
	}

	; 3rd Parties should call this if they want Defense thread to initiate fleeing
	method RunAway(string Reason="Not Specified")
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		This.Hide:Set[TRUE]
		This.HideReason:Set[${Reason}]
		if !${This.Hiding}
		{
			UI:UpdateConsole["Fleeing: ${Reason}", LOG_CRITICAL]
		}
	}

	method ReturnToDuty()
	{
		UI:UpdateConsole["Returning to duty", LOG_CRITICAL]
		This.Hide:Set[FALSE]
	}

	member:bool TankReady()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		;Only return false if it wasn't because of low cap, cap recharges on dock
		if !${Me.InSpace}
		{
			;Our cap recharges on docking.
			if ${Config.Combat.RunOnLowCap} && ${This.HideReason.Equal["Low Capacitor"]}
			{
				return TRUE
			}
			return FALSE
		}

		if  ${_MyShip.ArmorPct} < ${Config.Combat.ArmorPctReady} || \
			(${_MyShip.ShieldPct} < ${Config.Combat.ShieldPctReady} && ${Config.Combat.MinimumShieldPct} > 0) || \
			${_MyShip.CapacitorPct} < ${Config.Combat.CapacitorPctReady}
		{
			return FALSE
		}

		return TRUE
	}

	method CheckLocal()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${Ship.IsCloaked} || !${Me.InSpace}
		{
			return
		}

		if ${Social.IsSafe} == FALSE
		{
			This:RunAway["Hostiles in Local"]
		}
		elseif ${This.Hide} && ${This.HideReason.Equal["Hostiles in Local"]}
		{
			This:ReturnToDuty
		}
	}

	function Flee()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${_Me.ToEntity.IsWarpScrambled}
		{
			if ${Config.Combat.QuitIfWarpScrambled}
			{
				UI:UpdateConsole["Warp Scrambled: Quitting game."]
				exit
				; Todo: Optionally start the launcher to restart EVE in a while.
			}
			else
			{
				UI:UpdateConsole["Warp Scrambled: Not quitting game. Don't blame us if you pop."]
				; Return because we can't do anything else.
				return
			}
		}

		This.Hiding:Set[TRUE]
		if ${Config.Combat.RunToStation} || ${Safespots.Count} == 0
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
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if !${Station.Docked}
		{
			call Station.Dock
		}
	}

	function FleeToSafespot()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		variable bool KeepMoving = TRUE

		if ${Safespots.AtSafespot}
		{
			if !${This.TankReady} && ${Social.IsSafe}
			{
				; We deactivate cloak here, regardless of flee reason, because social is "safe",
				; and we need to rep. We will cycle safespots while doing so.
				Ship:Deactivate_Cloak[]
				KeepMoving:Set[TRUE]
			}
			elseif ${Ship.HasCloak}
			{
				if !${Ship.IsCloaked}
				{
					Ship:Activate_Cloak[]
					KeepMoving:Set[FALSE]
				}
			}
			elseif ${Safespots.Count} > 1
			{
				; This ship doesn't have a cloak so let's bounce between safe spots
				KeepMoving:Set[TRUE]
			}
		}
		else
		{
			KeepMoving:Set[TRUE]
		}

		if ${KeepMoving} && ${Me.ToEntity.Mode} != 3
		{
			; Are we at the safespot and not warping?
			; TODO - Shutdown Eve or dock if we are fleeing without a cloak for more than (configurable) minutes - CyberTech
			call Safespots.WarpToNext
			wait 30
		}
	}

	method TakeDefensiveAction()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${Ship.IsCloaked} || !${Me.InSpace}
		{
			return
		}

		if ${_MyShip.ArmorPct} < ${Config.Combat.ArmorPctEnable}
		{
			/* Turn on armor reps, if you have them
				Armor reps do not rep right away -- they rep at the END of the cycle.
				To counter this we start the rep as soon as any damage occurs.
			*/
			Ship:Activate_Armor_Reps[]
		}
		elseif ${_MyShip.ArmorPct} > ${Config.Combat.ArmorPctDisable}
		{
			Ship:Deactivate_Armor_Reps[]
		}

		if (${_Me.ToEntity.Mode} == 3)
		{
			; We are in warp, we turn on shield regen so we can use up cap while it has time to regen
			if ${_MyShip.ShieldPct} < 99
			{
				Ship:Activate_Shield_Booster[]
			}
			else
			{
				Ship:Deactivate_Shield_Booster[]
			}
		}
		else
		{
			; We're not in warp, so use normal percentages to enable/disable
			if ${_MyShip.ShieldPct} < ${Config.Combat.ShieldPctEnable} || ${Config.Combat.AlwaysShieldBoost}
			{
				Ship:Activate_Shield_Booster[]
			}
			elseif ${_MyShip.ShieldPct} > ${Config.Combat.ShieldPctDisable} && !${Config.Combat.AlwaysShieldBoost}
			{
				Ship:Deactivate_Shield_Booster[]
			}
		}

		if ${_MyShip.CapacitorPct} < ${Config.Combat.CapacitorPctEnable}
		{
			Ship:Activate_Cap_Booster[]
		}
		elseif ${_MyShip.CapacitorPct} > ${Config.Combat.CapacitorPctDisable}
		{
			Ship:Deactivate_Cap_Booster[]
		}

		; Active shield (or armor) hardeners
		; If you don't have hardeners this code does nothing.
		; This uses shield and uncached GetTargetedBy (to reduce chance of a
		; volley making it thru before hardeners are up)
		Me:DoGetTargetedBy[This.TargetingMe]
		if ${This.TargetingMe.Used} > 0 || ${_MyShip.ShieldPct} < 99
		{
			Ship:Activate_Hardeners[]
			Ship:Activate_ECCM[]
		}
		else
		{
			Ship:Deactivate_Hardeners[]
			Ship:Deactivate_ECCM[]
		}
	}
}

variable(global) obj_Defense Defense

function main()
{
	EVEBot.Threads:Insert[${Script.Filename}]
	while ${Script[EVEBot](exists)}
	{
		if ${Defense.Hide}
		{
			call Defense.Flee
			wait 10 !${Script[EVEBot](exists)}
		}
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}