/*
	EVEDB

	Objects related to loading and parsing EVE database dumps which have been converted to LavishSettings files

	-- CyberTech

*/

objectdef obj_EVEDB_Spawns inherits obj_BaseClass
{
	variable string SET_NAME = "EVEDB_Spawns"

#ifdef TESTCASE
	variable string CONFIG_FILE = "${Script.CurrentDirectory}/../Data/EVEDB_Spawns.xml"
#else
	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Spawns.xml"
#endif

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		Logger:Log["${LogPrefix}: Loading database from ${This.CONFIG_FILE}", LOG_MINOR]
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import[${CONFIG_FILE}]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
	}

	member:int SpawnBounty(string spawnName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${spawnName}].FindSetting[bounty, NOTSET]}
	}
}

objectdef obj_EVEDB_Stations inherits obj_BaseClass
{
	variable string SET_NAME = "EVEDB_Stations"

#ifdef TESTCASE
	variable string CONFIG_FILE = "${Script.CurrentDirectory}/../Data/EVEDB_Stations.xml"
#else
	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Stations.xml"
#endif

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		Logger:Log["${LogPrefix}: Loading database from ${This.CONFIG_FILE}", LOG_MINOR]
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import[${CONFIG_FILE}]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
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

objectdef obj_EVEDB_Items inherits obj_BaseClass
{
	variable string SET_NAME = "EVEDB_Items"

#ifdef TESTCASE
	variable string CONFIG_FILE = "${Script.CurrentDirectory}/../Data/EVEDB_Items.xml"
#else
	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Items.xml"
#endif

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		Logger:Log["${LogPrefix}: Loading database from ${This.CONFIG_FILE}", LOG_MINOR]
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import[${This.CONFIG_FILE}]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
	}

	member:int TypeID(string itemName)
	{
		variable iterator anIterator

		LavishSettings[${This.SET_NAME}]:GetSettingIterator[anIterator]

		if ${anIterator:First(exists)}
		{
			do
			{
				if ${anIterator.Value.FindAttribute[ItemName, NOTSET].String.Equal[${itemName}]}
				{
					return ${anIterator.Key}
				}
			}
			while ${anIterator:Next(exists)}
		}

		return NULL
	}

	member:string Name(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[ItemName, NOTSET]}
	}

	member:int Metalevel(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[Metalevel, NOTSET]}
	}

	member:int GroupID(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[GroupID, NOTSET]}
	}

	member:float Volume(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[Volume, NOTSET]}
	}

	member:int Capacity(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[Capacity, NOTSET]}
	}

	member:int PortionSize(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[PortionSize, NOTSET]}
	}

	member:float BasePrice(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[BasePrice, NOTSET]}
	}

	member:float WeaponRangeMultiplier(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[weaponRangeMultiplier, 0]}
	}

}
