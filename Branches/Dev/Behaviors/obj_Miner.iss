/*
	Miner Class

	Primary Miner behavior module for EVEBot

	-- CyberTech

*/

objectdef obj_Miner
{
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable index:entity LockedTargets
	variable iterator Target
	variable int TotalTrips = 0						/* Total Times we've had to transfer to hanger */
	variable time TripStartTime
	variable int PreviousTripSeconds = 0
	variable int TotalTripSeconds = 0
	variable int AverageTripSeconds = 0
	variable int CurrentState

	variable bool AsteroidCacheInvalid = TRUE

	; Are we running out of asteroids to target?
	variable bool ConcentrateFire = FALSE

	variable int STATE_IDLE = 0
	variable int STATE_WAIT_WARP = 1
	variable int STATE_DOCKED = 2
	variable int STATE_MINE = 3
	variable int STATE_CHANGE_BELT = 4
	variable int STATE_BELTSFULL = 5
	variable int STATE_TRANSFER_TO_JETCAN = 6
	variable int STATE_DELIVER_ORE = 7
	variable int STATE_RETURN_TO_STATION = 8
	variable int STATE_ERROR = 99

	method Initialize()
	{
		EVEBot.BehaviorList:Insert["Miner"]
		Defense.Option_RunIfTargetJammed:Set[TRUE]

		This.TripStartTime:Set[${Time.Timestamp}]
		Logger:Log["${This.ObjectName}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			AsteroidCache.Enabled:Set[TRUE]
			This:SetState[]

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	function ProcessState()
	{
		if ${Config.Common.Behavior.NotEqual[Miner]}
		{
			return
		}

		echo ${This.CurrentState}

		switch ${This.CurrentState}
		{
			variablecase ${STATE_WAIT_WARP}
				break
			variablecase ${STATE_IDLE}
				break
			variablecase ${STATE_ABORT}
				Call Station.Dock
				break
			variablecase ${STATE_DOCKED}
			echo "docked state"
				call Cargo.TransferOreToHangar
				;call Station.CheckList
				call Station.Undock
				break
			variablecase ${STATE_CHANGE_BELT}
				if ${Config.Miner.UseFieldBookmarks}
				{
					call BeltBookmarks.WarpToNext
				}
				else
				{
					call Belts.WarpToNext
				}
				break
			variablecase ${STATE_MINE}
				call This.Mine
				break
			variablecase ${STATE_TRANSFER_TO_JETCAN}
				call Cargo.TransferOreToJetCan
				; TODO - This shouldn't notify until the jetcan is x% full - CyberTech
				This:NotifyHaulers[]
				break
			variablecase ${STATE_DELIVER_ORE}

				switch ${Config.Miner.DeliveryLocationType}
				{
					case Station
						Logger:Log["Delivering ore to station"]
						; Gets info about the crystals currently loaded
						call Ship.SetActiveCrystals

						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)}
						{
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
						}
						else
						{
							call Station.Dock
						}
						break
					case Hangar Array
						Logger:Log["Delivering ore to hangar array"]
						call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
						call Cargo.TransferOreToCorpHangarArray
						break
					case Large Ship Assembly Array
						Logger:Log["Delivering ore to Large Ship Assembly Array"]
						call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
						call Cargo.TransferOreToLargeShipAssemblyArray
						break
					case XLarge Ship Assembly Array
						Logger:Log["Delivering ore to XLarge Ship Assembly Array"]
						call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
						call Cargo.TransferOreToXLargeShipAssemblyArray
						break
					case Jetcan
						Logger:Log["Delivering ore to jetcan"]
						call Cargo.TransferOreToJetCan
						This:NotifyHaulers[]
						break
					default
						Logger:Log["ERROR: Delivery Location Type ${Config.Miner.DeliveryLocationType} unknown"]
						EVEBot.ReturnToStation:Set[TRUE]
						break
				}
				break
			variablecase ${STATE_ERROR}
				Logger:Log["CurrentState is ERROR"]
				break
			default
				Logger:Log["Error: CurrentState is unknown value ${This.CurrentState}"]
				break
		}
	}

	method SetState()
	{
		if ${Defense.Hiding}
		{
			This.CurrentState:Set[${STATE_IDLE}]
			return
		}

		if ${Ship.InWarp}
		{
			This.CurrentState:Set[${STATE_WAIT_WARP}]
			This.AsteroidCacheInvalid:Set[TRUE]
			return
		}

		if ${EVEBot.ReturnToStation} && ${Me.InSpace}
		{
			This.CurrentState:Set[${STATE_RETURN_TO_STATION}]
			return
		}

		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set[${STATE_IDLE}]
			return
		}

		if ${Me.InStation}
		{
	  		This.CurrentState:Set[${STATE_DOCKED}]
	  		return
		}

		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			Logger:Log["Avoiding player: Changing Belts"]
			This.CurrentState:Set[${STATE_CHANGE_BELT}]
			return
		}

		if ${Config.Miner.DeliveryLocationType.Equal[Jetcan]} && ${Ship.CargoHalfFull}
		{
			This.CurrentState:Set[${STATE_TRANSFER_TO_JETCAN}]
			return
		}

		if ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
		{
			; ignore this condition if the cargo window is not open
			if ${Ship.IsCargoOpen}
			{
				This.CurrentState:Set[${STATE_DELIVER_ORE}]
			}
			return
		}

		if ${Config.Miner.UseFieldBookmarks}
		{
			if !${BeltBookmarks.AtBelt}
			{
				Logger:Log["Bookmarked Belts: Count: ${BeltBookmarks.Count} Empty: ${BeltBookmarks.EmptyBelts.Used}"]
				if ${BeltBookmarks.Count} == ${BeltBookmarks.EmptyBelts.Used}
				{
					; TODO - CyberTech: Add option to switch to non-bookmark use in this case
					Logger:Log["All Belt Bookmarks marked empty, aborting"]
					This.CurrentState:Set[${STATE_RETURN_TO_STATION}]
					return
				}

		 		This.CurrentState:Set[${STATE_CHANGE_BELT}]
				return
			}
		}
		else
		{
			if !${Belts.AtBelt}
			{
				Logger:Log["Normal Belts: Count: ${Belts.Count} Empty: ${Belts.EmptyBelts.Used}"]
				if ${Belts.Count} == ${Belts.EmptyBelts.Used}
				{
					Logger:Log["All Belts marked empty, aborting"]
					This.CurrentState:Set[${STATE_RETURN_TO_STATION}]
					return
				}

			 	This.CurrentState:Set[${STATE_CHANGE_BELT}]
				return
			}
		}

		if ${This.AsteroidCacheInvalid} && (${BeltBookmarks.AtBelt} || ${Belts.AtBelt})
		{
			Logger:Log["${This.ObjectName}: Forcing asteroid cache update."]

			; EntityCache update will happen on the next pulse.
			AsteroidCache:ForceUpdate[]
			This.AsteroidCacheInvalid:Set[FALSE]
		 	This.CurrentState:Set[${STATE_IDLE}]

			return
		}

		if ${Asteroids.Count} == 0
		{
			Logger:Log["Belt is empty (or nothing we want), moving"]
		 	This.CurrentState:Set[${STATE_CHANGE_BELT}]
			return
		}

	 	This.CurrentState:Set[${STATE_MINE}]

	 	; delay the next state transition for a little bit
		This.NextPulse:Set[${Time.Timestamp}]
		This.NextPulse.Second:Inc[${Math.Calc[${This.PulseIntervalInSeconds}*5]}]
		This.NextPulse:Update
	}

	; Enable defenses, launch drones
	function Prepare_Environment()
	{
		call Ship.OpenCargo
	}

	function Statslog()
	{
		variable string Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int.LeadingZeroes[2]}
		variable string Minutes = ${Math.Calc[(${Script.RunningTime}/1000/60)%60].Int.LeadingZeroes[2]}
		variable string Seconds = ${Math.Calc[(${Script.RunningTime}/1000)%60].Int.LeadingZeroes[2]}

		Logger:UpdateStatStatus["Run ${This.TotalTrips} Done - Took ${ISXEVE.SecsToString[${This.PreviousTripSeconds}]}"]
		Logger:UpdateStatStatus["Total Run Time: ${Hours}:${Minutes}:${Seconds} - Average Run Time: ${ISXEVE.SecsToString[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]}"]
	}

	member:bool ReadyToMine()
	{
		if ${Defense.Hide}
		{
			return FALSE
		}

		if ${Ship.TotalMiningLasers} == 0
		{
			Defense.RunAway["No mining lasers detected"]
			return FALSE
		}

		if ${Config.Combat.LaunchCombatDrones} && \
			${Ship.Drones.CombatDroneShortage}
		{
			/* TODO - This should pick up drones from station instead of just docking */
			Defense.RunAway["Miner: Drone shortage detected"]
			return FALSE
		}

		/* - Removing this -- it shouldn't be needed when we cycle lasers.
		if (!${Config.Miner.IceMining} && \
			${SanityCheckCounter} > MINER_SANITY_CHECK_INTERVAL)
		{
			Defense.RunAway["Cargo volume unchanged for too long; assuming desync"]
			return FALSE
		}
		*/

		; TODO - CyberTech - this logic conflicts with defense.runiftargetjammed, add logic to defense to check if drones are deployed and engaged.
		if ${Targeting.IsTargetingJammed} &&  \
			${Ship.Drones.DronesInSpace} == 0
		{
			Logger:Log["Warning: Ship target jammed, no drones available. Changing Belts"]
			This.CurrentState:Set[${STATE_CHANGE_BELT}]
			return FALSE
		}

		return TRUE
	}

	; Mine() function
	;
	;	1) If asteroids are locked, in range, and lasers are idle, activate lasers
	; 2) If asteroids are locked and out of range, approach asteroids
	; 3) If no asteroids are locked add some to the targeting queue
	; 4) If cargohold is not opened open it
	;
	function Mine()
	{
		if !${Me.InSpace}
		{
			Logger:Log["DEBUG: obj_Miner.Mine called while not in space!"]
			return
		}

		; Make sure the cargo window is open.
		; This call does nothing if it is already open.
		call Ship.OpenCargo
		Ship:Deactivate_Cloak
		Me:GetTargets[LockedTargets]
		LockedTargets:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				; check if this target is an asteroid, if not continue to next target
				if ${Target.Value.CategoryID} != CATEGORYID_ORE
				{
					continue
				}

				if ${Target.Value.Distance} > ${Ship.OptimalMiningRange}
				{
					; if we are not approach something already, approach this target
					if !${Me.ToEntity.Approaching}
					{
						Logger:LogDebug["${This.ObjectName}: Approaching ${Target.Value.ID} from ${Target.Value.Distance} meters."]
						call Ship.Approach ${Target.Value.ID} ${Ship.OptimalMiningRange}
					}
				}
				elseif ${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers}
				{
					/* TODO: CyberTech - this concentrates fire fine if there's only 1 target, but if there's multiple targets
						it still prefers to distribute. Ice mining shouldn't distribute
					*/
					if (${This.ConcentrateFire} || \
						${Config.Miner.MinerType.Equal["Ice"]} || \
						!${Ship.IsMiningAsteroidID[${Target.Value.ID}]})
					{
						; TODO - CyberTech: None of this should be here. it should be in a TARGETING state
						Target.Value:MakeActiveTarget
						while ${Target.Value.ID} != ${Me.ActiveTarget.ID}
						{
							waitframe
						}

						if ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
						{
							break
						}

						call Ship.ActivateFreeMiningLaser

						if ${Config.Miner.UseMiningDrones} && \
							${Ship.Drones.DronesInSpace} > 0
						{
							Ship.Drones:ActivateMiningDrones
						}
					}
				}
			}
			while ${Target:Next(exists)}
		}
		else
		{
			call Asteroids.ChooseTargets
		}
	}

	function Old_Mine()
	{
		Logger:Log["Mining"]
		if !${Me.InSpace}
		{
			Logger:Log["DEBUG: obj_Miner.Mine called while not in space!"]
			return
		}

		This.TripStartTime:Set[${Time.Timestamp}]
		; Find an asteroid field, or stay at current one if we're near one.
		if !${Belts.AtBelt}
			call Belts.WarpToNext
		call This.Prepare_Environment
		call Asteroids.UpdateList

		variable int DroneCargoMin = ${Math.Calc[(${Ship.CargoMinimumFreeSpace}*1.4)]}
		variable int Counter = 0

		/* TODO: CyberTech: Move this to obj_Defense */
		if ${Config.Combat.LaunchCombatDrones} && \
			${Ship.Drones.DronesInSpace} == 0 && \
			!${Ship.InWarp}
		{
			Ship.Drones:LaunchAll[]
		}

		if ${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers}
		{
			; We've got idle lasers, and available targets. Do something with them.
			Me:GetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]
			if ${Target:First(exists)}
			do
			{
				if ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
				{
					break
				}

				if ${Target.Value.CategoryID} != CATEGORYID_ORE
				{
					continue
				}

				/* TODO: CyberTech - this concentrates fire fine if there's only 1 target, but if there's multiple targets
					it still prefers to distribute. Ice mining shouldn't distribute
				*/
				if (${This.ConcentrateFire} || \
					${Config.Miner.MinerType.Equal["Ice"]} || \
					!${Ship.IsMiningAsteroidID[${Target.Value.ID}]})
				{
					; TODO - CyberTech: None of this should be here. it should be in a TARGETING state
					Target.Value:MakeActiveTarget
					while ${Target.Value.ID} != ${Me.ActiveTarget.ID}
					{
						waitframe
					}

					if ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
					{
						break
					}
					call Ship.Approach ${Target.Value.ID} ${Ship.OptimalMiningRange}
					call Ship.ActivateFreeMiningLaser

					if (${Ship.Drones.DronesInSpace} > 0 && \
						${Config.Miner.UseMiningDrones})
					{
						Ship.Drones:ActivateMiningDrones
					}
				}
			}
			while ${Target:Next(exists)}
		}

		call Asteroids.ChooseTargets

		if (${Config.Miner.MinerType.NotEqual["Ore"]} || \
			(${Ship.TotalActivatedMiningLasers} == 0))
		{
			if ${Ship.TotalMiningLasers} > ${Ship.MaxLockedTargets}
			{
				This.ConcentrateFire:Set[TRUE]
			}
			else
			{
				This.ConcentrateFire:Set[FALSE]
			}
		}
		wait 10

		/*
		TODO - CyberTech - redo with static bookmark name so we're not creating bookmarks.  Possible detection risk.
		if ${Config.Miner.BookMarkLastPosition}
		{
			Bookmarks:StoreLocation
		}
		*/
/*
		This.TotalTrips:Inc
		This.PreviousTripSeconds:Set[${This.TripDuration}]
		This.TotalTripSeconds:Inc[${This.PreviousTripSeconds}]
		This.AverageTripSeconds:Set[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]
		Logger:Log["Cargo Hold has reached threshold, returning"]
		call ChatIRC.Say "Cargo Hold has reached threshold"
		call This.Statslog
*/
	}

	member:int TripDuration()
	{
		return ${Math.Calc64[${Time.Timestamp} - ${This.TripStartTime.Timestamp}]}
	}


	member:float VolumePerCycle(string AsteroidType)
	{

	}

	method NotifyHaulers()
	{
		/* notify hauler there is ore in space */
		variable string tempString
		tempString:Set["${Me.CharID},${Me.SolarSystemID},${Entity[GroupID = GROUP_ASTEROIDBELT].ID}"]
		relay all -event EVEBot_Miner_Full ${tempString}

		/* TO MANUALLY CALL A HAULER ENTER THIS IN THE CONSOLE
		 * relay all -event EVEBot_Miner_Full "${Me.CharID},${Me.SolarSystemID},${Entity[GroupID = 9].ID}"
		 */
	}

}
