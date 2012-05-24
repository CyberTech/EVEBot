/*
	Hauler Class

	Primary Hauler behavior module for EVEBot

	-- Tehtsuo

	(Recycled mainly from GliderPro I believe)
*/


objectdef obj_FullMiner
{
	variable int64 FleetMemberID
	variable int64 SystemID
	variable int64 BeltID

	method Initialize(int64 arg_FleetMemberID, int64 arg_SystemID, int64 arg_BeltID)
	{
		FleetMemberID:Set[${arg_FleetMemberID}]
		SystemID:Set[${arg_SystemID}]
		BeltID:Set[${arg_BeltID}]
		UI:UpdateConsole[ "DEBUG: obj_OreHauler:FullMiner: FleetMember: ${FleetMemberID} System: ${SystemID} Belt: ${Entity[${BeltID}].Name}", LOG_DEBUG]
	}
}

objectdef obj_Hauler
{
	;	Versioning information
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable collection:obj_FullMiner FullMiners

	;	State information (What we're doing)
	variable string CurrentState

	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	;	Used to get Fleet information
	variable queue:fleetmember FleetMembers
	variable index:entity     Entities

	;	This is used to keep track of what we are approaching and when we started
	variable int64 Approaching = 0
	variable int TimeStartedApproaching = 0

	;	This is used to keep track of how much cargo our orca has ready
	variable float OrcaCargo=-1


/*
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will SetState.
*/

	method Initialize()
	{
		UI:UpdateConsole["obj_OreHauler: Initialized", LOG_MINOR]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		LavishScript:RegisterEvent[EVEBot_Miner_Full]
		Event[EVEBot_Miner_Full]:AttachAtom[This:MinerFull]
		LavishScript:RegisterEvent[EVEBot_Orca_Cargo]
		Event[EVEBot_Orca_Cargo]:AttachAtom[This:OrcaCargoUpdate]
		BotModules:Insert["Hauler"]
	}


	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Hauler]}
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

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_Miner_Full]:DetachAtom[This:MinerFull]
		Event[EVEBot_Orca_Cargo]:DetachAtom[This:OrcaCargoUpdate]
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
		if !${Social.IsSafe}  && !${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["FLEE"]
			UI:UpdateConsole["FLEE: Low Standing player or system unsafe, fleeing"]
			return
		}
		if !${Social.IsSafe}  && !${EVEBot.ReturnToStation} && ${Me.InStation}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		;	If I'm in a station, and servicing an orca, wait until the orca needs serviced.
		;	Note: Due to "BASE" state causing undock after unload, this needs to be here.
		;	TODO: Clean up "BASE" state to enter "IDLE" state depending on hauler mode.
		if ${Config.Hauler.HaulerModeName.Equal["Service Orca"]} && (${OrcaCargo} < ${Config.Miner.CargoThreshold} && ${OrcaCargo} < 35000) && ${Me.InStation} && ${OrcaCargo} != -1
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		;	If I'm in a station, and servicing on demand, wait until someone needs serviced.
		;	Note: Due to "BASE" state causing undock after unload, this needs to be here.
		;	TODO: Clean up "BASE" state to enter "IDLE" state depending on hauler mode.
		if ${Config.Hauler.HaulerModeName.Equal["Service On-Demand"]} && ${Me.InStation} && !${FullMiners.FirstValue(exists)}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		;	If I'm in a station, I need to perform what I came there to do
		if ${Me.InStation} && (!${Config.Hauler.HaulerModeName.Equal["Service Orca"]} || (${OrcaCargo} > ${Config.Miner.CargoThreshold} || ${OrcaCargo} > 35000) || ${OrcaCargo} == -1)
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}


		;	If I'm not in a station and I'm full, I should head to a station to unload - Ignore dropoff if Orca Delivery is disabled.
	    if ${This.HaulerFull}
		{
			This.CurrentState:Set["DROPOFF"]
			return
		}

		;	If I'm not in a station and I have room to haul more, that's what I should do!
		if !${This.HaulerFull}
		{
		 	This.CurrentState:Set["HAUL"]
			return
		}

		This.CurrentState:Set["Unknown"]
	}


