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

	method Initialize()
	{
		UI:UpdateConsole["obj_Cargo: Initialized"]
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
			UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: CategoryID: ${CategoryID} ${CargoIterator.Value.Name} - ${CargoIterator.Value.Quantity} (CargoToTransfer.Used: ${This.CargoToTransfer.Used})"]
			if (${CategoryID} == ${CategoryIDToMove})
			{
				This.CargoToTransfer:Insert[${CargoIterator.Value}]
			}
		}
		while ${CargoIterator:Next(exists)}
		
		UI:UpdateConsole["DEBUG: obj_Cargo:FindShipCargo: This.CargoToTransfer Populated: ${This.CargoToTransfer.Used}"]
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

	function TransferListToPOSHangar()
	{
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		{
			do
			{
				if ${JetCan.IsReady[TRUE]}
				{
					call JetCan.Open ${JetCan.ActiveCan}
					UI:UpdateConsole["TransferListToPOSHangar: Transferring Cargo: ${CargoIterator.Value.Name}"]
					CargoIterator.Value:MoveTo[${JetCan.ActiveCan},${CargoIterator.Value.Quantity},Corporation Folder 1]
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

	function TransferListToJetCan()
	{
		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		{
			do
			{
				if ${JetCan.IsReady[TRUE]}
				{
					call JetCan.Open ${JetCan.ActiveCan}
					UI:UpdateConsole["TransferListToJetCan: Transferring Cargo: ${CargoIterator.Value.Name}"]
					CargoIterator.Value:MoveTo[${JetCan.ActiveCan}]
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
	
	function TransferOreToPOSHangar()
	{
		UI:UpdateConsole["Transferring Ore to POS Hangar"]
		
		if !${Entity[TypeID, 17621](exists)}
		{
			UI:ConsoleUpdate["No Hangar Array found"]
		}

		; TODO - can't use jetcan code ehre, need to abstract it out a bit more, corp cargo arrays are type GROUPID_CORPORATE_HANGAR_ARRAY 
		if ${JetCan.IsReady}
		{
			if ${Entity[${JetCan.ActiveCan}].Distance} > 2500
			{
				call Ship.Approach ${JetCan.ActiveCan} 2500
			}
		}

		call Ship.OpenCargo

		This:FindShipCargo[CATEGORYID_ORE]
		call This.TransferListToPOSHangar
		
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
		
		This:FindShipCargo[CATEGORYID_ORE]
		call This.TransferListToHangar
		
		This.CargoToTransfer:Clear[]
		Me.Station:StackAllHangarItems
		Ship:UpdateBaselineUsedCargo[]
		wait 25
		call This.CloseHolds
	}
}