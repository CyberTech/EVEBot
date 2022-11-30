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
*/

#macro Define_ConfigItem(_Type, _Key, _DefaultValue)
	member:_Type _Key()
	{
		;echo Returning \${This.Ref.FindSetting[_Key, _DefaultValue]} = ${This.Ref.FindSetting[_Key, _DefaultValue]}
		return ${This.Ref.FindSetting[_Key, _DefaultValue]}
	}

	method _Key(_Type Value)
	{
		;echo "Setting This.Ref:AddSetting[_Key, ${Value}]"
		This.Ref:AddSetting[_Key, ${Value}]
	}
#endmac


/* ************************************************************************* */
objectdef obj_Configuration_BaseConfig
{
	variable float ConfigVersion = 1.0

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
	variable filepath DATA_PATH = "${Script.CurrentDirectory}/Data"
	variable string ORG_CONFIG_FILE = "evebot.xml"
	variable string NEW_CONFIG_FILE = "${Me.Name} Config.xml"
	variable string CONFIG_FILE = "${Me.Name} Config.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[EVEBotSettings]:Remove
		LavishSettings:AddSet[EVEBotSettings]
		LavishSettings[EVEBotSettings]:AddSet[${Me.Name}]

		; Check new config file first, then fallball to original name for import

		CONFIG_FILE:Set["${CONFIG_PATH}/${NEW_CONFIG_FILE}"]

		if !${CONFIG_PATH.FileExists[${NEW_CONFIG_FILE}]}
		{
			Logger:Log["${CONFIG_FILE} not found - looking for ${ORG_CONFIG_FILE}"]
			Logger:Log["Configuration will be copied from ${ORG_CONFIG_FILE} to ${NEW_CONFIG_FILE}"]

			LavishSettings[EVEBotSettings]:Import[${CONFIG_PATH}/${ORG_CONFIG_FILE}]
		}
		else
		{
			Logger:Log["Configuration file is ${CONFIG_FILE}"]
			LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]
		}

		BaseRef:Set[${LavishSettings[EVEBotSettings].FindSet[${Me.Name}]}]
		Logger:Log["obj_Configuration_BaseConfig: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		This:Save[]
		LavishSettings[EVEBotSettings]:Remove
	}

	method Save()
	{
		Logger:Log["obj_Configuration_BaseConfig: Saved"]
		LavishSettings[EVEBotSettings]:Export[${CONFIG_FILE}]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration
{
	variable obj_Configuration_Common Common
	;variable obj_Configuration_Sound Sound
	;variable obj_Configuration_Logging Logging
	variable obj_Configuration_Combat Combat
	;variable obj_Configuration_Defense Defense
	variable obj_Configuration_Miner Miner
	variable obj_Configuration_Hauler Hauler
	variable obj_Configuration_Salvager Salvager
	variable obj_Configuration_Labels Labels
	variable obj_Configuration_Freighter Freighter
	variable obj_Configuration_Agents Agents
	variable obj_Configuration_Missioneer Missioneer
	variable obj_Configuration_Fleet Fleet

	method Shutdown()
	{
	}

	method Save()
	{
		BaseConfig:Save[]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration_Common
{
	variable string SetName = "Common"
	variable int AboutCount = 0
	variable weakref Ref

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		else
		{
			Ref:SetReference["BaseConfig.BaseRef.FindSet[${This.SetName}]"]
			if ${This.Ref.FindSetting[Bot Mode Name](exists)}
			{
				; The previous key was present, migrate it to the new one and delete it
				This.Ref:AddSetting[CurrentBehavior, ${This.Ref.FindSetting[Bot Mode Name]}]
				This.Ref.FindSetting[Bot Mode]:Remove
				This.Ref.FindSetting[Bot Mode Name]:Remove
				Logger:Log["Configuration: Migrating config value: Bot Mode Name -> Behavior (${This.Ref.FindSetting[CurrentBehavior]})", LOG_ECHOTOO]
			}
		}

		Logger:Log["obj_Configuration_Common: Initialized", LOG_MINOR]
	}

	member:settingsetref CommonRef()
	{
		return ${This.Ref}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		Ref:SetReference["BaseConfig.BaseRef.FindSet[${This.SetName}]"]

		; We use both so we have an ID to use to set the default selection in the UI.
		This.Ref:AddSetting[Home Station,1]
		This.Ref:AddSetting[Use Development Build,FALSE]
		This.Ref:AddSetting[Drones In Bay,0]
		This.Ref:AddSetting[Login Name, ""]
		This.Ref:AddSetting[Login Password, ""]
		This.Ref:AddSetting[AutoLogin, TRUE]
		This.Ref:AddSetting[AutoLoginCharID, 0]
		This.Ref:AddSetting[Maximum Runtime, 0]
		This.Ref:AddSetting[Use Sound, FALSE]
		This.Ref:AddSetting[Disable 3D, FALSE]
		This.Ref:AddSetting[TrainFastest, FALSE]
	}

	Define_ConfigItem(string, CurrentBehavior, "Idle")
	Define_ConfigItem(bool, SortBeltsRandom, FALSE)


	member:int DronesInBay()
	{
		return ${This.CommonRef.FindSetting[Drones In Bay, NOTSET]}
	}

	method SetDronesInBay(int value)
	{
		This.CommonRef:AddSetting[Drones In Bay,${value}]
	}

	member:string HomeStation()
	{
		return ${This.CommonRef.FindSetting[Home Station, NOTSET]}
	}

	method SetHomeStation(string value)
	{
		This.CommonRef:AddSetting[Home Station,${value}]
	}

	member:bool UseDevelopmentBuild()
	{
		return ${This.CommonRef.FindSetting[Use Development Build, FALSE]}
	}

	method SetUseDevelopmentBuild(bool value)
	{
		This.CommonRef:AddSetting[Home Station,${value}]
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

	member:bool AutoLogin()
	{
		return ${This.CommonRef.FindSetting[AutoLogin, TRUE]}
	}

	method SetAutoLogin(bool value)
	{
		This.CommonRef:AddSetting[AutoLogin,${value}]
	}

	member:int64 AutoLoginCharID()
	{
		return ${This.CommonRef.FindSetting[AutoLoginCharID, 0]}
	}

	method SetAutoLoginCharID(int64 value)
	{
		This.CommonRef:AddSetting[AutoLoginCharID,${value}]
	}

	member:int OurAbortCount()
	{
		return ${AbortCount}
	}

	function IncAbortCount()
	{
		This.AbortCount:Inc
	}

	member:int MaxRuntime()
	{
		return ${This.CommonRef.FindSetting[Maximum Runtime, NOTSET]}
	}

	method SetMaxRuntime(int value)
	{
		This.CommonRef:AddSetting[Maximum Runtime,${value}]
	}

	member:string IRCServer()
	{
		return ${This.CommonRef.FindSetting[IRC Server, "irc.lavishsoft.com"]}
	}

	method SetIRCServer(string value)
	{
		This.CommonRef:AddSetting[IRC Server, ${value}]
	}

	member:string IRCChannel()
	{
		return ${This.CommonRef.FindSetting[IRC Channel, "#objirc"]}
	}

	method SetIRCChannel(string value)
	{
		This.CommonRef:AddSetting[IRC Channel, ${value}]
	}

	member:string IRCUser()
	{
		return ${This.CommonRef.FindSetting[IRC User, "Test${Math.Rand[5000]:Inc[1000]}"]}
	}

	method SetIRCUser(string value)
	{
		This.CommonRef:AddSetting[IRC User, ${value}]
	}

	member:string IRCPassword()
	{
		return ${This.CommonRef.FindSetting[IRC Password, "evebot"]}
	}

	method SetIRCPassword(string value)
	{
		This.CommonRef:AddSetting[IRC Password, ${value}]
	}

	member:bool UseSound()
	{
		return ${This.CommonRef.FindSetting[Use Sound, FALSE]}
	}

	method SetUseSound(bool value)
	{
		This.CommonRef:AddSetting[Use Sound,${value}]
	}

	member:bool Disable3D()
	{
		return ${This.CommonRef.FindSetting[Disable 3D, FALSE]}
	}

	method SetDisable3D(bool value)
	{
		This.CommonRef:AddSetting[Disable 3D,${value}]
	}

	member:bool TrainFastest()
	{
		return ${This.CommonRef.FindSetting[TrainFastest, FALSE]}
	}

	method SetTrainFastest(bool value)
	{
		This.CommonRef:AddSetting[TrainFastest,${value}]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration_Miner
{
	variable string SetName = "Miner"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ice_Types](exists)}
		{
			Logger:Log["obj_Configuration_Miner: Initialized ICE Types"]
			This:Set_Default_Values_Ice[]
		}
		; Remove legacy ore volumes set 2020-09
		This.MinerRef.FindSet[ORE_Volumes]:Remove
	}

	member:settingsetref MinerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref OreTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Types]}
	}

	member:settingsetref IceTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ice_Types]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.MinerRef:AddSet[ORE_Types]
		This.MinerRef:AddSetting[Restrict To Belt, NO]
		This.MinerRef:AddSetting[Restrict To Ore Type, NONE]
		This.MinerRef:AddSetting[JetCan Naming, 1]
		This.MinerRef:AddSetting[Bookmark Last Position, TRUE]
		This.MinerRef:AddSetting[Distribute Lasers, TRUE]
		This.MinerRef:AddSetting[Use Mining Drones, FALSE]
		This.MinerRef:AddSetting[Avoid Player Range, 10000]
		This.MinerRef:AddSetting[Standing Detection, FALSE]
		This.MinerRef:AddSetting[Lowest Standing, 0]
		This.MinerRef:AddSetting[Minimum Security Status, -10.00]
		This.MinerRef:AddSetting[Ice Mining, 0]
		This.MinerRef:AddSetting[Delivery Location Type, 1]
		This.MinerRef:AddSetting[Delivery Location Type Name, Station]
		This.MinerRef:AddSetting[Use Field Bookmarks, FALSE]
		This.MinerRef:AddSetting[Strip Mine, FALSE]
		This.MinerRef:AddSetting[Cargo Threshold, 0]


		This.OreTypesRef:AddSetting[Vitreous Mercoxit, 1]
		This.OreTypesRef:AddSetting[Magma Mercoxit, 1]
		This.OreTypesRef:AddSetting[Mercoxit, 1]
		This.OreTypesRef:AddSetting[Prime Arkonor, 1]
		This.OreTypesRef:AddSetting[Crimson Arkonor, 1]
		This.OreTypesRef:AddSetting[Arkonor, 1]
		This.OreTypesRef:AddSetting[Monoclinic Bistot, 1]
		This.OreTypesRef:AddSetting[Triclinic Bistot, 1]
		This.OreTypesRef:AddSetting[Bistot, 1]
		This.OreTypesRef:AddSetting[Crystalline Crokite, 1]
		This.OreTypesRef:AddSetting[Sharp Crokite, 1]
		This.OreTypesRef:AddSetting[Crokite, 1]
		This.OreTypesRef:AddSetting[Gleaming Spodumain, 1]
		This.OreTypesRef:AddSetting[Bright Spodumain, 1]
		This.OreTypesRef:AddSetting[Spodumain, 1]
		This.OreTypesRef:AddSetting[Obsidian Ochre, 1]
		This.OreTypesRef:AddSetting[Onyx Ochre, 1]
		This.OreTypesRef:AddSetting[Dark Ochre, 1]
		This.OreTypesRef:AddSetting[Prismatic Gneiss, 1]
		This.OreTypesRef:AddSetting[Iridescent Gneiss, 1]
		This.OreTypesRef:AddSetting[Gneiss, 1]
		This.OreTypesRef:AddSetting[Glazed Hedbergite, 1]
		This.OreTypesRef:AddSetting[Vitric Hedbergite, 1]
		This.OreTypesRef:AddSetting[Hedbergite, 1]
		This.OreTypesRef:AddSetting[Radiant Hemorphite, 1]
		This.OreTypesRef:AddSetting[Vivid Hemorphite, 1]
		This.OreTypesRef:AddSetting[Hemorphite, 1]
		This.OreTypesRef:AddSetting[Pristine Jaspet, 1]
		This.OreTypesRef:AddSetting[Pure Jaspet, 1]
		This.OreTypesRef:AddSetting[Jaspet, 1]
		This.OreTypesRef:AddSetting[Fiery Kernite, 1]
		This.OreTypesRef:AddSetting[Luminous Kernite, 1]
		This.OreTypesRef:AddSetting[Kernite, 1]
		This.OreTypesRef:AddSetting[Golden Omber, 1]
		This.OreTypesRef:AddSetting[Silvery Omber, 1]
		This.OreTypesRef:AddSetting[Omber, 1]
		This.OreTypesRef:AddSetting[Rich Plagioclase, 1]
		This.OreTypesRef:AddSetting[Azure Plagioclase, 1]
		This.OreTypesRef:AddSetting[Plagioclase, 1]
		This.OreTypesRef:AddSetting[Viscous Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Solid Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Massive Scordite, 1]
		This.OreTypesRef:AddSetting[Condensed Scordite, 1]
		This.OreTypesRef:AddSetting[Scordite, 1]
		This.OreTypesRef:AddSetting[Dense Veldspar, 1]
		This.OreTypesRef:AddSetting[Concentrated Veldspar, 1]
		This.OreTypesRef:AddSetting[Veldspar, 1]

		; Base Moon Ore
		This.OreTypesRef:AddSetting[Bitumens, 1]
		This.OreTypesRef:AddSetting[Coesite, 1]
		This.OreTypesRef:AddSetting[Sylvite, 1]
		This.OreTypesRef:AddSetting[Zeolites, 1]
		This.OreTypesRef:AddSetting[Cobaltite, 1]
		This.OreTypesRef:AddSetting[Euxenite, 1]
		This.OreTypesRef:AddSetting[Scheelite, 1]
		This.OreTypesRef:AddSetting[Titanite, 1]
		This.OreTypesRef:AddSetting[Chromite, 1]
		This.OreTypesRef:AddSetting[Otavite, 1]
		This.OreTypesRef:AddSetting[Sperrylite, 1]
		This.OreTypesRef:AddSetting[Vanadinite, 1]
		This.OreTypesRef:AddSetting[Carnotite, 1]
		This.OreTypesRef:AddSetting[Cinnabar, 1]
		This.OreTypesRef:AddSetting[Pollucite, 1]
		This.OreTypesRef:AddSetting[Zircon, 1]
		This.OreTypesRef:AddSetting[Loparite, 1]
		This.OreTypesRef:AddSetting[Monazite, 1]
		This.OreTypesRef:AddSetting[Xenotime, 1]
		This.OreTypesRef:AddSetting[Ytterbite, 1]
		; R16/15% Moon Ore
		This.OreTypesRef:AddSetting[Brimful Bitumens, 1]
		This.OreTypesRef:AddSetting[Brimful Coesite, 1]
		This.OreTypesRef:AddSetting[Brimful Sylvite, 1]
		This.OreTypesRef:AddSetting[Brimful Zeolites, 1]
		This.OreTypesRef:AddSetting[Copious Cobaltite, 1]
		This.OreTypesRef:AddSetting[Copious Euxenite, 1]
		This.OreTypesRef:AddSetting[Copious Scheelite, 1]
		This.OreTypesRef:AddSetting[Copious Titanite, 1]
		This.OreTypesRef:AddSetting[Lavish Chromite, 1]
		This.OreTypesRef:AddSetting[Lavish Otavite, 1]
		This.OreTypesRef:AddSetting[Lavish Sperrylite, 1]
		This.OreTypesRef:AddSetting[Lavish Vanadinite, 1]
		This.OreTypesRef:AddSetting[Replete Carnotite, 1]
		This.OreTypesRef:AddSetting[Replete Cinnabar, 1]
		This.OreTypesRef:AddSetting[Replete Pollucite, 1]
		This.OreTypesRef:AddSetting[Replete Zircon, 1]
		This.OreTypesRef:AddSetting[Bountiful Loparite, 1]
		This.OreTypesRef:AddSetting[Bountiful Monazite, 1]
		This.OreTypesRef:AddSetting[Bountiful Xenotime, 1]
		This.OreTypesRef:AddSetting[Bountiful Ytterbite, 1]
		; R64/100% Moon Ore
		This.OreTypesRef:AddSetting[Glistening Bitumens, 1]
		This.OreTypesRef:AddSetting[Glistening Coesite, 1]
		This.OreTypesRef:AddSetting[Glistening Sylvite, 1]
		This.OreTypesRef:AddSetting[Glistening Zeolites, 1]
		This.OreTypesRef:AddSetting[Twinkling Cobaltite, 1]
		This.OreTypesRef:AddSetting[Twinkling Euxenite, 1]
		This.OreTypesRef:AddSetting[Twinkling Scheelite, 1]
		This.OreTypesRef:AddSetting[Twinkling Titanite, 1]
		This.OreTypesRef:AddSetting[Shimmering Chromite, 1]
		This.OreTypesRef:AddSetting[Shimmering Otavite, 1]
		This.OreTypesRef:AddSetting[Shimmering Sperrylite, 1]
		This.OreTypesRef:AddSetting[Shimmering Vanadinite, 1]
		This.OreTypesRef:AddSetting[Glowing Carnotite, 1]
		This.OreTypesRef:AddSetting[Glowing Cinnabar, 1]
		This.OreTypesRef:AddSetting[Glowing Pollucite, 1]
		This.OreTypesRef:AddSetting[Glowing Zircon, 1]
		This.OreTypesRef:AddSetting[Shining Loparite, 1]
		This.OreTypesRef:AddSetting[Shining Monazite, 1]
		This.OreTypesRef:AddSetting[Shining Xenotime, 1]
		This.OreTypesRef:AddSetting[Shining Ytterbite, 1]

		This:Set_Default_Values_Ice[]
	}

	method Set_Default_Values_Ice()
	{
		This.MinerRef:AddSet[ICE_Types]

		This.IceTypesRef:AddSetting[Dark Glitter, 1]
		This.IceTypesRef:AddSetting[Gelidus, 1]
		This.IceTypesRef:AddSetting[Glare Crust, 1]
		This.IceTypesRef:AddSetting[Krystallos, 1]
		This.IceTypesRef:AddSetting[Clear Icicle, 1]
		This.IceTypesRef:AddSetting[Smooth Glacial Mass, 1]
		This.IceTypesRef:AddSetting[Glacial Mass, 1]
		This.IceTypesRef:AddSetting[Pristine White Glaze, 1]
		This.IceTypesRef:AddSetting[White Glaze, 1]
		This.IceTypesRef:AddSetting[Thick Blue Ice, 1]
		This.IceTypesRef:AddSetting[Enriched Clear Icicle, 1]
		This.IceTypesRef:AddSetting[Blue Ice, 1]
	}

	; TODO - members/methods for these - CyberTech

	;		This.MinerRef:AddSetting[Restrict To Belt, NO]
	;		This.MinerRef:AddSetting[Restrict To Ore Type, NONE]

	member:int JetCanNaming()
	{
		return ${This.MinerRef.FindSetting[JetCan Naming, 1]}
	}

	method SetJetCanNaming(int value)
	{
		This.MinerRef:AddSetting[JetCan Naming, ${value}]
	}

	member:bool BookMarkLastPosition()
	{
		return ${This.MinerRef.FindSetting[Bookmark Last Position, TRUE]}
	}

	method SetBookMarkLastPosition(bool value)
	{
		This.MinerRef:AddSetting[Bookmark Last Position, ${value}]
	}

	member:bool DistributeLasers()
	{
		return ${This.MinerRef.FindSetting[Distribute Lasers, TRUE]}
	}

	method SetDistributeLasers(bool value)
	{
		This.MinerRef:AddSetting[Distribute Lasers, ${value}]
	}

	member:bool UseMiningDrones()
	{
		return ${This.MinerRef.FindSetting[Use Mining Drones, FALSE]}
	}

	method SetUseMiningDrones(bool value)
	{
		This.MinerRef:AddSetting[Use Mining Drones, ${value}]
	}

	member:bool MasterMode()
	{
		return ${This.MinerRef.FindSetting[Master Mode, FALSE]}
	}

	method SetMasterMode(bool value)
	{
		This.MinerRef:AddSetting[Master Mode, ${value}]
	}

	member:bool GroupMode()
	{
		return ${This.MinerRef.FindSetting[Group Mode, FALSE]}
	}

	method SetGroupMode(bool value)
	{
		This.MinerRef:AddSetting[Group Mode, ${value}]
	}

	member:bool GroupModeAtRange()
	{
		return ${This.MinerRef.FindSetting[Group Mode At Range, FALSE]}
	}

	method SetGroupModeAtRange(bool value)
	{
		This.MinerRef:AddSetting[Group Mode At Range, ${value}]
	}

	member:bool GroupModeAtBoostRange()
	{
		return ${This.MinerRef.FindSetting[Group Mode At Boost Range, FALSE]}
	}

	method SetGroupModeAtBoostRange(bool value)
	{
		This.MinerRef:AddSetting[Group Mode At Boost Range, ${value}]
	}

	member:bool CompressOreMode()
	{
		return ${This.MinerRef.FindSetting[Compress Ore Mode, FALSE]}
	}

	method SetCompressOreMode(bool value)
	{
		This.MinerRef:AddSetting[Compress Ore Mode, ${value}]
	}

	member:bool SoloCompressOreMode()
	{
		return ${This.MinerRef.FindSetting[Solo Compress Ore Mode, FALSE]}
	}

	method SetSoloCompressOreMode(bool value)
	{
		This.MinerRef:AddSetting[Solo Compress Ore Mode, ${value}]
	}

	; Deprecated 2020-11-222
	member:bool OrcaMode()
	{
		return ${This.MinerRef.FindSetting[Orca Mode, FALSE]}
	}

	; Deprecated 2020-11-222
	method SetOrcaMode(bool value)
	{
		This.MinerRef:AddSetting[Orca Mode, ${value}]
	}

	member:bool SafeJetcan()
	{
		return ${This.MinerRef.FindSetting[Safe Jetcan, FALSE]}
	}

	method SetSafeJetcan(bool value)
	{
		This.MinerRef:AddSetting[Safe Jetcan, ${value}]
	}

	member:bool OrcaTractorLoot()
	{
		return ${This.MinerRef.FindSetting[Orca Tractor Loot, FALSE]}
	}

	method SetOrcaTractorLoot(bool value)
	{
		This.MinerRef:AddSetting[Orca Tractor Loot, ${value}]
	}

	member:int AvoidPlayerRange()
	{
		return ${This.MinerRef.FindSetting[Avoid Player Range, 10000]}
	}

	method SetAvoidPlayerRange(int value)
	{
		This.MinerRef:AddSetting[Avoid Player Range, ${value}]
	}

	member:bool StandingDetection()
	{
		return ${This.MinerRef.FindSetting[Standing Detection, FALSE]}
	}

	method SetStandingDetection(bool value)
	{
		This.MinerRef:AddSetting[Standing Detection, ${value}]
	}

	member:int LowestStanding()
	{
		return ${This.MinerRef.FindSetting[Lowest Standing, 0]}
	}

	method SetLowestStanding(int value)
	{
		This.MinerRef:AddSetting[Lowest Standing, ${value}]
	}

	member:int MinimumSecurityStatus()
	{
		return ${This.MinerRef.FindSetting[Minimum Security Status, -10.00]}
	}

	method SetMinimumSecurityStatus(float Value)
	{
		This.MinerRef:AddSetting[Minimum Security Status, ${Value}]
	}

	member:bool IceMining()
	{
		return ${This.MinerRef.FindSetting[Ice Mining, 0]}
	}

	method SetIceMining(bool value)
	{
		This.MinerRef:AddSetting[Ice Mining, ${value}]
	}

	member:int DeliveryLocationType()
	{
		return ${This.MinerRef.FindSetting[Delivery Location Type, 1]}
	}

	method SetDeliveryLocationType(int value)
	{
		This.MinerRef:AddSetting[Delivery Location Type, ${value}]
	}

	member:string DeliveryLocationTypeName()
	{
		return ${This.MinerRef.FindSetting[Delivery Location Type Name, STATION]}
	}

	method SetDeliveryLocationTypeName(string value)
	{
		This.MinerRef:AddSetting[Delivery Location Type Name, ${value}]
	}

	member:string DeliveryLocation()
	{
		return ${This.MinerRef.FindSetting[Delivery Location]}
	}

	method SetDeliveryLocation(string value)
	{
		This.MinerRef:AddSetting[Delivery Location, ${value}]
	}

	member:string PanicLocation()
	{
		return ${This.MinerRef.FindSetting[Panic Location]}
	}

	method SetPanicLocation(string value)
	{
		This.MinerRef:AddSetting[Panic Location, ${value}]
	}


	member:bool UseFieldBookmarks()
	{
		return ${This.MinerRef.FindSetting[Use Field Bookmarks, FALSE]}
	}

	method SetUseFieldBookmarks(bool value)
	{
		This.MinerRef:AddSetting[Use Field Bookmarks, ${value}]
	}

	member:bool StripMine()
	{
		return ${This.MinerRef.FindSetting[Strip Mine, FALSE]}
	}

	method SetStripMine(bool value)
	{
		This.MinerRef:AddSetting[Strip Mine, ${value}]
	}

	member:float MiningRangeMultipler()
	{
		return ${This.MinerRef.FindSetting[Mining Range Multipler, 2.2]}
	}

	method SetMiningRangeMultipler(float value)
	{
		This.MinerRef:AddSetting[Mining Range Multipler, ${value}]
	}

	member:int CargoThreshold()
	{
		variable float threshold
		threshold:Set[${This.MinerRef.FindSetting[Cargo Threshold, 0]}]
		if (${threshold} == 0)
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)}
			{
				This:SetCargoThreshold[${Ship.OreHoldCapacity}]
			}
			else
			{
				This:SetCargoThreshold[${MyShip.CargoCapacity}]
			}
		}
		return ${threshold}
	}

	method SetCargoThreshold(int value)
	{
		This.MinerRef:AddSetting[Cargo Threshold, ${value}]
	}
}


