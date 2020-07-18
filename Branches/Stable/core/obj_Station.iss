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
		LavishSettings:Import[${CONFIG_FILE}]

		Logger:Log["obj_EVEDB_Stations: Initialized", LOG_MINOR]
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

		Logger:Log["Docking at ${EVE.GetLocationNameByID[${StationID}]}"]

		if ${Entity[${StationID}](exists)}
		{
			if ${Entity[${StationID}].Distance} > WARP_RANGE
			{
				Logger:Log["Warping to Station"]
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
				Logger:Log["Approaching docking range..."]
				wait 200 ${This.DockedAtStation[${StationID}]}
			}
			while (${Entity[${StationID}].Distance} > DOCKING_RANGE)

			Counter:Set[0]
			Logger:Log["In Docking Range ... Docking"]
			;Logger:Log["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			do
			{
				Entity[${StationID}]:Dock
				wait 200 ${This.DockedAtStation[${StationID}]}
			}
			while !${This.DockedAtStation[${StationID}]}
		}
		else
		{
			Logger:Log["Station Requested does not exist!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
	}

	function Dock()
	{
		variable int64 StationID
		StationID:Set[${Entity["(GroupID = 15 || GroupID = 1657) && Name = ${Config.Common.HomeStation}"].ID}]

		Logger:Log["Docking - Trying Home station..."]
		if ${StationID} <= 0 || !${Entity[${StationID}](exists)}
		{
			Logger:Log["Warning: Home station not found, finding nearest station"]
			StationID:Set[${Entity["(GroupID = 15 || GroupID = 1657)"].ID}]
		}

		if ${Entity[${StationID}](exists)}
		{
			Logger:Log["Docking at ${StationID}:${Entity[${StationID}].Name}"]
			call This.DockAtStation ${StationID}
		}
		else
		{
			Logger:Log["No stations in this system!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpTo
		}
	}

	function Undock()
	{
		variable int Counter
		variable int64 StationID
		StationID:Set[${Me.StationID}]

		Logger:Log["Undocking from ${Me.Station.Name}"]
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
			   Logger:Log["Undock: Unexpected failure, retrying...", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: EVEWindow[Local]=${EVEWindow[Local](exists)}", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: Me.InStation=${Me.InStation}", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: Me.StationID=${Me.StationID}", LOG_CRITICAL]
			}
		}
		while ${This.Docked}
		Logger:Log["Undock: Complete"]

		Config.Common:SetHomeStation[${Entity["(GroupID = 15 || GroupID = 1657)"].Name}]

		;Me:SetVelocity[100]
		wait 30

		Ship.RetryUpdateModuleList:Set[1]
	}

}