/*
;	Step 3:		ProcessState:  This is the nervous system of the module.  EVEBot calls this; it uses the state information from SetState
;				to figure out what it needs to do.  Then, it performs the actions, sometimes using functions - think of the functions as
;				arms and legs.  Don't ask me why I feel an analogy is needed.
*/

	function ProcessState()
	{
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
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						call Miner.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
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
					call Miner.FastWarp ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					break
				}
				if ${Entity["CategoryID = 3"](exists)}
				{
					UI:UpdateConsole["Docking at ${Entity["CategoryID = 3"].Name}"]
					call Miner.FastWarp ${Entity["CategoryID = 3"].ID}
					call Station.DockAtStation ${Entity["CategoryID = 3"].ID}
					break
				}
				if ${Me.ToEntity.Mode} != 3
				{
					call Safespots.WarpTo
					call Miner.FastWarp
					wait 30
				}

				UI:UpdateConsole["WARNING:  EVERYTHING has gone wrong. Hauler is in HARDSTOP mode and there are no panic locations, delivery locations, stations, or safe spots to use. You're probably going to get blown up..."]
				break

			;	This means there's something dangerous in the system, but once it leaves we're going to go back to mining.
			;	*	Stay in a station if we're there
			;	*	If our delivery location is in the same system, dock there
			;	*	If we have a panic location and it's in the same system, dock there
			;	*	If there are any stations in this system, dock there
			;	*	Otherwise, check if we're warping and warp to a safe spot
			;	*	If none of these work, something is terribly wrong, and we need to panic!
			case FLEE
				if ${Me.InStation}
				{
					break
				}
				if ${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					call Miner.FastWarp ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
					break
				}
				if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID} == ${Me.SolarSystemID}
				{
					if ${EVE.Bookmark[${Config.Miner.PanicLocation}](exists)} && ${EVE.Bookmark[${Config.Miner.PanicLocation}].TypeID} != 5
					{
						call Miner.FastWarp ${EVE.Bookmark[${Config.Miner.PanicLocation}].ItemID}
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
					UI:UpdateConsole["Docking at ${Entity["CategoryID = 3"].Name}"]
					call Miner.FastWarp ${Entity["CategoryID = 3"].ID}
					call This.DockAtStation ${Entity["CategoryID = 3"].ID}
					break
				}

				if ${Me.ToEntity.Mode} != 3
				{
					call Safespots.WarpTo
					call Miner.FastWarp
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
				echo WHY ARE WE IN BASE MODE
				call Cargo.TransferCargoToHangar
				call Station.Undock
				relay all -event EVEBot_HaulerMSG ${Ship.CargoFreeSpace}
				break


			case HAUL
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)} && ${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}
				}

				switch ${Config.Hauler.HaulerModeName}
				{
					case Service On-Demand
						call This.HaulOnDemand
						break
					case Service Fleet Members
						call This.HaulForFleet
						break
					case Service Orca
						call This.ServiceOrca
						break
					case Jetcan Mode (Flip-guard)
						call This.FlipGuard
						break
				}
				break

			case DROPOFF
				call This.DropOff
				break
		}
	}