/* ************************************************************************* */
objectdef obj_Configuration_Combat
{
	variable string SetName = "Combat"
	variable weakref Ref

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Ref:SetReference["BaseConfig.BaseRef.FindSet[${This.SetName}]"]
		Logger:Log["obj_Configuration_Combat: Initialized", LOG_MINOR]
	}

	member:settingsetref CombatRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		Ref:SetReference["BaseConfig.BaseRef.FindSet[${This.SetName}]"]

		This.CombatRef:AddSetting[AnomalyAssistMode, FALSE]
		This.CombatRef:AddSetting[RestockAmmo, FALSE]
		This.CombatRef:AddSetting[RestockAmmoFreeSpace, 150]
		This.CombatRef:AddSetting[MinimumDronesInSpace,3]
		This.CombatRef:AddSetting[MinimumArmorPct, 35]
		This.CombatRef:AddSetting[MinimumShieldPct, 25]
		This.CombatRef:AddSetting[MinimumCapPct, 5]
		This.CombatRef:AddSetting[AlwaysShieldBoost, FALSE]
		This.CombatRef:AddSetting[Launch Combat Drones, TRUE]
		This.CombatRef:AddSetting[Run On Low Ammo, FALSE]
		This.CombatRef:AddSetting[Run On Low Cap, FALSE]
		This.CombatRef:AddSetting[Run On Low Tank, TRUE]
		This.CombatRef:AddSetting[Run To Station, TRUE]
		This.CombatRef:AddSetting[Whitelist Standings Bypass, FALSE]
		This.CombatRef:AddSetting[Use Whitelist, FALSE]
		This.CombatRef:AddSetting[Use Blacklist, FALSE]
		This.CombatRef:AddSetting[Chain Spawns, TRUE]
		This.CombatRef:AddSetting[Chain Solo, TRUE]
		This.CombatRef:AddSetting[Use Belt Bookmarks, FALSE]
		This.CombatRef:AddSetting[Reverse Belt Order,FALSE]
		This.CombatRef:AddSetting[Min Chain Bounty, 1500000]
		This.CombatRef:AddSetting[AmmoTypeID, 2629]
		This.CombatRef:AddSetting[OrbitDistance, 30000]
		This.CombatRef:AddSetting[Orbit, FALSE]
		This.CombatRef:AddSetting[OrbitAtOptimal, FALSE]
		This.CombatRef:AddSetting[KeepAtRangeDistance, 30000]
		This.CombatRef:AddSetting[KeepAtRange, FALSE]
		This.CombatRef:AddSetting[KeepAtRangeAtOptimal, FALSE]
		This.CombatRef:AddSetting[WarpRange, 0]
		This.CombatRef:AddSetting[Lowest Standing, 0]
		This.CombatRef:AddSetting[IncludeNeutralInCalc, 1]
		This.CombatRef:AddSetting[LootMyKills, 0]
		This.CombatRef:AddSetting[Use Anom Bookmarks, FALSE]
		This.CombatRef:AddSetting[AnomBookmarkLabel, Anom:]
		This.CombatRef:AddSetting[MaxDroneReturnWaitTime, 3]
		This.CombatRef:AddSetting[CurrentAnomType, 0]
	}

	Define_ConfigItem(bool, EnableDroneDefense, TRUE)

	member:int CurrentAnomType()
	{
		return ${This.CombatRef.FindSetting[CurrentAnomType, 0]}
	}

	method SetCurrentAnomType(int value)
	{
		This.CombatRef:AddSetting[CurrentAnomType, ${value}]
	}

	member:string CurrentAnomTypeName()
	{
		return ${This.CombatRef.FindSetting[CurrentAnomTypeName, None]}
	}

	method SetCurrentAnomTypeName(string value)
	{
		This.CombatRef:AddSetting[CurrentAnomTypeName, ${value}]
	}

	member:string CurrentAnom()
	{
		return ${This.CombatRef.FindSetting[CurrentAnom]}
	}

	method SetCurrentAnom(string value)
	{
		This.CombatRef:AddSetting[CurrentAnom, ${value}]
	}

	member:int WarpRange()
	{
		return ${This.CombatRef.FindSetting[WarpRange, 0]}
	}

	method SetWarpRange(int value)
	{
		This.CombatRef:AddSetting[WarpRange,${value}]
	}

	member:bool UseAnomBookmarks()
	{
		return ${This.CombatRef.FindSetting[Use Anom Bookmarks, FALSE]}
	}

	method SetUseAnomBookmarks(bool value)
	{
		This.CombatRef:AddSetting[Use Anom Bookmarks,${value}]
	}

	method SetAnomBookmarkLabel(string value)
	{
		This.CombatRef:AddSetting[AnomBookmarkLabel,${value}]
	}

	member:string AnomBookmarkLabel()
	{
		return ${This.CombatRef.FindSetting[AnomBookmarkLabel, AMMO]}
	}


	member:int AmmoTypeID()
	{
		return ${This.CombatRef.FindSetting[AmmoTypeID, 2629]}
	}

	method SetAmmoTypeID(int value)
	{
		This.CombatRef:AddSetting[AmmoTypeID,${value}]
	}

	member:bool RestockAmmo()
	{
		return ${This.CombatRef.FindSetting[RestockAmmo, FALSE]}
	}

	method SetRestockAmmo(bool value)
	{
		This.CombatRef:AddSetting[RestockAmmo,${value}]
	}

	member:int RestockAmmoFreeSpace()
	{
		return ${This.CombatRef.FindSetting[RestockAmmoFreeSpace, 150]}
	}

	method SetRestockAmmoFreeSpace(int value)
	{
		This.CombatRef:AddSetting[RestockAmmoFreeSpace,${value}]
	}

	method SetOrbit(bool value)
	{
		This.CombatRef:AddSetting[Orbit,${value}]
	}

	member:bool Orbit()
	{
		return ${This.CombatRef.FindSetting[Orbit, FALSE]}
	}

	method SetOrbitAtOptimal(bool value)
	{
		This.CombatRef:AddSetting[OrbitAtOptimal,${value}]
	}

	member:bool OrbitAtOptimal()
	{
		return ${This.CombatRef.FindSetting[OrbitAtOptimal, FALSE]}
	}

	method SetOrbitDistance(int value)
	{
		This.CombatRef:AddSetting[OrbitDistance,${value}]
	}

	member:int OrbitDistance()
	{
		return ${This.CombatRef.FindSetting[OrbitDistance, 30000]}
	}

		method SetKeepAtRange(bool value)
	{
		This.CombatRef:AddSetting[KeepAtRange,${value}]
	}

	member:bool KeepAtRange()
	{
		return ${This.CombatRef.FindSetting[KeepAtRange, FALSE]}
	}

	method SetKeepAtRangeAtOptimal(bool value)
	{
		This.CombatRef:AddSetting[KeepAtRangeAtOptimal,${value}]
	}

	member:bool KeepAtRangeAtOptimal()
	{
		return ${This.CombatRef.FindSetting[KeepAtRangeAtOptimal, FALSE]}
	}

	method SetKeepAtRangeDistance(int value)
	{
		This.CombatRef:AddSetting[KeepAtRangeDistance,${value}]
	}

	member:int KeepAtRangeDistance()
	{
		return ${This.CombatRef.FindSetting[KeepAtRangeDistance, 30000]}
	}

	method SetAnomalyAssistMode(bool value)
	{
		This.CombatRef:AddSetting[AnomalyAssistMode, ${value}]
	}

	member:bool AnomalyAssistMode()
	{
		return ${This.CombatRef.FindSetting[AnomalyAssistMode, FALSE]}
	}

	member:bool RunOnLowAmmo()
	{
		return ${This.CombatRef.FindSetting[Run On Low Ammo, FALSE]}
	}

	method SetRunOnLowAmmo(bool value)
	{
		This.CombatRef:AddSetting[Run On Low Ammo, ${value}]
	}

	member:bool RunOnLowCap()
	{
		return ${This.CombatRef.FindSetting[Run On Low Cap, FALSE]}
	}

	method SetRunOnLowCap(bool value)
	{
		This.CombatRef:AddSetting[Run On Low Cap, ${value}]
	}

	member:bool RunOnLowTank()
	{
		return ${This.CombatRef.FindSetting[Run On Low Tank, TRUE]}
	}

	method SetRunOnLowTank(bool value)
	{
		This.CombatRef:AddSetting[Run On Low Tank, ${value}]
	}

	member:bool RunToStation()
	{
		return ${This.CombatRef.FindSetting[Run To Station, TRUE]}
	}

	method SetRunToStation(bool value)
	{
		This.CombatRef:AddSetting[Run To Station, ${value}]
	}

	member:bool WLBypassStandings()
	{
		return ${This.CombatRef.FindSetting[Whitelist Standings Bypass,FALSE]}
	}

	method SetWLBypassStandings(bool value)
	{
		This.CombatRef:AddSetting[Whitelist Standings Bypass,${value}]
	}
	member:bool UseWhiteList()
	{
		return ${This.CombatRef.FindSetting[Use Whitelist, FALSE]}
	}

	method SetUseWhiteList(bool value)
	{
		This.CombatRef:AddSetting[Use Whitelist, ${value}]
	}

	member:bool UseBlackList()
	{
		return ${This.CombatRef.FindSetting[Use Blacklist, FALSE]}
	}

	method SetUseBlackList(bool value)
	{
		This.CombatRef:AddSetting[Use Blacklist, ${value}]
	}

	member:bool ChainSpawns()
	{
		return ${This.CombatRef.FindSetting[Chain Spawns, TRUE]}
	}

	method SetChainSpawns(bool value)
	{
		This.CombatRef:AddSetting[Chain Spawns, ${value}]
	}

	member:bool ChainSolo()
	{
		return ${This.CombatRef.FindSetting[Chain Solo, TRUE]}
	}

	method SetChainSolo(bool value)
	{
		This.CombatRef:AddSetting[Chain Solo, ${value}]
	}

	member:bool UseBeltBookmarks()
	{
		return ${This.CombatRef.FindSetting[Use Belt Bookmarks, FALSE]}
	}

	method SetUseBeltBookmarks(bool value)
	{
		This.CombatRef:AddSetting[Use Belt Bookmarks, ${value}]
	}

	member:bool ReverseBeltOrder()
	{
		return ${This.CombatRef.FindSetting[Reverse Belt Order, FALSE]}
	}

	method SetReverseBeltOrder(bool value)
	{
		This.CombatRef:AddSetting[Reverse Belt Order, ${value}]
	}

	member:int MinChainBounty()
	{
		return ${This.CombatRef.FindSetting[Min Chain Bounty, 1500000]}
	}

	method SetMinChainBounty(int value)
	{
		This.CombatRef:AddSetting[Min Chain Bounty,${value}]
	}

	member:bool LaunchCombatDrones()
	{
		return ${This.CombatRef.FindSetting[Launch Combat Drones, TRUE]}
	}

	method SetLaunchCombatDrones(bool value)
	{
		This.CombatRef:AddSetting[Launch Combat Drones, ${value}]
	}

	member:int MinimumDronesInSpace()
	{
		return ${This.CombatRef.FindSetting[MinimumDronesInSpace, 3]}
	}

	method SetMinimumDronesInSpace(int value)
	{
		This.CombatRef:AddSetting[MinimumDronesInSpace,${value}]
	}

	member:int MaxDroneReturnWaitTime()
	{
		return ${This.CombatRef.FindSetting[MaxDroneReturnWaitTime, 3]}
	}

	method SetMaxDroneReturnWaitTime(int value)
	{
		This.CombatRef:AddSetting[MaxDroneReturnWaitTime,${value}]
	}

	member:int MinimumArmorPct()
	{
		return ${This.CombatRef.FindSetting[MinimumArmorPct, 35]}
	}

	method SetMinimumArmorPct(int value)
	{
		This.CombatRef:AddSetting[MinimumArmorPct, ${value}]
	}

	member:int MinimumShieldPct()
	{
		return ${This.CombatRef.FindSetting[MinimumShieldPct, 25]}
	}

	method SetMinimumShieldPct(int value)
	{
		This.CombatRef:AddSetting[MinimumShieldPct, ${value}]
	}

	member:int MinimumCapPct()
	{
		return ${This.CombatRef.FindSetting[MinimumCapPct, 5]}
	}

	method SetMinimumCapPct(int value)
	{
		This.CombatRef:AddSetting[MinimumCapPct, ${value}]
	}

	member:bool AlwaysShieldBoost()
	{
		return ${This.CombatRef.FindSetting[AlwaysShieldBoost, FALSE]}
	}

	method SetAlwaysShieldBoost(bool value)
	{
		This.CombatRef:AddSetting[AlwaysShieldBoost, ${value}]
	}

	member:int LowestStanding()
	{
		return ${This.CombatRef.FindSetting[Lowest Standing, 0]}
	}

	method SetLowestStanding(int value)
	{
		This.CombatRef:AddSetting[Lowest Standing, ${value}]
	}

	member:bool IncludeNeutralInCalc()
	{
		return ${This.CombatRef.FindSetting[IncludeNeutralInCalc, FALSE]}
	}

	method SetIncludeNeutralInCalc(bool value)
	{
		This.CombatRef:AddSetting[IncludeNeutralInCalc, ${value}]
	}

	member:bool TakeBreaks()
	{
		return ${This.CombatRef.FindSetting[Take Breaks, FALSE]}
	}

	method SetTakeBreaks(bool value)
	{
		This.CombatRef:AddSetting[Take Breaks, ${value}]
	}

	member:int TimeBetweenBreaks()
	{
		return ${This.CombatRef.FindSetting[Time Between Breaks, 0]}
	}

	method SetTimeBetweenBreaks(int value)
	{
		This.CombatRef:AddSetting[Time Between Breaks, ${value}]
	}

	member:int BreakDuration()
	{
		return ${This.CombatRef.FindSetting[Break Duration, 0]}
	}

	method SetBreakDuration(int value)
	{
		This.CombatRef:AddSetting[Break Duration, ${value}]
	}
	member:bool BroadcastBreaks()
	{
		return ${This.CombatRef.FindSetting[Broadcast Breaks, FALSE]}
	}

	method SetBroadcastBreaks(bool value)
	{
		This.CombatRef:AddSetting[Broadcast Breaks, ${value}]
	}

	member:bool UseSafeCooldown()
	{
		return ${This.CombatRef.FindSetting[Use Safe Cooldown, FALSE]}
	}

	method SetUseSafeCooldown(bool value)
	{
		This.CombatRef:AddSetting[Use Safe Cooldown, ${value}]
	}

	member:int SafeCooldown()
	{
		return ${This.CombatRef.FindSetting[Safe Cooldown Duration, 0]}
	}

	method SetSafeCooldown(int value)
	{
		This.CombatRef:AddSetting[Safe Cooldown Duration, ${value}]
	}


	member:bool LootMyKills()
	{
		return ${This.CombatRef.FindSetting[LootMyKills, FALSE]}
	}

	method SetLootMyKills(bool value)
	{
		This.CombatRef:AddSetting[LootMyKills, ${value}]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration_Hauler
{
	variable string SetName = "Hauler"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Configuration_Hauler: Initialized", LOG_MINOR]
	}

	member:settingsetref HaulerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.HaulerRef:AddSetting[Hauler Mode,1]
		This.HaulerRef:AddSetting[Hauler Mode Name, "Service Fleet Members"]
		This.HaulerRef:AddSetting[Multi System Support, FALSE]
		This.HaulerRef:AddSetting[Drop Off Bookmark, ""]
		This.HaulerRef:AddSetting[Mining System Bookmark, ""]
		This.HaulerRef:AddSetting[Haul for New Fleet Members, TRUE]
		This.HaulerRef:AddSetting[Orca running EveBOT,TRUE]
	}

	member:int HaulerMode()
	{
		return ${This.HaulerRef.FindSetting[Hauler Mode, 1]}
	}

	method SetHaulerMode(int Mode)
	{
		This.HaulerRef:AddSetting[Hauler Mode, ${Mode}]
	}

	member:string HaulerModeName()
	{
		return ${This.HaulerRef.FindSetting[Hauler Mode Name, "Service Fleet Members"]}
	}

	method SetHaulerModeName(string Mode)
	{
		This.HaulerRef:AddSetting[Hauler Mode Name,${Mode}]
	}

	member:bool MultiSystemSupport()
	{
		return ${This.HaulerRef.FindSetting[Multi System Support, FALSE]}
	}

	method SetMultiSystemSupport(bool value)
	{
		This.HaulerRef:AddSetting[Multi System Support, ${value}]
	}

	member:string MiningSystemBookmark()
	{
		return ${This.HaulerRef.FindSetting[Mining System Bookmark, ""]}
	}

	method SetMiningSystemBookmark(string Bookmark)
	{
		This.HaulerRef:AddSetting[Mining System Bookmark,${Bookmark}]
	}

	member:bool HaulNewFleetMembers()
	{
		return ${This.HaulerRef.FindSetting[Haul for New Fleet Members, TRUE]}
	}

	method SetHaulNewFleetMembers(bool value)
	{
		This.HaulerRef:AddSetting[Haul for New Fleet Members, ${value}]
	}

	member:string HaulerPickupName()
	{
		return ${This.HaulerRef.FindSetting[Hauler Pickup Name, ""]}
	}

	method SetHaulerPickupName(string Bookmark)
	{
		This.HaulerRef:AddSetting[Hauler Pickup Name,${Bookmark}]
	}

	member:bool OrcaRunningEvebot()
	{
		return ${This.HaulerRef.FindSetting[Orca Running EveBOT, TRUE]}
	}

	method SetOrcaRunningEvebot(bool value)
	{
		This.HaulerRef:AddSetting[Orca Running EveBOT, ${value}]
	}

}

