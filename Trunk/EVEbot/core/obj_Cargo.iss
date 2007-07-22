objectdef obj_Cargo
{
	variable index:item MyCargo
	variable index:item CargoToTransfer

	method Initialize()
	{
	}

	function OpenHolds()
	{
		call Ship.OpenCargo
		call Station.OpenHangar		
	}
	
	function CloseHolds()
	{
		call Ship.CloseCargo
		call Station.OpenHangar
	}
	
	; Transfer ALL items in MyCargo index
	function TransferAllToHangar()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
      
		call UpdateHudStatus "DEBUG: obj_Cargo:TransferToHangar: This.CargoToTransfer Populated, Size: ${This.CargoToTransfer.Used}"

		variable iterator CargoIterator
		This.CargoToTransfer:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		do
		{
			call UpdateHudStatus "obj_Cargo:TransferToHangar: Unloading Cargo: ${CargoIterator.Value.Name}"
			CargoIterator.Value:MoveTo[Hangar]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
	}

	function TransferOreToHangar()
	{	
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

			echo "DEBUG: obj_Cargo:TransferToHangar: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"			
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
			call UpdateHudStatus "DEBUG: obj_Cargo:TransferOreToHangar: Nothing found to move"
		}
		
		CargoToTransfer:Clear[]
		UI.TotalRuns:Inc
 
	    ; After everything is done ...let's clean up the stacks.
	    Me.Station:StackAllHangarItems
	    Ship:UpdateBaselineUsedCargo[]
	    wait 25

		call This.CloseHolds
	}
}