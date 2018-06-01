/*
	Cargo Class

	Interacting with Cargo of ship, hangar, and containers, and moving it.

	-- CyberTech

BUGS:


*/

objectdef obj_Cargo
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:item MyCargo
	variable index:item CargoToTransfer
	variable bool m_LastTransferComplete
	variable index:string ActiveMiningCrystals
	variable float m_ContainerFreeSpace

	;	Used to keep track of how much we've hauled per trip, per hour, and per session
	variable float64 TripHauled
	variable float64 HourHauled
	variable int CurrentHour=${Time.Hour}
	variable float64 TotalHauled


	method Initialize()
	{
		UI:UpdateConsole["obj_Cargo: Initialized", LOG_MINOR]
	}

	member:bool LastTransferComplete()
	{
		return ${m_LastTransferComplete}
	}

	function OpenHolds()
	{
		call Ship.OpenCargo
		call Station.OpenHangar
	}

	function CloseHolds()
	{
		return
		call Ship.CloseCargo
		call Station.CloseHangar
	}

	member:bool ShipHasContainers()
	{
		variable index:item anItemIndex
		variable iterator   anIterator

		MyShip:GetCargo[anItemIndex]
		anItemIndex:GetIterator[anIterator]
		if ${anIterator:First(exists)}
		do
		{
			;This:DumpItem[${anIterator.Value.ID}]
			if ${anIterator.Value.GroupID} == GROUPID_SECURE_CONTAINER
			{
				return TRUE
			}
		}
		while ${anIterator:Next(exists)}

		return FALSE
	}


	method DumpItem(item anItem)
	{
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: BasePrice:         ${anItem.BasePrice}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Capacity:          ${anItem.Capacity}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Category:          ${anItem.Category}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: CategoryID:        ${anItem.CategoryID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Description:       ${anItem.Description}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: GraphicID:         ${anItem.GraphicID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Group:             ${anItem.Group}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: GroupID:           ${anItem.GroupID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: ID:                ${anItem.ID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: IsContraband:      ${anItem.IsContraband}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: IsRepackable:      ${anItem.IsRepackable}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Location:          ${anItem.Location}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: LocationID:        ${anItem.LocationID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: MacroLocation:     ${anItem.MacroLocation}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: MacroLocationID:   ${anItem.MacroLocationID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: MarketGroupID:     ${anItem.MarketGroupID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Name:              ${anItem.Name}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: OwnerID:           ${anItem.OwnerID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: PortionSize:       ${anItem.PortionSize}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Quantity:          ${anItem.Quantity}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: RaceID:            ${anItem.RaceID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Radius:            ${anItem.Radius}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Slot:              ${anItem.Slot}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: SlotID:            ${anItem.SlotID}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Type:              ${anItem.Type}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: Volume:            ${anItem.Volume}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: GivenName:         ${anItem.Name}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: CargoCapacity:     ${anItem.CargoCapacity}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: UsedCargoCapacity: ${anItem.UsedCargoCapacity}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: GetCargo:          ${anItem.GetCargo}"]
		UI:UpdateConsole["========================================================"]

	}

	method FindAllShipCargo()
	{
		MyShip:GetCargo[This.MyCargo]

		variable iterator CargoIterator

		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			variable int CategoryID

			CategoryID:Set[${CargoIterator.Value.CategoryID}]
			;UI:UpdateConsole["DEBUG: obj_Cargo:FindAllShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.ID} ${CargoIterator.Value.Name} - ${CargoIterator.Value.Quantity} (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]
			This.CargoToTransfer:Insert[${CargoIterator.Value.ID}]
		}
		while ${CargoIterator:Next(exists)}

		;UI:UpdateConsole["DEBUG: obj_Cargo:FindAllShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
	}

	method FindShipCargo(int CategoryIDToMove)
	{
		MyShip:GetCargo[This.MyCargo]

		variable iterator CargoIterator

		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			variable int CategoryID

			CategoryID:Set[${CargoIterator.Value.CategoryID}]
			;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.ID} ${CargoIterator.Value.Name} - ${CargoIterator.Value.Quantity} (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]

			if (${CategoryID} == ${CategoryIDToMove})
			{
				This.CargoToTransfer:Insert[${CargoIterator.Value.ID}]
			}
		}
		while ${CargoIterator:Next(exists)}

		;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
	}

	method FindShipCargoByType(int TypeIDToMove)
   {
	  MyShip:GetCargo[This.MyCargo]

	  variable iterator CargoIterator

	  This.MyCargo:GetIterator[CargoIterator]
	  if ${CargoIterator:First(exists)}
	  do
	  {
		 variable int TypeID

		 TypeID:Set[${CargoIterator.Value.TypeID}]
		 ;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: TypeID: ${TypeID} ${CargoIterator.Value.Name} (${CargoIterator.Value.Quantity}) (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]

		 if (${TypeID} == ${TypeIDToMove})
		 {
			This.CargoToTransfer:Insert[${CargoIterator.Value.ID}]
		 }
	  }
	  while ${CargoIterator:Next(exists)}

	  UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
   }

	member:int CargoToTransferCount()
	{
		return ${This.CargoToTransfer.Used}
	}

	function ReplenishCrystals(int64 from=-1)
	{
		variable iterator CargoIterator
		variable iterator HangarIterator
		variable iterator CrystalIterator
		variable collection:int Crystals
		variable int MIN_CRYSTALS = ${Math.Calc[${Ship.ModuleList_MiningLaser.Used} + 1]}
		variable index:item HangarItems

		This.ActiveMiningCrystals:GetIterator[CrystalIterator]

		; Add in any Crystals that were brought in from the laser modules
		if ${CrystalIterator:First(exists)}
		do
		{
			;echo Setting active crystal: ${CrystalIterator.Value} ${CrystalIterator.Value}
			Crystals:Set[${CrystalIterator.Value}, ${Math.Calc[${Crystals.Element[${CrystalIterator.Value}]} + 1]}]
		}
		while ${CrystalIterator:Next(exists)}

		call Ship.OpenCargo
		This:FindShipCargo[CATEGORYID_CHARGE]

		This.CargoToTransfer:GetIterator[CargoIterator]


		; Add up the current crystal quantities in the cargo
		if ${CargoIterator:First(exists)}
		do
		{
			variable string crystal
			variable int quantity

			crystal:Set[${CargoIterator.Value.Name}]
			quantity:Set[${CargoIterator.Value.Quantity}]

			Crystals:Set[${crystal}, ${Math.Calc[${Crystals.Element[${crystal}]} + ${quantity} ]}]
		}
		while ${CargoIterator:Next(exists)}

		This.CargoToTransfer:Clear

		; No crystals found, just return
		if !${Crystals.FirstKey(exists)}
		{
			return
		}


		if ${from} == -1
		{
			call Station.OpenHangar
			Me:GetHangarItems[HangarItems]
			HangarItems:GetIterator[HangarIterator]

			; Cycle thru the Hangar looking for the needed Crystals and move them to the ship
			if ${HangarIterator:First(exists)}
			do
			{
				;echo CategoryID: ${HangarIterator.Value.CategoryID}
				if ${HangarIterator.Value.CategoryID} == CATEGORYID_CHARGE
				{
					variable string name
					variable int quant
					variable int needed

					name:Set[${HangarIterator.Value.Name}]
					quant:Set[${HangarIterator.Value.Quantity}]

					if ${Crystals.FirstKey(exists)}
					do
					{
						needed:Set[${Math.Calc[ ${MIN_CRYSTALS} - ${Crystals.CurrentValue}]}]

						;echo "${MIN_CRYSTALS} - ${Crystals.CurrentValue} = ${needed}"
						;echo Hangar: ${name} : ${quant} == ${Crystals.CurrentKey} : Needed: ${needed}

						if (${name.Equal[${Crystals.CurrentKey}]} && ${needed} > 0)
						{
							if ${quant} >= ${needed}
							{
								HangarIterator.Value:MoveTo[MyShip, CargoHold, ${needed}]
								Crystals:Set[${Crystals.CurrentKey}, ${Math.Calc[${Crystals.CurrentValue} + ${needed}]}]
							}
							else
							{
								HangarIterator.Value:MoveTo[MyShip, CargoHold]
								Crystals:Set[${Crystals.CurrentKey}, ${Math.Calc[${Crystals.CurrentValue} + ${quant}]}]
							}
						}
					}
					while ${Crystals.NextKey(exists)}
				}
			}
			while ${HangarIterator:Next(exists)}

			if ${Crystals.FirstKey(exists)}
			do
			{
				if ${Crystals.CurrentValue} < ${MIN_CRYSTALS}
				{
						 UI:UpdateConsole["Out of ${Crystals.CurrentKey} !!"]
				}
			}
			while ${Crystals.NextKey(exists)}
		}
		else
		{
			variable index:item HangarCargo
			Entity[${from}]:Open
			wait 30
			Entity[${from}]:GetCorpHangarsCargo[HangarCargo]
			HangarCargo:GetIterator[CargoIterator]

			; Cycle thru the Hangar looking for the needed Crystals and move them to the ship
			if ${CargoIterator:First(exists)}
			do
			{
				echo CategoryID: ${CargoIterator.Value.CategoryID} Name: ${CargoIterator.Value.Name}
				if ${CargoIterator.Value.CategoryID} == CATEGORYID_CHARGE
				{

					name:Set[${CargoIterator.Value.Name}]
					quant:Set[${CargoIterator.Value.Quantity}]

					if ${Crystals.FirstKey(exists)}
					do
					{
						needed:Set[${Math.Calc[ ${MIN_CRYSTALS} - ${Crystals.CurrentValue}]}]

						;echo "${MIN_CRYSTALS} - ${Crystals.CurrentValue} = ${needed}"
						;echo Hangar: ${name} : ${quant} == ${Crystals.CurrentKey} : Needed: ${needed}

						if (${name.Equal[${Crystals.CurrentKey}]} && ${needed} > 0)
						{
							if ${quant} >= ${needed}
							{
								CargoIterator.Value:MoveTo[MyShip, CargoHold, ${needed}]
								Crystals:Set[${Crystals.CurrentKey}, ${Math.Calc[${Crystals.CurrentValue} + ${needed}]}]
							}
							else
							{
								CargoIterator.Value:MoveTo[MyShip, CargoHold]
								Crystals:Set[${Crystals.CurrentKey}, ${Math.Calc[${Crystals.CurrentValue} + ${quant}]}]
							}
						}
					}
					while ${Crystals.NextKey(exists)}
				}
			}
			while ${CargoIterator:Next(exists)}

			if ${Crystals.FirstKey(exists)}
			do
			{
				if ${Crystals.CurrentValue} < ${MIN_CRYSTALS}
				{
						 UI:UpdateConsole["Out of ${Crystals.CurrentKey} !!"]
				}
			}
			while ${Crystals.NextKey(exists)}
		}
	}


	function TransferContainerToHangar(item anItem)
	{
		if ${anItem.GroupID} == GROUPID_SECURE_CONTAINER
		{
			anItem:Open
			wait 15

			variable index:item anItemIndex
			variable index:int64  anIntIndex
			variable iterator   anIterator

			anItem:GetCargo[anItemIndex]
			anItemIndex:GetIterator[anIterator]
			anIntIndex:Clear

			if ${anIterator:First(exists)}
			do
			{
				anIntIndex:Insert[${anIterator.Value.ID}]
			}
			while ${anIterator:Next(exists)}

			if ${anIntIndex.Used} > 0
			{
				EVE:MoveItemsTo[anIntIndex, ${Me.Station.ID}, Hangar]
				wait 15
			}

			anItem:Close
		}
		else
		{
			UI:UpdateConsole["TransferContainerToHangar: Not Supported!! ${CargoIterator.Value.Name}"]
		}
	}

	function TransferListToGSC(int64 dest)
	{
		variable index:item ShipCargo
		variable iterator Cargo
		variable int QuantityToMove

		UI:UpdateConsole["DEBUG: Offloading to GSC"]

		MyShip:GetCargo[ShipCargo]
		ShipCargo:GetIterator[Cargo]

		if ${Cargo:First(exists)}
		{
			do
			{
				UI:UpdateConsole["MoveGSC: Found ${Cargo.Value.Quantity} x ${Cargo.Value.Name} - ${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity}"]
				if (${Cargo.Value.Quantity} * ${Cargo.Value.Volume}) > (${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity})
				{
					QuantityToMove:Set[${Math.Calc[(${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity}) / ${Cargo.Value.Volume}]}]
				}
				else
				{
					QuantityToMove:Set[${Cargo.Value.Quantity}]
				}

				UI:UpdateConsole["MoveGSC: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
				if ${QuantityToMove} > 0
				{
					Cargo.Value:MoveTo[${dest},CargoHold,${QuantityToMove}]
					wait 30
					if (${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity}) < 1000
					{
						break
					}
				}

				if (${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity}) < 1000
				{
					/* TODO - this needs to keep a queue of bookmarks, named for the can ie, "Can CORP hh:mm", of partially looted cans */
					/* Be sure its names, and not ID.  We shouldn't store anything in a bookmark name that we shouldnt know */

					UI:UpdateConsole["MoveGSC: ${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity} < 1000"]
					break
				}
			}
			while ${Cargo:Next(exists)}
		}

	}

	function TransferListFromShipCorporateHangar(int64 dest)
	{
		variable index:item HangarCargo
		variable iterator CargoIterator
		variable float VolumeToMove=0
		variable index:int64 ListToMove
		Entity[${dest}]:GetFleetHangarCargo[HangarCargo]
		HangarCargo:RemoveByQuery[${LavishScript.CreateQuery[Name =- "Mining Crystal"]}]

		HangarCargo:GetIterator[CargoIterator]
		call Ship.OpenCargo

		UI:UpdateConsole["DEBUG: TransferListFromShipCorporateHangar", LOG_DEBUG]

		if ${CargoIterator:First(exists)}
		{
				do
				{
					if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) < ${Math.Calc[${Ship.CargoFreeSpace} - ${VolumeToMove}]}
					{
						ListToMove:Insert[${CargoIterator.Value.ID}]
						VolumeToMove:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
					}
					else
					{
						CargoIterator.Value:MoveTo[${MyShip.ID}, CargoHold, ${Math.Calc[(${Ship.CargoFreeSpace} - ${VolumeToMove}) / ${CargoIterator.Value.Volume}]}]
						break
					}
				}
				while ${CargoIterator:Next(exists)}
				if ${ListToMove.Used}
				{
					EVE:MoveItemsTo[ListToMove, MyShip, CargoHold]
				}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListFromShipCorporateHangar: Nothing found to move"]
			return
		}
	}

	function TransferCargoFromShipCorporateHangarToOreHold()
	{

		variable index:item HangarCargo
		variable int QuantityToMove
		variable iterator CargoIterator
		MyShip:GetFleetHangarCargo[HangarCargo]
		HangarCargo:GetIterator[CargoIterator]

		UI:UpdateConsole["DEBUG: TransferCargoFromShipCorporateHangarToOreHold", LOG_DEBUG]

		if ${CargoIterator:First(exists)}
		{
				do
				{
					if ${CargoIterator.Value.CategoryID} == CATEGORYID_ORE
					{
						if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${Ship.OreHoldFreeSpace}
						{
							QuantityToMove:Set[${Math.Calc[${Ship.OreHoldFreeSpace} / ${CargoIterator.Value.Volume}]}]
						}
						else
						{
							QuantityToMove:Set[${CargoIterator.Value.Quantity}]
						}

						UI:UpdateConsole["TransferCargoFromShipCorporateHangarToOreHold: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
						UI:UpdateConsole["TransferCargoFromShipCorporateHangarToOreHold: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
						if ${QuantityToMove} > 0
						{
							CargoIterator.Value:MoveTo[${MyShip.ID}, OreHold, ${QuantityToMove}]
							wait 15
						}

						if ${Ship.OreHoldFreeSpace} < ${Ship.OreHoldMinimumFreeSpace}
						{
							UI:UpdateConsole["DEBUG: TransferCargoFromShipCorporateHangarToOreHold: Ore Hold: ${Ship.OreHoldFreeSpace} < ${Ship.OreHoldMinimumFreeSpace}"]
							break
						}
					}
				}
				while ${CargoIterator:Next(exists)}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferCargoFromShipCorporateHangarToOreHold: Nothing found to move"]
		}
	}

	function TransferCargoFromShipOreHoldToStation()
	{

		variable index:item HangarCargo
		variable int QuantityToMove
		variable iterator CargoIterator
		MyShip:GetOreHoldCargo[HangarCargo]
		HangarCargo:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
				do
				{
					QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					UI:UpdateConsole["TransferCargoFromShipOreHoldToStation: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					UI:UpdateConsole["TransferCargoFromShipOreHoldToStation: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
					if ${QuantityToMove} > 0
					{
						CargoIterator.Value:MoveTo[MyStationHangar, Hangar, ${QuantityToMove}]
						wait 15
					}
				}
				while ${CargoIterator:Next(exists)}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferCargoFromShipOreHoldToStation: Nothing found to move"]
		}
	}

	function TransferCargoFromShipCorporateHangarToStation()
	{
		variable index:item HangarCargo
		variable int QuantityToMove
		variable iterator CargoIterator
		MyShip:GetFleetHangarCargo[HangarCargo]
		HangarCargo:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
				do
				{
					QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					UI:UpdateConsole["TransferCargoFromShipCorporateHangarToStation: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					UI:UpdateConsole["TransferCargoFromShipCorporateHangarToStation: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
					if ${QuantityToMove} > 0
					{
						CargoIterator.Value:MoveTo[MyStationHangar, Hangar, ${QuantityToMove}]
						wait 15
					}
				}
				while ${CargoIterator:Next(exists)}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferCargoFromShipCorporateHangarToStation: Nothing found to move"]
		}
	}

	function TransferCargoFromShipCorporateHangarToCargoHold()
	{

		variable index:item HangarCargo
		variable int QuantityToMove
		variable iterator CargoIterator
		MyShip:GetFleetHangarCargo[HangarCargo]
		HangarCargo:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
				do
				{
					if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${Ship.CargoFreeSpace}
					{
						QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${CargoIterator.Value.Volume}]}]
					}
					else
					{
						QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					}

					UI:UpdateConsole["TransferCargoFromShipCorporateHangarToCargoHold: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					UI:UpdateConsole["TransferCargoFromShipCorporateHangarToCargoHold: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
					if ${QuantityToMove} > 0
					{
						CargoIterator.Value:MoveTo[${MyShip.ID}, CargoHold, ${QuantityToMove}]
						wait 15
					}

					if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
					{
						UI:UpdateConsole["DEBUG: TransferCargoFromShipCorporateHangarToCargoHold: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
						break
					}
				}
				while ${CargoIterator:Next(exists)}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferCargoFromShipCorporateHangarToCargoHold: Nothing found to move"]
		}
	}

	function TransferCargoFromCargoHoldToShipCorporateHangar()
	{
		variable index:item HangarCargo
		variable int QuantityToMove
		variable iterator CargoIterator
		MyShip:GetCargo[HangarCargo]
		HangarCargo:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
				do
				{
					if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${Ship.CorpHangarFreeSpace}
					{
						QuantityToMove:Set[${Math.Calc[${Ship.CorpHangarFreeSpace} / ${CargoIterator.Value.Volume}]}]
					}
					else
					{
						QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					}

					UI:UpdateConsole["TransferCargoFromCargoHoldToShipCorporateHangar: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name} (Free Space: ${Ship.CorpHangarFreeSpace}m3"]
					UI:UpdateConsole["TransferCargoFromCargoHoldToShipCorporateHangar: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
					if ${QuantityToMove} > 0
					{
						CargoIterator.Value:MoveTo[${MyShip.ID}, FleetHangar, ${QuantityToMove}]
						wait 15
					}
				}
				while ${CargoIterator:Next(exists)}
		}
		else
		{
			;UI:UpdateConsole["DEBUG: obj_Cargo:TransferCargoFromCargoHoldToShipCorporateHangar: Nothing found to move"]
		}
	}
	; Call TransferListToPOSCorpHangar "LargeShipAssemblyArray"
	; Call TransferListToPOSCorpHangar "XLargeShipAssemblyArray" etc
	; Call TransferListToPOSCorpHangar "CorpHangarArray"
	; CompressionArray
	function TransferListToPOSCorpHangar(string LSAAObject)
	{
		variable float VolumeToMove=0
		variable index:int64 ListToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		call ${LSAAObject}.Open ${${LSAAObject}.ActiveCan}
		EVEWindow["Inventory"].ChildWindow[${${LSAAObject}.ActiveCan}]:MakeActive
		wait 1

		TripHauled:Set[0]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) < ${Math.Calc[${${LSAAObject}.CargoFreeSpace} - ${VolumeToMove}]}
				{
					TripHauled:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
					UI:UpdateConsole["TransferListToPOSCorpHangar(${LSAAObject}): Bulk Transferring Cargo: ${CargoIterator.Value.Name} * ${CargoIterator.Value.Quantity} Free Space: ${${LSAAObject}.CargoFreeSpace}"]
					ListToMove:Insert[${CargoIterator.Value.ID}]
					VolumeToMove:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
				}
				else
				{
					TripHauled:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
					UI:UpdateConsole["TransferListToPOSCorpHangar(${LSAAObject}): Transferring Cargo: ${CargoIterator.Value.Name} * ${CargoIterator.Value.Quantity} Free Space: ${${LSAAObject}.CargoFreeSpace}"]
					CargoIterator.Value:MoveTo[${${LSAAObject}.ActiveCan}, CorpHangars, ${Math.Calc[(${${LSAAObject}.CargoFreeSpace} - ${VolumeToMove}) / ${CargoIterator.Value.Volume}]}, "Corporation Folder 1"]
					break
				}
			}
			while ${CargoIterator:Next(exists)}
			if ${ListToMove.Used}
			{
				EVE:MoveItemsTo[ListToMove, ${${LSAAObject}.ActiveCan}, CorpHangars, "Corporation Folder 1"]
			}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToPOSCorpHangar(${LSAAObject}): Nothing found to move"]
			return
		}

		${LSAAObject}:StackAllCargo[${${LSAAObject}.ActiveCan}]

		if ${CurrentHour} != ${Time.Hour}
		{
			HourHauled:Set[0]
			CurrentHour:Set[${Time.Hour}]
		}

		HourHauled:Inc[${TripHauled}]
		TotalHauled:Inc[${TripHauled}]

		call ChatIRC.Say "Hauled: ${TripHauled.Round} m3    This Hour: ${HourHauled.Round} m3    Total: ${TotalHauled.Round} m3"
	}

	function TransferListFromLargeShipAssemblyArray()
	{
		variable float VolumeToMove=0
		variable index:int64 ListToMove
		variable index:item LSAACargo
		variable iterator CargoIterator

		call LargeShipAssemblyArray.Open ${LargeShipAssemblyArray.ActiveCan}

		Entity[${LargeShipAssemblyArray.ActiveCan}]:GetCorpHangarsCargo[LSAACargo]
		LSAACargo:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
				do
				{
						if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) < ${Math.Calc[${Ship.CargoFreeSpace} - ${VolumeToMove}]}
						{
							ListToMove:Insert[${CargoIterator.Value.ID}]
							VolumeToMove:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
						}
						else
						{
							CargoIterator.Value:MoveTo[MyShip, CargoHold, ${Math.Calc[(${Ship.CargoFreeSpace} - ${VolumeToMove}) / ${CargoIterator.Value.Volume}]}]
							break
						}
				}
				while ${CargoIterator:Next(exists)}
				if ${ListToMove.Used}
				{
					EVE:MoveItemsTo[ListToMove, MyShip, CargoHold]
				}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListFromLargeShipAssemblyArray: Nothing found to move"]
			return
		}

	}

	function TransferListToJetCan()
	{
		variable int QuantityToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				if ${JetCan.IsReady[TRUE]}
				{
					call JetCan.Open ${JetCan.ActiveCan}

					if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${JetCan.CargoFreeSpace}
					{
						if ${CargoIterator.Value.Volume} > 1.0
						{
							QuantityToMove:Set[${Math.Calc[${JetCan.CargoFreeSpace} / ${CargoIterator.Value.Volume}]}]
						}
						else
						{
							; Move only what will fit, minus 1 to account for CCP rounding errors.
							QuantityToMove:Set[${Math.Calc[${JetCan.CargoFreeSpace} / ${CargoIterator.Value.Volume} - 1]}]
						}
					}
					else
					{
						QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					}

					UI:UpdateConsole["TransferListToJetCan: Transferring Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name} - Jetcan Free Space: ${JetCan.CargoFreeSpace}"]
					CargoIterator.Value:MoveTo[${JetCan.ActiveCan}, CargoHold, ${QuantityToMove}]
				}
				else
				{
					UI:UpdateConsole["TransferListToJetCan: Ejecting Cargo: ${CargoIterator.Value.Quantity} units of ${CargoIterator.Value.Name}"]
					CargoIterator.Value:Jettison
					call JetCan.WaitForCan
					JetCan:Rename
				}
			}
			while ${CargoIterator:Next(exists)}
			;JetCan:StackAllCargo
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToJetCan: Nothing found to move"]
		}
	}

	member:int QuantityToMove(item src, item dest)
	{
		variable int qty = 0

		UI:UpdateConsole["DEBUG: QuantityToMove: ${src} ${dest}"]

		if ${src(exists)}
		{
			if ${dest(exists)} && ${dest} > 0
			{	/* assume destination is a container */
				if (${src.Quantity} * ${src.Volume}) > ${This.ContainerFreeSpace[${dest}]}
				{
					if ${src.Volume} > 1.0
					{
						qty:Set[${Math.Calc[${This.ContainerFreeSpace[${dest}]} / ${src.Volume}]}]
					}
					else
					{
						; Move only what will fit, minus 1 to account for CCP rounding errors.
						qty:Set[${Math.Calc[${This.ContainerFreeSpace[${dest}]} / ${src.Volume} - 1]}]
					}
				}
				else
				{
					qty:Set[${src.Quantity}]
				}
			}
			else
			{	/* assume destination is ship's cargo hold */
				if (${src.Quantity} * ${src.Volume}) > ${Ship.CargoFreeSpace}
				{
					if ${src.Volume} > 1.0
					{
						qty:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${src.Volume}]}]
					}
					else
					{
						; Move only what will fit, minus 1 to account for CCP rounding errors.
						qty:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${src.Volume} - 1]}]
					}
				}
				else
				{
					qty:Set[${src.Quantity}]
				}
			}
		}

		UI:UpdateConsole["DEBUG: QuantityToMove: returning ${qty}"]

		return ${qty}
	}

	function TransferListToShipWithContainers()
	{
		variable iterator   listItemIterator
		variable index:item shipItemIndex
		variable iterator   shipItemIterator
		variable index:item shipContainerIndex
		variable iterator   shipContainerIterator
		variable int qty
		variable int cnt
		variable int idx

		if ${This.CargoToTransfer.Used} == 0
		{
			return
		}

		call Ship.OpenCargo

		/* build the container list */
		MyShip:GetCargo[shipItemIndex]
		shipItemIndex:GetIterator[shipItemIterator]
		shipContainerIndex:Clear
		if ${shipItemIterator:First(exists)}
		do
		{
			if ${shipItemIterator.Value.GroupID} == GROUPID_SECURE_CONTAINER
			{
				shipContainerIndex:Insert[${shipItemIterator.Value.ID}]
			}
		}
		while ${shipItemIterator:Next(exists)}

		/* move the list to containers */
		shipContainerIndex:GetIterator[shipContainerIterator]
		if ${shipContainerIterator:First(exists)}
		do
		{
			shipContainerIterator.Value:Open
			wait 15
			cnt:Set[${This.CargoToTransfer.Used}]
			for (idx:Set[1] ; ${idx}<=${cnt} ; idx:Inc)
			{
				variable float usedSpace
				variable float totalSpace

				do
				{
					usedSpace:Set[${shipContainerIterator.Value.UsedCargoCapacity}]
					wait 2
				}
				while ${usedSpace} < 0
				totalSpace:Set[${shipContainerIterator.Value.Capacity}]
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: used space = ${usedSpace}"]
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: total space = ${totalSpace}"]
				if (${This.CargoToTransfer.Get[${idx}].Quantity} * ${This.CargoToTransfer.Get[${idx}].Volume}) > ${Math.Calc[${totalSpace}-${usedSpace}]}
				{
					if ${This.CargoToTransfer.Get[${idx}].Volume} > 1.0
					{
						qty:Set[${Math.Calc[${totalSpace}-${usedSpace} / ${This.CargoToTransfer.Get[${idx}].Volume}]}]
					}
					else
					{
						; Move only what will fit, minus 1 to account for CCP rounding errors.
						qty:Set[${Math.Calc[${totalSpace}-${usedSpace} / ${This.CargoToTransfer.Get[${idx}].Volume} - 1]}]
					}
				}
				else
				{
					qty:Set[${This.CargoToTransfer.Get[${idx}].Quantity}]
				}
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: quantity = ${qty}"]
				if ${qty} > 0
				{
					UI:UpdateConsole["TransferListToShipWithContainers: Loading Cargo: ${qty} units (${Math.Calc[${qty} * ${This.CargoToTransfer.Get[${idx}].Volume}]}m3) of ${This.CargoToTransfer.Get[${idx}].Name}"]
					This.CargoToTransfer.Get[${idx}]:MoveTo[${shipContainerIterator.Value.ID}, CargoHold, ${qty}]
					wait 15
				}
				if ${qty} == ${This.CargoToTransfer.Get[${idx}].Quantity}
				{
					This.CargoToTransfer:Remove[${idx}]
				}
				do
				{
					usedSpace:Set[${shipContainerIterator.Value.UsedCargoCapacity}]
					wait 2
				}
				while ${usedSpace} < 0
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: used space = ${usedSpace}"]
				if ${Math.Calc[${totalSpace}-${usedSpace}]} > ${Math.Calc[${totalSpace}*0.98]}
				{
					UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: Container full."]
					break
				}
			}
			This.CargoToTransfer:Collapse
			shipContainerIterator.Value:Close

			if ${This.CargoToTransfer.Used} == 0
			{	/* everything moved */
				break
			}
		}
		while ${shipContainerIterator:Next(exists)}

		/* move the list to the ship */
		cnt:Set[${This.CargoToTransfer.Used}]
		for (idx:Set[1] ; ${idx}<=${cnt} ; idx:Inc)
		{
			qty:Set[${This.QuantityToMove[${This.CargoToTransfer.Get[${idx}]},0]}]
			if ${qty} > 0
			{
				UI:UpdateConsole["TransferListToShipWithContainers: Loading Cargo: ${qty} units (${Math.Calc[${qty} * ${This.CargoToTransfer.Get[${idx}].Volume}]}m3) of ${This.CargoToTransfer.Get[${idx}].Name}"]
				This.CargoToTransfer.Get[${idx}]:MoveTo[MyShip, CargoHold, ${qty}]
				wait 15
			}
			if ${qty} == ${This.CargoToTransfer.Get[${idx}].Quantity}
			{
				This.CargoToTransfer:Remove[${idx}]
			}
			;if ${Ship.CargoFull}
			;{
			;	UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
			;	break
			;}
		}
		This.CargoToTransfer:Collapse
	}

	function TransferListToShip()
	{
		variable int QuantityToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			call Ship.OpenCargo
			if ${This.ShipHasContainers}
			{
				call This.TransferListToShipWithContainers
			}
			else
			{
				do
				{
					if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${Ship.CargoFreeSpace}
					{
						if ${CargoIterator.Value.Volume} > 1.0
						{
							QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${CargoIterator.Value.Volume}]}]
						}
						else
						{
							; Move only what will fit, minus 1 to account for CCP rounding errors.
							QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${CargoIterator.Value.Volume} - 1]}]
						}
					}
					else
					{
						QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					}

					UI:UpdateConsole["TransferListToShip: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					UI:UpdateConsole["TransferListToShip: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
					if ${QuantityToMove} > 0
					{
						CargoIterator.Value:MoveTo[MyShip, CargoHold, ${QuantityToMove}]
						wait 15
					}

					if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
					{
						UI:UpdateConsole["DEBUG: TransferListToShip: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
						break
					}
				}
				while ${CargoIterator:Next(exists)}
			}
			wait 10
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToShip: Nothing found to move"]
		}
	}

	function TransferOreToCorpHangarArray()
	{
		if ${CorpHangarArray.IsReady}
		{
			if ${Entity[${CorpHangarArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${CorpHangarArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:ConsoleUpdate["No Hangar Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToPOSCorpHangar "CorpHangarArray"

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToLargeShipAssemblyArray()
	{
		if ${LargeShipAssemblyArray.IsReady}
		{
			if ${Entity[${LargeShipAssemblyArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${LargeShipAssemblyArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:ConsoleUpdate["No Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToPOSCorpHangar "LargeShipAssemblyArray"

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToCompressionArray()
	{
		if ${CompressionArray.IsReady}
		{
			if ${Entity[${CompressionArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${CompressionArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:ConsoleUpdate["No Compression Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToPOSCorpHangar "CompressionArray"

		This.CargoToTransfer:Clear[]
	}

	function TransferCargoToLargeShipAssemblyArray()
	{
		if ${LargeShipAssemblyArray.IsReady}
		{
			if ${Entity[${LargeShipAssemblyArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${LargeShipAssemblyArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:ConsoleUpdate["No Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		This:FindAllShipCargo
		call This.TransferListToPOSCorpHangar "LargeShipAssemblyArray"

		This.CargoToTransfer:Clear[]
	}

	function TransferCargoFromLargeShipAssemblyArray()
	{
		if ${LargeShipAssemblyArray.IsReady}
		{
			if ${Entity[${LargeShipAssemblyArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${LargeShipAssemblyArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:ConsoleUpdate["No Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		call This.TransferListFromLargeShipAssemblyArray
	}

	function TransferOreToXLargeShipAssemblyArray()
	{
		if ${XLargeShipAssemblyArray.IsReady}
		{
			if ${Entity[${XLargeShipAssemblyArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${XLargeShipAssemblyArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:ConsoleUpdate["No Extra Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToPOSCorpHangar "XLargeShipAssemblyArray"

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToJetCan()
	{
		UI:UpdateConsole["Transferring Ore to JetCan"]

		call Ship.OpenCargo

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToJetCan

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToStationHangar()
	{
		while !${Station.Docked}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for dock..."]
			wait 10
		}

		; Need to cycle the the cargohold after docking to update the list.
		call This.CloseHolds

		UI:UpdateConsole["Transferring Ore to Station Hangar"]
		call This.OpenHolds

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToStationHangar

		This.CargoToTransfer:Clear[]
		EVEWindow[ByName, "hangarFloor"]:StackAll
		Ship:UpdateBaselineUsedCargo[]
		call This.ReplenishCrystals
		call This.CloseHolds
	}
	; Transfer ALL items in MyCargo index
	function TransferListToStationHangar()
	{
		variable index:int64 ListToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		TripHauled:Set[0]
		if ${CargoIterator:First(exists)}
		{
			call Station.OpenHangar
			do
			{
				UI:UpdateConsole["TransferListToStationHangar: Unloading Cargo: ${CargoIterator.Value.Name} x ${CargoIterator.Value.Quantity}"]
				UI:UpdateConsole["TransferListToStationHangar: Unloading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}", LOG_DEBUG]
				if ${CargoIterator.Value.GroupID} == GROUPID_SECURE_CONTAINER
				{
					call This.TransferContainerToHangar ${CargoIterator.Value.ID}
				}
				else
				{
					ListToMove:Insert[${CargoIterator.Value.ID}]
					TripHauled:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
				}
			}
			while ${CargoIterator:Next(exists)}
			if ${ListToMove.Used}
			{
				UI:UpdateConsole["Moving ${ListToMove.Used} items to hangar."]
				EVE:MoveItemsTo[ListToMove, MyStationHangar, Hangar]
				wait 10
			}
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToStationHangar: Nothing found to move"]
		}
		EVE:StackItems[MyStationHangar,Hangar]

		if ${CurrentHour} != ${Time.Hour}
		{
			HourHauled:Set[0]
			CurrentHour:Set[${Time.Hour}]
		}

		HourHauled:Inc[${TripHauled}]
		TotalHauled:Inc[${TripHauled}]

		call ChatIRC.Say "Hauled: ${TripHauled.Round} m3    This Hour: ${HourHauled.Round} m3    Total: ${TotalHauled.Round} m3"
		EVEWindow[ByItemID, ${MyShip.ID}]:StackAll
		wait 10

	}

	function TransferListToShipCorporateHangar(int64 dest)
	{
		variable index:int64 ListToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["TransferListToShipCorporateHangar: Unloading Cargo: ${CargoIterator.Value.Name} x ${CargoIterator.Value.Quantity}"]
				UI:UpdateConsole["TransferListToShipCorporateHangar: Unloading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}", LOG_DEBUG]

				ListToMove:Insert[${CargoIterator.Value.ID}]
				if ${ListToMove.Used}
				{
					UI:UpdateConsole["Moving ${ListToMove.Used} items to hangar."]
					CargoIterator.Value:MoveTo[${dest}, FleetHangar, ${CargoIterator.Value.Quantity}]
					;EVE:MoveItemsTo[ListToMove, ${dest}, CorpHangars]
					wait 10
					;EVEWindow[ByItemID, ${dest}]:StackAll
				}
			}
			while ${CargoIterator:Next(exists)}

		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToShipCorporateHangar: Nothing found to move"]
		}
	}

	function TransferOreToShipCorpHangar(int64 dest)
	{
		UI:UpdateConsole["Transferring Ore to Corp Hangar"]
		;call Ship.OpenCargo

		if ${MyShip.HasOreHold}
		{
			MyShip:GetOreHoldCargo[This.CargoToTransfer]
		}
		else
		{
			This:FindShipCargo[CATEGORYID_ORE]
		}
		call This.TransferListToShipCorporateHangar ${dest}

		This.CargoToTransfer:Clear[]
	}

	function TransferCargoToStationHangar()
	{
		while !${Station.Docked}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for dock..."]
			wait 10
		}

		/* Need to cycle the the cargohold after docking to update the list. */
		call This.CloseHolds

		UI:UpdateConsole["Transferring Cargo to Station Hangar"]
		call This.OpenHolds

		/* FOR NOW move all cargo.  Add filtering later */
		This:FindAllShipCargo

		call This.TransferListToStationHangar

		This.CargoToTransfer:Clear[]
		Ship:UpdateBaselineUsedCargo[]
		call This.CloseHolds
	}

	function TransferCargoToCorpHangarArray()
	{

		/* Need to cycle the the cargohold after docking to update the list. */
		call This.CloseHolds

		UI:UpdateConsole["Transferring Cargo to Corp Hangar Array"]
		call This.OpenHolds

		/* FOR NOW move all cargo.  Add filtering later */
		This:FindAllShipCargo

		call This.TransferListToPOSCorpHangar "CorpHangarArray"

		This.CargoToTransfer:Clear[]
		EVEWindow[ByName, "hangarFloor"]:StackAll
		Ship:UpdateBaselineUsedCargo[]
		call This.CloseHolds
	}

	function TransferCargoToShip()
	{
		if !${Station.Docked}
		{
			/* TODO - Support picking up from entities in space */
			m_LastTransferComplete:Set[TRUE]
		}
		else
		{
			/* Need to cycle the the cargohold after docking to update the list. */
			call This.CloseHolds

			UI:UpdateConsole["Transferring Cargo from Station Hangar"]
			call This.OpenHolds

			/* FOR NOW move all cargo.  Add filtering later */
			Me:GetHangarItems[This.CargoToTransfer]

			if ${This.CargoToTransfer.Used} > 0
			{
				call This.TransferListToShip

				This.CargoToTransfer:Clear[]
				EVEWindow[ByItemID, ${MyShip.ID}]:StackAll
				Ship:UpdateBaselineUsedCargo[]
				call This.CloseHolds

				/* Check for leftover items in the station */
				/* FOR NOW check all cargo.  Add filtering later */
				Me:GetHangarItems[This.CargoToTransfer]
				if ${This.CargoToTransfer.Used} > 0
				{
					This.CargoToTransfer:Clear[]
					UI:UpdateConsole["Could not carry all the cargo from the station hangar"]
					m_LastTransferComplete:Set[FALSE]
				}
				else
				{
					UI:UpdateConsole["Transfered all cargo from the station hangar"]
					m_LastTransferComplete:Set[TRUE]
				}
			}
			else
			{	/* Only set m_LastTransferComplete if we actually transfered something */
				UI:UpdateConsole["Couldn't find any cargo in the station hangar"]
				m_LastTransferComplete:Set[FALSE]
			}
		}
	}

	function TransferHangarItemToShip(int typeID)
	{
		if !${Station.Docked}
		{
			/* TODO - Support picking up from entities in space */
			m_LastTransferComplete:Set[TRUE]
		}
		else
		{
			/* Need to cycle the the cargohold after docking to update the list. */
			call This.CloseHolds

			UI:UpdateConsole["Transferring Item (${typeID}) from Station Hangar"]
			call This.OpenHolds

			variable index:item cargoIndex
			variable iterator cargoIterator
			Me:GetHangarItems[cargoIndex]
			cargoIndex:GetIterator[cargoIterator]
			This.CargoToTransfer:Clear

			if ${cargoIterator:First(exists)}
			{
				do
				{
					UI:UpdateConsole["DEBUG: ${cargoIterator.Value.Type}(${cargoIterator.Value.TypeID})"]
					if ${typeID} == ${cargoIterator.Value.TypeID}
					{
						This.CargoToTransfer:Insert[${cargoIterator.Value.ID}]
					}
				}
				while ${cargoIterator:Next(exists)}
			}

			if ${This.CargoToTransfer.Used} > 0
			{
				call This.TransferListToShip

				This.CargoToTransfer:Clear[]
				EVEWindow[ByItemID, ${MyShip.ID}]:StackAll
				Ship:UpdateBaselineUsedCargo[]
				call This.CloseHolds

				/* Check for leftover items in the station */
				Me:GetHangarItems[cargoIndex]
				cargoIndex:GetIterator[cargoIterator]
				This.CargoToTransfer:Clear

				if ${cargoIterator:First(exists)}
				{
					do
					{
						if ${typeID} == ${cargoIterator.Value.TypeID}
						{
							This.CargoToTransfer:Insert[${cargoIterator.Value.ID}]
						}
					}
					while ${cargoIterator:Next(exists)}
				}
				if ${This.CargoToTransfer.Used} > 0
				{
					This.CargoToTransfer:Clear[]
					UI:UpdateConsole["Could not carry all the cargo from the station hangar"]
					m_LastTransferComplete:Set[FALSE]
				}
				else
				{
					UI:UpdateConsole["Transfered all cargo from the station hangar"]
					m_LastTransferComplete:Set[TRUE]
				}
			}
			else
			{	/* Only set m_LastTransferComplete if we actually transfered something */
				UI:UpdateConsole["Couldn't find any cargo in the station hangar"]
				m_LastTransferComplete:Set[FALSE]
			}
		}
	}

	function TransferItemTypeToHangar(int typeID)
   {
	  if !${Station.Docked}
	  {
		 UI:UpdateConsole["ERROR: obj_Cargo.TransferItemTypeToHangar: Must be docked!"]
		 return
	  }

	  /* Need to cycle the the cargohold after docking to update the list. */
	  call This.CloseHolds

	  UI:UpdateConsole["Transferring Cargo to Station Hangar"]
	  call This.OpenHolds

	  This:FindShipCargoByType[${typeID}]

	  call This.TransferListToStationHangar

	  This.CargoToTransfer:Clear[]
	  EVEWindow[ByName, "hangarFloor"]:StackAll
	  Ship:UpdateBaselineUsedCargo[]
	  call This.CloseHolds
   }

	function TransferSpawnContainerCargoToShip()
	{
	}
}
