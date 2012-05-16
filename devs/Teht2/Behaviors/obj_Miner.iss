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
	variable int PulseIntervalInSeconds = 1
	
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
	
	;	This is used to keep track of how much space our hauler has available
	variable int64 HaulerAvailableCapacity=-0
	
	;	This keeps track of the wreck we are tractoring
	variable int64 Tractoring=-1
	
	;	This keeps track of the wreck we are salvaging
	variable int64 Salvaging=-1
	
	;	Search string for our Orca
	variable string Orca

	
/*	
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will SetState.
*/	
	
	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		LavishScript:RegisterEvent[EVEBot_Orca_InBelt]
		Event[EVEBot_Orca_InBelt]:AttachAtom[This:OrcaInBelt]
		LavishScript:RegisterEvent[EVEBot_HaulerMSG]
		Event[EVEBot_HaulerMSG]:AttachAtom[This:HaulerMSG]
		echo ${Config.Common.BotModeName.Equal[Miner]}
		if ${Config.Common.BotModeName.Equal[Miner]}
		{
			Asteroids:EnableAsteroidList
		}
		UI:UpdateConsole["obj_Miner: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_Orca_InBelt]:DetachAtom[This:OrcaInBelt]
		Event[EVEBot_HaulerMSG]:DetachAtom[This:HaulerMSG]
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
			echo ${This.CurrentState}
			This:ProcessState[]

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
		if ${Me.InStation} && ${This.MinerFull}
		{
	  		This.CurrentState:Set["UNLOAD"]
	  		return
		}

		;	If I'm in a station, I need to perform what I came there to do
		if ${Me.InStation} && !${This.MinerFull}
		{
	  		This.CurrentState:Set["UNDOCK"]
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
		Asteroids:EnableAsteroidList
		This.CurrentState:Set["MINE"]
	}	
	
	
/*	
;	Step 3:		ProcessState:  This is the nervous system of the module.  EVEBot calls this; it uses the state information from SetState
;				to figure out what it needs to do.  Then, it performs the actions, sometimes using functions - think of the functions as 
;				arms and legs.  Don't ask me why I feel an analogy is needed.
*/			
	
	method ProcessState()
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
		
			;	This means we're somewhere safe, and SetState wants us to stay there without spamming the UI.  If we're in space, open holds.
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
				if ${Me.InStation} || !${Me.InSpace}
				{
					break
				}
				if ${CommandQueue.Queued} != 0
				{
						CommandQueue:Clear
				}
				
				This:Cleanup_Environment
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						Station:DockAtStation[${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}]
					}
					else
					{
						Ship:New_WarpToBookmark[${Config.Miner.PanicLocation}]
					}
					break
				}				
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} != ${Me.SolarSystemID}
				{
					Ship:TravelToSystem[${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}]
					break
				}
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					Station:DockAtStation[${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}]
					break
				}
				if ${Entity["CategoryID = 3"](exists)}
				{
					Station:DockAtStation[${Entity["CategoryID = 3"].ID}]
					break
				}
				if ${Me.ToEntity.Mode} != 3
				{
					if !${Safespots.WarpTo}
					{
						UI:UpdateConsole["WARNING:  EVERYTHING has gone wrong. Miner is in HARDSTOP mode and there are no panic locations, delivery locations, stations, or safe spots to use. You're probably going to get blown up..."]
					}
					break
				}
				else
				{
					break
				}
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

					Station:DockAtStation[${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}]
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
						Station:DockAtStation[${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}]
					}
					else
					{
						Ship:New_WarpToBookmark[${Config.Miner.PanicLocation}]
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
					Station:DockAtStation[${Entity["CategoryID = 3"].ID}]
					break
				}				
				
				if ${Me.ToEntity.Mode} != 3
				{
					if !${Safespots.WarpTo}
					{
						UI:UpdateConsole["HARD STOP: Unable to flee, no stations available and no Safe spots available"]
						EVEBot.ReturnToStation:Set[TRUE]
					}
					break
				}
				else
				{
					break
				}
				
				break
				
			;	This means we're in a station and need to do what we need to do and leave.
			;	*	If this isn't where we're supposed to deliver ore, we need to leave the station so we can go to the right one.
			;	*	Move ore out of cargo hold if it's there
			;	*	Undock from station
			case UNLOAD
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID} != ${Me.StationID}
				{
					UI:UpdateConsole["This isn't our Delivery Location.  Undocking to go there."]
					Station:Undock
					break
				}
				
				
				;	If we're in Orca mode, we need to unload all locations capable of holding ore, not just the cargo hold.
				;	Note:  I need to replace the shuffle with 3 direct movements
				if ${CommandQueue.Queued} == 0
				{
					if ${Config.Miner.OrcaMode}
					{
						CommandQueue:QueueCommand[Cargo,CloseHolds]
						CommandQueue:QueueCommand[Cargo,OpenHolds]
						CommandQueue:QueueCommand[Ship,OpenOreHold]
						CommandQueue:QueueCommand[Ship,OpenCorpHangars]
						CommandQueue:QueueCommand[Cargo,FindCargo,"SHIPCORPORATEHANGAR, CATEGORYID_ORE"]
						CommandQueue:QueueCommand[Cargo,TransferListStationHangar]
						CommandQueue:QueueCommand[Cargo,FindCargo,"SHIPOREHOLD, CATEGORYID_ORE"]
						CommandQueue:QueueCommand[Cargo,TransferListStationHangar]
						CommandQueue:QueueCommand[Cargo,FindCargo,"SHIP, CATEGORYID_ORE"]
						CommandQueue:QueueCommand[Cargo,TransferListStationHangar]
					}
					else
					{
						CommandQueue:QueueCommand[Cargo,CloseHolds]
						CommandQueue:QueueCommand[Cargo,OpenHolds]
						CommandQueue:QueueCommand[Cargo,FindCargo,"SHIP, CATEGORYID_ORE"]
						CommandQueue:QueueCommand[Cargo,TransferListStationHangar]
						CommandQueue:QueueCommand[Station,StackHangar]
					}
				}
				
				break

				
				
			case UNDOCK
				if ${Cargo.ReplenishCrystals}
				{
					break
				}
			
				if ${CommandQueue.Queued} == 0
				{
						CommandQueue:QueueCommand[Cargo,CloseHolds]
						CommandQueue:QueueCommand[Station,Undock]
						CommandQueue:QueueCommand[Ship,OpenCargo]
				}
				break
				
			;	This means we're in space and should mine some more ore!  Only one choice here - MINE!
			;	It is prudent to make sure we're not warping, since you can't mine much in warp...
			case MINE
				if ${CommandQueue.Queued} != 0
				{
						break
				}
				

				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					Ship:TravelToSystem[${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}]
					break
				}
				if ${Me.ToEntity.Mode} != 3
				{
					This:Mine
				}
				break
				
			;	This means we're in space and we should act like an orca.
			;	*	If we're warping, wait for that to finish up
			;	*	If Orca In Belt is enabled, call OrcaInBelt
			case ORCA
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					Ship:TravelToSystem[${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}]
					break
				}
				if ${Me.ToEntity.Mode} != 3
				{
					This:OrcaInBelt
				}
				break
				
			;	This means we need to go to our delivery location to unload.
			case DROPOFF
				if ${CommandQueue.Queued} != 0
				{
						break
				}
				if ${Me.ToEntity.Mode} == 3
				{
					return
				}			
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
						Ship:SetActiveCrystals
						
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} != ${Me.SolarSystemID}
						{
							Ship:TravelToSystem[${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}]
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							if ${CommandQueue.Queued} == 0
							{
									CommandQueue:QueueCommand[Station,DockAtStation,${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}]
									CommandQueue:QueueCommand[IGNORE]
									CommandQueue:QueueCommand[Ship,OpenCargo]
							}
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
							Ship:TravelToSystem[${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}]
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Ship:New_WarpToBookMark[${Config.Miner.DeliveryLocation}]
							
							if ${CorpHangarArray.IsReady}
							{
								Ship:Approach[${CorpHangarArray.ActiveCan}, LOOT_RANGE]
								if ${Entity[${CorpHangarArray.ActiveCan}](exists)} && ${Entity[${CorpHangarArray.ActiveCan}].Distance} < LOOT_RANGE
								{
									if ${CommandQueue.Queued} == 0
									{
											CommandQueue:QueueCommand[CorpHangarArray,Open,${CorpHangarArray.ActiveCan}]
											CommandQueue:QueueCommand[Cargo,FindCargo,"SHIP, CATEGORYID_ORE"]
											CommandQueue:QueueCommand[Cargo,TransferListToHangarInSpace,${CorpHangarArray.ActiveCan}]
											CommandQueue:QueueCommand[CorpHangarArray,StackAllCargo]
									}
									CommandQueue:ProcessCommands
								}
							}
							else
							{
								return
							}
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
							Ship:TravelToSystem[${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}]
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Ship:New_WarpToBookmark[${Config.Miner.DeliveryLocation}]
								
							if ${LargeShipAssemblyArray.IsReady}
							{
								Ship:Approach[${LargeShipAssemblyArray.ActiveCan}, LOOT_RANGE]
								if ${Entity[${LargeShipAssemblyArray.ActiveCan}](exists)} && ${Entity[${LargeShipAssemblyArray.ActiveCan}].Distance} < LOOT_RANGE
								{
									if ${CommandQueue.Queued} == 0
									{
											CommandQueue:QueueCommand[LargeShipAssemblyArray,Open,${LargeShipAssemblyArray.ActiveCan}]
											CommandQueue:QueueCommand[Cargo,FindCargo,"SHIP, CATEGORYID_ORE"]
											CommandQueue:QueueCommand[Cargo,TransferListToHangarInSpace,${LargeShipAssemblyArray.ActiveCan}]
											CommandQueue:QueueCommand[LargeShipAssemblyArray,StackAllCargo]
									}
									CommandQueue:ProcessCommands
								}
							}
							else
							{
								return
							}
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
							Ship:TravelToSystem[${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}]
							break
						}
						if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
						{
							Ship:New_WarpToBookMark[${Config.Miner.DeliveryLocation}]
							if ${XLargeShipAssemblyArray.IsReady}
							{
								Ship:Approach[${XLargeShipAssemblyArray.ActiveCan}, LOOT_RANGE]
								if ${Entity[${XLargeShipAssemblyArray.ActiveCan}](exists)} && ${Entity[${XLargeShipAssemblyArray.ActiveCan}].Distance} < LOOT_RANGE
								{
									if ${CommandQueue.Queued} == 0
									{
											CommandQueue:QueueCommand[XLargeShipAssemblyArray,Open,${XLargeShipAssemblyArray.ActiveCan}]
											CommandQueue:QueueCommand[Cargo,FindCargo,"SHIP, CATEGORYID_ORE"]
											CommandQueue:QueueCommand[Cargo,TransferListToHangarInSpace,${XLargeShipAssemblyArray.ActiveCan}]
											CommandQueue:QueueCommand[XLargeShipAssemblyArray,StackAllCargo]
									}
									CommandQueue:ProcessCommands
								}
							}
							else
							{
								return
							}
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
								;call Cargo.TransferOreToJetCan
								;	Need a wait here because it would try to move the same item more than once
								;wait 20
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

						Ship:Approach[${Entity[${Orca.Escape}].ID}, LOOT_RANGE]
						
						;	Open the Orca if it's not open yet
						if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && !${EVEWindow[ByName, ${Entity[${Orca.Escape}]}](exists)}
						{
							Entity[${Orca.Escape}]:OpenCorpHangars
							break
						}
						
						if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && ${EVEWindow[ByName, ${Entity[${Orca.Escape}]}](exists)}
						{
							if ${CommandQueue.Queued} == 0
							{
									CommandQueue:QueueCommand[Cargo,FindCargo,"SHIP, CATEGORYID_ORE"]
									CommandQueue:QueueCommand[Cargo,TransferListToHangarInSpace,${Entity[${Orca.Escape}].ID}]
							}
							CommandQueue:ProcessCommands
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
		
	method Mine()
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
		
		if ${Ship.TotalActivatedMiningLasers} != ${Ship.TotalMiningLasers}
		{
		
			;	Find an asteroid field, or stay at current one if we're near one.  Choices are:
			;	*	If WarpToOrca and the orca is in fleet, warp there instead and clear our saved bookmark
			;	*	Warp to a belt based on belt labels or a random belt
			
			Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]

			if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${WarpToOrca} && !${Entity[${Orca.Escape}](exists)}
			{
				Ship:WarpToFleetMember[${Local[${Config.Miner.DeliveryLocation}]}]
				if ${Config.Miner.BookMarkLastPosition} && ${Bookmarks.CheckForStoredLocation}
				{
					Bookmarks:RemoveStoredLocation
				}
			}
			if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${Entity[${Orca.Escape}](exists)}
			{
				Asteroids.DistanceTarget:Set[${Entity[${Orca.Escape}].ID}]
			}

			Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
			if ${Ship.TotalActivatedMiningLasers} == 0 && ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${Me.ToEntity.Mode} == 3 && ${Entity[${Orca.Escape}].Mode} == 3 && ${Ship.Drones.DronesInSpace} != 0 && !${EVEBot.ReturnToStation}
			{
				if ${Me.ToEntity.Mode} == 3
				{
					EVE:Execute[CmdStopShip]				
				}
				Ship.Drones:ReturnAllToDroneBay
				return
			}
			
			if ${Asteroids.AsteroidList.Used} == 0 && !${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]}
			{	
				if ${Ship.Drones.DronesInSpace} != 0	
				{
					if ${Me.ToEntity.Mode} == 3
					{
						EVE:Execute[CmdStopShip]				
					}
					Ship.Drones:ReturnAllToDroneBay
				}
				CommandQueue:QueueCommand[Asteroids,MoveToField,"FALSE, FALSE"]
				CommandQueue:QueueCommand[IGNORE]
				CommandQueue:QueueCommand[IGNORE]
				CommandQueue:QueueCommand[IGNORE]
				CommandQueue:QueueCommand[IGNORE]
				CommandQueue:QueueCommand[IGNORE]
				CommandQueue:QueueCommand[IGNORE]
				CommandQueue:QueueCommand[IGNORE]
				return
			}
			This:Prepare_Environment
		}

		;	If our ship has no mining lasers, panic so the user knows to correct their configuration and try again
		if ${Ship.TotalMiningLasers} == 0
		{
			UI:UpdateConsole["ALERT: No mining lasers detected.  Switching to HARD STOP mode!"]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}


		;	This changes belts if someone's within Min. Distance to Players
		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			UI:UpdateConsole["Avoiding player: Changing Belts"]
			Ship.Drones:ReturnAllToDroneBay
			Asteroids:MoveToField[TRUE]
			return
		}
		

		;	We need to make sure we're near our orca if we're using it as a delivery location
		if ${Config.Miner.DeliveryLocationTypeName.Equal[Orca]}
		{
			Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]

			Ship:Approach[${Entity[${Orca.Escape}].ID}, LOOT_RANGE, TRUE]
			
			;	This performs Orca deliveries if we've got at least a tenth of our cargo hold full
			if ${Ship.CargoTenthFull}
			{
				;	Open the Orca if it's not open yet
				if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && !${EVEWindow[ByName, ${Entity[${Orca.Escape}]}](exists)}
				{
					Entity[${Orca.Escape}]:OpenCorpHangars
					return
				}
				
				if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && ${EVEWindow[ByName, ${Entity[${Orca.Escape}]}](exists)}
				{
					Cargo:FindCargo[SHIP, CATEGORYID_ORE]
					Cargo:TransferListToHangarInSpace[${Entity[${Orca.Escape}].ID}]
					Cargo:FindCargo[SHIP, 4]
					Cargo:TransferListToHangarInSpace[${Entity[${Orca.Escape}].ID}]
					This:StackAll
				}
			}

			if ${Entity[${Orca.Escape}](exists)} && ${Entity[${Orca.Escape}].Distance} <= LOOT_RANGE && ${EVEWindow[ByName, ${Entity[${Orca.Escape}]}](exists)}
			{
				;echo ${Cargo.ReplenishCrystals[${Entity[${Orca.Escape}]}]}
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
				variable bool LockedNewTarget
				Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
				if ${Config.Miner.DeliveryLocationTypeName.Equal[Orca]} && ${Entity[${Orca.Escape}](exists)} && !${Config.Miner.IceMining}
				{
					LockedNewTarget:Set[${Asteroids.TargetNextInRange[${Entity[${Orca.Escape}].ID}]}]
					if !${LockedNewTarget}
					{
						return
					}
				}
				elseif !${Config.Miner.DeliveryLocationTypeName.Equal[Orca]} || ${Config.Miner.IceMining}
				{
					LockedNewTarget:Set[${Asteroids.TargetNext}]
					if !${LockedNewTarget}
					{
						return
					}
				}
				AsteroidsLocked:Inc

			}
			
			;	We don't need to lock another asteroid.  Let's find out if we need to signal a concentrate fire based on limitations of our ship.
			;	Either our target count more than we can safely lock, or we have more mining lasers than we can safely lock.
			; else
			; {
				; if ${Asteroids.LockedAndLocking} >= ${Ship.SafeMaxLockedTargets} &&  ${Ship.TotalMiningLasers} > ${Ship.SafeMaxLockedTargets}
				; {
					; This.ConcentrateFire:Set[TRUE]
				; }
			; }
			
		}

		;	Time to get those lasers working!
		if ${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers}
		{
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
				if (${Asteroids.ConcentrateFire} || ${Config.Miner.IceMining} || !${Config.Miner.DistributeLasers}) || !${Ship.IsMiningAsteroidID[${Target.Value.ID}]}
				{
					echo Ship approaching: ${Ship.Approaching} - ${Entity[${Ship.ApproachingID}].Name}
					if !${Ship.Approaching}
					{
						Ship:Approach[${Target.Value.ID}, ${Ship.OptimalMiningRange[1]}]
					}

					;	The target is locked, it's our active target, and we should be in range.  Get a laser on that puppy!
					if ${Entity[${Target.Value.ID}].Distance} <= ${Ship.OptimalMiningRange[1]}
					{
						Ship:ActivateFreeMiningLaser[${Target.Value.ID}]
						return
					}

				}
			}
			while ${Target:Next(exists)}
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
				;call Cargo.TransferOreToJetCan
				;	Need a wait here because it would try to move the same item more than once
				;wait 20
				return
			}
		}
		
		if ${Ship.TotalSalvagers} != 0
		{
			This:Salvage
		}
		
	}	


