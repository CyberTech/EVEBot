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
	variable collection:bool cbTurrets
	variable iterator itrWeapon
	variable int iCurrentTurret = 0

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
				elseif ${Time.Timestamp} >= ${This.NextAmmoChange.Timestamp}
				{
					; iterate through every turret and determine if it needs an ammo change.
					; If so, deactivate it. Use a collection:bool cbTurrets to determine which need ammo change (TRUE) and cannot be activated,
					; and those that don't (FALSE) and may be activated
					
					Ship.ModuleList_Weapon:GetIterator[itrWeapon]
					
					; Only build the collection if it hasn't previously been built
					if ${cbTurrets.Used} == 0
					{
						UI:UpdateConsole["Offense: Building cbTurrets.",LOG_DEBUG]
						if ${itrWeapon:First(exists)}
						{
							do
							{
								iCurrentTurret:Inc
								;Only check if a gun needs ammo change if it isn't reloading or changing ammo already
								if ${itrWeapon.Value.IsChangingAmmo} || ${itrWeapon.Value.IsReloadingAmmo}
								{
									UI:UpdateConsole["Offense: Turret ${iCurrentTurret} is already changing ammo or reloading; skipping.",LOG_DEBUG]
									continue
								}
								
								UI:UpdateConsole["Offense: NeedAmmoChange[${Me.ActiveTarget.Distance},${iCurrentTurret}]: ${Ship.NeedAmmoChange[${Me.ActiveTarget.Distance},${iCurrentTurret}]}",LOG_DEBUG]
								if ${Ship.NeedAmmoChange[${Me.ActiveTarget.Distance},${iCurrentTurret}]}
								{
									; Add the turret to the collection
									cbTurrets:Set[${iCurrentTurret},TRUE]
									; Turn it off
									if ${itrWeapon.Value.IsActive}
									{
										itrWeapon.Value:Click
									}
								}
								else
								{
									;it doesn't need ammo change, set it false
									cbTurrets:Set[${iCurrentTurret},FALSE]
								}
							}
							while ${itrWeapon:Next(exists)}
							; We're done using iCurrentTurret for now, reset it
							iCurrentTurret:Set[0]
						}
					}
					
					; Now, I have a collection of turrets I can't turn on because they need an ammo change. Iterate through them and
					; see if they're inactive and not changing ammo and not reloading. If these are all true, do the ChangeAmmo and 
					; remove it from the collection then return so that we change the next ammo next pulse and don't de-sync.
					if ${cbTurrets.Used} > 0
					{
						if ${itrWeapon:First(exists)}
						{
							do
							{
								iCurrentTurret:Inc
								;Check that this is a turret we're changing ammo on
								;We can just 'if' this without a compare since it would return a true or false
								UI:UpdateConsole["Offense: cbTurrets.Element[${iCurrentTurret}]: ${cbTurrets.Element[${iCurrentTurret}]}",LOG_DEBUG]
								if ${cbTurrets.Element[${iCurrentTurret}]}
								{
									; IF this turret is active, changing ammo, or reloading, skip.
									if ${itrWeapon.Value.IsActive} || ${itrWeapon.Value.IsReloadingAmmo} || ${itrWeapon.Value.IsChangingAmmo}
									{
										if ${itrWeapon.Value.IsActive}
										{
											UI:UpdateConsole["Offense: Turret ${iCurrentTurret} is active, clicking it off.",LOG_DEBUG]
											itrWeapon.Value:Click
										}
										UI:UpdateConsole["Offense: Turret ${iCurrentTurret} is active, reloading, or changing ammo; skipping",LOG_DEBUG]
										continue
									}
									; If it's off and not doing something, change its ammo and remove it.
									elseif !${itrWeapon.Value.IsActive} && !${itrWeapon.Value.IsReloadingAmmo} && !${itrWeapon.Value.IsChangingAmmo}
									{
										UI:UpdateConsole["Offense: Changing turret ${iCurrentTurret}'s ammo and removing it from the collection, then returning.",LOG_DEBUG]
										Ship:LoadOptimalAmmo[${Me.ActiveTarget.Distance},${iCurrentTurret}]
										cbTurrets:Erase[${iCurrentTurret}]
										;Return, the ammo check will continue changing one more every pulse until all needed ammo swaps have been done. This will
										;help prevent the nasty de-sync.
										iCurrentTurret:Set[0]
										return
									}
								}
								else
								{
									;if it didn't need a weapon reload, erase it.
									UI:UpdateConsole["Offense: Turret ${iCurrentTurret} doesn't need an ammo change, erasing it.",LOG_DEBUG]
									cbTurrets:Erase[${iCurrentTurret}]
								}
							}
							while ${itrWeapon:Next(exists)}
						}
						; Since the above logic will naturally skip a few now and then, reset it to 0 if we've iterated through everything (and possibly skipped a few in state changes)
						; and still have entries in cbTurrets.
						if ${cbTurrets.Used} > 0
						{
							UI:UpdateConsole["Offense: Done iterating through but still have guns needing ammo; some were likely skipped for active/reload/changing. Resetting iCurrentTurret and returning.",LOG_DEBUG]
							iCurrentTurret:Set[0]
							return
						}
					}
					
					;If we have no more in cbTurrets, meaning it's cleared of both those that did and did not need ammo changes, we're done.
					if ${cbTurrets.Used} == 0
					{
						;If we had no turrets needing ammo changes, go ahead and reset the pulse timer. We're done for now.
						UI:UpdateConsole["Offense: Done swapping out ammo, resetting timer.",LOG_DEBUG]
						This.NextAmmoChange:Set[${Time.Timestamp}]
						This.NextAmmoChange.Second:Inc[5]
						This.NextAmmoChange:Update
					}
				}
				;Iterate through each weapon and activate it if we're within its ranges, accounting for *some* falloff.
				;Time to make use of iCurrentTurret again
				iCurrentTurret:Set[0]
				if ${itrWeapon:First(exists)}
				{
					do
					{
						iCurrentTurret:Inc
						; if the weapon is already active, don't effin' click it unless they're out of ze range
						if ${itrWeapon.Value.IsActive}
						{
							if ${Me.ActiveTarget.Distance} > ${Math.Calc[${Ship.GetMaximumTurretRange[${iCurrentTurret}]} * 1.2]} || \
								${Me.ActiveTarget.Distance} < ${Math.Calc[${Ship.GetMinimumTurretRange[${iCurrentTurret}]} * 0.5]}
							{
								itrWeapon.Value:Click
							}
						}
						else
						{
							; if the weapon isn't active and it's not reloading/changing ammo, click it on
							if ${Me.ActiveTarget.Distance} <= ${Math.Calc[${Ship.GetMaximumTurretRange[${iCurrentTurret}]} * 1.2]} && \
								${Me.ActiveTarget.Distance} >= ${Math.Calc[${Ship.GetMinimumTurretRange[${iCurrentTurret}]} * 0.5]} && \
								!${itrWeapon.Value.IsReloadingAmmo} && !${itrWeapon.Value.IsChangingAmmo}
							{
								itrWeapon.Value:Click
							}
						}
					}
					while ${itrWeapon:Next(exists)}
					;Remember to reset iCurrentTurret after we're done with it!
					iCurrentTurret:Set[0]
				}

				if ${Config.Combat.LaunchCombatDrones}
				{
					if ${Ship.Drones.CombatDroneShortage}
					{
						; TODO - This should pick up drones from station instead of just docking
						Defense:RunAway["Offense: Drone shortage detected"]
						return
					}
					if ${Me.ActiveTarget.Distance} < ${Math.Calc[${Me.DroneControlDistance} * 0.975]}
					{
						if ${Ship.Drones.ShouldLaunchCombatDrones} && \
							 ${Ship.Drones.DeployedDroneCount} == 0
						{
							Ship.Drones:LaunchAll[]
						}
						else
						{
							Ship.Drones:SendDrones
						}
					}
					elseif ${Ship.Drones.DeployedDroneCount} > 0
					{
						;If we have drones out and our active target isn't in range, recall them to prevent them from going
						;fucking berserk on everything and breaking the fucking chain. -- stealthy
						;Use the executecommand because the ship function isn't atomic
						EVE:Execute[CmdDronesReturnToBay]
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
				HaveAggro:Set[${Targets.HaveFullAggro["Ratter.RatCache.Entities"]}]
				break
			case Missioneer
				;todo: Pass Targets.HaveFullAggro[] the FQN of MissionCombat's entity cache. - Stealthy
				HaveAggro:Set[TRUE]
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