/* ************************************************************************* */
objectdef obj_Configuration_Salvager
{
	variable string SetName = "Salvager"

	method Initialize()
	{
		return
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Configuration_Salvager: Initialized", LOG_MINOR]
	}

	member:settingsetref SalvagerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

	}

}

/* ************************************************************************* */
objectdef obj_Configuration_Labels
{
	variable string SetName = "Labels"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Configuration_Labels: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref LabelsRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.LabelsRef:AddSetting[Safe Spot Prefix,"Safe:"]
		This.LabelsRef:AddSetting[Ore Belt Prefix,"Belt:"]
		This.LabelsRef:AddSetting[Ice Belt Prefix,"Ice Belt:"]
		This.LabelsRef:AddSetting[Ammo Prefix,"Ammo:"]
	}

	Define_ConfigItem(string, InstaUndockTag, "Undock")
	Define_ConfigItem(string, InstaDockTag, "Dock")

	member:string SafeSpotPrefix()
	{
		return ${This.LabelsRef.FindSetting[Safe Spot Prefix,"Safe:"]}
	}

	method SetSafeSpotPrefix(string value)
	{
		This.LabelsRef:AddSetting[Safe Spot Prefix,${value}]
	}

	member:string OreBeltPrefix()
	{
		return ${This.LabelsRef.FindSetting[Ore Belt Prefix,"Belt:"]}
	}

	method SetOreBeltPrefix(string value)
	{
		This.LabelsRef:AddSetting[Ore Belt Prefix,${value}]
	}

	member:string IceBeltPrefix()
	{
		return ${This.LabelsRef.FindSetting[Ice Belt Prefix,"Ice Belt:"]}
	}

	method SetIceBeltPrefix(string value)
	{
		This.LabelsRef:AddSetting[Ice Belt Prefix,${value}]
	}

	member:string AmmoPrefix()
	{
		return ${This.LabelsRef.FindSetting[Ammo Prefix, "Ammo:"]}
	}

	method SetAmmoPrefix(string value)
	{
		This.LabelsRef:AddSetting[Ammo Prefix,${value}]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration_Freighter
{
	variable string SetName = "Freighter"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Configuration_Freighter: Initialized", LOG_MINOR]
	}

	member:settingsetref FreighterRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.FreighterRef:AddSetting[Freighter Mode, 1]
		This.FreighterRef:AddSetting[Freighter Mode Name, "Source and Destination"]
		This.FreighterRef:AddSetting[Region Name, ""]
		This.FreighterRef:AddSetting[Destination,""]
		This.FreighterRef:AddSetting[Source Prefix,""]
		This.FreighterRef:AddSetting[Agent Name, ""]
		This.FreighterRef:AddSetting[Last Decline, ${Time.Timestamp}]
	}

	member:int FreighterMode()
	{
		return ${This.FreighterRef.FindSetting[Freighter Mode, 1]}
	}

	method SetFreighterMode(int Mode)
	{
		This.FreighterRef:AddSetting[Freighter Mode, ${Mode}]
	}

	member:string FreighterModeName()
	{
		return ${This.FreighterRef.FindSetting[Freighter Mode Name, "Source and Destination"]}
	}

	method SetFreighterModeName(string Mode)
	{
		This.FreighterRef:AddSetting[Freighter Mode Name,${Mode}]
	}

	member:string RegionName()
	{
		return ${This.FreighterRef.FindSetting[Region Name, ""]}
	}

	method SetRegionName(string Name)
	{
		This.FreighterRef:AddSetting[Region Name,${Name}]
	}

	member:string AgentName()
	{
		return ${This.FreighterRef.FindSetting[Agent Name, ""]}
	}

	method SetAgentName(string Name)
	{
		This.FreighterRef:AddSetting[Agent Name,${Name}]
	}

	member:string Destination()
	{
		return ${This.FreighterRef.FindSetting[Destination,""]}
	}

	method SetDestination(string value)
	{
		This.FreighterRef:AddSetting[Destination,${value}]
	}

	member:string SourcePrefix()
	{
		return ${This.FreighterRef.FindSetting[Source Prefix,""]}
	}

	method SetSourcePrefix(string value)
	{
		This.FreighterRef:AddSetting[Source Prefix,${value}]
	}

	member:int LastDecline()
	{
		return ${This.FreighterRef.FindSetting[Last Decline,${Time.Timestamp}]}
	}

	method SetLastDecline(int value)
	{
		This.FreighterRef:AddSetting[Last Decline,${value}]
	}

}

