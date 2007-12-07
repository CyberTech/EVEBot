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
		;ToDo Needs to be moved, into correct classes.
		
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

	function Dock()
	{
		variable int Counter = 0
		variable int StationID = ${Entity[CategoryID,3,${Config.Common.HomeStation}].ID}	

		UI:UpdateConsole["Docking at ${StationID}:${Config.Common.HomeStation}"]

		if ${StationID} <= 0 || !${Entity[${StationID}](exists)}
		{
			UI:UpdateConsole["Warning: Home station not found, going to nearest base"]
			StationID:Set[${Entity[CategoryID,3].ID}]
		}

		if ${Entity[${StationID}](exists)}
		{
			if ${Entity[${StationID}].Distance} >= 10000
			{
				UI:UpdateConsole["Warping to Station"]
				call Ship.WarpToID ${StationID}
				do
				{ 
				   wait 30
				}
				while ${Entity[${StationID}].Distance} >= 10000
			}

			Entity[${StationID}]:Approach
			do
			{
				wait 30
			}
			while (${Entity[${StationID}].Distance} > 100)
		
			Counter:Set[0]
			UI:UpdateConsole["In Docking Range ... Docking"]
			Entity[${StationID}]:Dock			
			do
			{
		   		wait 30
		   		Counter:Inc[20]
		   		if (${Counter} > 200)
		   		{
					UI:UpdateConsole[" - Docking attempt failed, trying again"]
					Entity[${StationID}]:Dock	
		      		Counter:Set[0]
		   		}
			}
			while (!${Me.InStation})

			wait 20
			UI:UpdateConsole["Finished Docking"]
		}
		else
		{
			UI:UpdateConsole["No stations in this system!  Quitting Game!!"]
			EVE:Execute[CmdQuitGame]
		}
	}	

	function Undock()
	{
		variable int Counter
		UI:UpdateConsole["Undock: Waiting while ship exits the station (13 sec)"]

		EVE:Execute[CmdExitStation]
		wait WAIT_UNDOCK
		Counter:Set[0]
		do
		{
			wait 10
			Counter:Inc[10]
			if ${Counter} > 200
			{
			   Counter:Set[0]
			   EVE:Execute[CmdExitStation]	
			   UI:UpdateConsole["Undock: Unexpected failure, retrying..."]
			   UI:UpdateConsole["Undock: Debug: EVEWindow[Local]=${EVEWindow[Local](exists)}"]
			   UI:UpdateConsole["Undock: Debug: Me.InStation=${Me.InStation}"]
			}
		}
		while ( !${Me.InStation(exists)} || ${Me.InStation} || !${EVEWindow[Local](exists)} )
		UI:UpdateConsole["Undock: Complete"]

		Config.Common:SetHomeStation[${Entity[CategoryID,3].Name}]
		
		Me:SetVelocity[100]
		wait 100

		Ship:UpdateModuleList[]
	}

}
