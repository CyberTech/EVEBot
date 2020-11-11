/*
	Orca Behavior Module for supporting miners (bot or other)
		- Much design specified by Gsousa
	- CyberTech
*/

objectdef obj_Orca
{
	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable time NextHaulerNotify

	;	State information (What we're doing)
	variable string CurrentState = "IDLE"

	;	Used to force a dropoff when the cargo hold isn't full
	variable bool ForceDropoff = FALSE

	;	This is used to keep track of what we are approaching and when we started
	variable int64 Approaching = 0
	variable int TimeStartedApproaching = 0

	;	This is used to keep track of if our master is in a belt.
	variable bool WarpToMaster=FALSE

	;	This keeps track of the wreck we are tractoring
	variable int64 Tractoring=-1

	;	Search string for our Orca
	variable string Orca

	;	Search string for our Master
	variable string Master

	; My master variables
	variable int64 MasterVote =-1
	variable string MasterName
	variable bool IsMaster=FALSE
	variable string DeliveryLocation

	method Initialize()
	{
		This.TripStartTime:Set[${Time.Timestamp}]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		LavishScript:RegisterEvent[EVEBot_Orca_InBelt]

		LavishScript:RegisterEvent[EVEBot_Master_InBelt]
		Event[EVEBot_Master_InBelt]:AttachAtom[This:MasterInBelt]
		LavishScript:RegisterEvent[EVEBot_Master_Vote]
		Event[EVEBot_Master_Vote]:AttachAtom[This:MasterVote]

		LavishScript:RegisterEvent[EVEBot_HaulerMSG]
		Event[EVEBot_HaulerMSG]:AttachAtom[This:HaulerMSG]

		Logger:Log["obj_Orca: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_Master_InBelt]:DetachAtom[This:MasterInBelt]
		Event[EVEBot_Master_Vote]:DetachAtom[This:MasterVote]
		Event[EVEBot_HaulerMSG]:DetachAtom[This:HaulerMSG]
		Event[EVEBot_TriggerAttack]:DetachAtom[This:UnderAttack]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.CurrentBehavior.Equal[Orca]}
		{
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
			Logger:Log["Orca: StartApproaching(${ID}) - Already approaching ${This.Approaching}. Lucy, the kids are fighting!"]
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

		Logger:Log["Orca: Approaching ${ID}:${Entity[${ID}].Name} @ ${EVEBot.MetersToKM_Str[${Distance}]}"]
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
		DeliveryLocation:Set[${Config.Miner.DeliveryLocation}]
		PanicLocation:Set[${Config.Miner.PanicLocation}]

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
					Logger:Log["FLEE: NPC Dreadnaught detected: ${Entity[\"GroupID = GROUP_DREADNOUGHT\" && CategoryID = CATEGORYID_ENTITY].Name}"]
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
		if !${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]} && ${This.OrcaFull}
		{
			This.CurrentState:Set["DROPOFF"]
			return
		}

		This.CurrentState:Set["ORCA"]
	}


/*
;	Step 3:		ProcessState:  This is the nervous system of the module.  EVEBot calls this; it uses the state information from SetState
;				to figure out what it needs to do.  Then, it performs the actions, sometimes using functions - think of the functions as
;				arms and legs.  Don't ask me why I feel an analogy is needed.
*/

	function ProcessState()
	{
		if !${Config.Common.CurrentBehavior.Equal[Orca]}
		{
			return
		}

		if ${Me.InSpace}
		{
			This:CheckAttack
		}

		if ${This.CurrentState.NotEqual[ORCA]}
		{
			relay all -event EVEBot_Orca_InBelt FALSE
			if ${IsMaster}
			{
				; Tell the miners we might not be in a belt and shouldn't be warped to.
				relay all -event EVEBot_Master_InBelt FALSE
			}
		}

		if ${Config.Miner.MasterMode} || ${Config.Miner.GroupMode}
		{
			if ${MasterVote} == -1
			{
				This:VoteForMaster
			}
			else
			{
				;This:ResetMaster
			}
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
				Ship.Drones:ReturnAllToDroneBay["Orca.Hardstop"]
				if ${EVE.Bookmark[${This.PanicLocation}](exists)} && ${EVE.Bookmark[${This.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${This.PanicLocation}](exists)} && ${EVE.Bookmark[${This.PanicLocation}].TypeID} != 5
					{
						;call This.FastWarp ${EVE.Bookmark[${This.PanicLocation}].ItemID}
						Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
						call Station.DockAtStation ${EVE.Bookmark[${This.PanicLocation}].ItemID}
					}
					else
					{
						Logger:Log["Debug: WarpToBookMarkName ${This.PanicLocation} from Line _LINE_ ", LOG_DEBUG]
						call Ship.WarpToBookMarkName "${This.PanicLocation}"
					}
					break
				}
				if ${EVE.Bookmark[${This.PanicLocation}](exists)} && ${EVE.Bookmark[${This.PanicLocation}].SolarSystemID} != ${Me.SolarSystemID}
				{
					Logger:Log["Debug: FastWarp to ${This.PanicLocation} from Line _LINE_ ", LOG_DEBUG]
					call This.FastWarp ${EVE.Bookmark[${This.PanicLocation}].SolarSystemID}
					call Ship.TravelToSystem ${EVE.Bookmark[${This.PanicLocation}].SolarSystemID}
					break
				}
				if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					;call This.FastWarp ${EVE.Bookmark[${This.DeliveryLocation}].ItemID}
					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${EVE.Bookmark[${This.DeliveryLocation}].ItemID}
					break
				}
				if ${Entity["(GroupID = 15 || GroupID = 1657)"](exists)}
				{
					Logger:Log["Docking at ${Entity["(GroupID = 15 || GroupID = 1657)"].Name}"]
					;call This.FastWarp ${Entity["(GroupID = 15 || GroupID = 1657)"].ID}
					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${Entity["(GroupID = 15 || GroupID = 1657)"].ID}
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

				Logger:Log["WARNING:  EVERYTHING has gone wrong. Orca is in HARDSTOP mode and there are no panic locations, delivery locations, stations, or safe spots to use. You're probably going to get blown up..."]
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
				Ship.Drones:ReturnAllToDroneBay["Orca.Flee"]
				if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${EVE.Bookmark[${This.DeliveryLocation}].ItemID}
					break
				}
				if ${EVE.Bookmark[${This.PanicLocation}](exists)} && ${EVE.Bookmark[${This.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					if ${EVE.Bookmark[${This.PanicLocation}](exists)} && ${EVE.Bookmark[${This.PanicLocation}].TypeID} != 5
					{
						Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
						call Station.DockAtStation ${EVE.Bookmark[${This.PanicLocation}].ItemID}
					}
					else
					{
						Logger:Log["Debug: FastWarp to ${This.PanicLocation} from Line _LINE_ ", LOG_DEBUG]
						call This.FastWarp -1 "${This.PanicLocation}"
					}
					break
				}

				if ${Entity["(GroupID = 15 || GroupID = 1657)"](exists)}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
					call Station.DockAtStation ${Entity["(GroupID = 15 || GroupID = 1657)"].ID}
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
				if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].ItemID} != ${Me.StationID}
				{
					call Station.Undock
					break
				}

				;	If we're in Orca mode, we need to unload all locations capable of holding ore, not just the cargo hold.
				;	Note:  I need to replace the shuffle with 3 direct movements
				call Cargo.TransferCargoFromShipOreHoldToStation
				call Cargo.TransferCargoFromShipCorporateHangarToStation
				call Cargo.TransferOreToStationHangar

				LastUsedCargoCapacity:Set[0]
				call Station.Undock
				wait 600 ${Me.InSpace}
				break

			;	This means we're in space and we should act like an orca.
			;	*	If we're warping, wait for that to finish up
			;	*	If Orca In Belt is enabled, call OrcaInBelt
			case ORCA
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}
				}
				if ${Me.ToEntity.Mode} == 3
				{
					break
				}
				call This.OrcaInBelt
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

						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: Station.DockAtStation called from Line _LINE_ ", LOG_DEBUG]
							call Station.DockAtStation ${EVE.Bookmark[${This.DeliveryLocation}].ItemID}
							break
						}
						Logger:Log["ALERT: Station dock failed for delivery location \"${This.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a Hangar Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Hangar Array
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${This.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${This.DeliveryLocation}"
							call Cargo.TransferOreToCorpHangarArray
							break
						}
						Logger:Log["ALERT: Hangar Array unload failed for delivery location \"${This.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a Large Ship Assembly Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Large Ship Assembly Array
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${This.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${This.DeliveryLocation}"
							call Cargo.TransferOreToLargeShipAssemblyArray
							break
						}
						Logger:Log["ALERT: Large Ship Assembly Array unload failed for delivery location \"${This.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a Large Ship Assembly Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case Compression Array
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${This.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${This.DeliveryLocation}"
							call Cargo.TransferOreToCompressionArray
							break
						}
						Logger:Log["ALERT: Compression Array unload failed for delivery location \"${This.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a XLarge Ship Assembly Array.
					;	*	If our delivery location is in another system, set autopilot and go there
					;	*	If our delivery location is in the same system, warp there and unload
					;	*	If the above didn't work, panic so the user knows to correct their configuration and try again.
					case XLarge Ship Assembly Array
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							call Ship.TravelToSystem ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID}
							break
						}
						if ${EVE.Bookmark[${This.DeliveryLocation}](exists)} && ${EVE.Bookmark[${This.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Logger:Log["Debug: WarpToBookMarkName to ${This.DeliveryLocation} from Line _LINE_ ", LOG_DEBUG]
							call Ship.WarpToBookMarkName "${This.DeliveryLocation}"
							call Cargo.TransferOreToXLargeShipAssemblyArray
							break
						}
						Logger:Log["ALERT: XLarge Ship Assembly Array unload failed for delivery location \"${This.DeliveryLocation}\""]
						Logger:Log["ALERT: Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break

					;	This means we're delivering to a jetcan.  This shouldn't get much action because they should be jettisoned continously during mining.
					case Jetcan
						;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
						if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
						{
							if ${Config.Miner.SafeJetcan}
							{
								if ${This.OrcaFull}
								{
									if ${Entity[Name = "${This.DeliveryLocation}"](exists)} && \
										${Entity[Name = "${This.DeliveryLocation}"].Distance} < 20000 && \
										${Entity[Name = "${This.DeliveryLocation}"].Mode} != 3
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
								if ${This.OrcaFull}
								{
									call Cargo.TransferOreToJetCan
									;	Need a wait here because it would try to move the same item more than once
									wait 20
									This:NotifyHaulers[]
								}
							}
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
;			OrcaInBelt:  This is it's own function so the ProcessState function doesn't get too giant.  This is mostly because it's just a trimmed
;				down version of This.Mine.  However, as with the miner, it's important to remember that anything you do here keeps you in the Orca state.
;				Until EVEBot makes it through this function, it can't get back to ProcessState to start running away from hostiles and whatnot.
;				Therefore, keep any use of the wait function to a minimum, and make sure you can get out of loops in a timely manner!
*/
	function OrcaInBelt()
	{
		;	Variable used to track asteroids
		variable iterator AsteroidIterator


		;	If we're in a station there's not going to be any mining going on.  This should clear itself up if it ever happens.
		if ${Me.InStation} != FALSE
		{
			Logger:Log["DEBUG: OrcaInBelt called while zoning or while in station!"]
			return
		}

		if !${Me.InSpace}
		{
			return
		}

		;	This checks our armor and shields to determine if we need to run like hell.  If we're being attacked by something
		;	dangerous enough to get us this damaged, it's best to switch to HARD STOP mode.
		if (${MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
			${MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct})
		{
			Logger:Log["Armor is at ${MyShip.ArmorPct}: ${MyShip.Armor}/${MyShip.MaxArmor}", LOG_CRITICAL]
			Logger:Log["Shield is at ${MyShip.ShieldPct}: ${MyShip.Shield}/${MyShip.MaxShield}", LOG_CRITICAL]
			Logger:Log["Orca aborting due to defensive status", LOG_CRITICAL]

			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		;	If configured to launch combat drones and there's a shortage, force a DropOff so we go to our delivery location
		if ${Config.Combat.LaunchCombatDrones} && ${Ship.Drones.CombatDroneShortage}
		{
			Logger:Log["Warning: Drone shortage detected.  Forcing a dropoff - make sure drones are available at your delivery location!"]
			ForceDropoff:Set[TRUE]
			return
		}

		;	Find an asteroid field, or stay at current one if we're near one.  Once we're there, prepare for mining and
		;	make sure we know what asteroids are available
		variable bool TimeToMove = FALSE
		if ${Asteroids.FieldEmpty}
		{
			Logger:Log["Orca.OrcaInBelt: No asteroids detected, forcing belt change"]
			TimeToMove:Set[TRUE]
		}

		;	This changes belts if someone's within Min. Distance to Players
		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			Logger:Log["Orca.OrcaInBelt: Avoiding player: Forcing belt change"]
			TimeToMove:Set[TRUE]
		}

		if ${TimeToMove}
		{
			TimeToMove:Set[FALSE]
			relay all -event EVEBot_Orca_InBelt FALSE
			if ${IsMaster}
			{
				; Tell the miners we might not be in a belt and shouldn't be warped to.
				relay all -event EVEBot_Master_InBelt FALSE
			}
			call Asteroids.MoveToField TRUE TRUE
			while TRUE
			{
				; Eventually, MoveToField will set ReturnToStation because there aren't any fields left.
				if ${EVEBot.ReturnToStation}
				{
					return
				}
				call Asteroids.UpdateList
				if !${Social.NonFleetPlayerOnGrid} && !${Asteroids.FieldEmpty}
				{
					; We're here!
					break
				}
				; Find a belt with nobody in it to start
				call Asteroids.MoveToField TRUE TRUE
			}
		}

		Ship:Activate_Gang_Links

		variable int OrcaRange = 30000

		;	Next we need to move in range of some ore so miners can mine near me
		variable int64 NearestAsteroidID = ${Asteroids.NearestAsteroid[100000, TRUE]}
		; Logger:Log["NearestAsteroidId: ${NearestAsteroidID}    ${Entity[${NearestAsteroidID}](exists)} && ${This.Approaching} == 0"]
		if ${Entity[${NearestAsteroidID}](exists)} && ${This.Approaching} == 0
		{
			if ${Entity[${NearestAsteroidID}].Distance} > WARP_RANGE
			{
				Logger:Log["Debug: Entity:WarpTo to NearestAsteroid from Line _LINE_ ", LOG_DEBUG]
				Entity[${NearestAsteroidID}]:WarpTo[${OrcaRange}]
				return
			}

			;	Find out if we need to approach this asteroid
			if ${Entity[${NearestAsteroidID}].Distance} > ${OrcaRange}
			{
				Logger:Log["Orca.OrcaInBelt: Approaching ${Entity[${Asteroids.NearestAsteroid}].Name}"]
				This:StartApproaching[${NearestAsteroidID}}, ${OrcaRange}]
				return
			}
		}

		; Either we've warped to an asteroid itself, or we're approaching it
		;	Tell our miners we're in a belt and they are safe to warp to me
		relay all -event EVEBot_Orca_InBelt TRUE
		if ${IsMaster}
		{
			;	Tell our miners we're in a belt and they are safe to warp to me
			relay all -event EVEBot_Master_InBelt TRUE
		}

		if ${This.Approaching} != 0
		{
			if !${Entity[${This.Approaching}](exists)}
			{
				This:StopApproaching["Orca.OrcaInBelt -Target ${This.Approaching} disappeared while I was approaching."]
				This.ApproachingOrca:Set[FALSE]
				return
			}

			if ${This.TimeSpentApproaching} >= 45
			{
				This:StopApproaching["Orca.OrcaInBelt - Approaching target ${This.Approaching} for > 45 seconds? Cancelling"]
				This.ApproachingOrca:Set[FALSE]
				return
			}

			;	If we're approaching a target, find out if we need to stop doing so
			if ${Entity[${This.Approaching}].Distance} <= ${OrcaRange}
			{
				This:StopApproaching["Orca.OrcaInBelt: In range of ${Entity[${Asteroids.NearestAsteroid}].Name} - Stopping"]
			}
		}

		;	This section is for moving ore into the Orca ore and cargo holds, so they will fill before the Corporate Hangar, to which the miner is depositing
		; TODO - reduce this cycle spam
		call Inventory.ShipFleetHangar.Activate

		if ${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]}
		{
			; We're in no-delivery mode (we don't deliver, it's picked up)
			; A hauler will be picking up from the fleet hold. Balance between keeping the fleet hold populated, but not full
			relay all -event EVEBot_Orca_Cargo ${Ship.CorpHangarUsedSpace[TRUE]}
			if ${Ship.CorpHangarFull}
			{
				; The fleet hangar filled up, because we're filling it faster than the hauler can get, or the hauler is busted. Move to Ore hold for safekeeping and to make room for more.
				call Cargo.TransferOreFromShipFleetHangarToOreHold
			}
		}
		else
		{
			if !${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]} && ${Ship.CorpHangarHalfFull}
			{
				call Inventory.ShipOreHold.Activate
				; Orca Base cargo space: Cargo: 30k, Ore: 150k, Fleet: 40k
				if !${Ship.OreHoldFull}
				{
					call Cargo.TransferOreFromShipFleetHangarToOreHold
					Ship:StackOreHold
				}
				if !${Ship.CargoFull}
				{
					call Cargo.TransferOreFromShipFleetHangarToCargoHold
					Ship:StackCargoHold
				}
			}
		}

		if ${Config.Miner.OrcaTractorLoot}
		{
			call This.Tractor
		}

		;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
		if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
		{
			if ${Config.Miner.SafeJetcan}
			{
				;	This checks to make sure the player in our delivery location is in range and not warping before we dump a jetcan
				if ((${MyShip.HasOreHold} && ${Ship.OreHoldHalfFull}) || ${Ship.CargoHalfFull})
				{
					if ${Entity[Name = "${This.DeliveryLocation}"](exists)} && \
						${Entity[Name = "${This.DeliveryLocation}"].Distance} < 20000 && \
						${Entity[Name = "${This.DeliveryLocation}"].Mode} != 3
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
				if ((${MyShip.HasOreHold} && ${Ship.OreHoldHalfFull}) || ${Ship.CargoHalfFull})
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

	;This method is triggered by an event.  If triggered, it tells us our master is in a belt and can be warped to.
	method MasterInBelt(bool State)
	{
		WarpToMaster:Set[${State}]
	}

	;This method is triggered by an event.  If triggered, lets Us figure out who is the master in group mode.
	method MasterVote(string groupParams)
	{
		Logger:Log["obj_Orca:MasterVote event:${groupParams}", LOG_DEBUG]

		if ${Config.Miner.MasterMode} || ${Config.Miner.GroupMode}
		{
			if ${MasterVote} == -1
			{
				This:VoteForMaster
			}

			variable string name
			variable int64 State = -1

			name:Set[${groupParams.Token[1,","]}]
			State:Set[${groupParams.Token[2,","]}]

			if ${Me.Name.NotEqual[${name}]}
			{
				MasterName:Set[${name}]
				if ${State} > ${MasterVote}
				{
					MasterName:Set[${name}]
					IsMaster:Set[FALSE]
					Logger:Log["obj_Orca: Master is: \"${MasterName}\"", LOG_DEBUG]
				}
				elseif ${State} == ${MasterVote}
				{
					if ${Config.Miner.MasterMode}
					{
						Logger:Log["obj_Orca: Hard Stop - There can be only one Master ERROR:${name}", LOG_DEBUG]
						This.CurrentState:Set["HARDSTOP"]
						relay all -event EVEBot_HARDSTOP "${Me.Name} - ${Config.Common.CurrentBehavior} (MasterConfigError)"
					}
					else
					{
						; re-vote for master
						Logger:Log["obj_Orca: Master Vote tie with:${name}", LOG_DEBUG]
						This:VoteForMaster
					}
				}
				else
				{
					IsMaster:Set[TRUE]
					MasterName:Set[${Me.Name}]
					Logger:Log["obj_Orca: I am Master", LOG_DEBUG]
					relay all -event EVEBot_Master_Vote "${Me.Name},${MasterVote}"
				}
			}
		}
	}

	method ResetMaster()
	{
		Logger:Log["Debug: Reset Master :${MasterVote}", LOG_DEBUG]

		if ${Config.Miner.MasterMode} || ${Config.Miner.GroupMode}
		{
			if ${Config.Miner.GroupMode}
			{
				MasterName:Set[NULL]
			}

			if ${Config.Miner.MasterMode}
			{
				MasterVote:Set[100]
			}

			relay all -event EVEBot_Master_Vote "${Me.Name},${MasterVote}"
		}
	}

	method VoteForMaster()
	{
		IsMaster:Set[TRUE]
		if ${Config.Miner.MasterMode}
		{
			MasterVote:Set[100]
		}
		else
		{
			MasterVote:Set[${Math.Rand[90]:Inc[10]}]
		}
		Logger:Log["Debug: Master Vote value: ${MasterVote}", LOG_DEBUG]

		relay all -event EVEBot_Master_Vote "${Me.Name},${MasterVote}"
	}

	;This method is used to trigger an event.  It tells our team-mates we are under attack by an NPC and what it is.
	method CheckAttack()
	{
		variable iterator CurrentAttack
		variable index:attacker attackerslist
		Me:GetAttackers[attackerslist]
		attackerslist:RemoveByQuery[${LavishScript.CreateQuery[!IsNPC]}]
		attackerslist:GetIterator[CurrentAttack]
		if ${CurrentAttack:First(exists)}
		{
			do
			{
				if !${AttackingTeam.Contains[${CurrentAttack.Value.ID}]}
				{
					Logger:Log["Orca.CheckAttack: Alerting team to kill ${CurrentAttack.Value.Name}(${CurrentAttack.Value.ID})"]
					Relay all -event EVEBot_TriggerAttack ${CurrentAttack.Value.ID}
				}
			}
			while ${CurrentAttack:Next(exists)}
		}
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
			if ${EVE.Bookmark[${This.PanicLocation}](exists)} && ${EVE.Bookmark[${This.PanicLocation}].TypeID} == 5
			{
				if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${EVE.Bookmark[${This.PanicLocation}].X}, ${EVE.Bookmark[${This.PanicLocation}].Y}, ${EVE.Bookmark[${This.PanicLocation}].Z}]} < WARP_RANGE
				{
					return TRUE
				}
			}
		}
		return FALSE
	}


	;	This member is used to determine if our miner is full based on a number of factors:
	;	*	ForceDropoff (Usually means we need drones)
	member:bool OrcaFull()
	{
		if ${ForceDropoff}
		{
			Return TRUE
		}
		if ${Ship.OreHoldFreeSpace} < 1000
		{
			return TRUE
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
				Logger:Log["Orca.Tractor: Wreck empty, clearing"]
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
					Logger:Log["Orca.Tractor: ${Wrecks.Used} wrecks found"]
				}
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
			{
				Logger:Log["Orca.Tractor: Opening wreck"]
				Entity[${Tractoring}]:Open
				if ${Ship.IsTractoringWreckID[${Tractoring}]}
				{
					Ship:Deactivate_Tractor
				}
				return
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && ${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
			{
				Logger:Log["Orca.Tractor: Looting wreck ${Entity[${Tractoring}].Name}"]
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
				Logger:Log["Orca.Tractor: Locking wreck ${Entity[${Tractoring}].Name}"]
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