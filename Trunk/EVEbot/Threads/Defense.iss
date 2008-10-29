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
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
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
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}