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
	
	variable int DockTimeout=0
	variable int UnDockTimeout=0

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
	
	member IsCorpHangarOpen()
	{
		if ${EVEWindow[Corporation Hangar](exists)}
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

	member:bool DockedAtStation(int64 StationID)
	{
		if ${Me.InStation} && \
			${Me.StationID} == ${StationID}
		{
			return TRUE
		}

	    return FALSE
	}

	method StackHangar()
	{
		EVEWindow[hangarFloor]:StackAll	
	}
	
	method OpenHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}

		if !${This.IsHangarOpen}
		{
			UI:UpdateConsole["Opening Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
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
			Me.Station:OpenCorpHangar
			wait WAIT_CARGO_WINDOW
			while !${This.IsCorpHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}
	
	method CloseHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}

		if ${This.IsHangarOpen}
		{
			UI:UpdateConsole["Closing Cargo Hangar"]
			EVEWindow[hangarFloor]:Close
		}
	}
	
	function CloseCorpHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}

		if ${This.IsCorpHangarOpen}
		{
			UI:UpdateConsole["Closing Corp Cargo Hangar"]
			Me.Station:OpenCorpHangar
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
		Station:OpenHangar
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

	method DockAtStation(int64 StationID)
	{
		if ${Me.ToEntity.Mode} == 3
		{
			return
		}
		
		if ${Me.InStation}
		{	
			return
		}
		
		if !${Me.InSpace}
		{
			return
		}

		if ${Entity[${StationID}](exists)}
		{
			UI:UpdateConsole["Sending dock command"]
			Entity[${StationID}]:Dock
		}
		else
		{
			UI:UpdateConsole["Station Requested does not exist!", LOG_CRITICAL]
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
			This:DockAtStation[${StationID}]
		}
		else
		{
			UI:UpdateConsole["No stations in this system!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
	}

	method Undock()
	{
			UI:UpdateConsole["Sending undock command"]
			EVE:Execute[CmdExitStation]
	}

}