/* ************************************************************************* */
objectdef obj_Config_Whitelist
{
	variable string DATA_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Whitelist.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[EVEBotWhitelist]:Clear
		LavishSettings:AddSet[EVEBotWhitelist]
		This.BaseRef:Set[${LavishSettings[EVEBotWhitelist]}]
		Logger:Log["obj_Config_Whitelist: Loading ${DATA_FILE}"]
		This.BaseRef:Import[${This.DATA_FILE}]

		if !${This.BaseRef.FindSet[Pilots](exists)}
		{
			This.BaseRef:AddSet[Pilots]
			This:Save
		}

		if !${This.BaseRef.FindSet[Corporations](exists)}
		{
			This.BaseRef:AddSet[Corporations]
			This:Save
		}

		if !${This.BaseRef.FindSet[Alliances](exists)}
		{
			This.BaseRef:AddSet[Alliances]
			This:Save
		}

		Logger:Log["obj_Config_Whitelist: Initialized", LOG_MINOR]
	}

	method Wipe()
	{
		LavishSettings[EVEBotWhitelist]:Clear
		LavishSettings:AddSet[EVEBotWhitelist]
		This.BaseRef:Set[${LavishSettings[EVEBotWhitelist]}]

		This.BaseRef:AddSet[Pilots]
		This.BaseRef:AddSet[Corporations]
		This.BaseRef:AddSet[Alliances]
		This:Save

	}

	method Shutdown()
	{
		; Don't save this on shutdown, we'll save it explicitly when needed
		; This:Save[]
		LavishSettings[EVEBotWhitelist]:Clear
	}

	method Save()
	{
		Logger:Log["obj_Config_Whitelist: Saved"]
		LavishSettings[EVEBotWhitelist]:Export[${This.DATA_FILE}]
	}

	member:settingsetref PilotsRef()
	{
		return ${This.BaseRef.FindSet[Pilots]}
	}

	member:settingsetref CorporationsRef()
	{
		return ${This.BaseRef.FindSet[Corporations]}
	}

	member:settingsetref AlliancesRef()
	{
		return ${This.BaseRef.FindSet[Alliances]}
	}
}

