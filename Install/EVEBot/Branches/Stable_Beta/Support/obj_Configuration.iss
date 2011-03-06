/*
	Configuration Classes

	Main object for interacting with the config file, and for wrapping access to the config items.

	-- CyberTech

	Description:
	obj_Configuration defines the config file and the root.  It contains an instantiation of obj_Configuration_MODE,
	where MODE is Hauler,Miner, Combat, etc.

	Each obj_Configuration_MODE is responsible for setting it's own default	values and for providing access members
	and update methods for the config items. ALL configuration items should receive both a member and a method.

	Instructions:
		To add a new module, add a variable to obj_Configuration, name it with the thought that it will be accessed
		as Config.Module (ie, Config.Miner).  Create the class, and it's members and methods, following the example
		of the existing classes below.

	Copied and modified by TruPoet for use with Launcher.iss config handling
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
			else
			{

				if ${mySet.Value.FindSetting["Default Login"].String.Equal["TRUE"]}
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
		This.CommonRef:AddSetting[CharacterName, ""]
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
	member:string CharacterName()
	{
		return ${This.CommonRef.FindSetting[CharacterName, ""]}
	}

	method SetCharacterName(string value)
	{
		This.CommonRef:AddSetting[CharacterName, ${value}]
	}


}

