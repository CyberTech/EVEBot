/*
	Station class
	
	Object to contain members related to in-station activities.
	
	-- CyberTech
	
*/

objectdef obj_Station
{
	variable index:item StationCargo
	variable index:item DronesInStation
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Station: Initialized"]
	}
	
	member IsHangarOpen()
	{
		if ${EVEWindow[hangarFloor](exists)}
		{
			return TRUE
		}
		else
		{
			return FALSE
		}		
	}
	
	function OpenHangar()
	{
		if !${This.IsHangarOpen}
		{
			UI:UpdateConsole["Opening Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsHangarOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}	

	function CloseHangar()
	{
		if ${This.IsHangarOpen}
		{
			UI:UpdateConsole["Closing Cargo Hangar"]
			EVEWindow[hangarFloor]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsHangarOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}
	
	function GetStationItems()
	{
		while !${Me.InStation}
		{
			UI:UpdateConsole["obj_Cargo: Waiting for InStation..."]
			wait 10
		}
		
		Me.Station:DoGetHangarItems[This.StationCargo]
		
		variable iterator CargoIterator
		This.StationCargo:GetIterator[CargoIterator]
		
			if ${CargoIterator:First(exists)}
			do
			{
				variable int CategoryID
				variable string Name

				CategoryID:Set[${CargoIterator.Value.CategoryID}]
				;echo "${CargoIterator.Value.Name}: ${CargoIterator.Value.CategoryID}"
				Name:Set[${CargoIterator.Value.Name}]

				;echo "DEBUG: obj_Cargo:TransferToHangar: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"			
				switch ${CategoryID}
				{
					default
						break
					case 18
						This.DronesInStation:Insert[${CargoIterator.Value}]
				}
			}
			while ${CargoIterator:Next(exists)}
	}
	
	function CheckList()
	{
		;BotType Checks
		
		;General Checks
		;To.Do Needs to be moved, into correct classes.
		
		;Awaiting ISXEVE Drone Bay Support
		/*
		echo "${Config.Common.DronesInBay} > ${Ship.Drones.DronesInBay}"
		if ${Config.Common.DronesInBay} > ${Ship.Drones.DronesInBay}
		{
		call Station.OpenHangar
		call This.GetStationItems
		wait 10
			
			echo "${Ship.Drones.DronesInStation}"
			if ${Ship.Drones.DronesInStation} > 0
			{
			echo "${Ship.Drones.DronesInStation}"
			call Ship.Drones.StationToBay
			}
			
		call Cargo.CloseHolds
		}
		*/
		
	}

	
}
