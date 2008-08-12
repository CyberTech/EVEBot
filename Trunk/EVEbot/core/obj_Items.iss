/*
	Items class
	
	Object to contain members related to items.
	
	-- GliderPro
	
*/

objectdef obj_EVEDB_Items
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/EVEDB_Items.xml"
	variable string SET_NAME = "EVEDB_Items"
	
	method Initialize()
	{
		LavishSettings:Import[${CONFIG_FILE}]
		
		UI:UpdateConsole["obj_EVEDB_Items: Initialized", LOG_MINOR]
	}
	
	method Shutdown()	
	{
		LavishSettings[${This.SET_NAME}]:Clear
	}	
	
	member:int ItemID(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[itemID, NOTSET]}
	}
	
	member:string ItemName(int itemID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemID}].FindSetting[itemName, NOTSET]}
	}

	member:float Volume(int itemID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemID}].FindSetting[Volume, NOTSET]}
	}
}

