/*
	Miner Class

	Primary Miner behavior module for EVEBot

	-- CyberTech

*/

objectdef obj_Miner
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable index:entity LockedTargets
	variable iterator Target
	variable int TotalTrips = 0						/* Total Times we've had to transfer to hanger */
	variable time TripStartTime
	variable int PreviousTripSeconds = 0
	variable int TotalTripSeconds = 0
	variable int AverageTripSeconds = 0
	variable string CurrentState
	variable bool CombatAbort = FALSE
	variable int SanityCheckCounter = 0
	variable bool SanityCheckAbort = FALSE
	variable float64 LastUsedCargoCapacity = 0

	variable int TargetJammedCounter = 0

	; Are we running out of asteroids to target?
	variable bool ConcentrateFire = FALSE

	method Initialize()
	{
		BotModules:Insert["Miner"]
		Defense.Option_RunIfTargetJammed:Set[TRUE]

		This.TripStartTime:Set[${Time.Timestamp}]
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Miner: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if !${Config.Common.BotMode.Equal[Miner]}
		{
			return
		}

	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				This:SetState[]
            	SanityCheckCounter:Inc
            }

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

	function ProcessState()
	{
		if !${Config.Common.BotMode.Equal[Miner]}
		{
			; There's no reason at all for the miner to check state if it's not a miner
			return
		}

		switch ${This.CurrentState}
		{
			case IDLE
				break
			case ABORT
				Call Station.Dock
				break
			case INSTATION
				call Cargo.TransferOreToHangar
				;call Station.CheckList
			    SanityCheckCounter:Set[0]
			    SanityCheckAbort:Set[FALSE]
			    LastUsedCargoCapacity:Set[0]
				call Station.Undock
				break
			case CHANGEBELT
				if ${Config.Miner.UseFieldBookmarks}
				{
					/* There's currently no obj_BeltBookmarks method for warping so this will silently fail. --Stealthy */
					BeltBookmarks:WarpToNext
				}
				else
				{
					call Belts.WarpToNext
				}
				break
			case MINE
				call This.Mine
				break
			case WARP_WAIT
				wait 10
				break
			case HAUL
				UI:UpdateConsole["Hauling"]
				call Hauler.Haul
				break
			case TRANSFER_TO_JETCAN
				call Cargo.TransferOreToJetCan
				This:NotifyHaulers[]
				break
			case DROPOFF

				switch ${Config.Miner.DeliveryLocationType}
				{
					case Station
						UI:UpdateConsole["Delivering ore to station"]
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
						UI:UpdateConsole["Delivering ore to hangary array"]
						call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
						call Cargo.TransferOreToCorpHangarArray
						break
					case Jetcan
						UI:UpdateConsole["Delivering ore to jetcan"]
						call Cargo.TransferOreToJetCan
						This:NotifyHaulers[]
						break
					Default
						UI:UpdateConsole["ERROR: Delivery Location Type ${Config.Miner.DeliveryLocationType} unknown"]
						EVEBot.ReturnToStation:Set[TRUE]
						break
				}
			    SanityCheckCounter:Set[0]
			    SanityCheckAbort:Set[FALSE]
			    LastUsedCargoCapacity:Set[0]
				break
			case RUNNING
				UI:UpdateConsole["Running Away"]
				call Station.Dock
				EVEBot.ReturnToStation:Set[TRUE]
				break
		}
	}

	method SetState()
	{
		if ${Defense.Hiding}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		if ${Ship.InWarp}
		{
			This.CurrentState:Set["WARP_WAIT"]
			return
		}

		if ${EVEBot.ReturnToStation} && ${Me.InSpace}
		{
			This.CurrentState:Set["ABORT"]
			return
		}

		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		if ${Me.InStation}
		{
	  		This.CurrentState:Set["INSTATION"]
	  		return
		}

		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			UI:UpdateConsole["Avoiding player: Changing Belts"]
			This.CurrentState:Set["CHANGEBELT"]
			return
		}

		if ${MyShip.UsedCargoCapacity} <= ${Config.Miner.CargoThreshold} && \
		    ${SanityCheckAbort} == FALSE
		{
			if ${Config.Miner.UseFieldBookmarks}
			{
				if ${BeltBookmarks.Count} == ${BeltBookmarks.EmptyBelts.Used}
				{
					; TODO - CyberTech: Add option to switch to non-bookmark use in this case
					This.CurrentState:Set["ABORT"]
					return
				}
				if !${BeltBookmarks.AtBelt}
				{
				 	This.CurrentState:Set["CHANGEBELT"]
					return
				}
			}
			else
			{
				UI:UpdateConsole["Normal Belts: Count: ${Belts.Count}, EmptyBelts.Used: ${Belts.EmptyBelts.Used}"]
				if ${Belts.Count} == ${Belts.EmptyBelts.Used}
				{
					This.CurrentState:Set["ABORT"]
					return
				}
				if !${Belts.AtBelt}
				{
				 	This.CurrentState:Set["CHANGEBELT"]
					return
				}
			}
			; TODO - CyberTech: implement this
			;if ${Asteroids.Count} == 0
			;{
			; 	This.CurrentState:Set["CHANGEBELT"]
			;	return
			;}
		 	This.CurrentState:Set["MINE"]
			return
		}

		if ${Config.Miner.DeliveryLocationType.Equal[Jetcan]} && ${Ship.CargoHalfFull}
		{
			This.CurrentState:Set["TRANSFER_TO_JETCAN"]
			return
		}

	    if ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold} || \
    	    ${EVEBot.ReturnToStation}  || \
    	    ${SanityCheckAbort} == TRUE
		{
			This.CurrentState:Set["DROPOFF"]
			return
		}

		This.CurrentState:Set["Unknown"]
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

		UI:UpdateStatStatus["Run ${This.TotalTrips} Done - Took ${ISXEVE.SecsToString[${This.PreviousTripSeconds}]}"]
		UI:UpdateStatStatus["Total Run Time: ${Hours}:${Minutes}:${Seconds} - Average Run Time: ${ISXEVE.SecsToString[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]}"]
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

		if ${Config.Miner.StandingDetection} && \
			${Social.StandingDetection[${Config.Miner.LowestStanding}]}
		{
			Defense.RunAway["Low-standing player in system"]
		}

		if ${Config.Combat.LaunchCombatDrones} && \
			${Ship.Drones.CombatDroneShortage}
		{
			/* TODO - This should pick up drones from station instead of just docking */
			Defense.RunAway["Drone shortage detected"]
			return FALSE
		}

		if (!${Config.Miner.IceMining} && \
			${SanityCheckCounter} > MINER_SANITY_CHECK_INTERVAL)
		{
			Defense.RunAway["Cargo volume unchanged for too long; assuming desync"]
			return FALSE
		}

		if ${_MyShip.MaxLockedTargets} == 0 && \
			 ${Ship.Drones.DronesInSpace} == 0
		{
			This.TargetJammedCounter:Inc
			if ${This.TargetJammedCounter} > 200
			{
				This.TargetJammedCounter:Set[0]
				UI:UpdateConsole["Warning: Ship target jammed, no drones available. Changing Belts"]
				This.CurrentState:Set["CHANGEBELT"]
				return FALSE
			}
		}
		else
		{
			This.TargetJammedCounter:Set[0]
		}

		return TRUE
	}

	function Mine()
	{
		UI:UpdateConsole["Mining"]
		if !${Me.InSpace}
		{
			UI:UpdateConsole["DEBUG: obj_Miner.Mine called while not in space!"]
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

		if ${MyShip.UsedCargoCapacity} != ${LastUsedCargoCapacity}
		{
			;UI:UpdateConsole["DEBUG: ${MyShip.UsedCargoCapacity} != ${LastUsedCargoCapacity}"]
		    SanityCheckCounter:Set[0]
		    LastUsedCargoCapacity:Set[${MyShip.UsedCargoCapacity}]
		}

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
			Me:DoGetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]
			if ${Target:First(exists)}
			do
			{
				if ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
				{
					break
				}

				if ${Target.Value.CategoryID} != ${Asteroids.AsteroidCategoryID}
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
						wait 0.5
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
		UI:UpdateConsole["Cargo Hold has reached threshold, returning"]
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
		tempString:Set["${_Me.CharID},${_Me.SolarSystemID},${Entity[GroupID, GROUP_ASTEROIDBELT].ID}"]
		relay all -event EVEBot_Miner_Full ${tempString}

		/* TO MANUALLY CALL A HAULER ENTER THIS IN THE CONSOLE
		 * relay all -event EVEBot_Miner_Full "${Me.CharID},${Me.SolarSystemID},0"
		 */
	}

}
