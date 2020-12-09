/*
	Cargo Class

	Interacting with Cargo of ship, hangar, and containers, and moving it.

	-- CyberTech

BUGS:


*/

objectdef obj_Cargo
{
	variable index:item CargoToTransfer
	variable bool m_LastTransferComplete
	variable index:string ActiveMiningCrystals
	variable float m_ContainerFreeSpace

	method Initialize()
	{
		Logger:Log["obj_Cargo: Initialized", LOG_MINOR]
	}

	member:bool LastTransferComplete()
	{
		return ${m_LastTransferComplete}
	}

	function ShipHasContainers()
	{
		variable index:item anItemIndex

		call Inventory.ShipCargo.Activate
		Inventory.ShipCargo:GetItems[anItemIndex, "GroupID == GROUPID_SECURE_CONTAINER"]
		if ${anItemIndex.Used} > 0
			return TRUE

		return FALSE
	}


	method DumpItem(item anItem)
	{
		Logger:Log["DEBUG: obj_Cargo: DumpItem: BasePrice:         ${anItem.BasePrice}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Capacity:          ${anItem.Capacity}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Category:          ${anItem.Category}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: CategoryID:        ${anItem.CategoryID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Description:       ${anItem.Description}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: GraphicID:         ${anItem.GraphicID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Group:             ${anItem.Group}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: GroupID:           ${anItem.GroupID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: ID:                ${anItem.ID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: IsContraband:      ${anItem.IsContraband}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: IsRepackable:      ${anItem.IsRepackable}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Location:          ${anItem.Location}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: LocationID:        ${anItem.LocationID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: MacroLocation:     ${anItem.MacroLocation}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: MacroLocationID:   ${anItem.MacroLocationID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: MarketGroupID:     ${anItem.MarketGroupID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Name:              ${anItem.Name}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: OwnerID:           ${anItem.OwnerID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: PortionSize:       ${anItem.PortionSize}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Quantity:          ${anItem.Quantity}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: RaceID:            ${anItem.RaceID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Radius:            ${anItem.Radius}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Slot:              ${anItem.Slot}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: SlotID:            ${anItem.SlotID}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Type:              ${anItem.Type}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: Volume:            ${anItem.Volume}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: CargoCapacity:     ${anItem.CargoCapacity}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: UsedCargoCapacity: ${anItem.UsedCargoCapacity}"]
		Logger:Log["DEBUG: obj_Cargo: DumpItem: GetCargo:          ${anItem.GetCargo}"]
		Logger:Log["========================================================"]

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

		This.ActiveMiningCrystals:GetIterator[CrystalIterator]

		; Add in any Crystals that were brought in from the laser modules
		if ${CrystalIterator:First(exists)}
		do
		{
			;echo Setting active crystal: ${CrystalIterator.Value} ${CrystalIterator.Value}
			Crystals:Set[${CrystalIterator.Value}, ${Math.Calc[${Crystals.Element[${CrystalIterator.Value}]} + 1]}]
		}
		while ${CrystalIterator:Next(exists)}

		call Inventory.ShipCargo.Activate
		if !${Inventory.ShipCargo.IsCurrent}
		{
			Logger:Log["ReplenishCrystals: Failed to activate ${Inventory.ShipCargo.EVEWindowParams}"]
			return
		}
		Inventory.Current:StackAll
		Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_CHARGE"]
		Inventory.Current.Items:GetIterator[CargoIterator]

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

		; No crystals types found to replenish, just return
		if !${Crystals.FirstKey(exists)}
		{
			return
		}

		if ${from} == -1
		{
			call Inventory.StationHangar.Activate ${Me.Station.ID}
			if !${Inventory.StationHangar.IsCurrent}
			{
				Logger:Log["ReplenishCrystals: Failed to activate ${Inventory.StationHangar.EVEWindowParams}"]
				return
			}
			Inventory.Current:StackAll
			Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_CHARGE"]
			Inventory.Current.Items:GetIterator[HangarIterator]

			; Cycle thru the Hangar looking for the needed Crystals and move them to the ship
			if ${HangarIterator:First(exists)}
			do
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
			while ${HangarIterator:Next(exists)}
		}
		else
		{
			call Inventory.OpenEntityFleetHangar ${from}
			call Inventory.EntityFleetHangar.Activate ${Return}
			Inventory.Current:StackAll
			Inventory.Current:GetItems[]
			Inventory.Current.Items:GetIterator[CargoIterator]

			; Cycle thru the Hangar looking for the needed Crystals and move them to the ship
			if ${CargoIterator:First(exists)}
			do
			{
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
		}

		; Did we get what we needed?
		if ${Crystals.FirstKey(exists)}
		do
		{
			if ${Crystals.CurrentValue} < ${MIN_CRYSTALS}
			{
					 Logger:Log["Out of ${Crystals.CurrentKey} !!"]
			}
		}
		while ${Crystals.NextKey(exists)}
	}


	function TransferContainerToHangar(item anItem)
	{
		if ${anItem.GroupID} == GROUPID_SECURE_CONTAINER
		{
			anItem:Open
			wait 15

			variable index:item anItemIndex
			variable index:int64  anIntIndex
			variable iterator CargoIterator

			anItem:GetCargo[anItemIndex]
			anItemIndex:GetIterator[CargoIterator]
			anIntIndex:Clear

			if ${CargoIterator:First(exists)}
			do
			{
				anIntIndex:Insert[${CargoIterator.Value.ID}]
			}
			while ${CargoIterator:Next(exists)}

			if ${anIntIndex.Used} > 0
			{
				EVE:MoveItemsTo[anIntIndex, ${Me.Station.ID}, Hangar]
				wait 15
			}

			anItem:Close
		}
		else
		{
			Logger:Log["TransferContainerToHangar: Not Supported!! ${CargoIterator.Value.Name}"]
		}
	}

	function TransferListToGSC(int64 dest)
	{
		variable index:item ShipCargo
		variable iterator CargoIterator
		variable int QuantityToMove

		Logger:Log["DEBUG: Offloading to GSC"]

		MyShip:GetCargo[ShipCargo]
		ShipCargo:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				QuantityToMove:Set[${This.CalcAmountToMove[${Math.Calc[${Entity[${dest}].CargoCapacity} - ${Entity[${dest}].UsedCargoCapacity}]}, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

				if ${QuantityToMove} == 0
				{
					Logger:Log["TransferListToGSC: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					continue
				}
				else
				{
					Logger:Log["TransferListToGSC: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				}

				CargoIterator.Value:MoveTo[${dest},CargoHold,${QuantityToMove}]
				wait 30
			}
			while ${CargoIterator:Next(exists)}
		}

	}

	function TransferListToCargoHold(weakref ListToMove)
	{
		variable iterator CargoIterator
		variable int QuantityToMove

		if ${ListToMove.Used} == 0
		{
			Logger:Log["TransferListToCargoHold: Nothing found to move", LOG_WARNING]
			return FALSE
		}

		ListToMove:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				QuantityToMove:Set[${This.CalcAmountToMove[${Ship.CargoFreeSpace}, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

				if ${QuantityToMove} == 0
				{
					Logger:Log["TransferListToCargoHold: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					continue
				}
				else
				{
					Logger:Log["TransferListToCargoHold: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				}

				CargoIterator.Value:MoveTo[${MyShip.ID}, CargoHold, ${QuantityToMove}]
				wait 15
			}
			while ${CargoIterator:Next(exists)}
			return TRUE
		}
		return FALSE
	}

	function TransferListToOreHold(weakref ListToMove)
	{
		variable iterator CargoIterator
		variable int QuantityToMove

		if ${ListToMove.Used} == 0
		{
			Logger:Log["TransferListToOreHold: Nothing found to move", LOG_WARNING]
			return FALSE
		}

		ListToMove:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				QuantityToMove:Set[${This.CalcAmountToMove[${Ship.OreHoldFreeSpace}, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

				if ${QuantityToMove} == 0
				{
					Logger:Log["TransferListToOreHold: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					continue
				}
				else
				{
					Logger:Log["TransferListToOreHold: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				}

				CargoIterator.Value:MoveTo[${MyShip.ID}, OreHold, ${QuantityToMove}]
				wait 15
			}
			while ${CargoIterator:Next(exists)}
			return TRUE
		}
		return FALSE
	}

	function TransferOreFromEntityFleetHangarToCargoHold(int64 SourceID)
	{
		Logger:Log["Moving ore from Entity ${SourceID} to Ship Cargo Hold"]

		call Inventory.OpenEntityFleetHangar ${SourceID}
		call Inventory.EntityFleetHangar.Activate ${SourceID}
		if ${Inventory.EntityFleetHangar.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_ORE"]
			call TransferListToCargoHold Inventory.Current.Items
		}
	}

	function TransferOreFromEntityFleetHangarToOreHold(int64 SourceID)
	{
		if !${MyShip.HasOreHold}
		{
			Logger:Log["TransferOreFromEntityFleetHangarToOreHold - No Ore Hold Detected!", LOG_DEBUG]
			return
		}

		Logger:Log["Moving ore from Entity ${SourceID} to Ship Ore Hold"]

		call Inventory.OpenEntityFleetHangar ${SourceID}
		call Inventory.EntityFleetHangar.Activate ${SourceID}
		if ${Inventory.EntityFleetHangar.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_ORE"]
			call TransferListToOreHold Inventory.Current.Items
		}
	}

	; Transfer cargo from my ships fleet hangar to my ships ore hold
	function TransferOreFromShipFleetHangarToOreHold()
	{
		if !${MyShip.HasOreHold}
		{
			Logger:Log["TransferOreFromShipFleetHangarToOreHold - No Ore Hold Detected!", LOG_DEBUG]
			return
		}

		Logger:Log["Moving ore from Ship Fleet Hangar to Ship Ore Hold"]

		call Inventory.ShipFleetHangar.Activate
		if ${Inventory.ShipFleetHangar.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_ORE"]
			call TransferListToOreHold Inventory.Current.Items
		}
	}

	function TransferCargoFromShipOreHoldToStation()
	{
		variable int QuantityToMove
		variable iterator CargoIterator
		if !${MyShip.HasOreHold}
		{
			return
		}

		Logger:Log["Moving ore from Ship Ore Hold to Station Hangar"]

		call Inventory.ShipOreHold.Activate
		if !${Inventory.ShipOreHold.IsCurrent}
		{
			return
		}
		Inventory.Current:StackAll
		Inventory.Current:GetItems[]
		Inventory.Current.Items:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				QuantityToMove:Set[${This.CalcAmountToMove[MAX_CARGO_SPACE, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

				if ${QuantityToMove} == 0
				{
					Logger:Log["TransferCargoFromShipOreHoldToStation: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					continue
				}
				else
				{
					Logger:Log["TransferCargoFromShipOreHoldToStation: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				}

				CargoIterator.Value:MoveTo[MyStationHangar, Hangar, ${QuantityToMove}]
				wait 15
			}
			while ${CargoIterator:Next(exists)}
		}
		else
		{
			Logger:Log["DEBUG: obj_Cargo:TransferCargoFromShipOreHoldToStation: Nothing found to move", LOG_DEBUG]
		}
	}

	function TransferCargoFromShipCorporateHangarToStation()
	{
		variable int QuantityToMove
		variable iterator CargoIterator
		if !${MyShip.HasFleetHangars}
		{
			return
		}

		call Inventory.ShipFleetHangar.Activate
		if !${Inventory.ShipFleetHangar.IsCurrent}
		{
			return
		}
		Inventory.Current:GetItems[]
		Inventory.Current.Items:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				QuantityToMove:Set[${This.CalcAmountToMove[MAX_CARGO_SPACE, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

				if ${QuantityToMove} == 0
				{
					Logger:Log["TransferCargoFromShipCorporateHangarToStation: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					continue
				}
				else
				{
					Logger:Log["TransferCargoFromShipCorporateHangarToStation: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				}

				CargoIterator.Value:MoveTo[MyStationHangar, Hangar, ${QuantityToMove}]
				wait 15
			}
			while ${CargoIterator:Next(exists)}
		}
		else
		{
			Logger:Log["DEBUG: obj_Cargo:TransferCargoFromShipCorporateHangarToStation: Nothing found to move"]
		}
	}

	function TransferOreFromShipFleetHangarToCargoHold()
	{
		variable int QuantityToMove
		variable iterator CargoIterator

		call Inventory.ShipFleetHangar.Activate
		if !${Inventory.ShipFleetHangar.IsCurrent}
		{
			return
		}
		Inventory.Current:StackAll
		Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_ORE"]
		Inventory.Current.Items:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				QuantityToMove:Set[${This.CalcAmountToMove[${Ship.CargoFreeSpace}, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

				if ${QuantityToMove} == 0
				{
					Logger:Log["TransferCargoFromShipCorporateHangarToStation: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					continue
				}
				else
				{
					Logger:Log["TransferCargoFromShipCorporateHangarToStation: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				}

				CargoIterator.Value:MoveTo[${MyShip.ID}, CargoHold, ${QuantityToMove}]
				wait 15
			}
			while ${CargoIterator:Next(exists)}
		}
		else
		{
			Logger:Log["TransferOreFromShipFleetHangarToCargoHold: Nothing found to move", LOG_DEBUG]
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
		call Inventory.EntityContainer.Activate ${${LSAAObject}.ActiveCan}

		if ${CargoIterator:First(exists)}
		{
			do
			{
				if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) < ${Math.Calc[${${LSAAObject}.CargoFreeSpace} - ${VolumeToMove}]}
				{
					Logger:Log["TransferListToPOSCorpHangar(${LSAAObject}): Bulk Transferring Cargo: ${CargoIterator.Value.Name} * ${CargoIterator.Value.Quantity} Free Space: ${${LSAAObject}.CargoFreeSpace}"]
					ListToMove:Insert[${CargoIterator.Value.ID}]
					VolumeToMove:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
				}
				else
				{
					Logger:Log["TransferListToPOSCorpHangar(${LSAAObject}): Transferring Cargo: ${CargoIterator.Value.Name} * ${CargoIterator.Value.Quantity} Free Space: ${${LSAAObject}.CargoFreeSpace}"]
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
			Logger:Log["DEBUG: obj_Cargo:TransferListToPOSCorpHangar(${LSAAObject}): Nothing found to move"]
			return
		}

		${LSAAObject}:StackAllCargo[${${LSAAObject}.ActiveCan}]
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

					QuantityToMove:Set[${This.CalcAmountToMove[${JetCan.CargoFreeSpace}, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]

					if ${QuantityToMove} == 0
					{
						Logger:Log["TransferListToJetCan: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
						continue
					}
					else
					{
						Logger:Log["TransferListToJetCan: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					}

					CargoIterator.Value:MoveTo[${JetCan.ActiveCan}, CargoHold, ${QuantityToMove}]
				}
				else
				{
					Logger:Log["TransferListToJetCan: Ejecting Cargo: ${CargoIterator.Value.Quantity} units of ${CargoIterator.Value.Name}"]
					CargoIterator.Value:Jettison
					call JetCan.WaitForCan
					JetCan:Rename
				}
			}
			while ${CargoIterator:Next(exists)}
			JetCan:StackAllCargo
		}
		else
		{
			Logger:Log["DEBUG: obj_Cargo:TransferListToJetCan: Nothing found to move"]
		}
	}

	member:int QuantityToMove(item src, item dest)
	{
		variable int qty = 0

		Logger:Log["DEBUG: QuantityToMove: ${src} ${dest}"]

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

		Logger:Log["DEBUG: QuantityToMove: returning ${qty}"]

		return ${qty}
	}

	function TransferListToShipWithContainers()
	{
		variable iterator   listItemIterator
		variable index:item shipContainerIndex
		variable iterator   shipContainerIterator
		variable int qty
		variable int cnt
		variable int idx

		if ${This.CargoToTransfer.Used} == 0
		{
			return
		}

		call Inventory.ShipCargo.Activate
		if !${Inventory.ShipCargo.IsCurrent}
		{
			Logger:Log["TransferListToShipWithContainers: Failed to activate ${Inventory.ShipCargo.EVEWindowParams}"]
			return
		}
		Inventory.Current:StackAll
		Inventory.Current:GetItems[shipContainerIndex, "CategoryID == GROUPID_SECURE_CONTAINER"]

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
				;;Logger:Log["DEBUG: TransferListToShipWithContainers: used space = ${usedSpace}"]
				;;Logger:Log["DEBUG: TransferListToShipWithContainers: total space = ${totalSpace}"]
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
				;;Logger:Log["DEBUG: TransferListToShipWithContainers: quantity = ${qty}"]
				if ${qty} > 0
				{
					Logger:Log["TransferListToShipWithContainers: Loading Cargo: ${qty} units (${Math.Calc[${qty} * ${This.CargoToTransfer.Get[${idx}].Volume}].Precision[2]}m3) of ${This.CargoToTransfer.Get[${idx}].Name}"]
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
				;;Logger:Log["DEBUG: TransferListToShipWithContainers: used space = ${usedSpace}"]
				if ${Math.Calc[${totalSpace}-${usedSpace}]} > ${Math.Calc[${totalSpace}*0.98]}
				{
					Logger:Log["DEBUG: TransferListToShipWithContainers: Container full."]
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
				Logger:Log["TransferListToShipWithContainers: Loading Cargo: ${qty} units (${Math.Calc[${qty} * ${This.CargoToTransfer.Get[${idx}].Volume}].Precision[2]}m3) of ${This.CargoToTransfer.Get[${idx}].Name}"]
				This.CargoToTransfer.Get[${idx}]:MoveTo[MyShip, CargoHold, ${qty}]
				wait 15
			}
			if ${qty} == ${This.CargoToTransfer.Get[${idx}].Quantity}
			{
				This.CargoToTransfer:Remove[${idx}]
			}
			;if ${Ship.CargoFull}
			;{
			;	Logger:Log["DEBUG: TransferListToShipWithContainers: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
			;	break
			;}
		}
		This.CargoToTransfer:Collapse
	}

	member:int CalcAmountToMove(float FreeSpace, int Quantity, float Volume)
	{
		variable int QuantityToMove

		; Move only what will fit, minus 0.1 to account for CCP rounding errors.
		;echo if (${Quantity} * ${Volume}) > (${FreeSpace}-0.1)
		if (${Quantity} * ${Volume}) > (${FreeSpace}-0.1)
		{
			;echo Math.Calc[(${FreeSpace} - 0.1) / ${Volume}]
			QuantityToMove:Set[${Math.Calc[(${FreeSpace} - 0.1) / ${Volume}]}]
			if ${QuantityToMove} < ${Quantity}
			{
				return ${QuantityToMove}
			}
		}
		return ${Quantity}
	}

	function TransferListToShip()
	{
		variable int QuantityToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${This.CargoToTransfer.Used} == 0
		{
			Logger:Log["DEBUG: obj_Cargo:TransferListToShip: Nothing found to move"]
			return
		}

		if ${CargoIterator:First(exists)}
		{
			call Cargo.ShipHasContainers
			if ${Return}
			{
				call This.TransferListToShipWithContainers
			}
			else
			{
				do
				{
					QuantityToMove:Set[${This.CalcAmountToMove[${Ship.CargoFreeSpace}, ${CargoIterator.Value.Quantity}, ${CargoIterator.Value.Volume}]}]
					if ${QuantityToMove} == 0
					{
						Logger:Log["TransferListToShip: Skipping - no space: ${CargoIterator.Value.Quantity} units (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
						continue
					}
					elseif ${QuantityToMove} == ${CargoIterator.Value.Quantity}
					{
						Logger:Log["TransferListToShip: Moving ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					}
					else
					{
						Logger:Log["TransferListToShip: Moving ${QuantityToMove}/${CargoIterator.Value.Quantity} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}].Precision[2]}m3) of ${CargoIterator.Value.Name} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
					}

					CargoIterator.Value:MoveTo[MyShip, CargoHold, ${QuantityToMove}]
					wait 15
				}
				while ${CargoIterator:Next(exists)}
			}
			; Wait a bit to let the eve client move the cargo
			wait 20
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
			Logger:Log["No Hangar Array found - nothing moved"]
			return
		}

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "CorpHangarArray"
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "CorpHangarArray"
		}

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
			Logger:Log["No Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "LargeShipAssemblyArray"
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "LargeShipAssemblyArray"
		}

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
			Logger:Log["No Compression Array found - nothing moved"]
			return
		}

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "CompressionArray"
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "CompressionArray"
		}

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
			Logger:Log["No Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer]
			call This.TransferListToPOSCorpHangar "LargeShipAssemblyArray"
		}

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
			Logger:Log["No Large Ship Assembly Array found - nothing moved"]
			return
		}

		variable float VolumeToMove = 0
		variable index:int64 ListToMove
		variable index:item LSAACargo
		variable iterator CargoIterator

		call Inventory.ShipCargo.Activate
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
			Logger:Log["DEBUG: obj_Cargo:TransferCargoFromLargeShipAssemblyArray: Nothing found to move"]
			return
		}
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
			Logger:Log["No Extra Large Ship Assembly Array found - nothing moved"]
			return
		}

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "XLargeShipAssemblyArray"
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToPOSCorpHangar "XLargeShipAssemblyArray"
		}

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToJetCan()
	{
		Logger:Log["Transferring Ore to JetCan"]

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToJetCan
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToJetCan
		}

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToStationHangar()
	{
		if !${Me.InStation}
		{
			Logger:Log["obj_Cargo: TransferOreToStationHangar called when not in station"]
			return
		}

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToStationHangar
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToStationHangar
		}

		This.CargoToTransfer:Clear[]
		Ship:UpdateBaselineUsedCargo[]
		call This.ReplenishCrystals
	}

	; Transfer ALL items in MyCargo index
	function TransferListToStationHangar()
	{
		variable index:int64 ListToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				Logger:Log["TransferListToStationHangar: Unloading Cargo: ${CargoIterator.Value.Name} x ${CargoIterator.Value.Quantity} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]
				if ${CargoIterator.Value.GroupID} == GROUPID_SECURE_CONTAINER
				{
					call This.TransferContainerToHangar ${CargoIterator.Value.ID}
				}
				else
				{
					ListToMove:Insert[${CargoIterator.Value.ID}]
				}
			}
			while ${CargoIterator:Next(exists)}
			if ${ListToMove.Used}
			{
				Logger:Log["Moving ${ListToMove.Used} items to hangar."]
				EVE:MoveItemsTo[ListToMove, MyStationHangar, Hangar]
				wait 15
			}
		}
		else
		{
			Logger:Log["DEBUG: obj_Cargo:TransferListToStationHangar: Nothing found to move"]
		}
		EVE:StackItems[MyStationHangar,Hangar]

		EVEWindow[ByItemID, ${MyShip.ID}]:StackAll
	}

	function TransferListToShipCorporateHangar(int64 dest)
	{
		variable index:int64 ListToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			call Inventory.OpenEntityFleetHangar ${dest}
			call Inventory.EntityFleetHangar.Activate ${dest}
			if !${Inventory.EntityFleetHangar.IsCurrent}
			{
				Logger:Log["DEBUG: obj_Cargo:TransferListToShipCorporateHangar: Unable to open target fleet hangar"]
				return false
			}

			do
			{
				Logger:Log["TransferListToShipCorporateHangar: Unloading Cargo: ${CargoIterator.Value.Name} x ${CargoIterator.Value.Quantity} (TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID})"]

				ListToMove:Insert[${CargoIterator.Value.ID}]
				if ${ListToMove.Used}
				{
					Logger:Log["Moving ${ListToMove.Used} items to hangar."]
					CargoIterator.Value:MoveTo[${dest}, FleetHangar, ${CargoIterator.Value.Quantity}]
					wait 15
				}
			}
			while ${CargoIterator:Next(exists)}
		}
		else
		{
			Logger:Log["DEBUG: obj_Cargo:TransferListToShipCorporateHangar: Nothing found to move"]
		}
	}

	function TransferOreToShipCorpHangar(int64 dest)
	{
		Logger:Log["Transferring Ore to Corp Hangar"]

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToShipCorporateHangar ${dest}
		}

		call Inventory.ShipOreHold.Activate
		if ${Inventory.ShipOreHold.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "CategoryID == CATEGORYID_ORE"]
			call This.TransferListToShipCorporateHangar ${dest}
		}

		This.CargoToTransfer:Clear[]
	}

	function TransferCargoToStationHangar()
	{
		if !${Me.InStation}
		{
			Logger:Log["obj_Cargo: TransferOreToStationHangar called when not in station"]
			return
		}

		Logger:Log["Transferring Cargo to Station Hangar"]

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer]
			call This.TransferListToStationHangar
		}
		else
		{
			Logger:Log["TransferOreToStationHangar: Failed to activate station hangar", LOG_ERROR]
			return FALSE
		}


		This.CargoToTransfer:Clear[]
		Ship:UpdateBaselineUsedCargo[]
		return TRUE
	}

	function TransferCargoToCorpHangarArray()
	{
		Logger:Log["Transferring Cargo to Corp Hangar Array"]

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer]
			call This.TransferListToPOSCorpHangar "CorpHangarArray"
		}

		This.CargoToTransfer:Clear[]
		EVEWindow[ByName, "hangarFloor"]:StackAll
		Ship:UpdateBaselineUsedCargo[]
	}

	function TransferHangarItemToShip(int typeID = -1)
	{
		variable string querystr

		if !${Station.Docked}
		{
			m_LastTransferComplete:Set[TRUE]
		}
		else
		{
			if ${typeID} == -1
			{
				Logger:Log["Transferring all items from Station Hangar to ship"]
			}
			else
			{
				Logger:Log["Transferring Item (${typeID}) from Station Hangar to ship"]
				querystr:Set["TypeID == ${typeID}"]
			}

			call Inventory.StationHangar.Activate ${Me.Station.ID}
			if !${Inventory.StationHangar.IsCurrent}
			{
				Logger:Log["TransferHangarItemToShip: Failed to activate station hangar", LOG_ERROR]
				return FALSE
			}

			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, ${querystr}]
			if ${This.CargoToTransfer.Used} == 0
			{
				Logger:Log["Couldn't find any cargo in the station hangar"]
				m_LastTransferComplete:Set[TRUE]
			}

			call This.TransferListToShip
			Ship:UpdateBaselineUsedCargo[]

			call Inventory.StationHangar.Activate ${Me.Station.ID}

			; Re-check the cargo.
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, ${querystr}]
			if ${This.CargoToTransfer.Used} > 0
			{
				Logger:Log["Could not carry all the cargo from the station hangar"]
				m_LastTransferComplete:Set[FALSE]
			}
			else
			{
				Logger:Log["Transfered all cargo from the station hangar"]
				m_LastTransferComplete:Set[TRUE]
			}
		}
		return TRUE
	}

	function TransferItemTypeToHangar(int typeID)
   {
	  if !${Station.Docked}
	  {
		 	Logger:Log["ERROR: obj_Cargo.TransferItemTypeToHangar: Must be docked!"]
		 	return
	  }

	  Logger:Log["Transferring Cargo to Station Hangar"]

		call Inventory.ShipCargo.Activate
		if ${Inventory.ShipCargo.IsCurrent}
		{
			Inventory.Current:StackAll
			Inventory.Current:GetItems[This.CargoToTransfer, "TypeID == ${typeID}"]
		  call This.TransferListToStationHangar
		}

	  This.CargoToTransfer:Clear[]
	  Ship:UpdateBaselineUsedCargo[]
   }

	function TransferSpawnContainerCargoToShip()
	{
	}
}
