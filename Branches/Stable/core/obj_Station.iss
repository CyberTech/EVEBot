/*
	Station class

	Object to contain members related to in-station activities.

	-- CyberTech

*/

objectdef obj_EVEDB_Stations
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/EVEDB_Stations.xml"
	variable string SET_NAME = "EVEDB_Stations"

	method Initialize()
	{
		LavishSettings:Import[${CONFIG_FILE}]

		UI:UpdateConsole["obj_EVEDB_Stations: Initialized", LOG_MINOR]
	}

	member:string StationName(int64 stationID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${stationID}].FindSetting[stationName, NOTSET]}
	}

	member:int SolarSystemID(int64 stationID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${stationID}].FindSetting[solarSystemID, NOTSET]}
	}
}

objectdef obj_Station
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:item StationCargo
	variable index:item DronesInStation

	method Initialize()
	{
		UI:UpdateConsole["obj_Station: Initialized", LOG_MINOR]
	}

	member IsHangarOpen()
	{
		if ${EVEWindow["Inventory"].ChildWindowExists[StationItems]} 
		{
			EVEWindow["Inventory"]:MakeChildActive[StationItems]
			return TRUE
		}
		else
		{
			return FALSE
		}
	}
	
	member IsCorpHangarOpen()
	{
		if ${EVEWindow["Inventory"].ChildWindowExists[StationCorpHangar](exists)}
		{
			EVEWindow["Inventory"]:MakeChildActive[StationCorpHangar]
			return TRUE
		}
		else
		{
			return FALSE
		}
	}

	member:bool Docked()
	{
		if ${Me.InStation} && \
			${Me.StationID} > 0
		{
			return TRUE
		}
	    return FALSE
	}

	member:bool DockedAtStation(int64 StationID)
	{
		if ${Me.InStation} && \
			${Me.StationID} == ${StationID}
		{
			return TRUE
		}

	    return FALSE
	}

	function OpenHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}

		if !${This.IsHangarOpen}
		{
			UI:UpdateConsole["Opening Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}

	function OpenCorpHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}

		if !${This.IsCorpHangarOpen}
		{
			UI:UpdateConsole["Opening Corp Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsCorpHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}
	
	function CloseHangar()
	{
		return /* no need to close hangars anymore? */
		if ${This.Docked} == FALSE
		{
			return
		}

		if ${This.IsHangarOpen}
		{
			UI:UpdateConsole["Closing Cargo Hangar"]
			EVEWindow[ByCaption, "item hangar"]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}
	
	function CloseCorpHangar()
	{
		return /* no need to close hangars anymore? */
		if ${This.Docked} == FALSE
		{
			return
		}

		if ${This.IsCorpHangarOpen}
		{
			UI:UpdateConsole["Closing Corp Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while ${This.IsCorpHangarOpen}
			{
				wait 1
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

		Me:GetHangarItems[This.StationCargo]

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
						This.DronesInStation:Insert[${CargoIterator.Value.ID}]
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

	function DockAtStation(int64 StationID)
	{
		variable int Counter = 0

		UI:UpdateConsole["Docking at ${EVE.GetLocationNameByID[${StationID}]}"]

		if ${Entity[${StationID}](exists)}
		{
			if ${Entity[${StationID}].Distance} > WARP_RANGE
			{
				UI:UpdateConsole["Warping to Station"]
				call Ship.WarpToID ${StationID}
				do
				{
				   wait 30
				}
				while ${Entity[${StationID}].Distance} > WARP_RANGE
			}

			do
			{
				Entity[${StationID}]:Dock
				UI:UpdateConsole["Approaching docking range..."]
				wait 200 ${This.DockedAtStation[${StationID}]}
			}
			while (${Entity[${StationID}].Distance} > DOCKING_RANGE)

			Counter:Set[0]
			UI:UpdateConsole["In Docking Range ... Docking"]
			;UI:UpdateConsole["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			do
			{
				Entity[${StationID}]:Dock
		   		wait 200 ${This.DockedAtStation[${StationID}]}
			}
			while !${This.DockedAtStation[${StationID}]}
			wait 75
			UI:UpdateConsoleIRC["Finished Docking"]
		}
		else
		{
			UI:UpdateConsole["Station Requested does not exist!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
	}

	function Dock()
	{
		variable int64 StationID = ${Entity["CategoryID = 3 && Name = ${Config.Common.HomeStation}"].ID}

		UI:UpdateConsole["Docking - Trying Home station..."]
		if ${StationID} <= 0 || !${Entity[${StationID}](exists)}
		{
			UI:UpdateConsole["Warning: Home station not found, finding nearest station"]
			StationID:Set[${Entity["CategoryID = 3"].ID}]
		}

		if ${Entity[${StationID}](exists)}
		{
			UI:UpdateConsole["Docking at ${StationID}:${Entity[${StationID}].Name}"]
			call This.DockAtStation ${StationID}
		}
		else
		{
			UI:UpdateConsole["No stations in this system!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
	}

	function Undock()
	{
		variable int Counter
		variable int64 StationID
		StationID:Set[${Me.StationID}]

		UI:UpdateConsole["Undocking from ${Me.Station.Name}"]
		Config.Common:SetHomeStation[${Me.Station.Name}]

		EVE:Execute[CmdExitStation]
		wait WAIT_UNDOCK
		Counter:Set[0]
		do
		{
			wait 10
			Counter:Inc[1]
			if ${Counter} > 20
			{
			   Counter:Set[0]
			   EVE:Execute[CmdExitStation]
			   UI:UpdateConsole["Undock: Unexpected failure, retrying...", LOG_CRITICAL]
			   UI:UpdateConsole["Undock: Debug: EVEWindow[Local]=${EVEWindow[Local](exists)}", LOG_CRITICAL]
			   UI:UpdateConsole["Undock: Debug: Me.InStation=${Me.InStation}", LOG_CRITICAL]
			   UI:UpdateConsole["Undock: Debug: Me.StationID=${Me.StationID}", LOG_CRITICAL]
			}
		}
		while ${This.Docked}
		UI:UpdateConsole["Undock: Complete"]
   		call ChatIRC.Say "Undock: Complete"

		Config.Common:SetHomeStation[${Entity["CategoryID = 3"].Name}]

		;Me:SetVelocity[100]
		wait 30

		Ship.RetryUpdateModuleList:Set[1]
	}

}
