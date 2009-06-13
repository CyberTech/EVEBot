#include ..\core\defines.iss
/*
	Offense Thread

	This thread handles shooting targets (rats, players, structures, etc...)

	-- GliderPro

*/
objectdef obj_Offense
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	variable bool Warned_LowAmmo = FALSE
	variable time NextAmmoChange
	variable int NumTurrets = 0

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["Thread: obj_Offense: Initialized", LOG_MINOR]
		/* If you want to use missiles, pass true to this */
		Config.Combat:ShouldUseMissiles[FALSE]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			Script:End
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${This.Running} && !${EVEBot.Paused}
			{
				This:TakeOffensiveAction
				This:CheckAmmo[]
			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method TakeOffensiveAction()
	{
		if ${Me.ActiveTarget(exists)} && !${Me.ActiveTarget.IsPC}
		{
			if !${This.IsConcordTarget[${Me.ActiveTarget.GroupID}]}
			{
				if ${Ship.IsCloaked}
				{
					Ship:Deactivate_Cloak
					; Need to give it time to uncloak
					return
				}

				Ship:Activate_StasisWebs
				Ship:Activate_TargetPainters

				
				if !${Config.Combat.ShouldUseMissiles} && ${Time.Timestamp} >= ${This.NextAmmoChange.Timestamp}
				{
					if ${Ship.GetNumberTurrets} > 0 && ${NumTurrets} == 0
					{
						Ship:Deactivate_Weapons
						NumTurrets:Set[${Ship.GetNumberTurrets}]
						return
					}
					if ${NumTurrets} > 0
					{
						Ship:LoadOptimalAmmo[${Me.ActiveTarget.Distance}]
						NumTurrets:Dec
					}
					if ${NumTurrets} == 0
					{
						This.NextAmmoChange:Set[${Time.Timestamp}]
						This.NextAmmoChange.Second:Inc[20]
						This.NextAmmoChange:Update
					}
					return
				}
				
				UI:UpdateConsole["Max Distance: ${Ship.GetMaximumTurretDistance}, Min: ${Ship.GetMinimumTurretDistance}, Math: ${Math.Calc[${Ship.GetMinimumTurretDistance} * 0.5]}"]
				if ${Config.Combat.ShouldUseMissiles}
				{
					if ${Me.ActiveTarget.Distance} < ${Ship.OptimalWeaponRange}
					{
						Ship:Activate_Weapons
					}					
				}
				/* We can shoot a LITTLE past maximum because of falloff, and we can shoot a little under minimum, just won't do as much damage */
				elseif ${Me.ActiveTarget.Distance} <= (${Ship.GetMaximumTurretRange} * 1.2) && ${Me.ActiveTarget.Distance} >= (${Ship.GetMinimumTurretRange} * 0.5)
				{
					Ship:Activate_Weapons
				}

				if ${Ship.Drones.CombatDroneShortage}
				{
					/* TODO - This should pick up drones from station instead of just docking */
					Defense.RunAway["Combat: Drone shortage detected"]
					return
				}

				if ${Config.Combat.LaunchCombatDrones}
				{
					if ${Ship.Drones.CombatDroneShortage}
					{
						; TODO - This should pick up drones from station instead of just docking
						Defense.RunAway["Offense: Drone shortage detected"]
						return
					}

					if ${Ship.Drones.ShouldLaunchCombatDrones} && ${Ship.Drones.DeployedDroneCount} == 0
					{
						Ship.Drones:LaunchAll[]
					}
					else
					{
						Ship.Drones:SendDrones
					}
				}
			}
		}
		else
		{
			Ship:Deactivate_Weapons
			Ship:Deactivate_StasisWebs
		}
	}

	method CheckAmmo()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${Ship.IsCloaked} || !${Me.InSpace}
		{
			return
		}

		if !${Ship.IsAmmoAvailable}
		{
			if ${Config.Combat.RunOnLowAmmo}
			{
				Defense:RunAway["Offense - Out of ammo!"]
			}
			elseif !${This.Warned_LowAmmo}
			{
				This.Warned_LowAmmo:Set[TRUE]
				UI:UpdateConsole["Offense: Warning - Out of ammo!"]
			}
		}
		else
		{
			This.Warned_LowAmmo:Set[FALSE]
		}
	}

	member:bool IsConcordTarget(int GroupID)
	{
		switch ${GroupID}
		{
			case GROUP_LARGECOLLIDABLEOBJECT
			case GROUP_LARGECOLLIDABLESHIP
			case GROUP_SENTRYGUN
			case GROUP_CONCORDDRONE
			case GROUP_CUSTOMSOFFICIAL
			case GROUP_POLICEDRONE
			case GROUP_CONVOYDRONE
			case GROUP_FACTIONDRONE
			case GROUP_BILLBOARD
				return TRUE
		}

		return FALSE
	}

	method Enable()
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["Offense: Enabled"]
#endif
		This.Running:Set[TRUE]
	}

	method Disable()
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["Offense: Disabled"]
#endif
		This.Running:Set[FALSE]
	}
}

variable(global) obj_Offense Offense

function main()
{
	EVEBot.Threads:Insert[${Script.Filename}]
	while ${Script[EVEBot](exists)}
	{
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}