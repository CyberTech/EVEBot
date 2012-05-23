/*

	Miner Class
	
	Primary Miner behavior module for EVEBot
	
	-- Tehtsuo
	
	(large amounts of code recycled from CyberTech's module)
	
*/

objectdef obj_Miner
{
	;	Versioning information
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	
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
	
	;	This is a list of IDs for rats which are attacking a team member
	variable set AttackingTeam
	
	;	This is used to keep track of how much space our hauler has available
	variable int64 HaulerAvailableCapacity=-0
	
	;	This keeps track of the wreck we are tractoring
	variable int64 Tractoring=-1
	
	;	Search string for our Orca
	variable string Orca

	
/*	
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will SetState.
*/	
	
	method Initialize()
	{
		BotModules:Insert["Miner"]

		This.TripStartTime:Set[${Time.Timestamp}]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		LavishScript:RegisterEvent[EVEBot_Orca_InBelt]
		Event[EVEBot_Orca_InBelt]:AttachAtom[This:OrcaInBelt]
		LavishScript:RegisterEvent[EVEBot_HaulerMSG]
		Event[EVEBot_HaulerMSG]:AttachAtom[This:HaulerMSG]
		LavishScript:RegisterEvent[EVEBot_TriggerAttack]
		Event[EVEBot_TriggerAttack]:AttachAtom[This:UnderAttack]
		

		UI:UpdateConsole["obj_Miner: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_Orca_InBelt]:DetachAtom[This:OrcaInBelt]
		Event[EVEBot_HaulerMSG]:DetachAtom[This:HaulerMSG]
		Event[EVEBot_TriggerAttack]:DetachAtom[This:UnderAttack]
	}	
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Miner]}
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
	
	method SetState()
	{
		;	First, we need to check to find out if I should "HARD STOP" - dock and wait for user intervention.  Reasons to do this:
		;	*	If someone targets us
		;	*	They're lower than acceptable Min Security Status on the Miner tab
		;	*	I'm in a pod.  Oh no!
		if (${Social.PossibleHostiles} || ${Ship.IsPod}) && !${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["HARDSTOP"]
			UI:UpdateConsole["HARD STOP: Possible hostiles, cargo hold not changing, or ship in a pod!"]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		;	If we're in a station HARD STOP has been called for, just idle until user intervention
		if ${EVEBot.ReturnToStation} && ${Me.InStation}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		;	If we're at our panic location bookmark and HARD STOP has been called for, just idle until user intervention
		if ${EVEBot.ReturnToStation} && ${This.AtPanicBookmark}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		;	If we're in space and HARD STOP has been called for, try to get to a station
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["HARDSTOP"]
			return
		}
		
		;	Find out if we should "SOFT STOP" and flee.  Reasons to do this:
		;	*	Pilot lower than Min Acceptable Standing on the Fleeing tab
		;	*	Pilot is on Blacklist ("Run on Blacklisted Pilot" enabled on Fleeing tab)
		;	*	Pilot is not on Whitelist ("Run on Non-Whitelisted Pilot" enabled on Fleeing tab)
		;	This checks for both In Station and out, preventing spam if you're in a station.
		if !${Social.IsSafe}  && !${EVEBot.ReturnToStation} && ${Me.InStation}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
		if !${Social.IsSafe}  && !${EVEBot.ReturnToStation} && ${This.AtPanicBookmark}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
		if !${Social.IsSafe}  && !${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["FLEE"]
			UI:UpdateConsole["FLEE: Low Standing player or system unsafe, fleeing"]
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
		
		;	If Orca Mode is on, I'm going to behave like an Orca
		if ${Config.Miner.OrcaMode}
		{
			This.CurrentState:Set["ORCA"]
			return
		}
				
		;	If I'm not in a station and I have room to mine more ore, that's what I should do!
	 	This.CurrentState:Set["MINE"]
	}	
	
	
/*	
;	Step 3:		ProcessState:  This is the nervous system of the module.  EVEBot calls this; it uses the state information from SetState
;				to figure out what it needs to do.  Then, it performs the actions, sometimes using functions - think of the functions as 
;				arms and legs.  Don't ask me why I feel an analogy is needed.
*/			
	
	function ProcessState()
	{
		;	This should be processed regardless of what mode you're in - this way the hauler can report attacks to the team.
		if ${Me.InSpace}
		{
			This:CheckAttack
		}
		
		;	If Miner isn't the selected bot mode, this function shouldn't have been called.  However, if it was we wouldn't want it to do anything.
		if !${Config.Common.BotModeName.Equal[Miner]}
		{
			return
		}
		
		;	Tell the miners we might not be in a belt and shouldn't be warped to.
		if ${This.CurrentState.NotEqual[ORCA]} && ${Config.Miner.OrcaMode}
		{
			relay all -event EVEBot_Orca_InBelt FALSE
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
				relay all -event EVEBot_HARDSTOP
				if ${Me.InStation}
				{
					break
				}
				This:Cleanup_Environment
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						;call This.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
						call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
					}
					else
					{
						call Ship.WarpToBookMarkName "${Config.Miner.PanicLocation}"
					}
					break
				}				
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} != ${Me.SolarSystemID}
				{
					call This.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}
					break
				}
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					;call This.FastWarp ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					break
				}
				if ${Entity["CategoryID = 3"](exists)}
				{
					UI:UpdateConsole["Docking at ${Entity["CategoryID = 3"].Name}"]
					;call This.FastWarp ${Entity["CategoryID = 3"].ID}
					call Station.DockAtStation ${Entity["CategoryID = 3"].ID}
					break
				}
				if ${Me.ToEntity.Mode} != 3
				{
					call Safespots.WarpTo
					call This.FastWarp
					wait 30
				}

				UI:UpdateConsole["WARNING:  EVERYTHING has gone wrong. Miner is in HARDSTOP mode and there are no panic locations, delivery locations, stations, or safe spots to use. You're probably going to get blown up..."]
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
				This:Cleanup_Environment
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					;call This.FastWarp ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
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
						call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
					}
					else
					{
						call This.FastWarp -1 "${Config.Miner.PanicLocation}"
					}
					break
				}

				if ${Entity["CategoryID = 3"](exists)}
				{
					if ${Config.Miner.BookMarkLastPosition} && !${Bookmarks.CheckForStoredLocation}
					{
						Bookmarks:StoreLocation
					}

					UI:UpdateConsole["Docking at ${Entity["CategoryID = 3"].Name}"]
					;call This.FastWarp ${Entity["CategoryID = 3"].ID}
					call Station.DockAtStation ${Entity["CategoryID = 3"].ID}
					break
				}				
				
				if ${Me.ToEntity.Mode} != 3
				{
					call Safespots.WarpTo
					call This.FastWarp
					wait 30
					break
				}
				
				UI:UpdateConsole["HARD STOP: Unable to flee, no stations available and no Safe spots available"]
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
				
				;	If we're in Orca mode, we need to unload all locations capable of holding ore, not just the cargo hold.
				;	Note:  I need to replace the shuffle with 3 direct movements
				if ${Config.Miner.OrcaMode}
				{
					call Cargo.OpenHolds
					Ship:Open
					call Cargo.TransferCargoFromShipOreHoldToStation
					call Cargo.TransferCargoFromShipCorporateHangarToStation
					call Cargo.CloseHolds
					call Cargo.TransferOreToHangar
				}
				else
				{
					call Cargo.TransferOreToHangar
				}
				
			    LastUsedCargoCapacity:Set[0]
				call Station.Undock
				wait 600 ${Me.InSpace}
				if ${Config.Miner.OrcaMode}
				{
					Ship:Open
				}
				call Cargo.OpenHolds
				break
				
			;	This means we're in space and should mine some more ore!  Only one choice here - MINE!
			;	It is prudent to make sure we're not warping, since you can't mine much in warp...
			case MINE
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}
				}
				if ${Me.ToEntity.Mode} != 3
				{
					call This.Mine
				}
				break
				
			;	This means we're in space and we should act like an orca.
			;	*	If we're warping, wait for that to finish up
			;	*	If Orca In Belt is enabled, call OrcaInBelt
			case ORCA
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
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
				;	Clean up before we leave
				This:Cleanup_Environment

			
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
							call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
							break
						}
						UI:UpdateConsole["ALERT:  Station dock failed, check your delivery location!  Switching to HARD STOP mode!"]
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
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferOreToCorpHangarArray
							break
						}
						UI:UpdateConsole["ALERT:  Hangar Array unload failed, check your delivery location!  Switching to HARD STOP mode!"]
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
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferCargoToLargeShipAssemblyArray
							break
						}
						UI:UpdateConsole["ALERT:  Large Ship Assembly Array unload failed, check your delivery location!  Switching to HARD STOP mode!"]
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
							call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
							call Cargo.TransferOreToXLargeShipAssemblyArray
							break
						}
						UI:UpdateConsole["ALERT:  XLarge Ship Assembly Array unload failed, check your delivery location!  Switching to HARD STOP mode!"]
						EVEBot.ReturnToStation:Set[TRUE]
						break
						
					;	This means we're delivering to a jetcan.  This shouldn't get much action because they should be jettisoned continously during mining.
					case Jetcan
						UI:UpdateConsole["Warning: Cargo filled during jetcan mining, delays may occur"]

						;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
						if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
						{
							if !${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)}
							{
									This:NotifyHaulers[]
							}
							
							;	This checks to make sure the player in our delivery location is in range and not warping before we dump a jetcan
							if ${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)} && ${Entity[Name = "${Config.Miner.DeliveryLocation}"].Distance} < 20000 && ${Entity[Name = "${Config.Miner.DeliveryLocation}"].Mode} != 3 && ${Ship.CargoHalfFull}
							{
								call Cargo.TransferOreToJetCan
								;	Need a wait here because it would try to move the same item more than once
								wait 20
								return
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
							UI:UpdateConsole["ALERT:  The specified orca isn't in local - it may be incorrectly configured or out of system doing a dropoff."]
							break
						}
						
						if ${Me.ToEntity.Mode} == 3
						{
							break
						}				
						
						if !${Entity[${Orca.Escape}](exists)} && ${Local[${Config.Miner.DeliveryLocation}].ToFleetMember}
						{
							UI:UpdateConsole["ALERT:  The orca is not in this belt.  Warping there first to unload."]
							Fleet:WarpTo[${Config.Miner.DeliveryLocation]
							break
						}

						;	Find out if we need to approach this target
						if ${Entity[${Orca.Escape}].Distance} > LOOT_RANGE && ${This.Approaching} == 0
						{
							UI:UpdateConsole["ALERT:  Approaching to within loot range."]
							Entity[${Orca.Escape}]:Approach[LOOT_RANGE]
							This.Approaching:Set[${Entity[${Orca.Escape}]}]
							This.TimeStartedApproaching:Set[${Time.Timestamp}]
							break
						}
						
						;	If we've been approaching for more than 2 minutes, we need to give up and try again
						if ${Math.Calc[${TimeStartedApproaching}-${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
						{
							This.Approaching:Set[0]
							This.TimeStartedApproaching:Set[0]							
						}
						
						;	If we're approaching a target, find out if we need to stop doing so 
						if (${Entity[${This.Approaching}](exists)} && ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE && ${This.Approaching} != 0) || (!${Entity[${This.Approaching}](exists)} && ${This.Approaching} != 0)
						{
							UI:UpdateConsole["ALERT:  Within loot range."]
							EVE:Execute[CmdStopShip]
							This.Approaching:Set[0]
							This.TimeStartedApproaching:Set[0]
						}
						
						;	Open the Orca if it's not open yet
						if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && !${EVEWindow[ByItemID, ${Entity[${Orca.Escape}]}](exists)}
						{
							Entity[${Orca.Escape}]:Open
							break
						}
						
						if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && ${EVEWindow[ByItemID, ${Entity[${Orca.Escape}]}](exists)}
						{
							call This.Prepare_Environment
							call Cargo.TransferOreToShipCorpHangar ${Entity[${Orca.Escape}]}
						}	
						break
						
					;	This means the DeliveryLocation type is invalid.  This should only happen if someone monkeys with the UI.
					Default
						UI:UpdateConsole["ALERT: Delivery Location Type ${Config.Miner.DeliveryLocationTypeName} unknown.  Switching to HARD STOP mode!"]
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

		
		;	If we're in a station there's not going to be any mining going on.  This should clear itself up if it ever happens.
		if ${Me.InStation} != FALSE
		{
			UI:UpdateConsole["DEBUG: obj_Miner.Mine called while zoning or while in station!"]
			return
		}

		if !${Me.InSpace}
		{
			return
		}

		;	This checks our armor and shields to determine if we need to run like hell.  If we're being attacked by something
		;	dangerous enough to get us this damaged, it's best to switch to HARD STOP mode.
		if (${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
			${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct})
		{
			UI:UpdateConsole["Armor is at ${Me.Ship.ArmorPct}: ${Me.Ship.Armor}/${Me.Ship.MaxArmor}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${Me.Ship.ShieldPct}: ${Me.Ship.Shield}/${Me.Ship.MaxShield}", LOG_CRITICAL]
			UI:UpdateConsole["Miner aborting due to defensive status", LOG_CRITICAL]

			EVEBot.ReturnToStation:Set[TRUE]
			return
		}
		
		
		;	Find an asteroid field, or stay at current one if we're near one.  Choices are:
		;	*	If WarpToOrca and the orca is in fleet, warp there instead and clear our saved bookmark
		;	*	Warp to a belt based on belt labels or a random belt
		;	Note:  The UpdateList spam is necessary to make sure our actions are based on the closest asteroids
		call Asteroids.UpdateList
		
		Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]

		if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${WarpToOrca} && !${Entity[${Orca.Escape}](exists)}
		{
			call Ship.WarpToFleetMember ${Local[${Config.Miner.DeliveryLocation}]}
			if ${Config.Miner.BookMarkLastPosition} && ${Bookmarks.CheckForStoredLocation}
			{
				Bookmarks:RemoveStoredLocation
			}
			call Asteroids.UpdateList
		}
		if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${Entity[${Orca.Escape}](exists)}
		{
			call Asteroids.UpdateList ${Entity[${Orca.Escape}].ID}
		}

		Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
		if ${Ship.TotalActivatedMiningLasers} == 0 && ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${Me.ToEntity.Mode} == 3 && ${Entity[${Orca.Escape}].Mode} == 3 && ${Ship.Drones.DronesInSpace} != 0 && !${EVEBot.ReturnToStation}
		{
			EVE:Execute[CmdStopShip]				
			do
			{
				if ${Me.ToEntity.Mode} == 3
				{
					EVE:Execute[CmdStopShip]				
				}
				Ship.Drones:ReturnAllToDroneBay
				wait 20
			}
			while ${Ship.Drones.DronesInSpace} != 0	
		}
		
		if ${Ship.TotalActivatedMiningLasers} == 0 && !${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]}
		{	
			do
			{
				if ${Me.ToEntity.Mode} == 3
				{
					EVE:Execute[CmdStopShip]				
				}
				Ship.Drones:ReturnAllToDroneBay
				wait 20
			}
			while ${Ship.Drones.DronesInSpace} != 0		
			call Asteroids.MoveToField FALSE TRUE
			call Asteroids.UpdateList
		}
		call This.Prepare_Environment

		;	If our ship has no mining lasers, panic so the user knows to correct their configuration and try again
		if ${Ship.TotalMiningLasers} == 0
		{
			UI:UpdateConsole["ALERT: No mining lasers detected.  Switching to HARD STOP mode!"]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		;	If configured to launch combat drones and there's a shortage, force a DropOff so we go to our delivery location
		 ; if ${Config.Combat.LaunchCombatDrones} && ${Ship.Drones.CombatDroneShortage}
		; {
			; UI:UpdateConsole["Warning: Drone shortage detected.  Forcing a dropoff - make sure drones are available at your delivery location!"]
			; ForceDropoff:Set[TRUE]
			; return
		; }

		;	This changes belts if someone's within Min. Distance to Players
		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			UI:UpdateConsole["Avoiding player: Changing Belts"]
			Ship.Drones:ReturnAllToDroneBay
			call Asteroids.MoveToField TRUE
			return
		}
		

		;	This calls the defense routine if Launch Combat Drones is turned on
		if ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
		{
			call Defend
		}		
		

		;	We need to make sure we're near our orca if we're using it as a delivery location
		if ${Config.Miner.DeliveryLocationTypeName.Equal[Orca]}
		{
			Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]

			;	Find out if we need to approach this target.
			if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} > LOOT_RANGE && ${This.Approaching} == 0
			{
				if ${Entity[${Orca.Escape}].Distance} > WARP_RANGE 
				{
					UI:UpdateConsole["ALERT:  ${Entity[${Orca.Escape}].Name} is a long way away.  Warping to it."]
					Entity[${Orca.Escape}]:WarpTo[1000]
					return
				}
				UI:UpdateConsole["ALERT:  Approaching to within loot range."]
				Entity[${Orca.Escape}]:Approach[LOOT_RANGE]
				This.Approaching:Set[${Entity[${Orca.Escape}]}]
				This.TimeStartedApproaching:Set[${Time.Timestamp}]
				This.ApproachingOrca:Set[TRUE]
				return
			}
			
			;	If we've been approaching for more than 2 minutes, we need to give up and try again
			if ${Math.Calc[${TimeStartedApproaching} - ${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
			{
				echo Approach Orca stopping because of timeout.
				This.Approaching:Set[0]
				This.TimeStartedApproaching:Set[0]			
				This.ApproachingOrca:Set[FALSE]
				return
			}			
			
			;	If we're approaching a target, find out if we need to stop doing so.
			;	After moving, we need to find out if any of our targets are out of mining range and unlock them so we can get new ones.
			if (${Entity[${This.Approaching}](exists)} && ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE && ${This.Approaching} != 0) || (!${Entity[${This.Approaching}](exists)} && ${This.Approaching} != 0)
			{
				UI:UpdateConsole["ALERT:  Within loot range."]
				EVE:Execute[CmdStopShip]
				This.Approaching:Set[0]
				This.TimeStartedApproaching:Set[0]
				This.ApproachingOrca:Set[FALSE]
				
				LockedTargets:Clear
				Me:GetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				
				if ${Target:First(exists)}
				do
				{
					if ${Entity[${Target.Value.ID}].Distance} > ${Ship.OptimalMiningRange}
					{
						UI:UpdateConsole["ALERT:  unlocking ${Target.Value.Name} as it is out of range after we moved."]
						Target.Value:UnlockTarget
					}
				}
				while ${Target:Next(exists)}
				return
			}
			
			;	This performs Orca deliveries if we've got at least a tenth of our cargo hold full
			if ${Ship.CargoTenthFull}
			{
				;	Open the Orca if it's not open yet
				if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && !${EVEWindow[ByItemID, ${Entity[${Orca.Escape}]}](exists)}
				{
					Entity[${Orca.Escape}]:Open
					return
				}
				
				if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && ${EVEWindow[ByItemID, ${Entity[${Orca.Escape}]}](exists)}
				{
					call This.Prepare_Environment
					call Cargo.TransferOreToShipCorpHangar ${Entity[${Orca.Escape}]}
					call Cargo.ReplenishCrystals ${Entity[${Orca.Escape}]}
				}
			}
		}

		
		
		
		
		;	Here is where we lock new asteroids.  We always want to do this if we have no asteroids locked.  If we have at least one asteroid locked, however,
		;	we should only lock more asteroids if we're not ice mining
		if ((!${Config.Miner.DistributeLasers} || ${Config.Miner.IceMining}) && ${Asteroids.LockedAndLocking} == 0) || ((${Config.Miner.DistributeLasers} && !${Config.Miner.IceMining}) && ${Asteroids.LockedAndLocking} >= 0)
		{
			;	Calculate how many asteroids we need
			variable int AsteroidsNeeded=${Ship.TotalMiningLasers}
			
			;	If we're supposed to use Mining Drones, we need one more asteroid
			if ${Config.Miner.UseMiningDrones}
			{
				AsteroidsNeeded:Inc
			}
			
			;	So we need to lock another asteroid.  First make sure that our ship can lock another, and make sure we don't already have enough asteroids locked
			;	The Asteroids.TargetNext function will let us know if we need to concentrate fire because we're out of new asteroids to target.
			;	If we're using an orca and it's in the belt, use Asteroids.TargetNextInRange to only target roids nearby
			if (${Math.Calc[${Me.TargetCount} + ${Me.TargetingCount}]} < ${Ship.SafeMaxLockedTargets}) && ${Asteroids.LockedAndLocking} < ${AsteroidsNeeded}
			{
				do
				{
					Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
					if ${Config.Miner.DeliveryLocationTypeName.Equal[Orca]} && ${Entity[${Orca.Escape}](exists)} && !${Config.Miner.IceMining}
					{
						call Asteroids.TargetNextInRange ${Entity[${Orca.Escape}].ID}
					}
					elseif !${Config.Miner.DeliveryLocationTypeName.Equal[Orca]} || ${Config.Miner.IceMining}
					{
						call Asteroids.TargetNext
					}
					This.ConcentrateFire:Set[!${Return}]
					AsteroidsLocked:Inc
				}
				while (${Asteroids.LockedAndLocking} < ${Ship.SafeMaxLockedTargets}) && ${Asteroids.LockedAndLocking} < ${AsteroidsNeeded} && !${This.ConcentrateFire}
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
			;	First, get our locked targets
			LockedTargets:Clear
			Me:GetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]

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
				if ${This.ConcentrateFire} || ${Config.Miner.IceMining} || !${Config.Miner.DistributeLasers} || (!${Ship.IsMiningAsteroidID[${Target.Value.ID}]} && !${Ship.Drones.IsMiningAsteroidID[${Target.Value.ID}]})
				{
					
					;	Find out if we need to approach this target - also don't approach if we're approaching another target
					if ${Entity[${Target.Value.ID}].Distance} > ${Ship.OptimalMiningRange[1]} && ${This.Approaching} == 0
					{
						UI:UpdateConsole["Approaching ${Target.Value.Name}"]
						Entity[${Target.Value.ID}]:Approach[${Ship.OptimalMiningRange[1]}]
						This.Approaching:Set[${Target.Value.ID}]
						This.TimeStartedApproaching:Set[${Time.Timestamp}]	
						return
					}

					;	If we're supposed to be using Mining Drones, send them - remember not to do so if we're ice mining
					if ${Ship.Drones.DronesInSpace} > 0 && ${Config.Miner.UseMiningDrones} && !${Config.Miner.IceMining}
					{
						Ship.Drones:ActivateMiningDrones
						return
					}
					
					;	The target is locked, it's our active target, and we should be in range.  Get a laser on that puppy!
					if ${Entity[${Target.Value.ID}].Distance} <= ${Ship.OptimalMiningRange[1]}
					{
						call Ship.ActivateFreeMiningLaser ${Target.Value.ID}
					}

				}
			}
			while ${Target:Next(exists)}
		}
		
		;	If we've been approaching for more than 2 minutes, we need to give up and try again
		if ${Math.Calc[${TimeStartedApproaching} - ${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
		{
			This.Approaching:Set[0]
			This.TimeStartedApproaching:Set[0]			
			This.ApproachingOrca:Set[FALSE]
			return
		}			

		;	If we're approaching a target, find out if we need to stop doing so 
		if (${Entity[${This.Approaching}](exists)} && ${Entity[${This.Approaching}].Distance} <= ${Ship.OptimalMiningRange[1]} && ${This.Approaching} != 0 && !${This.ApproachingOrca}) || (!${Entity[${This.Approaching}](exists)} && ${This.Approaching} != 0)
		{
			EVE:Execute[CmdStopShip]
			This.Approaching:Set[0]
			This.TimeStartedApproaching:Set[0]	
		}		

		;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
		if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
		{
			if !${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)}
			{
					This:NotifyHaulers[]
			}
			
			;	This checks to make sure the player in our delivery location is in range and not warping before we dump a jetcan
			if ${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)} && ${Entity[Name = "${Config.Miner.DeliveryLocation}"].Distance} < 20000 && ${Entity[Name = "${Config.Miner.DeliveryLocation}"].Mode} != 3 && ${Ship.CargoHalfFull}
			{
				call Cargo.TransferOreToJetCan
				;	Need a wait here because it would try to move the same item more than once
				wait 20
				return
			}
		}
		
		
	}	


/*	
;	Step 5:		OrcaInBelt:  This is it's own function so the ProcessState function doesn't get too giant.  This is mostly because it's just a trimmed
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
			UI:UpdateConsole["DEBUG: obj_Miner.Mine called while zoning or while in station!"]
			return
		}

		if !${Me.InSpace}
		{
			return
		}
		
		;	This checks our armor and shields to determine if we need to run like hell.  If we're being attacked by something
		;	dangerous enough to get us this damaged, it's best to switch to HARD STOP mode.
		if (${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
			${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct})
		{
			UI:UpdateConsole["Armor is at ${Me.Ship.ArmorPct}: ${Me.Ship.Armor}/${Me.Ship.MaxArmor}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${Me.Ship.ShieldPct}: ${Me.Ship.Shield}/${Me.Ship.MaxShield}", LOG_CRITICAL]
			UI:UpdateConsole["Miner aborting due to defensive status", LOG_CRITICAL]

			EVEBot.ReturnToStation:Set[TRUE]
			return
		}
		
		;	Find an asteroid field, or stay at current one if we're near one.  Once we're there, prepare for mining and
		;	make sure we know what asteroids are available
		call Asteroids.UpdateList
		Asteroids.AsteroidList:GetIterator[AsteroidIterator]
		if !${AsteroidIterator:First(exists)}
		{
			do
			{
				Ship.Drones:ReturnAllToDroneBay
				wait 20
			}
			while ${Ship.Drones.DronesInSpace} != 0		
			call Asteroids.MoveToField FALSE FALSE TRUE
			call Asteroids.UpdateList
		}
		call This.Prepare_Environment


		;	If configured to launch combat drones and there's a shortage, force a DropOff so we go to our delivery location
		 if ${Config.Combat.LaunchCombatDrones} && ${Ship.Drones.CombatDroneShortage}
		{
			UI:UpdateConsole["Warning: Drone shortage detected.  Forcing a dropoff - make sure drones are available at your delivery location!"]
			ForceDropoff:Set[TRUE]
			return
		}


		;	This changes belts if someone's within Min. Distance to Players
		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			UI:UpdateConsole["Avoiding player: Changing Belts"]
			Ship.Drones:ReturnAllToDroneBay
			call Asteroids.MoveToField TRUE FALSE TRUE
			return
		}
		
		;	Tell our miners we're in a belt and they are safe to warp to me
		relay all -event EVEBot_Orca_InBelt TRUE
		Ship:Activate_Gang_Links
		
		variable int OrcaRange
		if ${Config.Miner.IceMining}
		{
			OrcaRange:Set[10000]
		}
		else
		{
			OrcaRange:Set[5000]
		}
		
		;	Next we need to move in range of some ore so miners can mine near me
		if ${Entity[${Asteroids.NearestAsteroid}](exists)} && ${This.Approaching} == 0
		{
			if ${Entity[${Asteroids.NearestAsteroid}].Distance} > WARP_RANGE 
			{
				Entity[${Asteroids.NearestAsteroid}]:WarpTo[${OrcaRange}]
				return
			}
		
			;	Find out if we need to approach this asteroid
			if ${Entity[${Asteroids.NearestAsteroid}].Distance} > ${OrcaRange} 
			{
				UI:UpdateConsole["Approaching: ${Entity[${Asteroids.NearestAsteroid}].Name}"]
				Entity[${Asteroids.NearestAsteroid}]:Approach[${OrcaRange}]
				This.Approaching:Set[${Asteroids.NearestAsteroid}]
				This.TimeStartedApproaching:Set[${Time.Timestamp}]			
				return
			}
		}

		;	If we've been approaching for more than 2 minutes, we need to give up and try again
		if ${Math.Calc[${TimeStartedApproaching}-${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
		{
			This.Approaching:Set[0]
			This.TimeStartedApproaching:Set[0]			
			return
		}			

		;	If we're approaching a target, find out if we need to stop doing so 
		if (${Entity[${This.Approaching}](exists)} && ${Entity[${This.Approaching}].Distance} <= ${OrcaRange} && ${This.Approaching} != 0) || (!${Entity[${This.Approaching}](exists)} && ${This.Approaching} != 0)
		{
			UI:UpdateConsole["In range of ${Entity[${Asteroids.NearestAsteroid}].Name} - Stopping"]
			EVE:Execute[CmdStopShip]
			This.Approaching:Set[0]
			This.TimeStartedApproaching:Set[0]			
		}

		
		;	This section is for moving ore into the ore and cargo holds, so they will fill before the Corporate Hangar
		Ship:Open

		call This.Prepare_Environment
		
		if !${Ship.CorpHangarEmpty}
		{
			if !${Ship.OreHoldFull} && !${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]} && !${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
			{
				call Cargo.TransferCargoFromShipCorporateHangarToOreHold
				Ship:StackOreHold
				return
			}
			if !${Ship.CargoFull} && !${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]}
			{
				call Cargo.TransferCargoFromShipCorporateHangarToCargoHold
				Ship:StackCargoHold
				return
			}
			if ${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]}
			{
				call Cargo.TransferCargoFromCargoHoldToShipCorporateHangar
				relay all -event EVEBot_Orca_Cargo ${Ship.CorpHangarUsedSpace[TRUE]}
			}
		}
		
		;	This calls the defense routine if Launch Combat Drones is turned on
		if ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
		{
			call Defend
		}
		if ${Config.Miner.OrcaTractorLoot}
		{
			call This.Tractor
		}
		

		if ${This.Approaching} != 0
		{
			return
		}
		
		
		;	This checks to make sure there aren't any potential jet can flippers around before we dump a jetcan
		if !${Social.PlayerInRange[10000]} && ${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
		{
			if !${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)}
			{
					This:NotifyHaulers[]
			}
			
			;	This checks to make sure the player in our delivery location is in range and not warping before we dump a jetcan
			if ${Entity[Name = "${Config.Miner.DeliveryLocation}"](exists)} && ${Entity[Name = "${Config.Miner.DeliveryLocation}"].Distance} < 20000 && ${Entity[Name = "${Config.Miner.DeliveryLocation}"].Mode} != 3 && ${Ship.CargoHalfFull}
			{
				call Cargo.TransferOreToJetCan
				;	Need a wait here because it would try to move the same item more than once
				wait 20
				return
			}
		}
		

		
	}	
	
	

	
	
	
	
	
	;	If I don't add more than opening cargo, I will likely remove this function...
	function Prepare_Environment()
	{
		call Ship.OpenCargo
	}

	;	If I don't add more than collecting drones, I will likely remove this function...
	method Cleanup_Environment()
	{
		Ship.Drones:ReturnAllToDroneBay
	}
	
	;	Don't fix what isn't broke!
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

	;This method is triggered by an event.  If triggered, it tells us our orca is in a belt and can be warped to.
	method OrcaInBelt(bool State)
	{
		WarpToOrca:Set[${State}]
	}


	;This method is triggered by an event.  If triggered, it tells us how much space our hauler has available
	method HaulerMSG(int64 value)
	{
		HaulerAvailableCapacity:Set[${value}]
	}

	;This method is triggered by an event.  If triggered, it tells a team-mate is under attack by an NPC and what it is.
	method UnderAttack(int64 value)
	{
		
		AttackingTeam:Add[${value}]
		UI:UpdateConsole["Warning: Added ${value} to attackers list.  ${AttackingTeam.Used} attackers now in list."]
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
			UI:UpdateConsole["Warning: Ship attacked by rats, alerting team to kill ${CurrentAttack.Value.Name}"]
			Relay all -event EVEBot_TriggerAttack ${CurrentAttack.Value.ID}
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
				echo EVE.Bookmark[${BookmarkName}]:WarpTo[0]
				EVE.Bookmark[${BookmarkName}]:WarpTo[0]
			}
			if ${LocationID} != 0
			{
				if ${Entity[${LocationID}](exists)}
				{
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
	
	;	This function's purpose is to defend against rats which are attacking our team.  Goals:
	;	*	Keep it atomic - don't get stuck in here, killing rats quickly is NOT a concern
	;	*	Don't use up our targets, we need those for mining - Only one target should ever be used for a rat.
	function Defend()
	{
		;	This is used to keep track of what we are defending against (rats)
		variable int64 Attacking=-1

		variable iterator GetData

		
		if ${AttackingTeam.Used} > 0
		{
			AttackingTeam:GetIterator[GetData]
			if ${GetData:First(exists)}
				do
				{
					if ${Entity[${GetData.Value}](exists)} && ${Entity[${GetData.Value}].Distance} < ${Ship.OptimalTargetingRange} && ${Entity[${GetData.Value}].Distance} < ${Me.DroneControlDistance} && !${Entity[${GetData.Value}].IsLockedTarget} && !${${GetData.Value}].BeingTargeted}
						Entity[${GetData.Value}]:LockTarget
					if !${Entity[${GetData.Value}](exists)}
						AttackingTeam:Remove[${GetData.Value}]
				}
				while ${GetData:Next(exists)}
		}

		if ${Ship.Drones.DronesInSpace} > 0 && ${AttackingTeam.Used} == 0
		{
			UI:UpdateConsole["Warning: Recalling Drones"]
			Ship.Drones:ReturnAllToDroneBay
		}

		if ${Ship.Drones.DronesInSpace} == 0  && ${AttackingTeam.Used} > 0
		{
			UI:UpdateConsole["Warning: Deploying drones to defend"]
			Ship.Drones:LaunchAll
		}

		Attacking:Set[-1]
		AttackingTeam:GetIterator[GetData]
		if ${GetData:First(exists)}
			do
			{
				if ${Entity[${GetData.Value}](exists)} && ${Entity[${GetData.Value}].Distance} < ${Ship.OptimalTargetingRange} && ${Entity[${GetData.Value}].Distance} < ${Me.DroneControlDistance}
				{
					Attacking:Set[${GetData.Key}]
					break
				}
			}
			while ${GetData:Next(exists)}
			
		if ${Attacking} != -1 && ${Entity[${Attacking}].IsLockedTarget} && ${Entity[${Attacking}](exists)}
		{
			Entity[${Attacking}]:MakeActiveTarget
			wait 50 ${Me.ActiveTarget.ID} == ${Attacking}

			variable index:activedrone ActiveDroneList
			variable iterator DroneIterator
			variable index:int64 AttackDrones

			Me:GetActiveDrones[ActiveDroneList]
			ActiveDroneList:GetIterator[DroneIterator]
			if ${DroneIterator:First(exists)}
				do
				{
					echo ${DroneIterator.Value.State}
					if ${DroneIterator.Value.State} == 0
						AttackDrones:Insert[${DroneIterator.Value.ID}]
				}
				while ${DroneIterator:Next(exists)}

			if ${AttackDrones.Used} > 0
			{
				UI:UpdateConsole["Warning: Sending ${AttackDrones.Used} Drones to attack ${Entity[${Attacking}].Name}"]
				EVE:DronesEngageMyTarget[AttackDrones]
			}
		}
		
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
			if ${Config.Miner.OrcaMode} && ${Ship.CorpHangarFreeSpace} < 1000
			{
				return TRUE
			}
			if ${Ship.CargoFreeSpace} < 1000 || ${Me.Ship.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
			{
				return TRUE
			}
		}
		else
		{
			if ${Config.Miner.OrcaMode} && ${Ship.CorpHangarFreeSpace} <= ${Ship.CorpHangarMinimumFreeSpace}
			{
				return TRUE
			}
			if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${Me.Ship.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
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
				UI:UpdateConsole["Warning: Wreck empty, clearing"]
				if ${Entity[${Tractoring}].LootWindow(exists)}
				{
					Entity[${Tractoring}]:CloseCargo
				}
				if ${Ship.IsTractoringWreckID[${Tractoring}]}
				{
					Ship:Deactivate_Tractor
				}
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
					UI:UpdateConsole["Warning: ${Wrecks.Used} wrecks found"]
				}
			}
			
			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && !${Entity[${Tractoring}].LootWindow(exists)}
			{
				UI:UpdateConsole["Warning: Opening wreck"]
				Entity[${Tractoring}]:Open
				if ${Ship.IsTractoringWreckID[${Tractoring}]}
				{
					Ship:Deactivate_Tractor
				}
				return
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && ${Entity[${Tractoring}].LootWindow(exists)}
			{
				UI:UpdateConsole["Warning: Looting wreck ${Entity[${Tractoring}].Name}"]
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
				UI:UpdateConsole["Warning: Locking wreck ${Entity[${Tractoring}].Name}"]
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