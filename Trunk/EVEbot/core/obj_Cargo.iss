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
	
	; Transfer ALL items in MyCargo index
	function TransferAllToHangar()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
      
		UI:UpdateConsole["DEBUG: obj_Cargo:TransferToHangar: This.CargoToTransfer Populated, Size: ${This.CargoToTransfer.Used}"]

		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		do
		{
			UI:UpdateConsole["obj_Cargo:TransferToHangar: Unloading Cargo: ${CargoIterator.Value.Name}"]
			CargoIterator.Value:MoveTo[Hangar]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
	}

	function TransferOreToJetCan()
	{
		UI:UpdateConsole["Transfering all ore to JetCan."]

		call Ship.OpenCargo
		Me.Ship:DoGetCargo[This.MyCargo]
		
		variable iterator ThisCargo
		
		This.MyCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			variable int CategoryID
			variable string Name

			CategoryID:Set[${ThisCargo.Value.CategoryID}]
			;Name:Set[${ThisCargo.Value.Name}]
			;echo "DEBUG: obj_Cargo:TransferOreToJetCan: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"
			switch ${CategoryID}
			{
				case 4
					This.CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				case 25
					This.CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}

		if ${This.CargoToTransfer.Used} > 0
		{
			This.CargoToTransfer:GetIterator[ThisCargo]

			if ${JetCan.IsReady}
			{
				call JetCan.Open
			}

			if ${ThisCargo:First(exists)}
			do
			{
				if !${JetCan.IsReady}
				{
					ThisCargo.Value:Jettison
					call JetCan.WaitForCan
					JetCan:Rename
					call JetCan.Open
				}
				else
				{
					ThisCargo.Value:MoveTo[${JetCan.ActiveCan}]
				}
			}
			while ${ThisCargo:Next(exists)}
			JetCan:StackAllCargo
			call JetCan.Close
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferOreToJetCan: Nothing found to move"]
		}
		
		CargoToTransfer:Clear[]		
	}
	
	function TransferOreToHangar()
	{	
		while !${Me.InStation}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for InStation..."]
			wait 10
		}

		UI:UpdateConsole["Transfering all ore to hangar."]

		if ${Ship.IsCargoOpen}
		{
			call Ship.CloseCargo
		}
		call Ship.OpenCargo
		Me.Ship:DoGetCargo[This.MyCargo]
		
		variable iterator ThisCargo
		
		This.MyCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			variable int CategoryID
			variable string Name

			CategoryID:Set[${ThisCargo.Value.CategoryID}]
			Name:Set[${ThisCargo.Value.Name}]

			;echo "DEBUG: obj_Cargo:TransferToHangar: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"			
			switch ${CategoryID}
			{
				case 4
					This.CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				case 25
					This.CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}

		if ${This.CargoToTransfer.Used} > 0
		{
			call Station.OpenHangar
			call This.TransferAllToHangar
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Cargo:TransferOreToHangar: Nothing found to move"]
		}
		
		CargoToTransfer:Clear[]
 
	    ; After everything is done ...let's clean up the stacks.
	    Me.Station:StackAllHangarItems
	    Ship:UpdateBaselineUsedCargo[]
	    wait 25
		call This.CloseHolds
	}
}