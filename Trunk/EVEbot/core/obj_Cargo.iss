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
		call Ship.CloseCargo
		call Station.CloseHangar
	}

	member:int MaxQuantityForVolume(float FreeSpace, float Volume, int QuantityOnHand)
	{
		variable int64 Quantity

		if ${Volume} == 0
		{
			UI:UpdateConsole["Error: CalcMaxQuantityInSpace passed 0 for item volume"]
			return ${QuantityOnHand}
		}
		Quantity:Set[${Math.Calc[${FreeSpace} / ${Volume}].Round}]

		if ${Volume} < 1
		{
			; With large #'s of small volume items, sometimes EVE rounding errors cause us not to be able to move as much as we calc'd
			Quantity:Dec
		}

		if ${Quantity} < ${QuantityOnHand}
		{
			UI:UpdateConsole["DEBUG: CalcMaxQuantityInSpace returning ${Quantity}", LOG_DEBUG]
			return ${Quantity}
		}

		UI:UpdateConsole["DEBUG: CalcMaxQuantityInSpace returning ${QuantityOnHand}", LOG_DEBUG]
		return ${QuantityOnHand}
	}

	member:bool ShipHasContainers()
	{
		variable index:item anItemIndex
		variable iterator   anIterator

		MyShip:DoGetCargo[anItemIndex]
		anItemIndex:GetIterator[anIterator]
		if ${anIterator:First(exists)}
		do
		{
			;This:DumpItem[${anIterator.Value}]
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
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: GivenName:         ${anItem.GivenName}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: CargoCapacity:     ${anItem.CargoCapacity}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: UsedCargoCapacity: ${anItem.UsedCargoCapacity}"]
		UI:UpdateConsole["DEBUG: obj_Cargo: ShipHasContainers: GetCargo:          ${anItem.GetCargo}"]
		UI:UpdateConsole["========================================================"]

	}

	method FindAllShipCargo()
	{
		MyShip:DoGetCargo[This.MyCargo]

		variable iterator CargoIterator

		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			variable int CategoryID

			CategoryID:Set[${CargoIterator.Value.CategoryID}]
			;UI:UpdateConsole["DEBUG: obj_Cargo:FindAllShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.Name} - ${CargoIterator.Value.Quantity} (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]
			This.CargoToTransfer:Insert[${CargoIterator.Value}]
		}
		while ${CargoIterator:Next(exists)}

		;UI:UpdateConsole["DEBUG: obj_Cargo:FindAllShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
	}

	method FindShipCargo(int CategoryIDToMove)
	{
		MyShip:DoGetCargo[This.MyCargo]

		variable iterator CargoIterator

		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			variable int CategoryID

			CategoryID:Set[${CargoIterator.Value.CategoryID}]
			;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.Name} (${CargoIterator.Value.Quantity}) (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]

			if (${CategoryID} == ${CategoryIDToMove})
			{
				This.CargoToTransfer:Insert[${CargoIterator.Value}]
			}
		}
		while ${CargoIterator:Next(exists)}

		;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
	}

   method FindShipCargoByType(int TypeIDToMove)
   {
	  MyShip:DoGetCargo[This.MyCargo]

	  variable iterator CargoIterator

	  This.MyCargo:GetIterator[CargoIterator]
	  if ${CargoIterator:First(exists)}
	  do
	  {
		 variable int TypeID

		 TypeID:Set[${CargoIterator.Value.TypeID}]
		 UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: TypeID: ${TypeID} ${CargoIterator.Value.Name} (${CargoIterator.Value.Quantity}) (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]

		 if (${TypeID} == ${TypeIDToMove})
		 {
			This.CargoToTransfer:Insert[${CargoIterator.Value}]
		 }
	  }
	  while ${CargoIterator:Next(exists)}

	  UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
   }

	member:int CargoToTransferCount()
	{
		return ${This.CargoToTransfer.Used}
	}

	function ReplenishCrystals()
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
			;echo Setting active crystal: ${CrystalIterator.Value}
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

		call Station.OpenHangar
		Me:DoGetHangarItems[HangarItems]
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
								HangarIterator.Value:MoveTo[MyShip, ${needed}]
								Crystals:Set[${Crystals.CurrentKey}, ${Math.Calc[${Crystals.CurrentValue} + ${needed}]}]
							}
							else
							{
								HangarIterator.Value:MoveTo[MyShip]
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

	; Transfer the entire contents of a GSC to the hangar.
	function TransferContainerToHangar(item Container)
	{
		if ${Container.GroupID} == GROUPID_SECURE_CONTAINER
		{
			Container:Open
			wait 15

			variable index:item ContainerContents
			variable index:int64  anIntIndex
			variable iterator   anIterator

			Container:DoGetCargo[ContainerContents]
			ContainerContents:GetIterator[anIterator]
			anIntIndex:Clear

			if ${anIterator:First(exists)}
			do
			{
				anIntIndex:Insert[${anIterator.Value.ID}]
			}
			while ${anIterator:Next(exists)}

			if ${anIntIndex.Used} > 0
			{
				EVE:MoveItemsTo[anIntIndex, Hangar]
				wait 15
			}

			Container:Close
			wait 15
		}
		else
		{
			UI:UpdateConsole["TransferContainerToHangar: Not Supported - ${Container.Name}"]
		}
	}

	; Transfer ALL items in MyCargo index
	function TransferListToHangar()
	{
		/*
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			call Station.OpenHangar
			do
			{
				UI:UpdateConsole["TransferListToHangar: Unloading Cargo: ${CargoIterator.Value.Name}"]
				UI:UpdateConsole["TransferListToShip: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
				if ${CargoIterator.Value.GroupID} == GROUPID_SECURE_CONTAINER
				{
					call This.TransferContainerToHangar ${CargoIterator.Value}
				}
				else
				{
					CargoIterator.Value:MoveTo[Hangar]
				}
				wait 30
			}
			while ${CargoIterator:Next(exists)}
			wait 10
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToHangar: Nothing found to move"]
		}
		*/
		call Station.OpenHangar
		UI:UpdateConsole["obj_Cargo:TransferListToHangar: Moving all items in index This.CargoToTransfer to hangar",LOG_DEBUG]

		variable index:int64  anIntIndex
		variable iterator   anIterator

		This.CargoToTransfer:GetIterator[anIterator]
		anIntIndex:Clear

		if ${anIterator:First(exists)}
		do
		{
			anIntIndex:Insert[${anIterator.Value.ID}]
		}
		while ${anIterator:Next(exists)}

		EVE:MoveItemsTo[anIntIndex,Hangar]
	}

	function TransferListToCorpHangarArray()
	{
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				if ${CorpHangarArray.IsReady[TRUE]}
				{
					call CorpHangarArray.Open ${CorpHangarArray.ActiveCan}
					UI:UpdateConsole["TransferListToCorpHangarArray: Transferring Cargo: ${CargoIterator.Value.Name}"]
					CargoIterator.Value:MoveTo[${CorpHangarArray.ActiveCan},${CargoIterator.Value.Quantity},Corporation Folder 1]
				}
			}
			while ${CargoIterator:Next(exists)}
			CorpHangarArray:StackAllCargo
		}
		else
		{
			UI:UpdateConsole["DEBUG: TransferListToCorpHangarArray: Nothing found to move"]
		}
		/* TODO - moveitemsto is not working with ids at the moment
		UI:UpdateConsole["obj_Cargo:TransferListToCorpHangarArray: Moving all items in index This.CargoToTransfer to corp hangar array ID ${CorpHangarArray.ActiveCan}",LOG_DEBUG]
		EVE:MoveItemsTo[This.CargoToTransfer,CorpHangarArray.ActiveCan]
		*/
	}

	function TransferListToAssemblyArray()
	{
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		{
			do
			{
				if ${AssemblyArray.IsReady[TRUE]}
				{
					call AssemblyArray.Open ${AssemblyArray.ActiveCan}
					UI:UpdateConsole["TransferListToAssemblyArray: Transferring Cargo: ${CargoIterator.Value.Name}"]
					CargoIterator.Value:MoveTo[${AssemblyArray.ActiveCan},${CargoIterator.Value.Quantity},Corporation Folder 1]
				}
			}
			while ${CargoIterator:Next(exists)}
			AssemblyArray:StackAllCargo
		}
		else
		{
			UI:UpdateConsole["DEBUG: TransferListToAssemblyArray: Nothing found to move"]
		}
		/* TODO - moveitemsto is not working with ids at the moment
		UI:UpdateConsole["obj_Cargo:TransferListToCorpHangarArray: Moving all items in index This.CargoToTransfer to corp hangar array ID ${CorpHangarArray.ActiveCan}",LOG_DEBUG]
		EVE:MoveItemsTo[This.CargoToTransfer,CorpHangarArray.ActiveCan]
		*/
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

					QuantityToMove:Set[${This.MaxQuantityForVolume[${JetCan.CargoFreeSpace}, ${CargoIterator.Value.Volume}, ${CargoIterator.Value.Quantity}]}]

					UI:UpdateConsole["TransferListToJetCan: Transferring Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					CargoIterator.Value:MoveTo[${JetCan.ActiveCan}, ${QuantityToMove}]
				}
				else
				{
					UI:UpdateConsole["TransferListToJetCan: Ejecting Cargo: ${CargoIterator.Value.Name}"]
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
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToJetCan: Nothing found to move"]
		}
	}

	function TransferListToShipWithContainers()
	{
		variable iterator   listItemIterator
		variable index:item shipItemIndex
		variable iterator   shipItemIterator
		variable index:item shipContainerIndex
		variable iterator   shipContainerIterator
		variable int QuantityToMove
		variable int cnt
		variable int idx

		if ${This.CargoToTransfer.Used} == 0
		{
			return
		}

		call Ship.OpenCargo

		/* build the container list */
		MyShip:DoGetCargo[shipItemIndex]
		shipItemIndex:GetIterator[shipItemIterator]
		shipContainerIndex:Clear
		if ${shipItemIterator:First(exists)}
		do
		{
			if ${shipItemIterator.Value.GroupID} == GROUPID_SECURE_CONTAINER
			{
				shipContainerIndex:Insert[${shipItemIterator.Value}]
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
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: Container used space = ${usedSpace}"]
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: Container total space = ${totalSpace}"]
				QuantityToMove:Set[${This.MaxQuantityForVolume[${Math.Calc[${totalSpace}-${usedSpace}]}, ${This.CargoToTransfer.Get[${idx}].Volume}, ${This.CargoToTransfer.Get[${idx}].Quantity}]}]

				if ${QuantityToMove} > 0
				{
					UI:UpdateConsole["TransferListToShipWithContainers: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${This.CargoToTransfer.Get[${idx}].Volume}]}m3) of ${This.CargoToTransfer.Get[${idx}].Name}"]
					This.CargoToTransfer.Get[${idx}]:MoveTo[${shipContainerIterator.Value.ID},${QuantityToMove}]
					wait 15
				}
				if ${QuantityToMove} == ${This.CargoToTransfer.Get[${idx}].Quantity}
				{
					This.CargoToTransfer:Remove[${idx}]
				}
				do
				{
					usedSpace:Set[${shipContainerIterator.Value.UsedCargoCapacity}]
					wait 2
				}
				while ${usedSpace} < 0
				;;UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: Contsainer used space = ${usedSpace}"]
				if ${Math.Calc[${totalSpace}-${usedSpace}]} > ${Math.Calc[${totalSpace}*0.98]}
				{
					UI:UpdateConsole["DEBUG: TransferListToShipWithContainers: Container full."]
					break
				}
			}
			This.CargoToTransfer:Collapse
			shipContainerIterator.Value:Close
			wait 15

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
			QuantityToMove:Set[${This.MaxQuantityForVolume[${Ship.CargoFreeSpace}, ${This.CargoToTransfer.Get[${idx}].Volume}, ${This.CargoToTransfer.Get[${idx}].Quantity}]}]
			if ${QuantityToMove} > 0
			{
				UI:UpdateConsole["TransferListToShipWithContainers: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${This.CargoToTransfer.Get[${idx}].Volume}]}m3) of ${This.CargoToTransfer.Get[${idx}].Name}"]
				This.CargoToTransfer.Get[${idx}]:MoveTo[MyShip,${QuantityToMove}]
				wait 15
			}
			if ${QuantityToMove} == ${This.CargoToTransfer.Get[${idx}].Quantity}
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
					QuantityToMove:Set[${This.MaxQuantityForVolume[${Ship.CargoFreeSpace}, ${CargoIterator.Value.Volume}, ${CargoIterator.Value.Quantity}]}]

					UI:UpdateConsole["TransferListToShip: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					UI:UpdateConsole["TransferListToShip: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}", LOG_DEBUG]
					if ${QuantityToMove} > 0
					{
						CargoIterator.Value:MoveTo[MyShip,${QuantityToMove}]
						wait 30
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


	function TransferOreToAssemblyArray()
	{
		if ${AssemblyArray.IsReady}
		{
			if ${Entity[${AssemblyArray.ActiveCan}].Distance} > CORP_HANGAR_LOOT_RANGE
			{
				call Ship.Approach ${AssemblyArray.ActiveCan} CORP_HANGAR_LOOT_RANGE
			}
		}
		else
		{
			UI:UpdateConsole["No Assembly Array found - nothing moved"]
			return
		}
		echo "TransferOreToAssemblyArray found can"

		call Ship.OpenCargo
		This:FindShipCargo[CATEGORYID_ORE]
		call TransferListToAssemblyArray

		/* TODO - moveitems to isn't working with ID's atm - cybertech
		if ${AssemblyArray.IsReady[TRUE]}
		{
			call AssemblyArray.Open ${AssemblyArray.ActiveCan}
			UI:UpdateConsole["TransferOreToAssemblyArray: Moving ${This.CargoToTransfer.Used} items to assembly array ID ${AssemblyArray.ActiveCan}"]
			EVE:MoveItemsTo[CargoToTransfer,AssemblyArray.ActiveCan]
			AssemblyArray:StackAllCargo
		}
		*/
		This.CargoToTransfer:Clear[]
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
			UI:UpdateConsole["No Hangar Array found - nothing moved"]
			return
		}

		call Ship.OpenCargo

		This:FindShipCargo[CATEGORYID_ORE]
		call TransferListToCorpHangarArray
		/* TODO - moveitems to isn't working with ID's atm - cybertech
		if ${CorpHangarArray.IsReady[TRUE]}
		{
			call CorpHangarArray.Open ${CorpHangarArray.ActiveCan}
			UI:UpdateConsole["TransferOreToCorpHangarArray: Moving  ${This.CargoToTransfer.Used} items to corp hangar array ID ${CorpHangarArray.ActiveCan}"]
			EVE:MoveItemsTo[CargoToTransfer,CorpHangarArray.ActiveCan]
			CorpHangarArray:StackAllCargo
		}
		*/
		This.CargoToTransfer:Clear[]
	}

	function TransferOreToJetCan()
	{
		UI:UpdateConsole["Transferring Ore to JetCan"]

		call Ship.OpenCargo

		This:FindShipCargo[CATEGORYID_ORE]
		call This.TransferListToJetCan

		This.CargoToTransfer:Clear[]
	}

	function TransferOreToHangar()
	{
		while !${Station.Docked}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for dock..."]
			wait 10
		}

		; Need to cycle the the cargohold after docking to update the list.
		call Ship.CloseCargo

		UI:UpdateConsole["Transferring Ore to Station Hangar"]
		call Ship.OpenCargo

		This:FindShipCargo[CATEGORYID_ORE]
		call This.TransferListToHangar

		This.CargoToTransfer:Clear[]
		Me:StackAllHangarItems
		Ship:UpdateBaselineUsedCargo[]
		wait 25

		call This.ReplenishCrystals
		wait 10

		call This.CloseHolds
	}

	function TransferCargoToHangar()
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

		call This.TransferListToHangar

		This.CargoToTransfer:Clear[]
		Me:StackAllHangarItems
		Ship:UpdateBaselineUsedCargo[]
		wait 25
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
			Me:DoGetHangarItems[This.CargoToTransfer]

			if ${This.CargoToTransfer.Used} > 0
			{
				call This.TransferListToShip

				This.CargoToTransfer:Clear[]
				MyShip:StackAllCargo
				Ship:UpdateBaselineUsedCargo[]
				wait 25
				call This.CloseHolds

				/* Check for leftover items in the station */
				/* FOR NOW check all cargo.  Add filtering later */
				Me:DoGetHangarItems[This.CargoToTransfer]
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
			Me:DoGetHangarItems[cargoIndex]
			cargoIndex:GetIterator[cargoIterator]
			This.CargoToTransfer:Clear

			if ${cargoIterator:First(exists)}
			{
				do
				{
					UI:UpdateConsole["DEBUG: ${cargoIterator.Value.Type}(${cargoIterator.Value.TypeID})"]
					if ${typeID} == ${cargoIterator.Value.TypeID}
					{
						This.CargoToTransfer:Insert[${cargoIterator.Value}]
					}
				}
				while ${cargoIterator:Next(exists)}
			}

			if ${This.CargoToTransfer.Used} > 0
			{
				call This.TransferListToShip

				This.CargoToTransfer:Clear[]
				MyShip:StackAllCargo
				Ship:UpdateBaselineUsedCargo[]
				wait 25
				call This.CloseHolds

				/* Check for leftover items in the station */
				Me:DoGetHangarItems[cargoIndex]
				cargoIndex:GetIterator[cargoIterator]
				This.CargoToTransfer:Clear

				if ${cargoIterator:First(exists)}
				{
					do
					{
						if ${typeID} == ${cargoIterator.Value.TypeID}
						{
							This.CargoToTransfer:Insert[${cargoIterator.Value}]
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
		 UI:UpdateConsole["ERROR: obj_Cargo.TransferItemToHangar: Must be docked!"]
		 return
	  }

	  /* Need to cycle the the cargohold after docking to update the list. */
	  call This.CloseHolds

	  UI:UpdateConsole["Transferring Cargo to Station Hangar"]
	  call This.OpenHolds

	  This:FindShipCargoByType[${typeID}]

	  call This.TransferListToHangar

	  This.CargoToTransfer:Clear[]
	  Me:StackAllHangarItems
	  Ship:UpdateBaselineUsedCargo[]
	  wait 25
	  call This.CloseHolds
   }

	function TransferSpawnContainerCargoToShip(int entityID)
	{
	}
}
