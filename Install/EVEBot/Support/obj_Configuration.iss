/*
	Configuration Classes

	Main object for interacting with the config file, and for wrapping access to the config items.

	-- CyberTech

	Description:
		Derived from EVEBot main configuration handler, see there for more advanced version
*/

objectdef obj_Configuration_BaseConfig
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "./config/Launcher.xml"
	variable string unchar = ""
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[LauncherSettings]:Remove
		LavishSettings:AddSet[LauncherSettings]
		LavishSettings[LauncherSettings]:Import[${CONFIG_FILE}]

		This:GetDefaultSet
		UI:UpdateConsole["obj_Configuration_BaseConfig: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		This:Save[]
		LavishSettings[LauncherSettings]:Remove
	}

	method Save()
	{
		LavishSettings[LauncherSettings]:Export[${CONFIG_FILE}]
	}

	method GetDefaultSet()
	{
		variable iterator mySet

		LavishSettings[LauncherSettings]:GetSetIterator[mySet]
		if ${mySet:First(exists)}
		do
		{
			if !${This.unchar.Equal[""]}
			{
				if ${mySet.Value.Name.Equal[${This.unchar}]}
				{
					BaseRef:Set[${mySet.Value}]
					return
				}
			}
		}
		while ${mySet:Next(exists)}
	}

	method ChangeConfig(string unchar)
	{
		This:Shutdown
		;echo unchar going to be ${unchar}
		This.unchar:Set[${unchar}]
		;echo unchar now ${This.unchar}
		This:Initialize
	}

}

objectdef obj_Configuration
{
	variable obj_Configuration_Common Common

	method Save()
	{
		BaseConfig:Save[]
	}
}

objectdef obj_Configuration_Common
{
	variable string SetName = "Common"
	variable int AboutCount = 0

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		s"obj_Configuration_Common: Initialized", LOG_MINOR]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		; We use both so we have an ID to use to set the default selection in the UI.
		This.CommonRef:AddSetting[Login Name, ""]
		This.CommonRef:AddSetting[Login Password, ""]
		This.CommonRef:AddSetting[AutoLoginCharID, 0]
	}


	/* TODO - Encrypt this as much as lavishcript will allow */
	member:string LoginName()
	{
		return ${This.CommonRef.FindSetting[Login Name, ""]}
	}

	method SetLoginName(string value)
	{
		This.CommonRef:AddSetting[Login Name, ${value}]
	}

	member:string LoginPassword()
	{
		return ${This.CommonRef.FindSetting[Login Password, ""]}
	}

	method SetLoginPassword(string value)
	{
		This.CommonRef:AddSetting[Login Password,${value}]
	}

	member:int64 AutoLoginCharID()
	{
		return ${This.CommonRef.FindSetting[AutoLoginCharID, 0]}
	}

	method SetAutoLoginCharID(int64 value)
	{
		This.CommonRef:AddSetting[AutoLoginCharID,${value}]
	}

}

