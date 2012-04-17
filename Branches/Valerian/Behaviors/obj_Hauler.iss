/*
	The hauler object and subclasses

	The obj_Hauler object contains functions that a usefull in creating
	a hauler bot.  The obj_OreHauler object extends obj_Hauler and adds
	functions that are useful for bots the haul ore in conjunction with
	one or more miner bots.

	-- GliderPro
*/
#define GROUP_GANGCOORDINATOR 316

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
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	/* The name of the player we are hauling for (null if using m_corpName) */
	variable string m_playerName

	/* The name of the corp we are hauling for (null if using m_playerName) */
	variable string m_corpName

	method Initialize()
	{
		UI:UpdateConsole["obj_Hauler: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		/* nothing needs cleanup AFAIK */
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		/* the base obj_Hauler class does not use events */
	}

	member:int64 NearestMatchingJetCan(int64 id)
	{
		variable index:entity JetCans
		variable int JetCanCounter
		variable string tempString

		JetCanCounter:Set[0]
		EVE.QueryEntities[JetCans,"GroupID = 12"]
		while ${JetCanCounter:Inc} <= ${JetCans.Used}
		{
			if ${JetCans.Get[${JetCanCounter}](exists)}
			{
 				if ${JetCans.Get[${JetCanCounter}].Owner.CharID} == ${id}
 				{
					return ${JetCans.Get[${JetCanCounter}].ID}
 				}
			}
			else
			{
				echo "No jetcans found"
			}
		}

		return 0	/* no can found */
	}
}

