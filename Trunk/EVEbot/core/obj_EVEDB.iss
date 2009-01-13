/*
	EVEDB

	Objects related to loading and parsing EVE database dumps which have been converted to LavishSettings files

	-- CyberTech

*/

objectdef obj_EVEDB_Spawns
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Spawns.xml"
	variable string SET_NAME = "EVEDB_Spawns"

	method Initialize()
	{
		LavishSettings:Import[${CONFIG_FILE}]

		UI:UpdateConsole["obj_EVEDB_Spawns: Initialized", LOG_MINOR]
	}

	member:int SpawnBounty(string spawnName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${spawnName}].FindSetting[bounty, NOTSET]}
	}
}

objectdef obj_EVEDB_Stations
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Stations.xml"
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
