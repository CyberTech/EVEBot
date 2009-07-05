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
	variable time NextAmmoCheck
	variable int PulseIntervalInSeconds = 1.5
	variable int AmmoCheckIntervalInSeconds = 10
	variable bool Warned_LowAmmo = FALSE
	variable iterator itrWeapon
	variable collection:bool TurretNeedsAmmo

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

				if ${Config.Combat.ShouldUseMissiles}
				{
					if ${Me.ActiveTarget.Distance} < ${Ship.OptimalWeaponRange}
					{
						Ship:Activate_Weapons
					}
				}
				else
				{
					; iterate through every turret and determine if it needs an ammo change.
					Ship.ModuleList_Weapon:GetIterator[itrWeapon]
					if ${Time.Timestamp} >= ${This.NextAmmoCheck.Timestamp}
					{
						if ${itrWeapon:First(exists)}
						{
							do
							{
								if ${Ship.NeedAmmoChange[${Me.ActiveTarget.Distance},${itrWeapon.Key}]}
								{
									TurretNeedsAmmo:Set[${itrWeapon.Key},TRUE]
								}
								else
								{
									TurretNeedsAmmo:Erase[${itrWeapon.Key},FALSE]
								}
							}
							while ${itrWeapon:Next(exists)}
						}
						This.NextAmmoCheck:Set[${Time.Timestamp}]
						This.NextAmmoCheck.Second:Inc[${This.AmmoCheckIntervalInSeconds}]
						This.NextAmmoCheck:Update
					}

					
					if ${itrWeapon:First(exists)}
					{
						do
						{
							variable int MinRange = 0
							variable int MaxRange = 0
							variable bool ChargeExists = FALSE
							if ${itrWeapon.Value.Charge(exists)}
							{
								ChargeExists:Set[TRUE]
							}
							;If a module's reloading, or changing ammo, continue on.
							if ${itrWeapon.Value.IsChangingAmmo} || ${itrWeapon.Value.IsReloadingAmmo} || !${ChargeExists}
							{
								continue
							}
							
							MinRange:Set[${Ship.MinimumTurretRange[${itrWeapon.Key}]}]
							MaxRange:Set[${Ship.MaximumTurretRange[${itrWeapon.Key}]}]
							
							;Awesome, our guns are ready for ammo checks. Does our gun need an ammo change?
							if ${This.TurretNeedsAmmo.Element[${itrWeapon.Key}]}
							{
								UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: need ammo change.",LOG_DEBUG]
								;ok, if our Turret needs ammo change, make sure IT IS OFF.
								;We can't change ammo 'til it's inactive so just continue after deactivating.
								if ${itrWeapon.Value.IsActive}
								{
									UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: active during ammo change, deactivating and continuing.",LOG_DEBUG]
									itrWeapon.Value:Click
									continue
								}
								else
								{
									;If the weapon's off, go ahead and change ammo.
									UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: Loading optimal ammo and breaking.",LOG_DEBUG]
									Ship:LoadOptimalAmmo[${Me.ActiveTarget.Distance},${itrWeapon.Key}]
									This.TurretNeedsAmmo:Set[${itrWeapon.Key},FALSE]
									;Break after loading a turret's ammo, because chaging too much ammo too fast will REALLY fuck things up and make ammo disappear
									break
								}
							}
							else
							{
								UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: Didn't need ammo change.",LOG_DEBUG]
								;If we didn't need an ammo change, check if we need to activate or deactivate the weapon.
								;Account for some falloff in our ammo checks. EFT shows we can maintain about 75% of our dps
								;at about 1.5* our range, so assume skills suck and we're going for 1.3. The only real problem
								;with overshooting is tracking speed, and we need some sort of entity.rad/s member to check that.
								UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: IsActive? ${itrWeapon.Value.IsActive}, Distance? ${Me.ActiveTarget.Distance}, Min? ${Math.Calc[${MinRange} * 0.5]}, Max? ${Math.Calc[${MaxRange} * 1.3]}",LOG_DEBUG]
								if ${itrWeapon.Value.IsActive}
								{
									if ${Me.ActiveTarget.Distance} > ${Math.Calc[${MaxRange} * 1.3]} || \
										${Me.ActiveTarget.Distance} < ${Math.Calc[${MinRange} * 0.5]}
									{
										UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: Turret on but we're either below or above range, deactivating",LOG_DEBUG]
										itrWeapon.Value:Click
									}
								}
								else
								{
									if ${Me.ActiveTarget.Distance} <= ${Math.Calc[${MaxRange} * 1.3]} && \
										${Me.ActiveTarget.Distance} >= ${Math.Calc[${MinRange} * 0.5]}
									{
										UI:UpdateConsole["Offense: Turret ${itrWeapon.Key}: Turret off but we're within range, activating",LOG_DEBUG]
										itrWeapon.Value:Click
									}
								}
							}
						}
						while ${itrWeapon:Next(exists)}
					}
				}

				if ${Config.Combat.LaunchCombatDrones}
				{
					variable bool ShouldLaunchCombatDrones = ${Ship.Drones.ShouldLaunchCombatDrones}
					if ${Ship.Drones.CombatDroneShortage}
					{
						; TODO - This should pick up drones from station instead of just docking
						Defense:RunAway["Offense: Drone shortage detected"]
						return
					}
					if ${Me.ActiveTarget.Distance} < ${Math.Calc[${Me.DroneControlDistance} * 0.975]}
					{
						if ${ShouldLaunchCombatDrones}
						{
							if ${Ship.Drones.DeployedDroneCount} < 5 && ${Ship.Drones.DeployedDroneCount} < ${MyShip.GetDrones}
							{
								Ship.Drones:LaunchAll
							}
							else
							{
								Ship.Drones:SendDrones
								Ship.Drones:CheckDroneHP
							}
						}
						else
						{
							if ${Ship.Drones.DeployedDroneCount} > 0
							{
								UI:UpdateConsole["Offense: Shouldn't have combat drones out but we do, recalling!"]
								Ship.Drones:QuickReturnAllToDroneBay
							}
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
	
	/* bool HaveFullAggro:
	Using the correct entity cache for a given bot mode, determine if we have aggro from all aggroing entities.
	This will account for non-aggressing spawns such as hauler spawns. */
	member:bool HaveFullAggro()
	{
		variable bool HaveAggro = FALSE
		
		switch ${Config.Common.BotMode}
		{
			case Ratter
				HaveAggro:Set[${Targets.HaveFullAggro["Ratter.RatCache"]}]
				break
			case Missioneer
				HaveAggro:Set[${Targets.HaveFullAggro["Missions.missionCombat.MissionCommands.EntityCache"]}]
				break
		}
		return ${HaveAggro}
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