objectdef obj_OreHauler inherits obj_Hauler
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable collection:obj_FullMiner FullMiners

	variable bool InitReturn=FALSE
	variable bool CleanupStarted=FALSE
	variable collection:int64 CleanupBelts /* belt ID, value is system ID */

	/* the bot logic is currently based on a state machine */
	variable string CurrentState

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable index:bookmark SafeSpots
	variable iterator SafeSpotIterator

	variable queue:fleetmember FleetMembers
	variable queue:entity     Entities

	variable bool PickupFailed = FALSE

	/* status variables */
	variable int TotalTrips = 0
	variable time TripStartTime
	variable int PreviousTripSeconds = 0
	variable int TotalTripSeconds = 0
	variable int AverageTripSeconds = 0
	variable float64 TotalCargo = 0

	method Initialize(string player, string corp)
	{
		m_CheckedCargo:Set[FALSE]
		This.TripStartTime:Set[${Time.Timestamp}]
		UI:UpdateConsole["obj_OreHauler: Initialized", LOG_MINOR]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This:SetupEvents[]
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

		if !${UIElement[EVEBot].FindUsableChild[HaulerFrame,frame].Visible}
		{
			UIElement[EVEBot].FindUsableChild[MinerFrame,frame]:Hide
			UIElement[EVEBot].FindUsableChild[HaulerFrame,frame]:Show
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
		Event[EVEBOT_INTERACTION]:DetachAtom[This:Interaction]
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]
		/* override any events setup by the base class */

		LavishScript:RegisterEvent[EVEBot_Miner_Full]
		LavishScript:RegisterEvent[EVEBOT_INTERACTION]
		Event[EVEBOT_INTERACTION]:AttachAtom[This:Interaction]
		Event[EVEBot_Miner_Full]:AttachAtom[This:MinerFull]

	}

	/*
		COMMANDS:
		InitReturn <FleetID>
		CancelReturn <FleetID>
	*/
	method Interaction(string Params)
	{
		if !${Config.Common.BotModeName.Equal[Hauler]}
		{
			return
		}
		variable string Command
		variable int64 FleetID=0

		Command:Set[${Arg[1,${Params}]}]
		FleetID:Set[${Arg[2,${Params}]}]
		UI:UpdateConsole["DEBUG: obj_Hauler:Interaction event: Command '${Command}' Params '${FleetID}'", LOG_DEBUG]
		switch ${Command}
		{
		case InitReturn
			if ${FleetID.Equal[0]} || ${FleetID.Equal[${Me.Fleet.ID}]}
			{
				InitReturn:Set[TRUE]
				relay "all other" -event EVEBOT_INTERACTION "CancelReturn, ${Me.Fleet.ID}"
				This:SetState
			}
			break
		case CancelReturn
			if ${FleetID.Equal[0]} || ${FleetID.Equal[${Me.Fleet.ID}]}
			{
				InitReturn:Set[FALSE]
				CleanupStarted:Set[FALSE]
				This:SetState
			}
			break
		case StopMiner
		case ReturnNow
		case MoveMinersTo
		default
			break
		}
	}
	/* A miner's jetcan is full.  Let's go get the ore.  */
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
		CleanupBelts:Set[${beltID},${systemID}]
		FullMiners:Set[${charID},${charID},${systemID},${beltID}]
	}

	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{
		variable float ThisCargo
		switch ${This.CurrentState}
		{
			case IDLE
				Ship:Activate_Gang_Links
				break
			case ABORT
				Ship:Activate_Gang_Links
				UI:UpdateConsole["Aborting operation: Returning to base"]
				Call Station.Dock
				break
			case INSTATION
				call Ship.CloseCargo
				call Ship.OpenCargo
				wait 10
				UI:UpdateConsole["Hauler: Cargo in station: ${MyShip.UsedCargoCapacity}"]
				if ${MyShip.UsedCargoCapacity} > 0
				{
					ThisCargo:Set[${MyShip.UsedCargoCapacity}]
					call Cargo.TransferCargoToHangar
					This:IncrementTrip[${ThisCargo}]
				}
				call Station.Undock
				if ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}](exists)}
				{
					call Ship.TravelToSystem ${EVE.Bookmark[${Config.Hauler.MiningSystemBookmark}].SolarSystemID}
				}
				break
			case HAUL
				Ship:Activate_Gang_Links
				call This.Haul
				break
			case CLEANUP
				call This.Cleanup
				break
			case CARGOFULL
				Ship:Activate_Gang_Links
				call This.DropOff
				This.PickupFailed:Set[FALSE]
				break
		}
	}

	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${Ship.IsPod}
		{
			UI:UpdateConsole["Warning: We're in a pod, running"]
			EVEBot.ReturnToStation:Set[TRUE]
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${Me.InStation}
		{
	  		This.CurrentState:Set["INSTATION"]
		}
		elseif ${This.PickupFailed} || ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{
			This.CurrentState:Set["CARGOFULL"]
		}
		elseif ${InitReturn}
		{
			This.CurrentState:Set["CLEANUP"]
		}
		elseif ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	This.CurrentState:Set["HAUL"]
		}
		else
		{
			This.CurrentState:Set["Unknown"]
		}
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

		Entities.Peek:OpenCargo
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
					QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${Cargo.Value.Volume} - 1]}]
					if ${QuantityToMove} <= 0
					{
						This.PickupFailed:Set[TRUE]
					}
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
				}

				if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
				{
					/* TODO - this needs to keep a queue of bookmarks, named for the can ie, "Can CORP hh:mm", of partially looted cans */
					/* Be sure its names, and not ID.  We shouldn't store anything in a bookmark name that we shouldnt know */

					UI:UpdateConsole["DEBUG: obj_Hauler.LootEntity: Ship Cargo Free Space: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
					break
				}
			}
			while ${Cargo:Next(exists)}
		}

		EVEWindow[ByName,${MyShip.ID}]:StackAll
		wait 10
		;EVEWindow[ByName,${MyShip.ID}]:Close
		;wait 10
	}


	function Haul()
	{
		switch ${Config.Hauler.HaulerModeName}
		{
			case Service On-Demand
				call This.HaulOnDemand
				break
			case Service Gang Members
			case Service Fleet Members
				call This.HaulForFleet
				break
			case Service All Belts
				call This.HaulAllBelts
				break
			case Stationary Service
				call This.StationaryService
				break
		}
	}

	function DropOff()
	{
		if !${EVE.Bookmark[${Config.Miner.DeliveryLocation}](exists)}
		{
			UI:UpdateConsole["ERROR: ORE Delivery location & type must be specified (on the miner tab) - docking"]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		if ${Config.Miner.DeliveryLocationTypeName.NotEqual[Station]}
		{
			This:IncrementTrip
		}
		switch ${Config.Miner.DeliveryLocationTypeName}
		{
			case Station
				call Ship.TravelToSystem ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}
				wait 40
				call Station.DockAtStation ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}
				break
			case Hangar Array
				call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
				call Cargo.TransferOreToCorpHangarArray
				break
			case Large Ship Assembly Array
				call Ship.WarpToBookMarkName "${Config.Miner.DeliveryLocation}"
				call Cargo.TransferOreToLargeShipAssemblyArray
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

	/* The HaulOnDemand function will be called repeatedly   */
	/* until we leave the HAUL state due to downtime,        */
	/* agression, or a full cargo hold.  The Haul function   */
	/* should do one (and only one) of the following actions */
	/* each it is called.									 */
	/*                                                       */
	/* 1) Warp to fleet member and loot nearby cans           */
	/* 2) Warp to next safespot                              */
	/* 3) Travel to new system (if required)                 */
	/*                                                       */
	function HaulOnDemand()
	{
		variable string MbrName
		variable string FQN
		FQN:Set[${UIElement[EVEBot].FindUsableChild[FleetList,listbox].FullName}]
		while ${CurrentState.Equal[HAUL]} && ${FullMiners.FirstValue(exists)}
		{
			MbrName:Set[${Me.Fleet.Member[${FullMiners.FirstKey}].ToPilot.Name}]
			if ${This.IsSelected[${FQN},${MbrName}]} && ${Me.Fleet.IsMember[${FullMiners.FirstKey}]}
			{
				UI:UpdateConsole["Hauler: ${FullMiners.Used} pickups waiting! Picking up can at ${MbrName}", LOG_DEBUG]
				if ${FullMiners.CurrentValue.SystemID} != ${Me.SolarSystemID}
				{
					UI:UpdateConsole["Hauler: Moving to ${Universe[${FullMiners.CurrentValue.SystemID}].Name} for pickup.", LOG_DEBUG]
					call Ship.TravelToSystem ${FullMiners.CurrentValue.SystemID}
				}
				call This.WarpToFleetMemberAndLoot ${FullMiners.CurrentValue.FleetMemberID}
			}
			else
			{
				FullMiners:Erase[${FullMiners.FirstKey}]
			}
		}
		if ${CurrentState.Equal[HAUL]}
			call This.WarpToNextSafeSpot
	}
	member:bool IsSelected(string FQN, string Text)
	{
		variable int count
		for (count:Set[${UIElement[${FQN}].SelectedItems}] ; ${count} > 0 ; count:Dec )
		{
			if ${UIElement[${FQN}].SelectedItem[${count}].Text.Equal[${Text}]}
				return TRUE
		}
		/* If pilot isn't listed, AND we haul for new fleet members... */
		if !${UIElement[${FQN}].ItemByText[${Text}](exists)} && ${Config.Hauler.HaulNewFleetMembers}
			return TRUE
		return FALSE
	}

	/* 1) Warp to fleet member and loot nearby cans           */
	/* 2) Repeat until cargo hold is full                    */
	/*                                                       */
	function StationaryService()
	{
		variable string FQN
		FQN:Set[${UIElement[EVEBot].FindUsableChild[FleetList,listbox].FullName}]
		if ${FleetMembers.Used} == 0
		{
			This:BuildFleetMemberList
		}
		else
		{
			if ${FleetMembers.Peek(exists)} && \
			   ${Local[${FleetMembers.Peek.ToPilot.Name}](exists)} && \
			   ${This.IsSelected[${FQN},${FleetMembers.Peek.ToPilot.Name}]}
			{
				call This.WarpToFleetMemberAndLootStationary ${FleetMembers.Peek.CharID}
			}
			if !${Local[${FleetMembers.Peek.ToPilot.Name}](exists)}
			{
				FleetMembers:Dequeue
			}
		}
	}

	/* 1) Warp to fleet member and loot nearby cans           */
	/* 2) Repeat until cargo hold is full                    */
	/*                                                       */
	function HaulForFleet()
	{
		variable string FQN
		FQN:Set[${UIElement[EVEBot].FindUsableChild[FleetList,listbox].FullName}]
		if ${FleetMembers.Used} == 0
		{
			This:BuildFleetMemberList
			call This.WarpToNextSafeSpot
		}
		else
		{
			if ${FleetMembers.Peek(exists)} && \
			   ${Local[${FleetMembers.Peek.ToPilot.Name}](exists)} && \
			   ${This.IsSelected[${FQN},${FleetMembers.Peek.ToPilot.Name}]}
			{
				call This.WarpToFleetMemberAndLoot ${FleetMembers.Peek.CharID}
			}
			FleetMembers:Dequeue
		}
	}

	function Cleanup()
	{
		variable string FQN
		FQN:Set[${UIElement[EVEBot].FindUsableChild[FleetList,listbox].FullName}]
		if !${CleanupStarted}
		{
			This:BuildFleetMemberList
			CleanupStarted:Set[TRUE]
			call This.WarpToNextSafeSpot
		}
		if ${FleetMembers.Peek(exists)} && \
			${Local[${FleetMembers.Peek.ToPilot.Name}](exists)} && \
			${This.IsSelected[${FQN},${FleetMembers.Peek.ToPilot.Name}]}
		{
			relay all -event EVEBOT_INTERACTION "StopMiner, ${FleetMembers.Peek.CharID}"
			call This.WarpToFleetMemberAndLoot ${FleetMembers.Peek.CharID}
			if ${PickupFailed}
			{
				relay all -event EVEBOT_INTERACTION "StartMiner, ${FleetMembers.Peek.CharID}"
				This:SetState
				return
			}
			if ${Config.Miner.DeliveryLocationTypeName.Equal[Station]}
				relay all -event EVEBOT_INTERACTION "ReturnNow, ${FleetMembers.Peek.CharID}, ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].SolarSystemID}, ${EVE.Bookmark[${Config.Miner.DeliveryLocation}].ItemID}"
			else
				relay all -event EVEBOT_INTERACTION "ReturnNow, ${FleetMembers.Peek.CharID}"

			FleetMembers:Dequeue
		}
		elseif ${FleetMembers.Used}
		{
			FleetMembers:Dequeue
		}
		else /* No more fleet members to clean up */
		{
			call This.DropOff
			if ${MyShip.UsedCargoCapacity} > 0
			{
				variable float ThisCargo = ${MyShip.UsedCargoCapacity}
				call Cargo.TransferCargoToHangar
				This:IncrementTrip[${ThisCargo}]
			}
			EVEBot.ReturnToStation:Set[TRUE]
		}

	}

	function HaulAllBelts()
	{
		UI:UpdateConsole["Service All Belts mode not implemented!"]
		EVEBot.ReturnToStation:Set[TRUE]
	}

	function WarpToFleetMemberAndLootStationary(int64 charID)
	{
		variable int id = 0

		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{	/* if we are already full ignore this request */
			return FULL
		}

		if !${Entity["OwnerID = ${charID} && CategoryID = 6"](exists)}
		{
			call Ship.WarpToFleetMember ${charID}
		}

		if ${Entity["OwnerID = ${charID} && CategoryID = 6"].Distance} > CONFIG_MAX_SLOWBOAT_RANGE
		{
			if ${Entity["OwnerID = ${charID} && CategoryID = 6"].Distance} < WARP_RANGE
			{
				UI:UpdateConsole["Fleet member is too far for approach; warping to bounce point"]
				if ${Ship.Drones.DronesInSpace} > 0
				{
					call Ship.Drones.ReturnAllToDroneBay
				}
				call This.WarpToNextSafeSpot
			}
			call Ship.WarpToFleetMember ${charID}
		}

		call Ship.OpenCargo
		if ${Config.Combat.LaunchCombatDrones} && \
			${Ship.Drones.DronesInSpace} == 0 && \
			!${Ship.InWarp}
		{
			Ship.Drones:LaunchAll[]
		}

		variable int Slot
		for ( Slot:Set[0] ; ${Slot} <= 7 ; Slot:Inc )
		{
			if ${MyShip.Module[HiSlot${Slot}](exists)}
			{
				if ${MyShip.Module[HiSlot${Slot}].ToItem.GroupID} == GROUP_GANGCOORDINATOR
				{
					if !${MyShip.Module[HiSlot${Slot}].IsActive} && !${MyShip.Module[HiSlot${Slot}].IsChangingAmmo} && !${MyShip.Module[HiSlot${Slot}].IsReloadingAmmo} /* && !${MyShip.Module[HiSlot${Slot}].IsActivating} <--- BROKEN? */ && !${MyShip.Module[HiSlot${Slot}].IsDeactivating} && ${MyShip.Module[HiSlot${Slot}].IsOnline}
					{
						MyShip.Module[HiSlot${Slot}]:Activate
					}
				}
			}
		}


		This:BuildJetCanList[0]
		wait 50
		while ${Entities.Peek(exists)}
		{

			/* approach within tractor range and tractor entity */
			variable float ApproachRange = ${Ship.OptimalTractorRange}
			if ${ApproachRange} > ${Ship.OptimalTargetingRange}
			{
				ApproachRange:Set[${Ship.OptimalTargetingRange}]
			}

			if ${Entities.Peek.Distance} > LOOT_RANGE && \
				${ApproachRange} > 0 /* we have a tractor beam */
			{
				if ${Entities.Peek.Distance} > ${ApproachRange}
				{
					call Ship.Approach ${Entities.Peek.ID} ${ApproachRange}
				}
				Entities.Peek:LockTarget
				wait 10 ${Entities.Peek.BeingTargeted} || ${Entities.Peek.IsLockedTarget}
				while !${Entities.Peek.IsLockedTarget}
				{
					wait 1
				}
				Entities.Peek:MakeActiveTarget
				while !${Me.ActiveTarget.ID.Equal[${Entities.Peek.ID}]}
				{
					wait 1
				}
				Ship:Activate_Tractor
				while ${Entities.Peek.Distance} > LOOT_RANGE
				{
					wait 1
				}
			}
			else
			{
				/* approach within loot range */
				call Ship.Approach ${Entities.Peek.ID} LOOT_RANGE
				Entities.Peek:Approach
			}
			Entities.Peek:UnlockTarget
			Entities.Peek:OpenCargo
			wait 30
			call This.LootEntity ${Entities.Peek.ID}


			if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
			{
				if ${Entities.Peek(exists)} && ${Entities.Used} > 1
				{
					This.PickupFailed:Set[TRUE]
				}
				if ${Ship.Drones.DronesInSpace} > 0
				{
					call Ship.Drones.ReturnAllToDroneBay
				}
				return FULL
			}

			if ${Entities.Peek(exists)}
			{
				Entities.Peek:CloseCargo
			}
			Entities:Dequeue

		}

	}
	function WarpToFleetMemberAndLoot(int64 charID)
	{
		variable int64 id = 0

		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{	/* if we are already full ignore this request */
			return FULL
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
				call This.WarpToNextSafeSpot
			}
			call Ship.WarpToFleetMember ${charID}
		}

		call Ship.OpenCargo

		This:BuildJetCanList[${charID}]
		while ${Entities.Peek(exists)}
		{
			variable int64 PlayerID
			variable bool PopCan = FALSE
			PopCan:Set[${CleanupStarted}]

			; Find the player who owns this can
			if ${Entity["OwnerID = ${charID} && CategoryID = 6"](exists)}
			{
				PlayerID:Set[${Entity["OwnerID = ${charID} && CategoryID = 6"].ID}]
			}

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
			if ${PopCan}
			{
				call This.LootEntity ${Entities.Peek.ID} 0
			}
			else
			{
				call This.LootEntity ${Entities.Peek.ID} 1
			}

			Entities:Dequeue
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


	method BuildSafeSpotList()
	{
		SafeSpots:Clear
		EVE:GetBookmarks[SafeSpots]

		variable int idx
		idx:Set[${SafeSpots.Used}]

		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set["${Config.Labels.SafeSpotPrefix}"]

			variable string Label
			Label:Set["${SafeSpots.Get[${idx}].Label.Escape}"]
			if ${Label.Left[${Prefix.Length}].NotEqual[${Prefix}]}
			{
				SafeSpots:Remove[${idx}]
			}
			elseif ${SafeSpots.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
			{
				SafeSpots:Remove[${idx}]
			}

			idx:Dec
		}
		SafeSpots:Collapse
		SafeSpots:GetIterator[SafeSpotIterator]

		UI:UpdateConsole["BuildSafeSpotList found ${SafeSpots.Used} safespots in this system."]
	}

	function WarpToNextSafeSpot()
	{
		if ${SafeSpots.Used} == 0 || \
			${SafeSpots.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:BuildSafeSpotList
		}

		if !${SafeSpotIterator:Next(exists)}
		{
			SafeSpotIterator:First
		}

		if ${SafeSpotIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}

			/* open cargo hold so the CARGOFULL detection has a chance to work */
			call Ship.OpenCargo
		}
	}

	method BuildJetCanList(int64 id)
	{
		variable index:entity cans
		variable int idx

		EVE:QueryEntities[cans,"GroupID = GROUPID_CARGO_CONTAINER"]
		idx:Set[${cans.Used}]
		Entities:Clear
echo Cans found: ${idx} ID: ${id} 
		while ${idx} > 0
		{
echo elseif ${id.Equal[0]} && ${cans[${idx}].HaveLootRights} (${cans[${idx}].Name})
			if ${id.Equal[${cans.Get[${idx}].Owner.CharID}]}
			{
				Entities:Queue[${cans.Get[${idx}].ID}]
			}
			elseif !${Entity["OwnerID = ${cans[${idx}].Owner.CharID} && CategoryID =6"](exists)} && \
					${cans[${idx}].HaveLootRights}
			{
				Entities:Queue[${cans[${idx}].ID}]
			}
			elseif ${id.Equal[0]} && ${cans[${idx}].HaveLootRights}
			{
				Entities:Queue[${cans[${idx}].ID}]
			}

			idx:Dec
		}

		EVE:QueryEntities[cans,"GroupID = GROUPID_WRECK"]
		idx:Set[${cans.Used}]
		while ${idx} > 0
		{
			if ${cans[${idx}].HaveLootRights} && !${cans[${idx}].IsWreckEmpty}
			{
				Entities:Queue[${cans[${idx}].ID}]
			}

			idx:Dec
		}


		UI:UpdateConsole["BuildJetCanList found ${Entities.Used} cans/wrecks nearby."]
	}

	member:int TripDuration()
	{
		return ${Math.Calc64[${Time.Timestamp} - ${This.TripStartTime.Timestamp}]}
	}

	method IncrementTrip(float ThisCargo=0)
	{
		This.TotalTrips:Inc
		This.PreviousTripSeconds:Set[${This.TripDuration}]
		This.TotalTripSeconds:Inc[${This.PreviousTripSeconds}]
		This.AverageTripSeconds:Set[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]
		This.TripStartTime:Set[${Time.Timestamp}]
		This.TotalCargo:Inc[${ThisCargo} + ${MyShip.UsedCargoCapacity}]
	}
}

