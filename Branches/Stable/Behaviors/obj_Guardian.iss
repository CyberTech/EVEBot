/*

	Guardian Class

	Primary Guardian behavior module for EVEBot

	-- Tehtsuo


*/

objectdef obj_Guardian
{
	;	Versioning information
	variable string SVN_REVISION = "$Rev: 2527 $"
	variable int Version

	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	;	State information (What we're doing)
	variable string CurrentState = "IDLE"

	;	This is used to keep track of what we are approaching and when we started
	variable int64 Approaching = 0
	variable int TimeStartedApproaching = 0

	;	Search string for our Orca
	variable string Orca





/*
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will SetState.
*/

	method Initialize()
	{
		BotModules:Insert["Guardian"]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]


		UI:UpdateConsole["obj_Guardian: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Guardian]}
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
		if ${EVEBot.ReturnToStation} && ${Miner.AtPanicBookmark}
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
		if !${Social.IsSafe}  && !${EVEBot.ReturnToStation} && ${Miner.AtPanicBookmark}
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

		;	If I'm in a station, I need to leave cause there's no reason for me to be here.
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


		;	If I'm not in a station I should be defending like I'm supposed to
	 	This.CurrentState:Set["GUARDIAN"]
	}


/*
;	Step 3:		ProcessState:  This is the nervous system of the module.  EVEBot calls this; it uses the state information from SetState
;				to figure out what it needs to do.  Then, it performs the actions, sometimes using functions - think of the functions as
;				arms and legs.  Don't ask me why I feel an analogy is needed.
*/

	function ProcessState()
	{

		;	If Miner isn't the selected bot mode, this function shouldn't have been called.  However, if it was we wouldn't want it to do anything.
		if !${Config.Common.BotModeName.Equal[Guardian]}
		{
			return
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
				if ${Me.ToEntity.Mode} == 3
				{
					break
				}

				Ship.Drones:ReturnAllToDroneBay
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						;call This.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
						call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
					}
					else
					{
						call Miner.FastWarp -1 "${Config.Miner.PanicLocation}"
					}
					break
				}
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} != ${Me.SolarSystemID}
				{
					call Miner.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}
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

					call Safespots.WarpTo
					call Miner.FastWarp

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
				Miner:Cleanup_Environment
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
						call Miner.FastWarp -1 "${Config.Miner.PanicLocation}"
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
					call Miner.FastWarp
					break
				}

				UI:UpdateConsole["HARD STOP: Unable to flee, no stations available and no Safe spots available"]
				EVEBot.ReturnToStation:Set[TRUE]
				break

			;	This means we're in a station and need to do what we need to leave because it's safe and we're not a miner or a hauler
			;	*	If this isn't where we're supposed to deliver ore, we need to leave the station so we can go to the right one.
			;	*	Move ore out of cargo hold if it's there
			;	*	Undock from station
			case BASE
				call Station.Undock
				break

			;	This means we're in space and should go defend someone!  Only one choice here - GUARD!
			;	It is prudent to make sure we're not warping, since you can't guard much in warp...
			case GUARDIAN
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}
				}
				if ${Me.ToEntity.Mode} != 3
				{
					call This.Guard
				}
				break
		}
	}


/*
;	Step 4:		Mine:  This is it's own function so the ProcessState function doesn't get too giant.  There's a lot going on while mining.
;				However, it's important to remember that anything you do here keeps you in the mining state.  Until EVEBot makes it through
;				this function, it can't get back to ProcessState to start running away from hostiles and whatnot.  Therefore, keep any use of the
;				wait function to a minimum, and make sure you can get out of loops in a timely manner!
*/

	function Guard()
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


		Orca:Set[Name = "${Config.Miner.DeliveryLocation}"]
		if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${Me.ToEntity.Mode} == 3 && ${Entity[${Orca.Escape}].Mode} == 3 && ${Ship.Drones.DronesInSpace[FALSE]} != 0 && !${EVEBot.ReturnToStation}
		{
			EVE:Execute[CmdStopShip]
			while ${Ship.Drones.DronesInSpace[FALSE]} != 0
			{
				if ${Me.ToEntity.Mode} == 3
				{
					EVE:Execute[CmdStopShip]
				}
				Ship.Drones:ReturnAllToDroneBay
				wait 20
			}
		}

		if ${Config.Miner.DeliveryLocationTypeName.Equal["Orca"]} && ${Miner.WarpToOrca} && !${Entity[${Orca.Escape}](exists)}
		{
			call Ship.WarpToFleetMember ${Local[${Config.Miner.DeliveryLocation}]}
			if ${Config.Miner.BookMarkLastPosition} && ${Bookmarks.CheckForStoredLocation}
			{
				Bookmarks:RemoveStoredLocation
			}
		}


		;	This changes belts if someone's within Min. Distance to Players
		if ${Social.PlayerInRange[${Config.Miner.AvoidPlayerRange}]}
		{
			UI:UpdateConsole["Avoiding player: Changing Belts"]
			Miner:Cleanup_Environment
			call Asteroids.MoveToField TRUE
			return
		}



		variable index:fleetmember MyFleet
		variable iterator MyFleetMember
		Me.Fleet:GetMembers[MyFleet]
		MyFleet:GetIterator[MyFleetMember]
		if ${MyFleetMember:First(exists)}
			do
			{
				if !${MyFleetMember.Value.ToEntity.IsLockedTarget} && !${MyFleetMember.Value.ToEntity.BeingTargeted} && ${MyFleetMember.Value.ID} != ${Me.ID} && ${MyFleetMember.Value.ToEntity.Distance} <= ${Ship.OptimalTargetingRange}
				{
					MyFleetMember.Value.ToEntity:LockTarget
				}
			}
			while ${MyFleetMember:Next(exists)}

		variable index:entity MyTargets
		variable iterator MyTarget
		Me:GetTargets[MyTargets]
		MyTargets:GetIterator[MyTarget]

		if ${MyTarget:First(exists)}
			do
			{
				if ${Me.Fleet.IsMember[${MyTarget.Value.CharID}]}
				{
					if ${Ship.ShieldTransportersOnID[${MyTarget.Value.ID}]} > 0 && ${MyTarget.Value.ShieldPct} >= 95
					{
						call Ship.Deactivate_Shield_Transporter ${MyTarget.Value.ID}
					}
					if ${Ship.ShieldTransportersOnID[${MyTarget.Value.ID}]} == 0 && ${MyTarget.Value.ShieldPct} < 95
					{
						call Ship.ActivateFreeShieldTransporter ${MyTarget.Value.ID}
					}

					if ${Ship.ShieldTransportersOnID[${MyTarget.Value.ID}]} > 1 && ${MyTarget.Value.ShieldPct} >= 60
					{
						call Ship.Deactivate_Shield_Transporter ${MyTarget.Value.ID}
					}
					if ${Ship.ShieldTransportersOnID[${MyTarget.Value.ID}]} <= 1 && ${MyTarget.Value.ShieldPct} < 60
					{
						call Ship.ActivateFreeShieldTransporter ${MyTarget.Value.ID}
					}

				}
			}
			while ${MyTarget:Next(exists)}



		;	This calls the defense routine if Launch Combat Drones is turned on
		if ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
		{
			call Miner.Defend
		}


		;	We need to make sure we're near our orca if we're using it as a delivery location

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
				return
			}

			;	If we've been approaching for more than 2 minutes, we need to give up and try again
			if ${Math.Calc[${TimeStartedApproaching}-${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
			{
				This.Approaching:Set[0]
				This.TimeStartedApproaching:Set[0]
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
				return
			}

	}



}