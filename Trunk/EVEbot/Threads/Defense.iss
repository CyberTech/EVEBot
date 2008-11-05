#include ..\core\defines.iss
/*
	Defense Thread

	This thread handles ship _defense_.
	
	No offensive actions occur in this thread.

	-- CyberTech

*/

objectdef obj_Defense
{
	variable string SVN_REVISION = "$Rev: 728 $"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1
	
	variable bool Fled = FALSE

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		Script[EVEBot].VariableScope.UI:UpdateConsole["Thread: obj_Defense: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${Script[EVEBot].VariableScope.EVEBot.Paused}
		{
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${This.Running}
			{
				This:TakeDefensiveAction
				if ${This.Fled} == FALSE && (${This.IsTankHolding} == FALSE || \
					${This.IsLocalHot} == TRUE || ${This.OutOfAmmo} == TRUE)
				{
					;; run away fool
					This.Fled:Set[TRUE]
					Script[EVEBot].VariableScope.UI:UpdateConsole["Thread: obj_Defense: fleeing...  ${This.IsTankHolding} ${This.IsLocalHot} ${This.OutOfAmmo}"]	
				}
				else
				{
					if ${This.Fled} && ${This.DidTankRegen} == TRUE && \
						${This.IsLocalHot} == FALSE && ${This.OutOfAmmo} == FALSE
					{
						;; return to action
						This.Fled:Set[FALSE]
						Script[EVEBot].VariableScope.UI:UpdateConsole["Thread: obj_Defense: returning to action..."]
					}	
				}
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
	
	member:bool IsTankHolding()
	{
		if	${Script[EVEBot].VariableScope.Ship.IsCloaked} || \
			${_Me.InStation}
		{
			return TRUE
		}
		
		if (${_Me.Ship.ArmorPct} < ${Script[EVEBot].VariableScope.Config.Combat.MinimumArmorPct}  || \
			${_Me.Ship.ShieldPct} < ${Script[EVEBot].VariableScope.Config.Combat.MinimumShieldPct} || \
			${_Me.Ship.CapacitorPct} < ${Script[EVEBot].VariableScope.Config.Combat.MinimumCapPct})
		{
			Script[EVEBot].VariableScope.UI:UpdateConsole["Armor is at ${_Me.Ship.ArmorPct.Int}%: ${Me.Ship.Armor.Int}/${Me.Ship.MaxArmor.Int}", LOG_CRITICAL]
			Script[EVEBot].VariableScope.UI:UpdateConsole["Shield is at ${_Me.Ship.ShieldPct.Int}%: ${Me.Ship.Shield.Int}/${Me.Ship.MaxShield.Int}", LOG_CRITICAL]
			Script[EVEBot].VariableScope.UI:UpdateConsole["Cap is at ${_Me.Ship.CapacitorPct.Int}%: ${Me.Ship.Capacitor.Int}/${Me.Ship.MaxCapacitor.Int}", LOG_CRITICAL]

			if !${Script[EVEBot].VariableScope.Config.Combat.RunOnLowTank}
			{
				Script[EVEBot].VariableScope.UI:UpdateConsole["Run On Low Tank Disabled: Fighting", LOG_CRITICAL]
			}
			elseif ${_Me.ToEntity.IsWarpScrambled}
			{
				Script[EVEBot].VariableScope.UI:UpdateConsole["Warp Scrambled: Fighting", LOG_CRITICAL]
			}
			else
			{
				Script[EVEBot].VariableScope.UI:UpdateConsole["Fleeing due to defensive status", LOG_CRITICAL]
				return FALSE
			}
		}
		
		return TRUE
	}
	
	member:bool DidTankRegen()
	{
		/* don't leave the "fled" state until we regen */
		if ${This.Fled} == TRUE && (${_Me.Ship.ArmorPct} < 50 || \
			(${_Me.Ship.ShieldPct} < 80 && ${Config.Combat.MinimumShieldPct} > 0) || \
			${_Me.Ship.CapacitorPct} < 80 )
		{
				return FALSE
		}

		return TRUE
	}
	
	member:bool IsLocalHot()
	{
		if	${Script[EVEBot].VariableScope.Ship.IsCloaked} || \
			${_Me.InStation}
		{
			return FALSE
		}
		
		if ${Script[EVEBot].VariableScope.Social.IsSafe} == FALSE
		{
			if ${_Me.ToEntity.IsWarpScrambled}
			{
				; TODO - we need to quit if a red warps in while we're scrambled -- cybertech
				Script[EVEBot].VariableScope.UI:UpdateConsole["Warp Scrambled: Ignoring System Status"]
			}
			else
			{
				return TRUE	
			}
		}
		
		return FALSE
	}
	
	member:bool OutOfAmmo()
	{
		if	${Script[EVEBot].VariableScope.Ship.IsCloaked} || \
			${_Me.InStation}
		{
			return FALSE
		}

		if ${Script[EVEBot].VariableScope.Ship.IsAmmoAvailable} == FALSE
		{
			if ${Script[EVEBot].VariableScope.Config.Combat.RunOnLowAmmo} == TRUE
			{			
				; TODO - what to do about being warp scrambled in this case?
				return TRUE
			}
		}
		
		return FALSE
	}
	
	function Flee()
	{
		if ${Script[EVEBot].VariableScope.Config.Combat.RunToStation}
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
		if !${Script[EVEBot].VariableScope.Station.Docked}
		{
			call Script[EVEBot].VariableScope.Station.Dock
		}
	}

	function FleeToSafespot()
	{
		if ${Script[EVEBot].VariableScope.Safespots.IsAtSafespot}
		{
			if !${Script[EVEBot].VariableScope.Ship.IsCloaked}
			{
				${Script[EVEBot].VariableScope.Ship:Activate_Cloak[]
			}
		}
		else
		{
			; Are we at the safespot and not warping?
			if ${_Me.ToEntity.Mode} != 3
			{
				call Script[EVEBot].VariableScope.Safespots.WarpTo
				wait 30
			}
		}
	}

	method TakeDefensiveAction()
	{
		if	${Script[EVEBot].VariableScope.Ship.IsCloaked} || \
			${_Me.InStation}
		{
			return
		}
		
		if ${_Me.Ship.ArmorPct} < 100
		{
			/* Turn on armor reps, if you have them 
				Armor reps do not rep right away -- they rep at the END of the cycle.
				To counter this we start the rep as soon as any damage occurs.
			*/
			Script[EVEBot].VariableScope.Ship:Activate_Armor_Reps[]
		}
		elseif ${_Me.Ship.ArmorPct} > 98
		{
			Script[EVEBot].VariableScope.Ship:Deactivate_Armor_Reps[]
		}
		
		if (${_Me.ToEntity.Mode} == 3)
		{
			; We are in warp, we turn on shield regen so we can use up cap while it has time to regen
			if ${_Me.Ship.ShieldPct} < 99
			{
				Script[EVEBot].VariableScope.Ship:Activate_Shield_Booster[]
			}
			else
			{
				Script[EVEBot].VariableScope.Ship:Deactivate_Shield_Booster[]
			}
		}
		else
		{
			; We're not in warp, so use normal percentages to enable/disable 
			if ${_Me.Ship.ShieldPct} < 95 || ${Script[EVEBot].VariableScope.Config.Combat.AlwaysShieldBoost}
			{
				Script[EVEBot].VariableScope.Ship:Activate_Shield_Booster[]
			}
			elseif ${_Me.Ship.ShieldPct} > 95 && !${Script[EVEBot].VariableScope.Config.Combat.AlwaysShieldBoost}
			{
				Script[EVEBot].VariableScope.Ship:Deactivate_Shield_Booster[]
			}
		}
		
		if ${_Me.Ship.CapacitorPct} < 20
		{
			Script[EVEBot].VariableScope.Ship:Activate_Cap_Booster[]
		}
		elseif ${_Me.Ship.CapacitorPct} > 80
		{
			Script[EVEBot].VariableScope.Ship:Deactivate_Cap_Booster[]
		}

		; Active shield (or armor) hardeners
		; If you don't have hardeners this code does nothing.
		; This uses shield and uncached GetTargetedBy (to reduce chance of a 
		; volley making it thru before hardeners are up)
		if ${Me.GetTargetedBy} > 0 || ${_Me.Ship.ShieldPct} < 99
		{
			Script[EVEBot].VariableScope.Ship:Activate_Hardeners[]
		}
		else
		{
			Script[EVEBot].VariableScope.Ship:Deactivate_Hardeners[]
		}
	}
}

variable(global) obj_Defense Defense

function main()
{
	while ${Script[EVEBot](exists)}
	{
		if ${Defense.Fled} == TRUE
		{
			call Defense.Flee
			wait 60
		}
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}