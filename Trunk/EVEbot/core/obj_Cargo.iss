/*
	Cargo Class
	
	Interacting with Cargo of ship, hangar, and containers, and moving it.
	
	-- CyberTech

BUGS:
	
			
*/

objectdef obj_Cargo
{
	variable index:item MyCargo
	variable index:item CargoToTransfer
	variable bool m_LastTransferComplete

	method Initialize()
	{
		UI:UpdateConsole["obj_Cargo: Initialized"]
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
	
	method FindAllShipCargo()
	{
		Me.Ship:DoGetCargo[This.MyCargo]
		
		variable iterator CargoIterator
		
		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			variable int CategoryID

			CategoryID:Set[${CargoIterator.Value.CategoryID}]
			UI:UpdateConsole["DEBUG: obj_Cargo:FindAllShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.Name} - ${CargoIterator.Value.Quantity} (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]
			This.CargoToTransfer:Insert[${CargoIterator.Value}]
		}
		while ${CargoIterator:Next(exists)}
		
		UI:UpdateConsole["DEBUG: obj_Cargo:FindAllShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
	}
		
	method FindShipCargo(int CategoryIDToMove)
	{
		Me.Ship:DoGetCargo[This.MyCargo]
		
		variable iterator CargoIterator
		
		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			variable int CategoryID

			CategoryID:Set[${CargoIterator.Value.CategoryID}]
			;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.Name} - ${CargoIterator.Value.Quantity} (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]
			if (${CategoryID} == ${CategoryIDToMove})
			{
				This.CargoToTransfer:Insert[${CargoIterator.Value}]
			}
		}
		while ${CargoIterator:Next(exists)}
		
		;UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
	}
	
	; Transfer ALL items in MyCargo index
	function TransferListToHangar()
	{
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		{
			call Station.OpenHangar
			do
			{
				UI:UpdateConsole["TransferListToHangar: Unloading Cargo: ${CargoIterator.Value.Name}"]
				CargoIterator.Value:MoveTo[Hangar]
				wait 30
			}
			while ${CargoIterator:Next(exists)}
			wait 10
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToHangar: Nothing found to move"]
		}
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
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToCorpHangarArray: Nothing found to move"]
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
						/* Move only what will fit, minus 1 to account for CCP rounding errors. */
						QuantityToMove:Set[${JetCan.CargoFreeSpace} / ${CargoIterator.Value.Volume} - 1]
					}
					else
					{
						QuantityToMove:Set[${CargoIterator.Value.Quantity}]
					}

					UI:UpdateConsole["TransferListToJetCan: Transferring Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
					CargoIterator.Value:MoveTo[${JetCan.ActiveCan}, ${QuantityToMove}]
				}
				else
				{
					UI:UpdateConsole["TransferListToJetCan: Ejecting Cargo: ${CargoIterator.Value.Name}"]
					CargoIterator.Value:Jettison
					call JetCan.WaitForCan
					/* This isn't a botter giveaway; I don't know a single miner who doesn't rename cans - failure to do so affects can life. */
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

	function TransferListToShip()
	{
		variable int QuantityToMove
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		{
			call Ship.OpenCargo
			do
			{
				if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${Ship.CargoFreeSpace}
				{
					/* Move only what will fit, minus 1 to account for CCP rounding errors. */
					QuantityToMove:Set[${Ship.CargoFreeSpace} / ${CargoIterator.Value.Volume} - 1]
				}
				else
				{
					QuantityToMove:Set[${CargoIterator.Value.Quantity}]
				}

				UI:UpdateConsole["TransferListToShip: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
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

		This:FindShipCargo[CATEGORYID_ORE]
		call This.TransferListToCorpHangarArray
		
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
		while !${Me.InStation}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for InStation..."]
			wait 10
		}

		UI:UpdateConsole["Transferring Ore to Station Hangar"]

		if ${Ship.IsCargoOpen}
		{
			; Need to cycle the the cargohold after docking to update the list.
			call Ship.CloseCargo
		}
		
		call Ship.OpenCargo
		
		variable int captionCount
		captionCount:Set[${EVEWindow[MyShipCargo].Caption.Token[2,"["].Token[1,"]"]}]
		;UI:UpdateConsole["DEBUG: obj_Cargo: captionCount = ${captionCount}"]
		while ${captionCount} > ${Me.Ship.GetCargo}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for cargo to load..."]
			wait 10
		}
		
		This:FindShipCargo[CATEGORYID_ORE]
		
		call This.TransferListToHangar
		
		This.CargoToTransfer:Clear[]
		Me:StackAllHangarItems
		Ship:UpdateBaselineUsedCargo[]
		wait 25
		call This.CloseHolds
	}
	
	function TransferCargoToHangar()
	{	
		while !${Me.InStation}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for InStation..."]
			wait 10
		}

		UI:UpdateConsole["Transferring Cargo to Station Hangar"]

		/* Need to cycle the the cargohold after docking to update the list. */
		call This.CloseHolds
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
		if !${Me.InStation}
		{
			/* TODO - Support picking up from entities in space */
			m_LastTransferComplete:Set[TRUE]
		}
		else
		{
			UI:UpdateConsole["Transferring Cargo from Station Hangar"]
	
			/* Need to cycle the the cargohold after docking to update the list. */
			call This.CloseHolds
			call This.OpenHolds

			/* FOR NOW move all cargo.  Add filtering later */
			Me:DoGetHangarItems[This.CargoToTransfer]

			if ${This.CargoToTransfer.Used} > 0
			{
				call This.TransferListToShip
				
				This.CargoToTransfer:Clear[]
				Me.Ship:StackAllCargo
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
	
	function TransferSpawnContainerCargoToShip()
	{
	}
}