/* ************************************************************************* */
objectdef obj_Config_Blacklist
{
	variable string DATA_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Blacklist.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[EVEBotBlacklist]:Clear
		LavishSettings:AddSet[EVEBotBlacklist]
		This.BaseRef:Set[${LavishSettings[EVEBotBlacklist]}]
		Logger:Log["obj_Config_Blacklist: Loading ${DATA_FILE}"]
		This.BaseRef:Import[${This.DATA_FILE}]

		if !${This.BaseRef.FindSet[Pilots](exists)}
		{
			This.BaseRef:AddSet[Pilots]
			This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
			This:Save
		}

		if !${This.BaseRef.FindSet[Corporations](exists)}
		{
			This.BaseRef:AddSet[Corporations]
			This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
			This:Save
		}

		if !${This.BaseRef.FindSet[Alliances](exists)}
		{
			This.BaseRef:AddSet[Alliances]
			This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
			This:Save
		}

		Logger:Log["obj_Config_Blacklist: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		; Don't save this on shutdown, we'll save it explicitly when needed
		; This:Save[]
		LavishSettings[EVEBotBlacklist]:Clear
	}

	method Save()
	{
		Logger:Log["obj_Config_Blacklist: Saved"]
		LavishSettings[EVEBotBlacklist]:Export[${This.DATA_FILE}]
	}

	member:settingsetref PilotsRef()
	{
		return ${This.BaseRef.FindSet[Pilots]}
	}

	member:settingsetref CorporationsRef()
	{
		return ${This.BaseRef.FindSet[Corporations]}
	}

	member:settingsetref AlliancesRef()
	{
		return ${This.BaseRef.FindSet[Alliances]}
	}
}
/* ************************************************************************* */
objectdef obj_Configuration_Agents
{
	variable string SetName = "Agents"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Configuration_Agents: Initialized", LOG_MINOR]
	}

	member:settingsetref AgentsRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref AgentRef(string name)
	{
		return ${This.AgentsRef.FindSet[${name}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.AgentsRef:AddSet["Fykalia Adaferid"]
		This.AgentRef["Fykalia Adaferid"]:AddSetting[AgentIndex,9591]
		This.AgentRef["Fykalia Adaferid"]:AddSetting[AgentID,3018920]
		This.AgentRef["Fykalia Adaferid"]:AddSetting[LastDecline,${Time.Timestamp}]
	}

	member:int AgentIndex(string name)
	{
		;Logger:Log["obj_Configuration_Agents: AgentIndex ${name}"]
		return ${This.AgentRef[${name}].FindSetting[AgentIndex,9591]}
	}

	method SetAgentIndex(string name, int value)
	{
		;Logger:Log["obj_Configuration_Agents: SetAgentIndex ${name} ${value}"]
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[AgentIndex,${value}]
	}

	member:int AgentID(string name)
	{
		;Logger:Log["obj_Configuration_Agents: AgentID ${name}"]
		return ${This.AgentRef[${name}].FindSetting[AgentID,3018920]}
	}

	method SetAgentID(string name, int value)
	{
		;Logger:Log["obj_Configuration_Agents: SetAgentID ${name} ${value}"]
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[AgentID,${value}]
	}

	member:int LastDecline(string name)
	{
		;Logger:Log["obj_Configuration_Agents: LastDecline ${name}"]
		return ${This.AgentRef[${name}].FindSetting[LastDecline,${Time.Timestamp}]}
	}

	method SetLastDecline(string name, int value)
	{
		;Logger:Log["obj_Configuration_Agents: SetLastDecline ${name} ${value}"]
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[LastDecline,${value}]
	}

	member:int LastCompletionTime(string name)
	{
		;;;Logger:Log["obj_Configuration_Agents: LastCompletionTime ${name}"]
		return ${This.AgentRef[${name}].FindSetting[LastCompletionTime,0]}
	}

	method SetLastCompletionTime(string name, int value)
	{
		;;;Logger:Log["obj_Configuration_Agents: SetLastCompletionTime ${name} ${value}"]
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[LastCompletionTime,${value}]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration_Missioneer
{
	variable string SetName = "Missioneer"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Configuration_Missioneer: Initialized", LOG_MINOR]
	}

	member:settingsetref MissioneerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.MissioneerRef:AddSetting[Run Courier Missions, TRUE]
		This.MissioneerRef:AddSetting[Run Trade Missions, FALSE]
		This.MissioneerRef:AddSetting[Run Mining Missions, FALSE]
		This.MissioneerRef:AddSetting[Run Kill Missions, FALSE]
		This.MissioneerRef:AddSetting[Small Hauler, ""]
		This.MissioneerRef:AddSetting[Large Hauler, ""]
		This.MissioneerRef:AddSetting[Mining Ship, ""]
		This.MissioneerRef:AddSetting[Combat Ship, ""]
		This.MissioneerRef:AddSetting[Salvage Mode, 1]
		This.MissioneerRef:AddSetting[Salvage Mode Name, "None"]
		This.MissioneerRef:AddSetting[Salvage Ship, ""]
		This.MissioneerRef:AddSetting[Avoid Low Sec, TRUE]
		This.MissioneerRef:AddSetting[Small Hauler Limit, 600]
	}

	member:bool RunCourierMissions()
	{
		return ${This.MissioneerRef.FindSetting[Run Courier Missions, TRUE]}
	}

	method SetRunCourierMissions(bool value)
	{
		This.MissioneerRef:AddSetting[Run Courier Missions, ${value}]
	}

	member:bool RunTradeMissions()
	{
		return ${This.MissioneerRef.FindSetting[Run Trade Missions, FALSE]}
	}

	method SetRunTradeMissions(bool value)
	{
		This.MissioneerRef:AddSetting[Run Trade Missions, ${value}]
	}

	member:bool RunMiningMissions()
	{
		return ${This.MissioneerRef.FindSetting[Run Mining Missions, FALSE]}
	}

	method SetRunMiningMissions(bool value)
	{
		This.MissioneerRef:AddSetting[Run Mining Missions, ${value}]
	}

	member:bool RunKillMissions()
	{
		return ${This.MissioneerRef.FindSetting[Run Kill Missions, FALSE]}
	}

	method SetRunKillMissions(bool value)
	{
		This.MissioneerRef:AddSetting[Run Kill Missions, ${value}]
	}

	member:string SmallHauler()
	{
		return ${This.MissioneerRef.FindSetting[Small Hauler, ""]}
	}

	method SetSmallHauler(string value)
	{
		This.MissioneerRef:AddSetting[Small Hauler,${value}]
	}

	member:string LargeHauler()
	{
		return ${This.MissioneerRef.FindSetting[Large Hauler, ""]}
	}

	method SetLargeHauler(string value)
	{
		This.MissioneerRef:AddSetting[Large Hauler,${value}]
	}

	member:string MiningShip()
	{
		return ${This.MissioneerRef.FindSetting[Mining Ship, ""]}
	}

	method SetMiningShip(string value)
	{
		This.MissioneerRef:AddSetting[Mining Ship,${value}]
	}

	member:string CombatShip()
	{
		return ${This.MissioneerRef.FindSetting[Combat Ship, ""]}
	}

	method SetCombatShip(string value)
	{
		This.MissioneerRef:AddSetting[Combat Ship,${value}]
	}

	member:int SalvageMode()
	{
		return ${This.MissioneerRef.FindSetting[Salvage Mode, 1]}
	}

	method SetSalvageMode(int value)
	{
		This.MissioneerRef:AddSetting[Salvage Mode,${value}]
	}

	member:string SalvageModeName()
	{
		return ${This.MissioneerRef.FindSetting[Salvage Mode Name, "None"]}
	}

	method SetSalvageModeName(string value)
	{
		This.MissioneerRef:AddSetting[Salvage Mode Name,${value}]
	}

	member:string SalvageShip()
	{
		return ${This.MissioneerRef.FindSetting[Salvage Ship, ""]}
	}

	method SetSalvageShip(string value)
	{
		This.MissioneerRef:AddSetting[Salvage Ship,${value}]
	}

	member:bool AvoidLowSec()
	{
		return ${This.MissioneerRef.FindSetting[Avoid Low Sec, TRUE]}
	}

	method SetAvoidLowSec(bool value)
	{
		This.MissioneerRef:AddSetting[Avoid Low Sec, ${value}]
	}

	member:int SmallHaulerLimit()
	{
		return ${This.MissioneerRef.FindSetting[Small Hauler Limit, 600]}
	}

	method SetSmallHaulerLimit(int value)
	{
		This.MissioneerRef:AddSetting[Small Hauler Limit,${value}]
	}

}

objectdef obj_FleetMember
{
	variable string FleetMemberName
	variable bool Wing

	method Initialize(string arg_FleetMemberName, bool arg_Wing)
	{
		FleetMemberName:Set[${arg_FleetMemberName}]
		Wing:Set[${arg_Wing}]
	}
}


/* ************************************************************************* */
objectdef obj_Configuration_Fleet
{
	variable string SetName = "Fleet"
	variable index:obj_FleetMember FleetMembers
	variable bool WingOne=FALSE

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)} || !${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[FleetMembers](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}

		Logger:Log["obj_Configuration_Fleet: Initialized", LOG_MINOR]
	}

	member:settingsetref FleetRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	member:settingsetref FleetMembersRef()
	{
		return ${This.FleetRef.FindSet[FleetMembers]}
	}
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.FleetRef:AddSet[FleetMembers]
	}

	member:bool ManageFleet()
	{
		return ${This.FleetRef.FindSetting[Manage Fleet, FALSE]}
	}

	method SetManageFleet(bool value)
	{
		This.FleetRef:AddSetting[Manage Fleet, ${value}]
	}

	member:bool IsLeader()
	{
		return ${This.FleetRef.FindSetting[Is Leader, FALSE]}
	}

	method SetIsLeader(bool value)
	{
		This.FleetRef:AddSetting[Is Leader, ${value}]
	}

	member:string FleetLeader()
	{
		return ${This.FleetRef.FindSetting[Fleet Leader, ""]}
	}

	method SetFleetLeader(string value)
	{
		This.FleetRef:AddSetting[Fleet Leader, ${value}]
	}

	method AddFleetMember(string value)
	{
		if ${This.IsListed[${value}]}
			This:UpdateFleetMember[${value}]
		else
			This.FleetMembersRef:AddSetting[${value}, ${WingOne}]
	}
	method RemoveFleetMember(string value)
	{
		This.FleetMembersRef.FindSetting[${value}]:Remove
	}
	method UpdateFleetMember(string value)
	{
		This.FleetMembersRef.FindSetting[${value}]:Set[${WingOne}]
	}
	method SetWingOne(bool value)
	{
		WingOne:Set[${value}]
	}

	member:bool IsWing(string value)
	{
		This:RefreshFleetMembers
		variable iterator InfoFromSettings
		This.FleetMembers:GetIterator[InfoFromSettings]
		if ${InfoFromSettings:First(exists)}
			do
			{
				if ${InfoFromSettings.Value.FleetMemberName.Equal[${value}]} && ${InfoFromSettings.Value.Wing}
					return TRUE
			}
			while ${InfoFromSettings:Next(exists)}
		return FALSE
	}
	member:bool IsListed(string value)
	{
		This:RefreshFleetMembers
		variable iterator InfoFromSettings
		This.FleetMembers:GetIterator[InfoFromSettings]
		if ${InfoFromSettings:First(exists)}
			do
			{
				if ${InfoFromSettings.Value.FleetMemberName.Equal[${value}]}
					return TRUE
			}
			while ${InfoFromSettings:Next(exists)}
		return FALSE
	}

	method RefreshFleetMembers()
	{
		FleetMembers:Clear
		variable iterator InfoFromSettings
		This.FleetMembersRef:GetSettingIterator[InfoFromSettings]
		if ${InfoFromSettings:First(exists)}
		{
			do
			{
				FleetMembers:Insert[${InfoFromSettings.Key},${InfoFromSettings.Value}]
			}
			while ${InfoFromSettings:Next(exists)}
		}
	}
}