/*	
;	Step 5:		OrcaInBelt:  This is it's own function so the ProcessState function doesn't get too giant.  This is mostly because it's just a trimmed
;				down version of This.Mine.  However, as with the miner, it's important to remember that anything you do here keeps you in the Orca state.  
;				Until EVEBot makes it through this function, it can't get back to ProcessState to start running away from hostiles and whatnot.
;				Therefore, keep any use of the wait function to a minimum, and make sure you can get out of loops in a timely manner!
*/		
		
	method OrcaInBelt()
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
		Asteroids.AsteroidList:GetIterator[AsteroidIterator]
		if !${AsteroidIterator:First(exists)}
		{
			if ${Ship.Drones.DronesInSpace} != 0
			{
				Ship.Drones:ReturnAllToDroneBay
				return
			}
			Asteroids:MoveToField[FALSE, TRUE]
		}
		This:Prepare_Environment


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
			Asteroids:MoveToField[TRUE, TRUE]
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
		if ${Entity[${Asteroids.NearestAsteroid}](exists)}
		{
			Ship:Approach[${Asteroids.NearestAsteroid}, ${OrcaRange}]
		}


		
		;	This section is for moving ore into the ore and cargo holds, so they will fill before the Corporate Hangar
		Ship:OpenOreHold
		Ship:OpenCorpHangars
		This:Prepare_Environment
		
		if !${Ship.CorpHangarEmpty}
		{
			if !${Ship.OreHoldFull} && !${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]} && !${Config.Miner.DeliveryLocationTypeName.Equal["Jetcan"]}
			{
				Cargo:TransferCargoFromShipCorporateHangarToOreHold
				Ship:StackOreHold
				return
			}
			if !${Ship.CargoFull} && !${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]}
			{
				Cargo:TransferCargoFromShipCorporateHangarToCargoHold
				Ship:StackCargoHold
				return
			}
			if ${Config.Miner.DeliveryLocationTypeName.Equal["No Delivery"]}
			{
				Cargo:TransferCargoFromCargoHoldToShipCorporateHangar
				relay all -event EVEBot_Orca_Cargo ${Ship.CorpHangarUsedSpace[TRUE]}
			}
		}
		

		if ${Config.Miner.OrcaTractorLoot}
		{
			This:Tractor
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
				;call Cargo.TransferOreToJetCan
				;	Need a wait here because it would try to move the same item more than once
				;wait 20
				return
			}
		}
		

		
	}	
	
	

	
	
	
	
	
	;	If I don't add more than opening cargo, I will likely remove this function...
	method Prepare_Environment()
	{
		Ship:OpenCargo
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

	method Tractor()
	{
		if ${Ship.TotalTractorBeams} > 0
		{
			variable index:entity Wrecks

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} < LOOT_RANGE && ${Entity[${Tractoring}].IsWreckEmpty}
			{
				UI:UpdateConsole["Warning: Wreck empty, clearing"]
				if ${Entity[${Tractoring}].LootWindow(exists)}
				{
					Entity[${Tractoring}]:CloseCargo
				}
				if ${Entity[${Tractoring}].IsLockedTarget}
				{
					Entity[${Tractoring}]:UnlockTarget
				}
				Tractoring:Set[-1]
			}
			
			if ${Tractoring} == -1
			{
				variable iterator Wreck
				Wrecks:Clear
				EVE:QueryEntities[Wrecks,${LavishScript.CreateQuery[GroupID = 186 && HaveLootRights && Distance < ${Ship.OptimalTractorRange} && Distance < ${Ship.OptimalTargetingRange}]}]

				Wrecks:GetIterator[Wreck]
				if ${Wreck:First(exists)}
					do
					{
						if !${Wreck.Value.IsWreckEmpty} || ${Wreck.Value.Distance} > LOOT_RANGE
						Tractoring:Set[${Wreck.Value.ID}]
						UI:UpdateConsole["${Wrecks.Used} wrecks found"]
					}
					while ${Wreck:Next(exists)}
			}
			
			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && !${Entity[${Tractoring}].LootWindow(exists)} && !${Entity[${Tractoring}].IsWreckEmpty}
			{
				UI:UpdateConsole["Opening wreck ${Entity[${Tractoring}].Name}"]
				Entity[${Tractoring}]:OpenCargo
				if ${Ship.IsTractoringWreckID[${Tractoring}]}
				{
					Ship:Deactivate_Tractor
				}
				return
			}

			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].Distance} <= LOOT_RANGE && ${Entity[${Tractoring}].LootWindow(exists)}
			{
				UI:UpdateConsole["Looting wreck ${Entity[${Tractoring}].Name}"]
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
			
			if ${Entity[${Tractoring}](exists)} && !${Entity[${Tractoring}].IsLockedTarget} && ${Entity[${Tractoring}].Distance} > LOOT_RANGE
			{
				UI:UpdateConsole["Warning: Locking wreck ${Entity[${Tractoring}].Name}"]
				Entity[${Tractoring}]:LockTarget
				return
			}
			if ${Entity[${Tractoring}](exists)} && ${Entity[${Tractoring}].IsLockedTarget} && !${Ship.IsTractoringWreckID[${Tractoring}]}
			{
				Ship:ActivateFreeTractorBeam[${Entity[${Tractoring}].ID}]
				return
			}
		}
	}
	

	
	method Salvage()
	{
		variable index:entity Wrecks

		if 	${Me.TargetingCount} != 0
		{
			return
		}
				
		if ${WrecksLockedAndLocking} == 0
		{
			Wrecks:Clear
			EVE:QueryEntities[Wrecks,${LavishScript.CreateQuery[GroupID = 186 && HaveLootRights && Distance < ${Ship.OptimalSalvageRange} && IsWreckEmpty]}]

			if ${Wrecks.Used} > 0
			{
				Salvaging:Set[${Wrecks[1]}]
				UI:UpdateConsole["Warning: ${Wrecks.Used} empty wrecks found"]
			}
		}
				
		if ${Entity[${Salvaging}](exists)} && !${Entity[${Salvaging}].IsLockedTarget}
		{
			UI:UpdateConsole["Warning: Locking wreck ${Entity[${Salvaging}].Name}"]
			Entity[${Salvaging}]:LockTarget
			return
		}
		
		if ${Entity[${Salvaging}](exists)} && ${Entity[${Salvaging}].IsLockedTarget} && !${Ship.IsSalvagingWreckID[${Salvaging}]}
		{
			Ship:Activate_Salvager[${Entity[${Salvaging}].ID}]
			return
		}
	}	
	
	member:int WrecksLockedAndLocking()
	{
		variable iterator Target
		variable int AsteroidsLocked=0
		Targets:UpdateLockedAndLockingTargets
		Targets.LockedOrLocking:GetIterator[Target]

		if ${Target:First(exists)}
		do
		{
			if ${Target.Value.CategoryID} == 186
			{
				AsteroidsLocked:Inc
			}
		}
		while ${Target:Next(exists)}
		return ${AsteroidsLocked}
	}
	
	method StackAll()
	{
		variable index:evewindow Windows
		variable iterator iWindow
		EVE:GetEVEWindows[Windows]
		Windows:GetIterator[iWindow]
		if ${iWindow:First(exists)}
		{
			do
			{
				iWindow.Value:StackAll
			}
			while ${iWindow:Next(exists)}
		}
	}
	
}