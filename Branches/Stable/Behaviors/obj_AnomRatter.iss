/*

	The obj_AnomRatter object is a bot module designed to be used with
	EVEBOT. This is a heavily modified version of obj_Ratter

*/

objectdef obj_AnomRatter inherits obj_BaseClass
{
	variable string CurrentState
	variable obj_Combat Combat
	variable int OrbitDistance = 30000
	variable bool WeFled = FALSE
	variable string MyCurrentSite
	variable int64 Approaching = 0
	variable int TimeStartedApproaching = 0

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This.PulseTimer:SetIntervals[2.0,4.0]
		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

;		This.Rat_CacheID:Set[${EntityCache.AddFilter[${This.ObjectName}, CategoryID = CATEGORYID_ENTITY && IsNPC = 1 && IsMoribund = 0, 2.0]}]
;		EntityCache.EntityFilters.Get[${This.Rat_CacheID}].Entities:GetIterator[Rat_CacheIterator]

		This.CurrentState:Set["LOOT"]
		This.MyCurrentSite:Set["Clear"]
		Targets:ResetTargets
		;; call the combat object's init routine
		This.Combat:Initialize
		;; set the combat "mode"
		This.Combat:SetMode["AGGRESSIVE"]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}


	method Pulse()
	{
		if ${EVEBot.Disabled} || ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.CurrentBehavior.Equal[AnomRatter]}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			This:SetState

			This.PulseTimer:Update
		}

		;; call the combat frame action code
		This.Combat:Pulse
	}

	method StartApproaching(int64 ID, int64 Distance=0)
	{
		if ${This.Approaching} != 0
		{
			Logger:Log["Anomly Ratter: StartApproaching(${ID}) - Already approaching ${This.Approaching}."]
			return
		}

		if !${Entity[${ID}](exists)}
		{
			return
		}

		if ${Distance} == 0
		{
			if ${MyShip.MaxTargetRange} < ${Ship.OptimalMiningRange}
			{
					Distance:Set[${Math.Calc[${MyShip.MaxTargetRange} - 5000]}]
			}
			else
			{
					Distance:Set[${Ship.OptimalMiningRange}]
			}
		}

		Logger:Log["Anom Ratter: Approaching ${ID}:${Entity[${ID}].Name} @ ${EVEBot.MetersToKM_Str[${Distance}]}"]
		Entity[${ID}]:Approach[${Distance}]
		This.Approaching:Set[${ID}]
		This.TimeStartedApproaching:Set[${Time.Timestamp}]
	}

	method StopApproaching(string Msg)
	{
		Logger:Log[${Msg}]
		EVE:Execute[CmdStopShip]
		This.Approaching:Set[0]
		This.TimeStartedApproaching:Set[0]
	}

	member:int TimeSpentApproaching()
	{
		;	Return the time spent approaching the current target
		if ${This.Approaching} == 0
		{
			return 0
		}
		return ${Math.Calc[${Time.Timestamp} - ${This.TimeStartedApproaching}]}
	}

	method Shutdown()
	{
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom
	}

	/* NOTE: The order of these if statements is important!! */

	;; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> LOOT -> DROP -> *
	method SetState()
	{
		if ${Config.Common.CurrentBehavior.NotEqual[AnomRatter]}
		{
			return
		}
		/* Combat module handles all fleeing states now */
		switch ${This.CurrentState}
		{
			case IDLE
				This.CurrentState:Set["MOVE"]
				break
			default
				break
		}
	}

	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{
		if ${Config.Common.CurrentBehavior.NotEqual[AnomRatter]}
		{
			return
		}

		; call the combat object state processing
		call This.Combat.ProcessState

		;Logger:Log["Debug: AnomRatter: This.Combat.Fled = ${This.Combat.Fled} This.CurrentState = ${This.CurrentState} Social.IsSafe = ${Social.IsSafe}"]

		; see if combat object wants to
		; override bot module state.
		if ${This.Combat.Fled}
			return

		switch ${This.CurrentState}
		{
			case MOVE
				call This.Move
				break
			case FIGHT
				call This.Fight
				break
			case LOOT
				call This.Loot
				break
			case DROP
				call This.Drop
				break
		}
	}

	function Move()
	{
		if ${Social.IsSafe}
		{
			Ship:Deactivate_Weapons
			Ship:Deactivate_Tracking_Computer
			Ship:Deactivate_ECCM
			Ship:WarpPrepare

			Logger:Log["Debug: Time to find an anom and warp to it"]
			variable index:systemanomaly MyAnomalies
    		variable iterator MyAnomalies_Iterator

    		MyShip.Scanners.System:GetAnomalies[MyAnomalies]
    		MyAnomalies:GetIterator[MyAnomalies_Iterator]
			Logger:Log["Debug: Anoms found, looking for one we can warp to"]
				if (${MyAnomalies_Iterator:First(exists)})
					do
					{
						if (${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
							break
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Haven (Both)"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110980) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
							elseif ((${MyAnomalies_Iterator.Value.DungeonID} == 110972) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Haven (Gas)"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110972) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Haven (Rock)"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110980) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Forlorn Hub"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 111343) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Forsaken Hub"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 111348) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[0, FALSE]
								break
							}  
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Hidden Hub"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 113148) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}  
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Hub"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110917) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}  
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110937) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							} 
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Guristas Forsaken Rally Point"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 111334) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[0, FALSE]
								break
							}  
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Sansha Haven (Both)"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110983) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
							elseif ((${MyAnomalies_Iterator.Value.DungeonID} == 110974) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Sansha Haven (Gas)"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110974) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Sansha Haven (Rock)"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 110983) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
						elseif (${Config.Combat.CurrentAnomTypeName.Equal["Sansha Forsaken Hub"]} && !${MyAnomalies_Iterator.Value.Name.Equal[${MyCurrentSite}]})
						{
							Logger:Log["Debug: Checking each anom till we find one we want to run"]
							if ((${MyAnomalies_Iterator.Value.DungeonID} == 111349) && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]})
							{
								Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
								relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
								MyCurrentSite:Set[${MyAnomalies_Iterator.Value.Name}]
								wait 20
								MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
								break
							}    
						}
					}
					while ${MyAnomalies_Iterator:Next(exists)}
			}

		; Wait for the rats to warp into the Anom. Reports are between 10 and 20 seconds.
		variable int Count
		for (Count:Set[0] ; ${Count}<=17 ; Count:Inc)
		{
			if ((${Config.Combat.AnomalyAssistMode} && (${Targets.NPC} || !${Social.IsSafe})) || \
				(!${Config.Combat.AnomalyAssistMode} && (${Targets.PC} || ${Targets.NPC} || !${Social.IsSafe})))
			{
				break
			}
			wait 10
			if !${Social.IsSafe}
			{
				return
			}
		}

		if (${Count} > 1)
		{
			; If we had to wait for rats, Wait another second to try to let them get into range/out of warp
			wait 10
		}
		call This.PlayerCheck

		Count:Set[0]
		if ${Config.Combat.AnomalyAssistMode}
		{
			while (${Count:Inc} < 10) && ${Social.IsSafe} && ${Targets.NPC}
			{
				wait 10
				if !${Social.IsSafe}
				{
					return
				}
			}
		}
		else
		{
			while (${Count:Inc} < 10) && ${Social.IsSafe} && !${Targets.PC} && ${Targets.NPC}
			{
				wait 10
				if !${Social.IsSafe}
				{
					return
				}
			}
		}
	}

	function PlayerCheck()
	{
		if ((${Config.Combat.AnomalyAssistMode} && ${Targets.NPC}) || \
			(!${Config.Combat.AnomalyAssistMode} && (!${Targets.PC} && ${Targets.NPC})))
		{
			Logger:Log["PlayerCheck - Fight"]
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			Logger:Log["PlayerCheck - Move"]
			This.CurrentState:Set["MOVE"]
		}
	}

	function Fight()
	{	/* combat logic */
		;; just handle targetting, obj_Combat does the rest
		Ship:Activate_Armor_Reps
		Ship:Activate_SensorBoost
		Ship:Activate_Tracking_Computer
		Ship:Activate_ECCM
		if ((${Me.ToEntity.Mode} != 3) && ${Targets.TargetNPCs} && ${Me.ToEntity.Mode} != 4)
		{
			Logger:Log["Debug: Close ship computer pop up"]
			EVEWindow[ByCaption, Information].Button[ok_dialog_button]:Press
			wait 10
			if (${Entity[Name == "Pirate Gate"]} && ${Me.ToEntity.Mode} != 4)
			{
				Entity[Name == "Pirate Gate"]:Orbit[${OrbitDistance}]
			}
			elseif (${Entity[Name == "Small Rock"]} && ${Me.ToEntity.Mode} != 4)
			{
				Entity[Name == "Small Rock"]:Orbit[${OrbitDistance}]
			}
			elseif (${Entity[Name == "Broken Orange Crystal Asteroid"]} && ${Me.ToEntity.Mode} != 4)
			{
				Entity[Name == "Broken Orange Crystal Asteroid"]:Orbit[${OrbitDistance}]
			}
			elseif (${Entity[Name == "Sharded Rock"]} && ${Me.ToEntity.Mode} != 4)
			{
				Entity[Name == "Sharded Rock"]:Orbit[${OrbitDistance}]
			}
            Ship:Activate_AfterBurner
		}


		if ${Targets.TargetNPCs} && ${Social.IsSafe}
		{
			if ${Targets.SpecialTargetPresent}
			{
				Logger:Log["Special spawn Detected - ${Targets.m_SpecialTargetName}!", LOG_CRITICAL]
				call Sound.PlayDetectSound
				; Wait 5 seconds
				wait 50
			}
		}
		else
		{
			if ${Config.Combat.LootMyKills}
			{
				if (${Entity[Name == "Mobile Tractor Unit"](exists)} && ${Social.IsSafe})
				{
					Ship.Drones:ReturnAllToDroneBay["Combat", "Moving"]
					if (${Entity[Name == "Mobile Tractor Unit"].Distance} > 2001 && ${This.Approaching} == 0)
					{
					Logger:Log["Approach MTU to scoop it"]
					This:StartApproaching[${Entity[Name == "Mobile Tractor Unit"].ID}, 2000]
					}
					if (${This.Approaching} != 0)
					{
						if !${Entity[${This.Approaching}](exists)}
						{
							This:StopApproaching["MTU disappeared while I was approaching. Going to check if its on grid or we looted it."]
						}

						;	If we're approaching a target, find out if we need to stop doing so
						if ${Entity[${This.Approaching}].Distance} <= 2000
						{
							This:StopApproaching["Within loot range of ${Entity[${This.Approaching}].Name}(${Entity[${This.Approaching}].ID})"]
							; Don't break here
						}
					}
					if (${Entity[Name == "Mobile Tractor Unit"](exists)} && ${Entity[Name == "Mobile Tractor Unit"].Distance} <= 2000)
					{
						Entity[Name == "Mobile Tractor Unit"]:ScoopToCargoHold
						if (!${Entity[Name == "Mobile Tractor Unit"](exists)})
						{
						;EVE:CreateBookmark["Done Site ${Math.Rand[5000]:Inc[1000]}","","mining"]
						return
						}
					}
				}
				else
				{
					Ship.Drones:ReturnAllToDroneBay["Combat", "Moving"]
					Ship:WarpPrepare
					wait 50
					This.CurrentState:Set["LOOT"]
				}
                return
			}
			else
			{
				if (${Entity[Name == "Mobile Tractor Unit"](exists)} && ${Social.IsSafe})
				{
					Ship.Drones:ReturnAllToDroneBay["Combat", "Moving"]
					if (${Entity[Name == "Mobile Tractor Unit"].Distance} > 2001 && ${This.Approaching} == 0)
					{
					Logger:Log["Approach MTU to scoop it"]
					This:StartApproaching[${Entity[Name == "Mobile Tractor Unit"].ID}, 2000]
					}
					if ${This.Approaching} != 0
					{
						if !${Entity[${This.Approaching}](exists)}
						{
							This:StopApproaching["MTU disappeared while I was approaching. Going to check if its on grid or we looted it."]
						}

						;	If we're approaching a target, find out if we need to stop doing so
						if ${Entity[${This.Approaching}].Distance} <= 2000
						{
							This:StopApproaching["Within loot range of ${Entity[${This.Approaching}].Name}(${Entity[${This.Approaching}].ID})"]
							; Don't break here
						}
					}
					if (${Entity[Name == "Mobile Tractor Unit"](exists)} && ${Entity[Name == "Mobile Tractor Unit"].Distance} <= 2000)
					{
						Entity[Name == "Mobile Tractor Unit"]:ScoopToCargoHold
						if (!${Entity[Name == "Mobile Tractor Unit"](exists)})
						{
						;EVE:CreateBookmark["Done Site ${Math.Rand[5000]:Inc[1000]}","","mining"]
						}
					}
				}
				else
                {
				Ship.Drones:ReturnAllToDroneBay["Combat", "Moving"]
				Ship:WarpPrepare
				wait 50
				This.CurrentState:Set["IDLE"]
                }
                return
			}
		}
	}

	function Loot()
	{
		variable index:entity Wrecks
		variable iterator     Wreck
		variable index:item   Items
		variable iterator     Item
		variable index:int64  ItemsToMove
		variable float        TotalVolume = 0
		variable float        ItemVolume = 0
		variable int QuantityToMove

		EVE:QueryEntities[Wrecks, "GroupID = GROUP_WRECK && Distance <= WARP_RANGE"]
		Wrecks:GetIterator[Wreck]
		if ${Wreck:First(exists)}
		{
			do
			{
				if ${Wreck.Value(exists)} && \
					!${Wreck.Value.IsWreckEmpty} && \
					${Wreck.Value.HaveLootRights} && \
					${Targets.IsSpecialTargetToLoot[${Wreck.Value.Name}]}
				{
					call Ship.Approach ${Wreck.Value.ID} LOOT_RANGE
					if ((${Config.Combat.AnomalyAssistMode} && ${Targets.NPC}) || \
						(!${Config.Combat.AnomalyAssistMode} && (!${Targets.PC} && ${Targets.NPC})))
					{
						This.CurrentState:Set["FIGHT"]
						break
					}
					call Inventory.ShipCargo.Activate
					Wreck.Value:Open
					wait 10
					Wreck.Value:GetCargo[Items]
					Logger:Log["obj_AnomRatter: DEBUG:  Wreck contains ${Items.Used} items.", LOG_DEBUG]

					Items:GetIterator[Item]
					if ${Item:First(exists)}
					{
						do
						{
							Logger:Log["obj_AnomRatter: Found ${Item.Value.Quantity} x ${Item.Value.Name} - ${Math.Calc[${Item.Value.Quantity} * ${Item.Value.Volume}].Precision[2]}m3"]
							if (${Item.Value.Quantity} * ${Item.Value.Volume}) > ${Ship.CargoFreeSpace}
							{
								/* Move only what will fit, minus 1 to account for CCP rounding errors. */
									QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${Item.Value.Volume} - 1]}]
								if ${QuantityToMove} <= 0
								{
								Logger:Log["ERROR: obj_AnomRatter: QuantityToMove = ${QuantityToMove}!"]
								This.CurrentState:Set["DROP"]
								break
								}
							}
							else
							{
								QuantityToMove:Set[${Item.Value.Quantity}]
							}

							Logger:Log["obj_AnomRatter: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Item.Value.Volume}].Precision[2]}m3"]
							if ${QuantityToMove} > 0
							{
								Item.Value:MoveTo[${MyShip.ID},CargoHold,${QuantityToMove}]
								wait 30
							}

							if ${Ship.CargoFull}
							{
								Logger:Log["DEBUG: obj_AnomRatter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
								This.CurrentState:Set["DROP"]
								break
							}
						}
						while ${Item:Next(exists)}
					}
				}
				if ${Ship.CargoFull}
				{
					Logger:Log["DEBUG: obj_AnomRatter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
					This.CurrentState:Set["DROP"]
					break
				}
			}
			while ${Wreck:Next(exists)}
		}

		if ${This.CurrentState.Equal["LOOT"]}
		{
		  This.CurrentState:Set["IDLE"]
		}
	}

	function Drop()
	{
		call Station.Dock
		wait 100
		call Cargo.TransferCargoToStationHangar
		wait 100
		; need to restock ammo here
		This.CurrentState:Set["IDLE"]
	}
}