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
	variable int PulseIntervalInSeconds = 1
	variable bool Warned_LowAmmo = FALSE
	variable time NextAmmoChange
	variable int NumTurrets = 0
	variable float Range
	variable bool bDeactivatedWeapons = FALSE

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["Thread: obj_Offense: Initialized", LOG_MINOR]

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

				
				UI:UpdateConsole["Max Distance: ${Ship.MaximumTurretRange}, Min: ${Ship.MinimumTurretRange}, Math: ${Math.Calc[${Ship.MaximumTurretRange} * 1.2]}, ${Math.Calc[${Ship.MinimumTurretRange} * 0.833]}"]
				if ${Config.Combat.ShouldUseMissiles}
				{
					if ${Me.ActiveTarget.Distance} < ${Ship.OptimalWeaponRange}
					{
						Ship:Activate_Weapons
					}					
				}
				elseif ${Time.Timestamp} >= ${This.NextAmmoChange.Timestamp}
				{
					UI:UpdateConsole["Offense: NeedAmmoChange: ${Ship.NeedAmmoChange[${Me.ActiveTarget.Distance}]}"]
					if ${Ship.NeedAmmoChange[${Me.ActiveTarget.Distance}]}
					{
						UI:UpdateConsole["Ship.NumTurrets: ${Ship.NumberTurrets}, NumTurrets: ${NumTurrets}"]
						if ${Ship.NumberTurrets} > 0 && ${NumTurrets} == 0
						{
							UI:UpdateConsole["Setting num turrets"]
							NumTurrets:Set[${Ship.NumberTurrets}]
						}
						elseif ${NumTurrets} > 0
						{
							UI:UpdateConsole["Ship.WeaponsActive: ${Ship.WeaponsActive}"]
							if !${Ship.WeaponsActive}
							{
								if ${Range} == 0
								{
									Range:Set[${Me.ActiveTarget.Distance}]
								}
								Ship:LoadOptimalAmmo[${Range}]
								NumTurrets:Dec
							}
							elseif !${bDeactivatedWeapons}
							{
								Ship:Deactivate_Weapons
								bDeactivatedWeapons:Set[TRUE]
								return
							}
							else
							{
								/* we're still waiting for weapons to shut off */
								return
							}
							
							/* If we've just decremented NumTurrets to 0... */
							if ${NumTurrets} == 0
							{
								if ${Range} > 0
								{
									Range:Set[0]
								}
								bDeactivatedWeapons:Set[FALSE]
								This.NextAmmoChange:Set[${Time.Timestamp}]
								This.NextAmmoChange.Second:Inc[20]
								This.NextAmmoChange:Update
								return
							}
						} 
					}
					else
					{
						This.NextAmmoChange:Set[${Time.Timestamp}]
						This.NextAmmoChange.Second:Inc[20]
						This.NextAmmoChange:Update
					}
				}
				elseif ${Me.ActiveTarget.Distance} <= (${Ship.MaximumTurretRange} * 1.2) && ${Me.ActiveTarget.Distance} >= (${Ship.MinimumTurretRange} * 0.33)
				{
				/* We can shoot a LITTLE past maximum because of falloff, and we can shoot a little under minimum, just won't do as much damage */
					UI:UpdateConsole["Offense: Activating weapons"]
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

					if ${Targets.HaveFullAggro} && ${Me.ActiveTarget.Distance} < (${Config.Combat.MaximumDroneRange} * .975)
					{
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