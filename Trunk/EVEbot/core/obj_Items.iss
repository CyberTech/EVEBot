/*
	Items class
	
	Object to contain members related to items.
	
	-- GliderPro
	
*/

/*	keep for reference
	==================
		
		SELECT 
		`typeID`, 
		`groupID`, 
		`typeName`, 
		`volume`, 
		`capacity`, 
		`portionSize`, 
		`basePrice`, 
		invTypes.marketGroupID
		FROM `invTypes`
		WHERE invTypes.marketGroupID IS NOT NULL
		order by typeID	
*/

/* settings file format
   ====================

	<Set Name="Seeker F.O.F. Light Missile I Blueprint">
		<Setting Name="TypeID">1216</Setting>
		<Setting Name="GroupID">166</Setting>
		<Setting Name="Volume">0.01</Setting>
		<Setting Name="Capacity">0</Setting>
		<Setting Name="PortionSize">1</Setting>
		<Setting Name="BasePrice">180000</Setting>
		<Setting Name="MarketGroupID">315</Setting>
	</Set>

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
	
	member:int TypeID(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[TypeID, NOTSET]}
	}
	
	member:int GroupID(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[GroupID, NOTSET]}
	}

	member:float Volume(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[Volume, NOTSET]}
	}

	member:int Capacity(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[Capacity, NOTSET]}
	}
	
	member:int PortionSize(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[PortionSize, NOTSET]}
	}
	
	member:float BasePrice(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[BasePrice, NOTSET]}
	}
	
	member:int MarketGroupID(string itemName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${itemName}].FindSetting[MarketGroupID, NOTSET]}
	}

	member:string Name(int TypeID)	
	{
		variable iterator anInterator
		
		LavishSettings[${This.SET_NAME}]:GetSetIterator[anInterator]
		
		if ${anInterator:First(exists)}
		{
			do
			{
				if ${anInterator.Value.FindSetting[TypeID, NOTSET]} == ${TypeID}
				{
					return ${anInterator.Key}
				}
			}
			while ${anInterator:Next(exists)}
		}
				
		return NULL
	}
}

