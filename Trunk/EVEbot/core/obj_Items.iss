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

	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_Items.xml"
	variable string SET_NAME = "EVEDB_Items"

	method Initialize()
	{
		UI:UpdateConsole["obj_EVEDB_Items: Loading database", LOG_MINOR]
		LavishSettings:Import[${CONFIG_FILE}]
		UI:UpdateConsole["obj_EVEDB_Items: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Clear
	}

	member:int TypeID(string itemName)
	{
		; need to iterate - probably not needed
	}

	member:string Name(int TypeID)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[ItemName, NOTSET]}
	}

	member:int GroupID(int TypeID)
	{
		temp:Set[${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[GroupID, NOTSET]}]
	}

	member:float Volume(int TypeID)
	{
		variable float temp
		temp:Set[${LavishSettings[${This.SET_NAME}].FindSetting[${TypeID}].FindAttribute[Volume, NOTSET]}]
		echo "item:volume(${TypeID}) == ${temp}"
		return ${temp}
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
}

