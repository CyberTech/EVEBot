/*

	Miner Class

	Primary Miner behavior module for EVEBot

	-- Tehtsuo

	(large amounts of code recycled from CyberTech's module)

*/

objectdef obj_Miner
{
	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable time NextHaulerNotify

	;	State information (What we're doing)
	variable string CurrentState = "IDLE"

	;	Used to force a dropoff when the cargo hold isn't full
	variable bool ForceDropoff = FALSE

	;	Are we running out of asteroids to target?
	variable bool ConcentrateFire = FALSE

	;	This is used to keep track of what we are approaching and when we started
	variable int64 Approaching = 0
	variable int TimeStartedApproaching = 0
	variable bool ApproachingOrca=FALSE

	;	This is used to keep track of if our orca is in a belt.
	variable bool WarpToOrca=FALSE

	;	This is used to keep track of if our master is in a belt.
	variable bool WarpToMaster=FALSE


	;	This is used to keep track of how much space our hauler has available
	variable int64 HaulerAvailableCapacity=-0

	;	This keeps track of the wreck we are tractoring
	variable int64 Tractoring=-1

	;	Search string for our Orca
	variable string Orca

	;	Search string for our Master
	variable string Master

/*
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will SetState.
*/

	method Initialize()
	{
		This.TripStartTime:Set[${Time.Timestamp}]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		LavishScript:RegisterEvent[EVEBOT_Orca_InBelt]
		Event[EVEBot_Orca_InBelt]:AttachAtom[This:Event_OrcaIsInBelt]

		LavishScript:RegisterEvent[EVEBot_Master_InBelt]
		Event[EVEBot_Master_InBelt]:AttachAtom[This:Event_MasterIsInBelt]

		LavishScript:RegisterEvent[EVEBot_HaulerMSG]
		Event[EVEBot_HaulerMSG]:AttachAtom[This:HaulerMSG]

		Logger:Log["obj_Miner: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_Orca_InBelt]:DetachAtom[This:Event_OrcaIsInBelt]
		Event[EVEBot_Master_InBelt]:DetachAtom[This:Event_MasterIsInBelt]
		Event[EVEBot_HaulerMSG]:DetachAtom[This:HaulerMSG]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.CurrentBehavior.Equal[Miner]}
		{
			; There's no reason at all for the miner to check state if it's not a miner
			return
		}

	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:SetState[]
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

/*
;	Step 2:  	SetState:  This is the brain of the module.  Every time it is called - See Step 1 - this method will determine
;				what the module should be doing based on what's going on around you.  This will be used when EVEBot calls your module to ProcessState.
*/

	method StartApproaching(int64 ID, int64 Distance=0)
	{
		if ${This.Approaching} != 0
		{
			Logger:Log["Miner: StartApproaching(${ID}) - Already approaching ${This.Approaching}. Lucy, the kids are fighting!"]
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

		Logger:Log["Miner: Approaching ${ID}:${Entity[${ID}].Name} @ ${EVEBot.MetersToKM_Str[${Distance}]}"]
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

	method SetState()
	{
		if !${EVEBot.ReturnToStation}
		{
			;	First, we need to check to find out if I should "HARD STOP" - dock and wait for user intervention.  Reasons to do this:
			;	*	If someone targets us
			;	*	They're lower than acceptable Min Security Status on the Miner tab
			;	*	I'm in a pod.  Oh no!
			if ${Social.PossibleHostiles}
			{
				This.CurrentState:Set["HARDSTOP"]
				Logger:Log["HARD STOP: Possible hostiles, notifying fleet"]
				relay all -event EVEBot_HARDSTOP "${Me.Name} - ${Config.Common.CurrentBehavior} (Hostiles)"
				EVEBot.ReturnToStation:Set[TRUE]
				return
			}

			if ${Ship.IsPod}
			{
				This.CurrentState:Set["HARDSTOP"]
				Logger:Log["HARD STOP: Ship in a pod, notifying fleet that I failed them"]
				relay all -event EVEBot_HARDSTOP "${Me.Name} - ${Config.Common.CurrentBehavior} (InPod)"
				EVEBot.ReturnToStation:Set[TRUE]
				return
			}
		}

		if ${EVEBot.ReturnToStation}
		{
			;	If we're in a station HARD STOP has been called for, just idle until user intervention
			if ${Me.InStation}
			{
				This.CurrentState:Set["IDLE"]
				return
			}
			else
			{
				;	If we're at our panic location bookmark and HARD STOP has been called for, just idle until user intervention
				if ${This.AtPanicBookmark}
				{
					This.CurrentState:Set["IDLE"]
					return
				}

				This.CurrentState:Set["HARDSTOP"]
				return
			}
		}

		if !${EVEBot.ReturnToStation}
		{
			;	Find out if we should "SOFT STOP" and flee.  Reasons to do this:
			;	*	Pilot lower than Min Acceptable Standing on the Fleeing tab
			;	*	Pilot is on Blacklist ("Run on Blacklisted Pilot" enabled on Fleeing tab)
			;	*	Pilot is not on Whitelist ("Run on Non-Whitelisted Pilot" enabled on Fleeing tab)
			;	This checks for both In Station and out, preventing spam if you're in a station.
			if !${Social.IsSafe}
			{
				if ${Me.InStation}
				{
					This.CurrentState:Set["IDLE"]
					return
				}

				if ${This.AtPanicBookmark}
				{
					This.CurrentState:Set["IDLE"]
					return
				}

				This.CurrentState:Set["FLEE"]
				Logger:Log["FLEE: Low Standing player or system unsafe, fleeing"]
				return
			}

			if !${Me.InStation}
			{
				if ${Entity["GroupID = GROUP_DREADNOUGHT && CategoryID = CATEGORYID_ENTITY"](exists)}
				{
					This.CurrentState:Set["FLEE"]
					Logger:Log["FLEE: NPC Dreadnaught detected: ${Entity[GroupID = GROUP_DREADNOUGHT && CategoryID = CATEGORYID_ENTITY].Name}"]
					return
				}

				if ${Entity["GroupID = GROUP_TITAN && CategoryID = CATEGORYID_ENTITY"](exists)}
				{
					This.CurrentState:Set["FLEE"]
					Logger:Log["FLEE: NPC Titan detected: ${Entity[\"GroupID = GROUP_TITAN\" && CategoryID = CATEGORYID_ENTITY].Name}"]
					return
				}

				if ${Entity["GroupID = GROUP_INVASIONNPS && CategoryID = CATEGORYID_ENTITY"](exists)}
				{
					This.CurrentState:Set["FLEE"]
					Logger:Log["FLEE: NPC Invasion Precursor (Damavik?) detected: ${Entity[\"GroupID = GROUP_INVASIONNPS\" && CategoryID = CATEGORYID_ENTITY].Name}"]
					return
				}
			}
		}

		; TODO - make waiting for master to be a state; what if the master drops offline or takes longer to log in? we can't just loop here.
		if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${EVEBot.MasterName.Length} > 0 && !${WarpToOrca}
		{
			if ${This.AtPanicBookmark}
			{
				; If in orca delivery mode and orca not in belt and at panic spot, wait
				This.CurrentState:Set["IDLE"]
				return
			}
			; If in orca delivery and orca not in belt, flee
			This.CurrentState:Set["FLEE"]
			Logger:Log["FLEE: Orca not in belt (temporary)"]
			return
		}

		; If in group mode, not the master, dont warp to master, and at safe spot... wait.  This also covers when no master is set.
		if ${Config.Miner.GroupMode} && !${EVEBot.IsMaster} && ${EVEBot.MasterName.Length} > 0 && !${WarpToMaster}
		{
			if ${This.AtPanicBookmark}
			{
				This.CurrentState:Set["IDLE"]
				return
			}
			; If in group mode, not the master, and dont warp to the master... flee. This also covers when no master is set.
			This.CurrentState:Set["FLEE"]
			Logger:Log["FLEE: Master not in belt (temporary)"]
			return
		}

		;	If I'm in a station, I need to perform what I came there to do
		if ${Me.InStation}
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}

		if !${Me.InSpace}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		;	If I'm not in a station and I'm full, I should head to a station to unload unless "No Delivery" is our Delivery Location Type
		if ${This.MinerFull} && !${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]}
		{
			This.CurrentState:Set["DROPOFF"]
			return
		}

		; If I'm not in a station and I have room to mine more ore, that's what I should do!
		This.CurrentState:Set["MINE"]
	}


/*
;	Step 3:		ProcessState:  This is the nervous system of the module.  EVEBot calls this; it uses the state information from SetState
;				to figure out what it needs to do.  Then, it performs the actions, sometimes using functions - think of the functions as
;				arms and legs.  Don't ask me why I feel an analogy is needed.
*/

	function ProcessState()
	{
		;	If Miner isn't the selected bot mode, this function shouldn't have been called.  However, if it was we wouldn't want it to do anything.
		if !${Config.Common.CurrentBehavior.Equal[Miner]}
		{
			return
		}

		if ${EVEBot.IsMaster} && ${This.CurrentState.NotEqual[MINE]}
		{
			; Tell the miners we might not be in a belt and shouldn't be warped to.
			relay all -event EVEBot_Master_InBelt FALSE
		}

		switch ${This.CurrentState}
		{

			;	This means we're somewhere safe, and SetState wants us to stay there without spamming the UI
			case IDLE
				break

			;	This means something serious happened, like someone targetted us, we're in a pod, or mining is failing due to something
			;	weird going on.  In this situation our goal is to get to a station and stay there.
			;	*	Notify other team members that you're running, and they should too!
			;	*	Stay in a station if we're there
			;	*	If we have a panic location and it's in the same system, dock there
			;	*	If we have a panic location and it's in another system, set autopilot and go there
			;	*	If we don't have a panic location and our delivery location is in the same system, dock there
			;	*	If everything above failed and there's a station in the same system, dock there
			;	*	If everything above failed, check if we're warping and warp to a safe spot
			case HARDSTOP
				if ${Me.InStation}
				{
					break
				}
				Ship.Drones:ReturnAllToDroneBay["Miner", "HardStop"]
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
						call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
					}
					else
					{
						Logger:Log["Debug: WarpToBookMarkName ${Config.Miner.PanicLocation} from Line _LINE_ ", LOG_DEBUG]
						call Ship.WarpToBookMarkName "${Config.Miner.PanicLocation}"
					}
					break
				}
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} != ${Me.SolarSystemID}
				{
					Logger:Log["Debug: FastWarp to ${Config.Miner.PanicLocation} from Line _LINE_ ", LOG_DEBUG]
					call This.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}
					break
				}
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					;call This.FastWarp ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					break
				}
				if ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"](exists)}
				{
					Logger:Log["Docking at ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].Name}"]
					;call This.FastWarp ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].ID}
					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].ID}
					break
				}
				if ${Me.ToEntity.Mode} != 3
				{
					Logger:Log["Debug: Safespots.WarpTo called from Line _LINE_ ", LOG_DEBUG]
					call Safespots.WarpTo
					Logger:Log["Debug: FastWarp called from Line _LINE_ ", LOG_DEBUG]
					call This.FastWarp
					wait 30
				}

				Logger:Log["WARNING:  EVERYTHING has gone wrong. Miner is in HARDSTOP mode and there are no panic locations, delivery locations, stations, or safe spots to use. You're probably going to get blown up..."]
				break

			;	This means there's something dangerous in the system, but once it leaves we're going to go back to mining.
			;	*	Stay in a station if we're there
			;	*	If our delivery location is in the same system, dock there
			;	*	If we have a panic location and it's in the same system, dock there
			;	*	If there are any stations in this system, dock there
			;	*	Otherwise, check if we're warping and warp to a safe spot
			;	*	If none of these work, something is terribly wrong, and we need to panic!
			case FLEE
				;	Before we go anywhere, make a bookmark so we can get back here
				if ${Me.InStation}
				{
					break
				}
				Ship.Drones:ReturnAllToDroneBay["Miner", "Flee"]
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					;call This.FastWarp ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					break
				}
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						;call This.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
						Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
						call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
					}
					else
					{
						Logger:Log["Debug: FastWarp to ${Config.Miner.PanicLocation} from Line _LINE_ ", LOG_DEBUG]
						call This.FastWarp -1 "${Config.Miner.PanicLocation}"
					}
					break
				}

				if ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"](exists)}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					Logger:Log["Docking at ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].Name}"]
					;call This.FastWarp ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].ID}
					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].ID}
					break
				}

				if ${Me.ToEntity.Mode} != 3
				{
					Logger:Log["Debug: Safespots.WarpTo called from Line _LINE_ ", LOG_DEBUG]
					call Safespots.WarpTo
					Logger:Log["Debug: FastWarp called from Line _LINE_ ", LOG_DEBUG]
					call This.FastWarp
					wait 30
					break
				}

				Logger:Log["HARD STOP: Unable to flee, no stations available and no Safe spots available"]
				EVEBot.ReturnToStation:Set[TRUE]
				break

			;	This means we're in a station and need to do what we need to do and leave.
			;	*	If this isn't where we're supposed to deliver ore, we need to leave the station so we can go to the right one.
			;	*	Move ore out of cargo hold if it's there
			;	*	Undock from station
			case BASE
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID} != ${Me.StationID}
				{
					call Station.Undock
					break
				}

				call Cargo.TransferOreToStationHangar
				call Cargo.TransferCargoFromShipGeneralMiningHoldToStation

				LastUsedCargoCapacity:Set[0]
				call Station.Undock
				wait 600 ${Me.InSpace}
				break

			;	This means we're in space and should mine some more ore!  Only one choice here - MINE!
			;	It is prudent to make sure we're not warping, since you can't mine much in warp...
			case MINE
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					Logger:Log["Traveling to mining system - ${Universe[${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}].Name}"]
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}
				}
				if ${Me.ToEntity.Mode} != 3
				{
					call This.Mine
				}
				break

			;	This means we need to go to our delivery location to unload.
			case DROPOFF
				;	Before we go anywhere, make a bookmark so we can get back here
				if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
				{
					Bookmarks:StoreLocation
				}

				switch ${Config.Miner.DeliveryLocationTypeName}
				{

					;	This means we're delivering to a station.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, dock there
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Station

						;	Get info about the crystals currently loaded
						call Ship.SetActiveCrystals

						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
							call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
							break
						}
						Logger:Log["ALERT: Station dock failed for delivery location \"${Config.Miner.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a Hangar Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Hangar Array
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${Config.Miner.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferOreToCorpHangarArray
							break
						}
						Logger:Log["ALERT: Hangar Array unload failed for delivery location \"${Config.Miner.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a Large Ship Assembly Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Large Ship Assembly Array
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${Config.Miner.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferOreToLargeShipAssemblyArray
							break
						}
						Logger:Log["ALERT: Large Ship Assembly Array unload failed for delivery location \"${Config.Miner.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a Large Ship Assembly Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Compression Array
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${Config.Miner.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferOreToCompressionArray
							break
						}
						Logger:Log["ALERT: Compression Array unload failed for delivery location \"${Config.Miner.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a XLarge Ship Assembly Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case XLarge Ship Assembly Array
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${Config.Miner.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferOreToXLargeShipAssemblyArray
							break
						}
						Logger:Log["ALERT: XLarge Ship Assembly Array unload failed for delivery location \"${Config.Miner.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a jetcan.  This shouldn't get much action because they should be jettisoned continously during mining.
					case Jetcan
						Logger:Log["Warning: Cargo filled during jetcan mining, delays may occur"]

						;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
						if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
						{
							if ${Config.Miner.SafeJetcan}
							{
								if ${This.MinerFull}
								{
									if ${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)} && \
										${Entity[Name = "${Config.Miner.DeliveryLocation}"].Distance} < 20000 && \
										${Entity[Name = "${Config.Miner.DeliveryLocation}"].Mode} != 3
									{
										call Cargo.TransferOreToJetCan
										;	Need a wait here because it would try to move the same item more than once
										wait 20
										return
									}
									else
									{
										This:NotifyHaulers[]
									}
								}
							}
							else
							{
								if ${This.MinerFull}
								{
									call Cargo.TransferOreToJetCan
									;	Need a wait here because it would try to move the same item more than once
									wait 20
									This:NotifyHaulers[]
								}
							}
						}
						break

					;	This means we're delivering to an Orca.  Choices are:
					;	*	Break if the orca isn't in local - it may be incorrectly configured or out of system doing a dropoff.
					;	*	Break if we're warping - most likely to the orca.
					;	*	If the orca is at a safe location being used as a station.  Warp there first.
					;	*	If the orca is out of loot range, approach.
					;	*	Unload to the orca.
					case Orca
						Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
						if !${Local[${Config.Miner.DeliveryLocation}](exists)}
						{
							Logger:Log["ALERT:  The specified orca isn't in local - it may be incorrectly configured or out of system doing a dropoff."]
							break
						}

						if ${Me.ToEntity.Mode} == 3
						{
							break
						}

						if !${Entity[${Orca.Escape}](exists)} && ${Local[${Config.Miner.DeliveryLocation}].ToFleetMember}
						{
							Logger:Log["ALERT:  The orca is not in this belt.  Warping there first to unload."]
							Logger:Log["Debug: Fleet Warping to ${Config.Miner.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							Fleet:WarpTo[${Config.Miner.DeliveryLocation}]
							break
						}

						;	Find out if we need to approach this target
						if ${Entity[${Orca.Escape}].Distance} > LOOT_RANGE && ${This.Approaching} == 0
						{
							Logger:Log["Miner.ProcessState: Approaching Orca to within loot range (currently ${Entity[${Orca.Escape}].Distance})"]
							This:StartApproaching[${Entity[${Orca.Escape}].ID}, LOOT_RANGE]
							break
						}

						if ${This.Approaching} != 0
						{
							if !${Entity[${This.Approaching}](exists)}
							{
								This:StopApproaching["Miner.ProcessState - Orca disappeared while I was approaching. Freaking bermuda triangle around here..."]
								break
							}

							if ${This.TimeSpentApproaching} >= 45
							{
								This:StopApproaching["Miner.ProcessState - Approaching for > 45 seconds? Cancelling"]
								break
							}

							;	If we're approaching a target, find out if we need to stop doing so
							if ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE
							{
								This:StopApproaching["Miner.ProcessState - Within loot range of ${Entity[${This.Approaching}].Name}(${Entity[${This.Approaching}].ID})"]
								; Don't break here
							}
						}

						if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE
						{
							call Cargo.TransferOreToShipCorpHangar ${Entity[${Orca.Escape}]}
						}

						break

					;	This means the DeliveryLocation type is invalid.  This should only happen if someone monkeys with the UI.
					Default
						Logger:Log["ALERT: Delivery Location Type ${Config.Miner.DeliveryLocationTypeName} unknown.  Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break
				}
			    LastUsedCargoCapacity:Set[0]
				break
		}
	}

/*
;	Step 4:		Mine:  This is it's own function so the ProcessState function doesn't get too giant.  There's a lot going on while mining.
;				However, it's important to remember that anything you do here keeps you in the mining state.  Until EVEBot makes it through
;				this function, it can't get back to ProcessState to start running away from hostiles and whatnot.  Therefore, keep any use of the
;				wait function to a minimum, and make sure you can get out of loops in a timely manner!
*/

	function Mine()
	{
		;	Variables used to target and track asteroids
		variable index:entity LockedTargets
		variable iterator Target
		variable int AsteroidsLocked=0

		; lets compress
		if (${Config.Miner.CompressOreMode} && ${Ship.OreHoldThreeQuartersFull})
		{
			Logger:Log["Debug: We are not deliverying so we need to compress, lets check if we can"]
			call Compress.CheckForCompression
		}


		;	If we're in a station there's not going to be any mining going on.  This should clear itself up if it ever happens.
		if ${Me.InStation} != FALSE
		{
			Logger:Log["DEBUG: obj_Miner.Mine called while zoning or while in station!"]
			return
		}

		if !${Me.InSpace}
		{
			return
		}

		;	This checks our armor and shields to determine if we need to run like hell.  If we're being aggro'd by something
		;	dangerous enough to get us this damaged, it's best to switch to HARD STOP mode.
		if (${MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
			${MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct})
		{
			Logger:Log["Armor is at ${MyShip.ArmorPct}: ${MyShip.Armor}/${MyShip.MaxArmor}", LOG_CRITICAL]
			Logger:Log["Shield is at ${MyShip.ShieldPct}: ${MyShip.Shield}/${MyShip.MaxShield}", LOG_CRITICAL]
			Logger:Log["Miner aborting due to defensive status", LOG_CRITICAL]

			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		; Remove this check for now. There's a timing issue with undocking and getting module inventory.
		;	If our ship has no mining lasers, panic so the user knows to correct their configuration and try again
		;if ${Ship.TotalMiningLasers} == 0
		;{
		;	Logger:Log["ALERT: No mining lasers detected.  Returning to station."]
		;	EVEBot.ReturnToStation:Set[TRUE]
		;	return
		;}

		Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
		Master:Set[Name = "${EVEBot.MasterName}"]

		; If delivery is set to Orca
		if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]}
		{
			; Check if orca is on grid and if not warp to them
			if ${WarpToOrca} && !${Entity[${Orca.Escape}](exists)}
			{
				Logger:Log["Debug: WarpToFleetMember to ${Config.Miner.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
				call Ship.WarpToFleetMember ${Local["${Config.Miner.DeliveryLocation}"]}
				if ${Config.Miner.BookMarkLastPosition} && ${Bookmarks.CheckForStoredLocation}
				{
					Bookmarks:RemoveStoredLocation
				}
				call Asteroids.UpdateList ${Entity[${Orca.Escape}].ID}
			}
		}
		else
		{
			; Check if master is on grid and if not warp to them
			if ${Config.Miner.GroupMode} && ${WarpToMaster} && !${Entity[${Master.Escape}](exists)} && !${EVEBot.IsMaster}
			{
				Logger:Log["Debug: WarpToFleetMember to ${EVEBot.MasterName} from Line _LINE_ ", LOG_DEBUG]
				call Ship.WarpToFleetMember ${Local["${EVEBot.MasterName}"]}
				if ${Config.Miner.BookMarkLastPosition} && ${Bookmarks.CheckForStoredLocation}
				{
					Bookmarks:RemoveStoredLocation
				}
				call Asteroids.UpdateList
			}
		}

		if (!${Config.Miner.GroupMode} || ${EVEBot.IsMaster})
		{
			; We're not in group mode, or we're the master. So we're free to make our own decisions about movement.
			; Out of rocks, not delivering to Orca
			if ${Asteroids.FieldEmpty} && \
				!${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]}
			{
				Logger:Log["Miner.Mine: No asteroids detected, changing belts"]
				call Asteroids.MoveToField TRUE TRUE
				call Asteroids.UpdateList
			}

			; If player in range and in group mode/ is master... move
			if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
			{
				Logger:Log["Miner.Mine: Avoiding player: Forcing belt change"]
				call Asteroids.MoveToField TRUE
				call Asteroids.UpdateList
			}
		}

		; Past this point, we're in a belt. Presumably.
		if ${EVEBot.IsMaster}
		{
			;	Tell our miners we're in a belt and they are safe to warp to me
			relay all -event EVEBot_Master_InBelt TRUE
		}

		;	We need to make sure we're near our orca if we're using it as a delivery location
		if ${Config.Miner.DeliveryLocationTypeName.Equal[Orca]}
		{
			if ${This.Approaching} != 0
			{
				if !${Entity[${This.Approaching}](exists)}
				{
					This:StopApproaching["Miner.Mine - Orca disappeared while I was approaching. Freaking bermuda triangle around here..."]
					This.ApproachingOrca:Set[FALSE]
					return
				}
				if ${This.TimeSpentApproaching} >= 45
				{
					This:StopApproaching["Miner.Mine - Approaching orca for > 45 seconds? Cancelling"]
					This.ApproachingOrca:Set[FALSE]
					return
				}

				;	If we're approaching a target, find out if we need to stop doing so.
				;	After moving, we need to find out if any of our targets are out of mining range and unlock them so we can get new ones.
				if ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE
				{
					This:StopApproaching["Miner.Mine: Within loot range of ${Entity[${This.Approaching}].Name}(${Entity[${This.Approaching}].ID})"]
					This.ApproachingOrca:Set[FALSE]

					LockedTargets:Clear
					Me:GetTargets[LockedTargets]
					LockedTargets:GetIterator[Target]

					if ${Target:First(exists)}
					do
					{
						if ${Entity[${Target.Value.ID}].Distance} > ${Ship.OptimalMiningRange}
						{
							Logger:Log["Miner.Mine: Unlocking ${Target.Value.Name} as it is out of range after we moved."]
							Target.Value:UnlockTarget
						}
					}
					while ${Target:Next(exists)}
				}
			}
			elseif ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} > LOOT_RANGE
			{
				;	Find out if we need to approach the Orca
				if ${Entity[${Orca.Escape}].Distance} > WARP_RANGE
				{
					Logger:Log["ALERT:  ${Entity[${Orca.Escape}].Name} is a long way away.  Warping to it."]
					Logger:Log["Debug: Entity:WarpTo to Orca from Line _LINE_ ", LOG_DEBUG]
					Entity[${Orca.Escape}]:WarpTo[1000]
					return
				}
				Logger:Log["Miner.Mine: Approaching Orca to within loot range (currently ${Entity[${Orca.Escape}].Distance})"]
				This:StartApproaching[${Entity[${Orca.Escape}].ID}, LOOT_RANGE]
				This.ApproachingOrca:Set[TRUE]
				return
			}

			; This performs Orca deliveries if we've got at least a tenth of our cargo hold full
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)}
			{
				call Inventory.ShipGeneralMiningHold.Activate
			}
			else
			{
				call Inventory.ShipCargo.Activate
			}

			if (${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)} && ${Ship.OreHoldHalfFull}) || ${Ship.CargoTenthFull}
			{
					Logger:Log["Emptying ore to ${Entity[${Orca.Escape}].Name}'s Corporate Hangars"]
					call Cargo.TransferOreToShipCorpHangar ${Entity[${Orca.Escape}].ID}
					call Cargo.ReplenishCrystals ${Entity[${Orca.Escape}].ID}
			}

		}
		else
		{
			if ${Config.Miner.GroupMode}
			{
				Logger:Log["Debug: Checking Group mode ", LOG_DEBUG]
				; if for some reason we are too far away from our master go find him
				if ${EVEBot.MasterName.NotEqual[NULL]}
				{
					; We want to stay within loot range of the Master, see if we need to move
					if (${Config.Miner.GroupModeAtRange} || !${Config.Miner.GroupModeAtBoostRange})
					{
						;	Find out if we need to approach this target.
						if ${Entity[${Master.Escape}](exists)} && ${Entity[${Master.Escape}].Distance} > LOOT_RANGE/5 && ${This.Approaching} == 0
						{
							if ${Entity[${Master.Escape}].Distance} > WARP_RANGE
							{
								Logger:Log["ALERT:  ${Entity[${Master.Escape}].Name} is a long way away.  Warping to it."]
								Logger:Log["Debug: Entity:WarpTo to Master from Line _LINE_ ", LOG_DEBUG]
								Entity[${Master.Escape}]:WarpTo[1000]
								return
							}
							Logger:Log["Miner.Mine: Approaching Master to within loot range (currently ${Entity[${Master.Escape}].Distance})"]
							This:StartApproaching[${Entity[${Orca.Escape}].ID}, ${Math.Calc[LOOT_RANGE/5]}]
							This.ApproachingOrca:Set[TRUE]
							return
						}

						if ${This.Approaching} != 0
						{
							if !${Entity[${This.Approaching}](exists)}
							{
								This:StopApproaching["Miner.Mine - Group master disappeared while I was approaching. Freaking bermuda triangle around here..."]
								This.ApproachingOrca:Set[FALSE]
								return
							}

							if ${This.TimeSpentApproaching} >= 45
							{
								This:StopApproaching["Miner.Mine - Approaching group master for > 45 seconds? Cancelling"]
								This.ApproachingOrca:Set[FALSE]
								return
							}

							;	If we're approaching a target, find out if we need to stop doing so.
							;	After moving, we need to find out if any of our targets are out of mining range and unlock them so we can get new ones.
							if ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE/5
							{
								This:StopApproaching["Miner.Mine: Within loot range of ${Entity[${This.Approaching}].Name}(${Entity[${This.Approaching}].ID})"]
								This.ApproachingOrca:Set[FALSE]

								LockedTargets:Clear
								Me:GetTargets[LockedTargets]
								LockedTargets:GetIterator[Target]

								if ${Target:First(exists)}
								do
								{
									if ${Entity[${Target.Value.ID}].Distance} > ${Ship.OptimalMiningRange}
									{
										Logger:Log["Miner.Mine: Unlocking ${Target.Value.Name} as it is out of range after we moved."]
										Target.Value:UnlockTarget
									}
								}
								while ${Target:Next(exists)}
								return
							}
						}
					}
					; We want to stay within range of the Master for boosts, see if we need to move
					elseif (${Config.Miner.GroupModeAtBoostRange} || !${Config.Miner.GroupModeAtRange})
					{
						;	Find out if we need to approach this target.
						if ${Entity[${Master.Escape}](exists)} && ${Entity[${Master.Escape}].Distance} > 30000 && ${This.Approaching} == 0
						{
							if ${Entity[${Master.Escape}].Distance} > WARP_RANGE
							{
								Logger:Log["ALERT:  ${Entity[${Master.Escape}].Name} is a long way away.  Warping to it."]
								Logger:Log["Debug: Entity:WarpTo to Master from Line _LINE_ ", LOG_DEBUG]
								Entity[${Master.Escape}]:WarpTo[1000]
								return
							}
							Logger:Log["Miner.Mine: Approaching Master to within boost range (currently ${Entity[${Master.Escape}].Distance})"]
							This:StartApproaching[${Entity[${Master.Escape}].ID}, ${Math.Calc[1*30000]}]
							This.ApproachingOrca:Set[TRUE]
							return
						}

						if ${This.Approaching} != 0
						{
							if !${Entity[${This.Approaching}](exists)}
							{
								This:StopApproaching["Miner.Mine - Group master disappeared while I was approaching. Freaking bermuda triangle around here..."]
								This.ApproachingOrca:Set[FALSE]
								return
							}

							if ${This.TimeSpentApproaching} >= 45
							{
								This:StopApproaching["Miner.Mine - Approaching group master for > 45 seconds? Cancelling"]
								This.ApproachingOrca:Set[FALSE]
								return
							}

							;	If we're approaching a target, find out if we need to stop doing so.
							;	After moving, we need to find out if any of our targets are out of mining range and unlock them so we can get new ones.
							if ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE*12
							{
								This:StopApproaching["Miner.Mine: Within boost range of ${Entity[${This.Approaching}].Name}(${Entity[${This.Approaching}].ID})"]
								This.ApproachingOrca:Set[FALSE]

								LockedTargets:Clear
								Me:GetTargets[LockedTargets]
								LockedTargets:GetIterator[Target]

								if ${Target:First(exists)}
								do
								{
									if ${Entity[${Target.Value.ID}].Distance} > ${Ship.OptimalMiningRange}
									{
										Logger:Log["Miner.Mine: Unlocking ${Target.Value.Name} as it is out of range after we moved."]
										Target.Value:UnlockTarget
									}
								}
								while ${Target:Next(exists)}
								return
						}
							}
					}
					else
					{
						if ${Entity[${Master.Escape}].Distance} > WARP_RANGE
						{
							Logger:Log["ALERT:  ${Entity[${Master.Escape}].Name} is off grid. Warping."]
							Logger:Log["Debug: Entity:WarpTo to Master from Line _LINE_ ", LOG_DEBUG]
							Entity[${Master.Escape}]:WarpTo[10000]
							return
						}
					}
				}
			}
		}

		if ${This.Approaching} != 0 && !${This.ApproachingOrca}
		{
			if !${Entity[${This.Approaching}](exists)}
			{
				This:StopApproaching["Miner.Mine - Target ${This.Approaching} disappeared while I was approaching."]
			}
			if ${This.TimeSpentApproaching} >= 45
			{
				This:StopApproaching["Miner.Mine - Approaching ${This.Approaching} for > 45 seconds? Cancelling"]
			}

			;	If we're officially approaching a target, stop if we're close enough
			; If we're approaching a target that doesn't exist, stop
			if ${Entity[${This.Approaching}].Distance} <= ${Ship.OptimalMiningRange[1]}
			{
				This:StopApproaching["Miner.Mine - Approaching ${This.Approaching} completed in ${This.TimeSpentApproaching}s", LOG_DEBUG]
			}
		}

		;	Here is where we lock new asteroids.  We always want to do this if we have no asteroids locked.  If we have at least one asteroid locked, however,
		;	we should only lock more asteroids if we're not ice mining
		if ((!${Config.Miner.DistributeLasers} || ${Config.Miner.IceMining}) && ${Asteroids.LockedAndLocking} == 0) || \
			((${Config.Miner.DistributeLasers} && !${Config.Miner.IceMining}) && ${Asteroids.LockedAndLocking} < ${Ship.SafeMaxLockedTargets})
		{
			;	Calculate how many asteroids we need
			variable int AsteroidsNeeded=${Ship.TotalMiningLasers}

			;	If we're supposed to use Mining Drones, we need one more asteroid
			if ${Config.Miner.UseMiningDrones}
			{
				AsteroidsNeeded:Inc
			}
			if ${Config.Miner.IceMining}
			{
				AsteroidsNeeded:Set[1]
			}
			;	So we need to lock another asteroid.  First make sure that our ship can lock another, and make sure
			;	we don't already have enough asteroids locked. The Asteroids.TargetNext function will let us know if
			;	we need to concentrate fire because we're out of new asteroids to target. If we're using an orca and
			;	it's in the belt, use Asteroids.TargetNextInRange to only target roids nearby
			if (${Ship.TotalTargeting} < ${Ship.SafeMaxLockedTargets}) && ${Asteroids.LockedAndLocking} < ${AsteroidsNeeded}
			{
				if ${Config.Miner.DeliveryLocationTypeName.Equal[Orca]} && ${Entity[${Orca.Escape}](exists)}
				{
					call Asteroids.TargetNextInRange ${Entity[${Orca.Escape}].ID}
				}
				elseif ${Config.Miner.GroupMode} && ${Config.Miner.GroupModeAtRange}
				{
					call Asteroids.TargetNextInRange ${Entity[${Master.Escape}].ID}
				}
				else
				{
					call Asteroids.TargetNext
				}
				This.ConcentrateFire:Set[!${Return}]
				if ${Return}
				{
					return
				}
			}

			;	We don't need to lock another asteroid.  Let's find out if we need to signal a concentrate fire based on limitations of our ship.
			;	Either our target count more than we can safely lock, or we have more mining lasers than we can safely lock.
			else
			{
				if ${Asteroids.LockedAndLocking} >= ${Ship.SafeMaxLockedTargets} &&  ${Ship.TotalMiningLasers} > ${Ship.SafeMaxLockedTargets}
				{
					This.ConcentrateFire:Set[TRUE]
				}
			}
		}

		;	Time to get those lasers working!
		if ${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers}
		{
			wait 200 ${Me.TargetingCount} == 0
			LockedTargets:Clear
			Me:GetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]

			if ${Config.Miner.IceMining}
			{
				; We always concentrate fire on ice roids, so simplify the checks below
				This.ConcentrateFire:Set[TRUE]
			}

			;	If we have at least one locked target, get to work on them
			if ${Target:First(exists)}
			do
			{
				;	Ignore any targets we have locked that aren't asteroids
				if ${Target.Value.CategoryID} != ${Asteroids.AsteroidCategoryID}
				{
					continue
				}

				;	So this is an asteroid.  If we're not mining it or Distributed Laser Targetting is turned off, we should mine it.
				;	Also, if we're ice mining, we don't need to mine other asteroids, and if there aren't more asteroids to target we should mine this one.
				variable bool isBeingMined
				variable bool isBeingDroneMined
				isBeingMined:Set[${Ship.IsMiningAsteroidID[${Target.Value.ID}]}]
				isBeingDroneMined:Set[${Ship.Drones.IsMiningAsteroidID[${Target.Value.ID}]}]

				if ${This.ConcentrateFire} || \
					!${Config.Miner.DistributeLasers} || \
					(!${isBeingMined} || !${isBeingDroneMined})
				{
					;	The target is locked, it's our active target, and we should be in range.  Get a laser on that puppy!
					if ${Entity[${Target.Value.ID}].Distance} <= ${Ship.OptimalMiningRange[1]}
					{
						; If either it's not being mined OR we're not distributing lasers
						; OR, we're concentrating fire
						; Then activate a laser
						if (!${isBeingMined} || !${Config.Miner.DistributeLasers}) || ${This.ConcentrateFire}
						{
							call Ship.ActivateFreeMiningLaser ${Target.Value.ID}
							wait 5
						}
/*
BUG - This is broken. It relies on the activatarget, there's no checking if they're already mining something, etc
						;	If we're supposed to be using Mining Drones, send them - remember not to do so if we're ice mining
						if !${isBeingMined} && ${Ship.Drones.DronesInSpace} > 0 && ${Config.Miner.UseMiningDrones} && !${Config.Miner.IceMining}
						{
							Ship.Drones:ActivateMiningDrones
							continue
						}
*/
					}
					else
					{
						;	We need to approach this target - also don't approach if we're approaching another target
						if ${This.Approaching} == 0
						{
							This:StartApproaching[${Target.Value.ID}]
							continue
						}
					}

				}
			}
			while ${Target:Next(exists)}
		}

		;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
		if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
		{
			if ${Config.Miner.SafeJetcan}
			{
				if ((${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)} && ${Ship.OreHoldHalfFull}) || ${Ship.CargoHalfFull})
				{
					if ${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)} && \
						${Entity[Name = "${Config.Miner.DeliveryLocation}"].Distance} < 20000 && \
						${Entity[Name = "${Config.Miner.DeliveryLocation}"].Mode} != 3
					{
						call Cargo.TransferOreToJetCan
						;	Need a wait here because it would try to move the same item more than once
						wait 20
						return
					}
					else
					{
						This:NotifyHaulers[]
					}
				}
			}
			else
			{
				if ((${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)} && ${Ship.OreHoldHalfFull}) || ${Ship.CargoHalfFull})
				{
					call Cargo.TransferOreToJetCan
					;	Need a wait here because it would try to move the same item more than once

					wait 20
					This:NotifyHaulers[]
				}
			}
		}
	}

	method NotifyHaulers()
	{
	    if ${Time.Timestamp} >= ${This.NextHaulerNotify.Timestamp}
		{
			; Don't call the hauler more than once a minute
    		This.NextHaulerNotify:Set[${Time.Timestamp}]
    		This.NextHaulerNotify.Second:Inc[60]
    		This.NextHaulerNotify:Update

			/* notify hauler there is ore in space */
			variable string tempString
			tempString:Set["${Me.CharID},${Me.SolarSystemID},${Entity[GroupID = GROUP_ASTEROIDBELT].ID}"]
			relay all -event EVEBot_Miner_Full ${tempString}
		}

		/* TO MANUALLY CALL A HAULER ENTER THIS IN THE CONSOLE
		 * relay all -event EVEBot_Miner_Full "${Me.CharID},${Me.SolarSystemID},${Entity[GroupID = 9].ID}"
		 */
	}

	;This method is triggered by an event.  If triggered, it tells us our orca is in a belt and can be warped to.
	method Event_OrcaIsInBelt(bool State)
	{
		WarpToOrca:Set[${State}]
	}

	;This method is triggered by an event.  If triggered, it tells us our master is in a belt and can be warped to.
	method Event_MasterIsInBelt(bool State)
	{
		WarpToMaster:Set[${State}]
	}

	;This method is triggered by an event.  If triggered, it tells us how much space our hauler has available
	method HaulerMSG(int64 value)
	{
		HaulerAvailableCapacity:Set[${value}]
	}

	;	This function's sole purpose is to get your ship in warp as fast as possible from a dead stop with a MWD.  It accepts a value and will either Warp to it
	;	if it is an entity in the current system, or uses the autopilot if it's a bookmark in another system.  It is designed to do what it needs to do and then
	;	exit, after which the functions in obj_Ship can be used to make sure the navigation completes.
	function FastWarp(int64 LocationID=0,string BookmarkName="")
	{
		if ${Me.ToEntity.Mode} != 3
		{
			if ${LocationID} == -1
			{
				Logger:Log["Debug: Bookmark:WarpTo to ${BookmarkName} from Line _LINE_ ", LOG_DEBUG]
				EVE.Bookmark[${BookmarkName}]:WarpTo[0]
			}
			if ${LocationID} != 0
			{
				if ${Entity[${LocationID}](exists)}
				{
					Logger:Log["Debug: Entity:WarpTo to ${LocationID} from Line _LINE_ ", LOG_DEBUG]
					Entity[${LocationID}]:WarpTo[0]
				}
				if ${Universe[${LocationID}](exists)}
				{
					Universe[${LocationID}]:SetDestination
					if !${Me.AutoPilotOn}
					{
						EVE:Execute[CmdToggleAutopilot]
					}
				}
			}
		}
		wait 100 ${Me.ToEntity.Mode} == 3
		Ship:Activate_AfterBurner
		wait 20
		Ship:Deactivate_AfterBurner
	}

	member:bool AtPanicBookmark()
	{
		if ${Me.InSpace}
		{
			if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} == 5
			{
				if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${EVE.Bookmark[${Config.Miner.PanicLocation}].X}, ${EVE.Bookmark[${Config.Miner.PanicLocation}].Y}, ${EVE.Bookmark[${Config.Miner.PanicLocation}].Z}]} < WARP_RANGE
				{
					return TRUE
				}
			}
		}
		return FALSE
	}

	;	This member is used to determine if our miner is full based on a number of factors:
	;	*	Config.Miner.CargoThreshold
	;	*	Are we flying an orca
	;	*	Are we ice mining
	;	*	ForceDropoff (Usually means we need drones)
	member:bool MinerFull()
	{
		if ${ForceDropoff}
		{
			Return TRUE
		}
		if ${Config.Miner.IceMining}
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)}
			{
				if ${Ship.OreHoldFreeSpace} < 1000
				{
					return TRUE
				}
			}
			elseif ${Ship.CargoFreeSpace} < 1000 || ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
			{
				return TRUE
			}
		}
		else
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)}
			{
				if ${Ship.OreHoldFreeSpace} < ${Ship.OreHoldMinimumFreeSpace}
				{
					return TRUE
				}
			}
			elseif ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${MyShip.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
			{
				return TRUE
			}
		}
		return FALSE
	}

	function Tractor()
	{
		if ${Ship.TotalTractorBeams} > 0
		{
			variable index:entity Wrecks

			if 	${Me.TargetingCount} != 0
			{
				return
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].IsWreckEmpty}
			{
				Logger:Log["Miner.Tractor: Wreck empty, clearing"]
				if ${Entity[${Tractoring}].IsLockedTarget}
				{
					Entity[${Tractoring}]:UnlockTarget
				}
				Tractoring:Set[-1]
			}

			if ${Tractoring} == -1
			{
				Wrecks:Clear
				EVE:QueryEntities[Wrecks,${LavishScript.CreateQuery[GroupID = 186 && HaveLootRights && Distance < ${Ship.OptimalTractorRange} && !IsWreckEmpty && Distance < ${Ship.OptimalTargetingRange}]}]

				if ${Wrecks.Used} > 0
				{
					Tractoring:Set[${Wrecks[1]}]
					Logger:Log["Miner.Tractor: ${Wrecks.Used} wrecks found"]
				}
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
			{
				Logger:Log["Miner.Tractor: Opening wreck"]
				Entity[${Tractoring}]:Open
				if ${Ship.IsTractoringWreckID[${Tractoring}]}
				{
					Ship:Deactivate_Tractor
				}
				return
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && ${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
			{
				Logger:Log["Miner.Tractor: Looting wreck ${Entity[${Tractoring}].Name}"]
				variable index:item ContainerCargo
				variable iterator Cargo
				variable index:int64 CargoList
				Entity[${Tractoring}]:GetCargo[ContainerCargo]
				ContainerCargo:GetIterator[Cargo]
				if ${Cargo:First(exists)}
					do
					{
						CargoList:Insert[${Cargo.Value.ID}]
					}
					while ${Cargo:Next(exists)}
				EVE:MoveItemsTo[CargoList, MyShip, CorpHangars]
				return
			}

			if ${Entity[${Tractoring}](exists)} && !${Entity[${Tractoring}].IsLockedTarget}
			{
				Logger:Log["Miner.Tractor: Locking wreck ${Entity[${Tractoring}].Name}"]
				Entity[${Tractoring}]:LockTarget
				return
			}
			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].IsLockedTarget} && !${Ship.IsTractoringWreckID[${Tractoring}]}
			{
				call Ship.ActivateFreeTractorBeam ${Entity[${Tractoring}].WreckID}
				return
			}
		}
	}
}
