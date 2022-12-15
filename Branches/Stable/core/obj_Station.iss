/*
	Station class

	Object to contain members related to in-station activities.

	-- CyberTech

*/

objectdef obj_EVEDB_Stations
{
	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/EVEDB_Stations.xml"
	variable string SET_NAME = "EVEDB_Stations"

	method Initialize()
	{
		LavishSettings[${This.SET_NAME}]:Remove
		Logger:Log["${This.ObjectName}: Loading database from ${This.CONFIG_FILE}", LOG_MINOR]
		LavishSettings:Import[${CONFIG_FILE}]

		Logger:Log["obj_EVEDB_Stations: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
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
	variable index:item DronesInStation

	method Initialize()
	{
		Logger:Log["obj_Station: Initialized", LOG_MINOR]
	}

	member:bool Docked()
	{
		if ${ISXEVE.IsSafe} && \
				!${Me.InSpace} && \
				${Me.InStation} && \
				${Me.StationID} > 0
		{
			return TRUE
		}
		return FALSE
	}

	member:bool DockedAtStation(int64 StationID)
	{
		if ${This.Docked} && ${Me.StationID} == ${StationID}
		{
			return TRUE
		}

		return FALSE
	}

	function GetStationItems()
	{
		while !${Me.InStation}
		{
			Logger:Log["obj_Cargo: Waiting for InStation..."]
			wait 10
		}

		call Inventory.StationHangar.Activate ${Me.Station.ID}
		Inventory.StationHangar:GetItems[This.DronesInStation, "CategoryID == 18"]
	}

	function DockAtStation(int64 StationID)
	{
		variable int Counter = 0

		if ${Me.InStation}
		{
			Logger:Log["DockAtStation(${StationID}) called, but we're already in station ${Me.StationID}!"]
			return
		}

		Logger:Log["Docking at ${StationID}:${Entity[${StationID}].Name}"]

		if ${Entity[${StationID}](exists)}
		{
			Navigator:FlyToEntityID[${StationID}, 0, TRUE]
			while ${Navigator.Busy}
			{
				wait 1
			}

			Counter:Set[0]
			do
			{
				Counter:Inc[1]
				if (${Counter} > 20)
				{
					Logger:Log["Warning: Docking incomplete after 60 seconds", LOG_CRITICAL]
					Counter:Set[0]
				}
			}
			while !${This.DockedAtStation[${StationID}]} && ${Navigator.Busy}
		}
		elseif ${Safespots.Count} > 0
		{
			Logger:Log["Station Requested does not exist!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
		else
		{
			Logger:Log["Station Requested does not exist!", LOG_CRITICAL]
		}
	}

	function Dock()
	{
		variable int64 StationID
		StationID:Set[${Entity["(CategoryID = CATEGORYID_STATION || CategoryID = CATEGORYID_STRUCTURE) && Name = ${Config.Common.HomeStation}"].ID}]

		if ${Me.InStation}
		{
			Logger:Log["Dock called, but we're already instation!"]
			return
		}

		if ${StationID} <= 0 || !${Entity[${StationID}](exists)}
		{
			Logger:Log["Warning: Home station '${Config.Common.HomeStation}' not found, going to nearest base", LOG_CRITICAL]
			StationID:Set[${Entity["(CategoryID = CATEGORYID_STATION || CategoryID = CATEGORYID_STRUCTURE)"].ID}]
		}

		if ${Entity[${StationID}](exists)}
		{
			call This.DockAtStation ${StationID}
		}
		elseif ${Safespots.Count} > 0
		{
			Logger:Log["No stations in this system!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
		else
		{
			Logger:Log["No stations in this system!", LOG_CRITICAL]
		}
	}

	function Undock()
	{
		variable int Counter
		variable int64 StationID
		StationID:Set[${Me.StationID}]

		if !${Me.InStation}
		{
			Logger:Log["WARNING: Undock called, but we're already undocking!", LOG_ECHOTOO]
			return
		}

		Inventory:Close
		Logger:Log["Undocking from ${Me.Station.Name}"]
		Config.Common:SetHomeStation[${Me.Station.Name}]
		Logger:Log["Undock: Home Station set to ${Config.Common.HomeStation}"]

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
			   Logger:Log["Undock: Unexpected failure, retrying...", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: EVEWindow[Local]=${EVEWindow[Local](exists)}", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: Me.InStation=${Me.InStation}", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: Me.StationID=${Me.StationID}", LOG_CRITICAL]
			}
		}
		while (!${Me.InSpace} || ${Me.InStation})
		wait 10
		Logger:Log["Undock: Complete"]

		call Inventory.ShipCargo.Activate
		Config.Common:SetHomeStation[${Entity["(GroupID = GROUP_STATION || GroupID = GROUP_STRUCTURECITADEL)"].Name}]

		Ship.RetryUpdateModuleList:Set[1]
	}

}
