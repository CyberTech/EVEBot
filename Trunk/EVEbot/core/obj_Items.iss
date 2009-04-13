/*
	Items class

	Object to contain members related to items.

	-- GliderPro

 TODO - CyberTech - Unless this class is going to do something specific to items, let's move it into obj_EVEDB.iss

*/

objectdef obj_EVEDB_Items
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

#ifdef TESTCASE
	variable string CONFIG_FILE = "${LavishScript.HomeDirectory}/Scripts/EVEBot/Data/EVEDB_Items.xml"
#else
	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Items.xml"
#endif
	variable string SET_NAME = "EVEDB_Items"

	method Initialize()
	{
		UI:UpdateConsole["obj_EVEDB_Items: Loading database", LOG_MINOR]
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import["${CONFIG_FILE}"]
		UI:UpdateConsole["obj_EVEDB_Items: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
	}

	method DumpDB(string itemName)
	{
		variable iterator SetIterator
		variable iterator SettingIterator		

		LavishSettings[${This.SET_NAME}]:GetSettingIterator[SetIterator]

		if ${SetIterator:First(exists)}
		{
			do
			{
				echo ${SetIterator.Value.Name}

			}
			while ${SetIterator:Next(exists)}
		}
		else
		{
			echo "No Sets to iterate!"
		}
			
	}

	member:int TypeID(string itemName)
	{
		variable iterator anIterator

		LavishSettings[${This.SET_NAME}]:GetSettingIterator[anIterator]

		if ${anIterator:First(exists)}
		{
			do
			{
				echo ${anIterator.Value}
				;if ${anIterator.Value.FindSetting[TypeID, NOTSET]} == ${TypeID}
				;{
				;	return ${anIterator.Key}
				;}
			}
			while ${anIterator:Next(exists)}
		}

		return NULL
	}

	member:string Name(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[ItemName, NOTSET]}
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