/*
;	HaulOnDemand
;	*	Warp to fleet member and loot nearby cans
;	*	Warp to next safespot
*/
	function HaulOnDemand()
	{
		if ${Me.ToEntity.Mode} == 3
			return

		if ${FullMiners.FirstValue(exists)}
		{
			UI:UpdateConsole["${FullMiners.Used} cans to get! Picking up can at ${FullMiners.FirstKey}", LOG_DEBUG]

			if !${Local[${FullMiners.CurrentValue.FleetMemberID}](exists)}
			{
				UI:UpdateConsole["ALERT:  The specified fleet member isn't in local - it may be incorrectly configured or out of system."]
				return
			}


			if !${Entity[${Local[${FullMiners.CurrentValue.FleetMemberID}].ToEntity.ID}](exists)}
			{
				UI:UpdateConsole["ALERT:  The fleet member is not nearby.  Warping there first to pick up."]
				Local[${FullMiners.CurrentValue.FleetMemberID}].ToFleetMember:WarpTo
				return
			}

			;	Find out if we need to approach this target
			if ${Entity[${Local[${FullMiners.CurrentValue.FleetMemberID}].ToEntity.ID}].Distance} > LOOT_RANGE && ${This.Approaching} == 0
			{
				UI:UpdateConsole["ALERT:  Approaching to within loot range."]
				Entity${Local[${FullMiners.CurrentValue.FleetMemberID}].ToEntity.ID}]:Approach
				This.Approaching:Set[${Local[${FullMiners.CurrentValue.FleetMemberID}].ToEntity.ID}]
				This.TimeStartedApproaching:Set[${Time.Timestamp}]
			}

			;	If we've been approaching for more than 2 minutes, we need to give up and try again
			if ${Math.Calc[${TimeStartedApproaching}-${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
			{
				This.Approaching:Set[0]
				This.TimeStartedApproaching:Set[0]
			}

			;	If we're approaching a target, find out if we need to stop doing so
			if ${Entity[${This.Approaching}](exists)} && ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE && ${This.Approaching} != 0
			{
				UI:UpdateConsole["ALERT:  Within loot range."]
				EVE:Execute[CmdStopShip]
				This.Approaching:Set[0]
				This.TimeStartedApproaching:Set[0]
			}

			call This.FlipGuardLoot
			FullMiners:Erase[${FullMiners.FirstKey}]
		}
		elseif !${This.HaulerFull}
		{
			echo hauler not full
			call Safespots.WarpTo
		}
	}

/*
;	HaulForFleet
;	*	Warp to fleet member and loot nearby cans
;	*	Repeat until cargo hold is full
*/
	function HaulForFleet()
	{
		if ${FleetMembers.Used} == 0
		{
			This:BuildFleetMemberList
			call Safespots.WarpTo
		}
		else
		{
			if ${FleetMembers.Peek(exists)} && ${Local[${FleetMembers.Peek.ToPilot.Name}](exists)}
			{
				call This.WarpToFleetMemberAndLoot ${FleetMembers.Peek.CharID}
			}
			FleetMembers:Dequeue
		}
	}

/*
;	ServiceOrca
;	*	Warp to Orca
;	*	Approach
;	*
*/
	function ServiceOrca()
	{
		if !${Local[${Config.Hauler.HaulerPickupName}](exists)}
		{
			UI:UpdateConsole["ALERT:  The specified orca isn't in local - it may be incorrectly configured or out of system."]
			return
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return
		}

		variable int64 OrcaID
		if ${Entity[Name = "${Config.Hauler.HaulerPickupName}"](exists)}
		{
			OrcaID:Set[${Entity[Name = "${Config.Hauler.HaulerPickupName}"]}]
		}
		else
		{
			OrcaID:Set[0]
		}

		if ${OrcaCargo} < ${Config.Miner.CargoThreshold} && ${OrcaCargo} < 35000  && ${OrcaCargo} != -1 && ${OrcaID} != 0
		{
			return
		}

		if !${OrcaID} && ${Local[${Config.Hauler.HaulerPickupName}].ToFleetMember}
		{
			UI:UpdateConsole["ALERT: The orca is not nearby.  Warping there first to pick up."]
			Local[${Config.Hauler.HaulerPickupName}].ToFleetMember:WarpTo
			return
		}

		;	Find out if we need to approach this target
		if ${Entity[${OrcaID}].Distance} > LOOT_RANGE && ${This.Approaching} == 0
		{
			UI:UpdateConsole["ALERT: Approaching to within loot range."]
			Entity[${OrcaID}]:Approach
			This.Approaching:Set[${OrcaID}]
			This.TimeStartedApproaching:Set[${Time.Timestamp}]
			return
		}

		;	If we've been approaching for more than 2 minutes, we need to give up and try again
		if ${Math.Calc[${TimeStartedApproaching}-${Time.Timestamp}]} < -120 && ${This.Approaching} != 0
		{
			This.Approaching:Set[0]
			This.TimeStartedApproaching:Set[0]
		}

		;	If we're approaching a target, find out if we need to stop doing so
		if ${Entity[${This.Approaching}](exists)} && ${Entity[${This.Approaching}].Distance} <= LOOT_RANGE && ${This.Approaching} != 0
		{
			UI:UpdateConsole["ALERT: Within loot range."]
			EVE:Execute[CmdStopShip]
			This.Approaching:Set[0]
			This.TimeStartedApproaching:Set[0]
		}

		;	Open the Orca if it's not open yet
		if ${OrcaID} && ${Entity[${OrcaID}].Distance} <= LOOT_RANGE
		{
			if !${EVEWindow[ByItemID, ${OrcaID}](exists)}
			{
				UI:UpdateConsole["ALERT: Open Hangar."]
				Entity[${OrcaID}]:Open
				return
			}
			UI:UpdateConsole["ALERT: Transferring Cargo"]
			call Cargo.TransferListFromShipCorporateHangar ${OrcaID}
		}

		return
	}

/*
;	Jetcan Mode (Flip-guard)
;	*	Warp to fleet member and get in range
;	*	Warp to next safespot
*/
	function FlipGuard()
	{
		variable string Orca
		Orca:Set[Name = "${Config.Hauler.HaulerPickupName}"]
		if !${Local[${Config.Hauler.HaulerPickupName}](exists)}
		{
			UI:UpdateConsole["ALERT:  The specified player isn't in local - it may be incorrectly configured or out of system."]
			return
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return
		}

		if !${Entity[${Orca.Escape}](exists)} && ${Local[${Config.Hauler.HaulerPickupName}].ToFleetMember}
		{
			UI:UpdateConsole["ALERT:  The player is not nearby.  Warping there first to unload."]
			Local[${Config.Hauler.HaulerPickupName}].ToFleetMember:WarpTo
			return
		}

		call This.FlipGuardLoot
	}



	function FlipGuardLoot()
	{

		if ${This.HaulerFull}
		{
			return
		}

		if ${Entity["OwnerID = ${charID} && CategoryID = 6"].Distance} > CONFIG_MAX_SLOWBOAT_RANGE
		{
			if ${Entity["OwnerID = ${charID} && CategoryID = 6"].Distance} < WARP_RANGE
			{
				UI:UpdateConsole["Fleet member is too far for approach; warping to a bounce point"]
				call Safespots.WarpTo TRUE
			}
			call Ship.WarpToFleetMember ${charID}
		}

		call Ship.OpenCargo

		This:BuildJetCanList

		variable iterator Ent
		Entities:GetIterator[Ent]
		if ${Ent:First(exists)}
		do
		{
			call Ship.OpenCargo

			Ent.Value:Approach

			; approach within tractor range and tractor entity
			variable float ApproachRange = ${Ship.OptimalTractorRange}
			if ${ApproachRange} > ${Ship.OptimalTargetingRange}
			{
				ApproachRange:Set[${Ship.OptimalTargetingRange}]
			}

			if ${Ship.OptimalTractorRange} > 0
			{
				variable int Counter
				if ${Ent.Value.Distance} > ${Ship.OptimalTargetingRange}
				{
					call Ship.Approach ${Ent.Value.ID} ${Ship.OptimalTargetingRange}
				}

				Ent.Value:Approach
				Ent.Value:LockTarget

				wait 10 ${Ent.Value.BeingTargeted} || ${Ent.Value.IsLockedTarget}
				if !${Ent.Value.BeingTargeted} && !${Ent.Value.IsLockedTarget}
				{
					UI:UpdateConsole["Hauler: Failed to target, retrying"]
					Ent.Value:LockTarget
					wait 10 ${Ent.Value.BeingTargeted} || ${Ent.Value.IsLockedTarget}
				}
				if ${Ent.Value.Distance} > ${Ship.OptimalTractorRange}
				{
					call Ship.Approach ${Ent.Value.ID} ${Ship.OptimalTractorRange}
				}
				Counter:Set[0]
				while !${Ent.Value.IsLockedTarget} && ${Counter:Inc} < 300
				{
					wait 1
				}
				Ent.Value:MakeActiveTarget
				Counter:Set[0]
				while !${Me.ActiveTarget.ID.Equal[${Ent.Value.ID}]} && ${Counter:Inc} < 300
				{
					wait 1
				}
				Ship:Activate_Tractor
			}

			if ${Ent.Value.Distance} >= ${LOOT_RANGE}
			{
				call Ship.Approach ${Ent.Value.ID} LOOT_RANGE
			}
			Ship:Deactivate_Tractor
			EVE:Execute[CmdStopShip]

			if ${Ent.Value.ID.Equal[0]}
			{
				UI:Updateconsole["Hauler: Jetcan disappeared suddently. WTF?"]
				continue
			}


			call This.LootEntity ${Ent.Value.ID} 0
			if ${This.HaulerFull}
			{
				relay all -event EVEBot_HaulerMSG ${Ship.CargoFreeSpace}
				FullMiners:Clear
				break
			}
		}
		while ${Ent:Next(exists)}

		FullMiners:Erase[${charID}]
	}






	method OrcaCargoUpdate(float value)
	{
		OrcaCargo:Set[${value}]
	}








	;	Jetcan full, add it to FullMiners
	method MinerFull(string haulParams)
	{
		variable int64 charID = -1
		variable int64 systemID = -1
		variable int64 beltID = -1

		if !${Config.Common.BotModeName.Equal[Hauler]}
		{
			return
		}

		charID:Set[${haulParams.Token[1,","]}]
		systemID:Set[${haulParams.Token[2,","]}]
		beltID:Set[${haulParams.Token[3,","]}]

		; Logging is done by obj_FullMiner initialize
		FullMiners:Set[${charID},${charID},${systemID},${beltID}]
	}



	function LootEntity(int64 id, int leave = 0)
	{
		variable index:item ContainerCargo
		variable iterator Cargo
		variable int QuantityToMove

		if ${id.Equal[0]}
		{
			return
		}

		UI:UpdateConsole["obj_OreHauler.LootEntity ${Entity[${id}].Name}(${id}) - Leaving ${leave} units"]

		Entity[${id}]:Open
		wait 20
		Entity[${id}]:GetCargo[ContainerCargo]
		ContainerCargo:GetIterator[Cargo]
		if ${Cargo:First(exists)}
		{
			do
			{
				UI:UpdateConsole["Hauler: Found ${Cargo.Value.Quantity} x ${Cargo.Value.Name} - ${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}m3"]
				if (${Cargo.Value.Quantity} * ${Cargo.Value.Volume}) > ${Ship.CargoFreeSpace}
				{
					/* Move only what will fit, minus 1 to account for CCP rounding errors. */
					QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${Cargo.Value.Volume}]}]
				}
				else
				{
					QuantityToMove:Set[${Math.Calc[${Cargo.Value.Quantity} - ${leave}]}]
					leave:Set[0]
				}

				UI:UpdateConsole["Hauler: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
				if ${QuantityToMove} > 0
				{
					Cargo.Value:MoveTo[MyShip,CargoHold,${QuantityToMove}]
					wait 30
					if ${Ship.CargoFreeSpace} < 1000
					{
						break
					}
				}

				if ${Ship.CargoFreeSpace} < 1000
				{
					/* TODO - this needs to keep a queue of bookmarks, named for the can ie, "Can CORP hh:mm", of partially looted cans */
					/* Be sure its names, and not ID.  We shouldn't store anything in a bookmark name that we shouldnt know */

					UI:UpdateConsole["DEBUG: obj_Hauler.LootEntity: Ship Cargo Free Space: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
					break
				}
			}
			while ${Cargo:Next(exists)}
		}

		EVEWindow[ByItemID,${MyShip.ID}]:StackAll
		wait 10
		;EVEWindow[ByItemID,${MyShip.ID}]:Close
		;wait 10
	}


	function DropOff()
	{
		if !${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)}
		{
			UI:UpdateConsole["ERROR: ORE Delivery location & type must be specified (on the miner tab) - docking"]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}
		switch ${Config.Miner.DeliveryLocationTypeName}
		{
			case Station
				call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
				call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
				break
			case Hangar Array
				call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
				call Cargo.TransferOreToCorpHangarArray
				break
			case Large Ship Assembly Array
				echo Warp to LSAA
				call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
				echo Cargo LSAA
				call Cargo.TransferCargoToLargeShipAssemblyArray
				break
			case XLarge Ship Assembly Array
				call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
				call Cargo.TransferOreToXLargeShipAssemblyArray
				break
			case Jetcan
				UI:UpdateConsole["ERROR: ORE Delivery location may not be jetcan when in hauler mode - docking"]
				EVEBot.ReturnToStation:Set[TRUE]
				break
			Default
				UI:UpdateConsole["ERROR: Delivery Location Type ${Config.Miner.DeliveryLocationTypeName} unknown"]
				EVEBot.ReturnToStation:Set[TRUE]
				break
		}
	}



	function WarpToFleetMemberAndLoot(int64 charID)
	{
		variable int64 id = 0

		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{	/* if we are already full ignore this request */
			return
		}

		if !${Entity["OwnerID = ${charID} && CategoryID = 6"](exists)}
		{
			call Ship.WarpToFleetMember ${charID}
		}

		if ${Entity["OwnerID = ${charID} && CategoryID = 6"].Distance} > CONFIG_MAX_SLOWBOAT_RANGE
		{
			if ${Entity["OwnerID = ${charID} && CategoryID = 6"].Distance} < WARP_RANGE
			{
				UI:UpdateConsole["Fleet member is too far for approach; warping to a bounce point"]
				call Safespots.WarpTo TRUE
			}
			call Ship.WarpToFleetMember ${charID}
		}

		call Ship.OpenCargo

		This:BuildJetCanList[${charID}]
		while ${Entities.Peek(exists)}
		{
			variable int64 PlayerID
			variable bool PopCan = FALSE

			; Find the player who owns this can
			if ${Entity["OwnerID = ${charID} && CategoryID = 6"](exists)}
			{
				PlayerID:Set[${Entity["OwnerID = ${charID} && CategoryID = 6"].ID}]
			}

			call Ship.Approach ${PlayerID} LOOT_RANGE

			if ${Entities.Peek.Distance} >= ${LOOT_RANGE} && \
				(!${Entity[${PlayerID}](exists)} || ${Entity[${PlayerID}].DistanceTo[${Entities.Peek.ID}]} > LOOT_RANGE)
			{
				UI:UpdateConsole["Checking: ID: ${Entities.Peek.ID}: ${Entity[${PlayerID}].Name} is ${Entity[${PlayerID}].DistanceTo[${Entities.Peek.ID}]}m away from jetcan"]
				PopCan:Set[TRUE]

				if !${Entities.Peek(exists)}
				{
					Entities:Dequeue
					continue
				}
				Entities.Peek:Approach

				; approach within tractor range and tractor entity
				variable float ApproachRange = ${Ship.OptimalTractorRange}
				if ${ApproachRange} > ${Ship.OptimalTargetingRange}
				{
					ApproachRange:Set[${Ship.OptimalTargetingRange}]
				}

				if ${Ship.OptimalTractorRange} > 0
				{
					variable int Counter
					if ${Entities.Peek.Distance} > ${Ship.OptimalTargetingRange}
					{
						call Ship.Approach ${Entities.Peek.ID} ${Ship.OptimalTargetingRange}
					}
					if !${Entities.Peek(exists)}
					{
						Entities:Dequeue
						continue
					}
					Entities.Peek:Approach
					Entities.Peek:LockTarget
					wait 10 ${Entities.Peek.BeingTargeted} || ${Entities.Peek.IsLockedTarget}
					if !${Entities.Peek.BeingTargeted} && !${Entities.Peek.IsLockedTarget}
					{
						if !${Entities.Peek(exists)}
						{
							Entities:Dequeue
							continue
						}
						UI:UpdateConsole["Hauler: Failed to target, retrying"]
						Entities.Peek:LockTarget
						wait 10 ${Entities.Peek.BeingTargeted} || ${Entities.Peek.IsLockedTarget}
					}
					if ${Entities.Peek.Distance} > ${Ship.OptimalTractorRange}
					{
						call Ship.Approach ${Entities.Peek.ID} ${Ship.OptimalTractorRange}
					}
					if !${Entities.Peek(exists)}
					{
						Entities:Dequeue
						continue
					}
					Counter:Set[0]
					while !${Entities.Peek.IsLockedTarget} && ${Counter:Inc} < 300
					{
						wait 1
					}
					Entities.Peek:MakeActiveTarget
					Counter:Set[0]
					while !${Me.ActiveTarget.ID.Equal[${Entities.Peek.ID}]} && ${Counter:Inc} < 300
					{
						wait 1
					}
					Ship:Activate_Tractor
				}
			}

			if !${Entities.Peek(exists)}
			{
				Entities:Dequeue
				continue
			}
			if ${Entities.Peek.Distance} >= ${LOOT_RANGE}
			{
				call Ship.Approach ${Entities.Peek.ID} LOOT_RANGE
			}
			Ship:Deactivate_Tractor
			EVE:Execute[CmdStopShip]

			if ${Entities.Peek.ID.Equal[0]}
			{
				UI:Updateconsole["Hauler: Jetcan disappeared suddently. WTF?"]
				Entities:Dequeue
				continue
			}

			call Ship.Approach ${Entities.Peek.ID} LOOT_RANGE

			if ${PopCan}
			{
				call This.LootEntity ${Entities.Peek.ID} 0
			}
			else
			{
				call This.LootEntity ${Entities.Peek.ID} 1
			}

			Entities:Dequeue
			if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
			{
				break
			}
		}

		FullMiners:Erase[${charID}]
	}




	method BuildFleetMemberList()
	{
		variable index:fleetmember myfleet
		FleetMembers:Clear
		Me.Fleet:GetMembers[myfleet]

		variable int idx
		idx:Set[${myfleet.Used}]

		while ${idx} > 0
		{
			if ${myfleet.Get[${idx}].CharID} != ${Me.CharID}
			{
				if ${myfleet.Get[${idx}].ToPilot(exists)}
				{
					FleetMembers:Queue[${myfleet.Get[${idx}]}]
				}
			}
			idx:Dec
		}

		UI:UpdateConsole["BuildFleetMemberList found ${FleetMembers.Used} other fleet members."]
	}











	method BuildJetCanList()
	{
		EVE:QueryEntities[Entities,"GroupID = 12"]
		Entities:RemoveByQuery[${LavishScript.CreateQuery[!HaveLootRights]}]



		UI:UpdateConsole["BuildJetCanList found ${Entities.Used} cans nearby."]
	}



	;	This member is used to determine if our hauler is full based on a number of factors:
	;	*	Config.Miner.CargoThreshold
	;	*	Are our miners ice mining
	member:bool HaulerFull()
	{
		if ${Config.Miner.IceMining}
		{
			if ${Ship.CargoFreeSpace} < 1000 || ${Me.Ship.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
			{
				return TRUE
			}
		}
		else
		{
			if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${Me.Ship.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
			{
				return TRUE
			}
		}
		return FALSE
	}

}

