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

	member:string StationName(int stationID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${stationID}].FindSetting[stationName, NOTSET]}
	}

	member:int SolarSystemID(int stationID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${stationID}].FindSetting[solarSystemID, NOTSET]}
	}
}

objectdef obj_EVEDB_StationID
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/EVEDB_StationID.xml"
	variable string SET_NAME = "EVEDB_StationID"

	method Initialize()
	{
		LavishSettings:Import[${CONFIG_FILE}]

		UI:UpdateConsole["obj_EVEDB_StationID: Initialized", LOG_MINOR]
	}

	member:int StationID(string stationName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${stationName}].FindSetting[stationName, NOTSET]}
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
		if ${EVEWindow[hangarFloor](exists)}
		{
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

	member:bool DockedAtStation(int StationID)
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

	function CloseHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}

		if ${This.IsHangarOpen}
		{
			UI:UpdateConsole["Closing Cargo Hangar"]
			EVEWindow[hangarFloor]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsHangarOpen}
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

	function DockAtStation(int StationID)
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
				Entity[${StationID}]:Approach
				UI:UpdateConsole["Approaching docking range..."]
				wait 30
			}
			while (${Entity[${StationID}].Distance} > DOCKING_RANGE)

			Counter:Set[0]
			UI:UpdateConsole["In Docking Range ... Docking"]
			;UI:UpdateConsole["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			do
			{
				Entity[${StationID}]:Dock
		   		wait 30
		   		Counter:Inc[1]
		   		if (${Counter} > 20)
		   		{
					UI:UpdateConsole["Warning: Docking incomplete after 60 seconds", LOG_CRITICAL]
					Entity[${StationID}]:Dock
		      		Counter:Set[0]
		   		}
				;UI:UpdateConsole["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
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
		variable int StationID
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

		Ship:UpdateModuleList[]
	}

}
