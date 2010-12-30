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
		;echo "This.Ref:AddSetting[_Key, ${Value}]"
		This.Ref:AddSetting[_Key, ${Value}]
	}
#endmac


/* ************************************************************************* */
objectdef obj_Configuration_BaseConfig
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable float ConfigVersion = 2.0
	
	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
	variable filepath DATA_PATH = "${Script.CurrentDirectory}/Data"

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${Me.Name}.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[EVEBotSettings]:Remove
		LavishSettings:AddSet[EVEBotSettings]

		; Check new config file first, then fallball to original name for import
		Logger:Log["Configuration file is ${CONFIG_FILE}"]
		LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]
		if !${LavishSettings[EVEBotSettings].FindSetting[Version](exists)} || \
			${LavishSettings[EVEBotSettings].FindSetting[Version].Float} < ${ConfigVersion}
		{
			echo "obj_Configuration_BaseConfig: Resetting configuration to default for version ${ConfigVersion}"
			Logger:Log["obj_Configuration_BaseConfig: Resetting configuration to default for version ${ConfigVersion}", LOG_CRITICAL]
			LavishSettings[EVEBotSettings]:Remove
			LavishSettings:AddSet[EVEBotSettings]
			LavishSettings[EVEBotSettings]:AddSetting[Version, ${ConfigVersion}]
		}
		BaseRef:Set[${LavishSettings[EVEBotSettings]}]
		Logger:Log["obj_Configuration_BaseConfig: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		This:Save[]
		LavishSettings[EVEBotSettings]:Remove
	}

	method Save()
	{
		LavishSettings[EVEBotSettings]:Export[${CONFIG_FILE}]
	}
}

/* ************************************************************************* */
objectdef obj_Configuration
{
	variable obj_Configuration_Common Common
	variable obj_Configuration_Sound Sound
	variable obj_Configuration_Logging Logging
	variable obj_Configuration_Combat Combat
	variable obj_Configuration_Defense Defense
	variable obj_Configuration_Miner Miner
	variable obj_Configuration_Hauler Hauler
	variable obj_Configuration_Salvager Salvager
	variable obj_Configuration_Labels Labels
	variable obj_Configuration_Freighter Freighter
	variable obj_Configuration_Agents Agents
	variable obj_Configuration_Missioneer Missioneer
	variable obj_Config_FleetMembers FleetMembers

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

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Common: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(string, Behavior, "Miner")
	Define_ConfigItem(bool, Callback, FALSE)
	Define_ConfigItem(int, MinimumDronesInBay, 0)
	Define_ConfigItem(string, HomeStation, NOTSET)
	Define_ConfigItem(int64, LastStationID, NOTSET)
	Define_ConfigItem(string, LoginName, NOTSET)
	Define_ConfigItem(string, LoginPassword, NOTSET)
	Define_ConfigItem(bool, AutoLogin, FALSE)
	Define_ConfigItem(int64, AutoLoginCharID, 0)
	Define_ConfigItem(int, MaxRuntime, 0)
	Define_ConfigItem(string, IRCServer, "irc.lavishsoft.com")
	Define_ConfigItem(string, IRCChannel, "#EVEBot_${Math.Rand[999999]}")
	Define_ConfigItem(string, IRCUser, "Test${Math.Rand[5000]:Inc[1000]}")
	Define_ConfigItem(string, IRCPassword, "evebot")
	Define_ConfigItem(bool, Disable3D, FALSE)
	Define_ConfigItem(bool, DisableUI, FALSE)
	Define_ConfigItem(bool, DisableScreenWhenBackgrounded, FALSE)
	Define_ConfigItem(bool, TrainSkills, FALSE)
	Define_ConfigItem(bool, Randomize, TRUE)
}

/* ************************************************************************* */
objectdef obj_Configuration_Sound
{
	variable string SetName = "Sound"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Sound: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	Define_ConfigItem(bool, EnableSound, TRUE)
;TODO - add config items for EnableChatAlerts
	Define_ConfigItem(bool, EnableChatAlerts, TRUE)
}

/* ************************************************************************* */
objectdef obj_Configuration_Logging
{
	variable string SetName = "Logging"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Sound: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

;TODO - add config items for LogLocalChat
;TODO - add config items for LogLocalChatToIRC
;TODO - add config items for LogCorpChat
;TODO - add config items for LogCorpChatToIRC
;TODO - add config items for LogAllianceChat
;TODO - add config items for LogAllianceChatToIRC
	Define_ConfigItem(bool, LogLocalChat, FALSE)
	Define_ConfigItem(bool, LogLocalChatToIRC, FALSE)
	Define_ConfigItem(bool, LogCorpChat, FALSE)
	Define_ConfigItem(bool, LogCorpChatToIRC, FALSE)
	Define_ConfigItem(bool, LogAllianceChat, FALSE)
	Define_ConfigItem(bool, LogAllianceChatToIRC, FALSE)
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
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Mercoxit_Types](exists)}
		{
			Logger:Log["obj_Configuration_Miner: Re-Initializing Asteroid Types"]
			BaseConfig.BaseRef.FindSet[${This.SetName}]:Remove
			This:Set_Default_Values[]
		}
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref OreTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Types]}
	}

	member:settingsetref MercoxitTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Mercoxit_Types]}
	}

	member:settingsetref IceTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ice_Types]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This:Set_Default_Values_Ore[]
		This:Set_Default_Values_Mercoxit[]
		This:Set_Default_Values_Ice[]
	}

	method Set_Default_Values_Ore_Template(string OreName, int TypeID, int Enabled, int Priority)
	{
		This.OreTypesRef.FindSetting[${TypeID}, ${OreName}]:AddAttribute[Enabled, ${Enabled}]
		This.OreTypesRef.FindSetting[${TypeID}, ${OreName}]:AddAttribute[Priority, ${Priority}]
	}
	
	method Set_Default_Values_Ore()
	{
		This.Ref:AddSet[ORE_Types]

		This:Set_Default_Values_Ore_Template[Prime Arkonor, 17426, 1, 1]
		This:Set_Default_Values_Ore_Template[Crimson Arkonor, 17425, 1, 2]
		This:Set_Default_Values_Ore_Template[Arkonor, 22, 1, 3]
		This:Set_Default_Values_Ore_Template[Monoclinic Bistot, 17429, 1, 4]
		This:Set_Default_Values_Ore_Template[Triclinic Bistot, 17428, 1, 5]
		This:Set_Default_Values_Ore_Template[Bistot, 1223, 1, 6]
		This:Set_Default_Values_Ore_Template[Crystalline Crokite, 17433, 1, 7]
		This:Set_Default_Values_Ore_Template[Sharp Crokite, 17432, 1, 8]
		This:Set_Default_Values_Ore_Template[Crokite, 1225, 1, 9]
		This:Set_Default_Values_Ore_Template[Gleaming Spodumain, 17467, 1, 10]
		This:Set_Default_Values_Ore_Template[Bright Spodumain, 17466, 1, 11]
		This:Set_Default_Values_Ore_Template[Spodumain, 19, 1, 12]
		This:Set_Default_Values_Ore_Template[Obsidian Ochre, 17437, 1, 13]
		This:Set_Default_Values_Ore_Template[Onyx Ochre, 17436, 1, 14]
		This:Set_Default_Values_Ore_Template[Dark Ochre, 1232, 1, 15]
		This:Set_Default_Values_Ore_Template[Prismatic Gneiss, 17866, 1, 16]
		This:Set_Default_Values_Ore_Template[Iridescent Gneiss, 17865, 1, 17]
		This:Set_Default_Values_Ore_Template[Gneiss, 1229, 1, 18]
		This:Set_Default_Values_Ore_Template[Glazed Hedbergite, 17441, 1, 19]
		This:Set_Default_Values_Ore_Template[Vitric Hedbergite, 17440, 1, 20]
		This:Set_Default_Values_Ore_Template[Hedbergite, 21, 1, 21]
		This:Set_Default_Values_Ore_Template[Radiant Hemorphite, 17445, 1, 22]
		This:Set_Default_Values_Ore_Template[Vivid Hemorphite, 17444, 1, 23]
		This:Set_Default_Values_Ore_Template[Hemorphite, 1231, 1, 24]
		This:Set_Default_Values_Ore_Template[Pristine Jaspet, 17449, 1, 25]
		This:Set_Default_Values_Ore_Template[Pure Jaspet, 17448, 1, 26]
		This:Set_Default_Values_Ore_Template[Jaspet, 1226, 1, 27]
		This:Set_Default_Values_Ore_Template[Fiery Kernite, 17453, 1, 28]
		This:Set_Default_Values_Ore_Template[Luminous Kernite, 17452, 1, 29]
		This:Set_Default_Values_Ore_Template[Kernite, 20, 1, 30]
		This:Set_Default_Values_Ore_Template[Golden Omber, 17868, 1, 31]
		This:Set_Default_Values_Ore_Template[Silvery Omber, 17867, 1, 32]
		This:Set_Default_Values_Ore_Template[Omber, 1227, 1, 33]
		This:Set_Default_Values_Ore_Template[Rich Plagioclase, 17456, 1, 34]
		This:Set_Default_Values_Ore_Template[Azure Plagioclase, 17455, 1, 35]
		This:Set_Default_Values_Ore_Template[Plagioclase, 18, 1, 36]
		This:Set_Default_Values_Ore_Template[Viscous Pyroxeres, 17460, 1, 37]
		This:Set_Default_Values_Ore_Template[Solid Pyroxeres, 17459, 1, 38]
		This:Set_Default_Values_Ore_Template[Pyroxeres, 1224, 1, 39]
		This:Set_Default_Values_Ore_Template[Massive Scordite, 17464, 1, 40]
		This:Set_Default_Values_Ore_Template[Condensed Scordite, 17463, 1, 41]
		This:Set_Default_Values_Ore_Template[Scordite, 1228, 1, 42]
		This:Set_Default_Values_Ore_Template[Dense Veldspar, 17471, 1, 43]
		This:Set_Default_Values_Ore_Template[Concentrated Veldspar, 17470, 1, 44]
		This:Set_Default_Values_Ore_Template[Veldspar, 1230, 1, 45]
	}

	method Set_Default_Values_Mercoxit_Template(string OreName, int TypeID, int Enabled, int Priority)
	{
		This.MercoxitTypesRef.FindSetting[${TypeID}, ${OreName}]:AddAttribute[Enabled, ${Enabled}] 
		This.MercoxitTypesRef.FindSetting[${TypeID}, ${OreName}]:AddAttribute[Priority, ${Priority}] 
	}

	method Set_Default_Values_Mercoxit()
	{
		This.Ref:AddSet[Mercoxit_Types]

		This:Set_Default_Values_Mercoxit_Template[Vitreous Mercoxit, 17870, 1, 1]
		This:Set_Default_Values_Mercoxit_Template[Magma Mercoxit, 17869, 1, 2]
		This:Set_Default_Values_Mercoxit_Template[Mercoxit, 11396, 1, 3]
	}

	method Set_Default_Values_Ice_Template(string OreName, int TypeID, int Enabled, int Priority)
	{
		This.IceTypesRef.FindSetting[${TypeID}, ${OreName}]:AddAttribute[Enabled, ${Enabled}] 
		This.IceTypesRef.FindSetting[${TypeID}, ${OreName}]:AddAttribute[Priority, ${Priority}] 
	}

	method Set_Default_Values_Ice()
	{
		This.Ref:AddSet[ICE_Types]

		This:Set_Default_Values_Ice_Template[Dark Glitter, 16267, 1, 1]
		This:Set_Default_Values_Ice_Template[Gelidus, 16268, 1, 2]
		This:Set_Default_Values_Ice_Template[Glare Crust, 16266, 1, 3]
		This:Set_Default_Values_Ice_Template[Krystallos, 16269, 1, 4]
		This:Set_Default_Values_Ice_Template[Clear Icicle, 16262, 1, 5]
		This:Set_Default_Values_Ice_Template[Smooth Glacial Mass, 17977, 1, 6]
		This:Set_Default_Values_Ice_Template[Glacial Mass, 16263, 1, 7]
		This:Set_Default_Values_Ice_Template[Pristine White Glaze, 17976, 1, 8]
		This:Set_Default_Values_Ice_Template[White Glaze, 16265, 1, 9]
		This:Set_Default_Values_Ice_Template[Thick Blue Ice, 17975, 1, 10]
		This:Set_Default_Values_Ice_Template[Enriched Clear Icicle, 17978, 1, 11]
		This:Set_Default_Values_Ice_Template[Blue Ice, 16264, 1, 12]
	}

	Define_ConfigItem(string, JetCanNaming, 1)
	Define_ConfigItem(bool, BookMarkLastPosition, FALSE)
	Define_ConfigItem(bool, UseMiningDrones, TRUE)
	Define_ConfigItem(int, AvoidPlayerRange, 10000)
	Define_ConfigItem(string, MinerType, Ore)
	Define_ConfigItem(string, DeliveryLocationType, STATION)
	Define_ConfigItem(string, DeliveryLocation, NOTSET)
	Define_ConfigItem(bool, UseFieldBookmarks, TRUE)
	Define_ConfigItem(bool, StripMine, FALSE)
	Define_ConfigItem(float, MiningRangeMultipler, 2.2)
	Define_ConfigItem(bool, StripMine, FALSE)
	Define_ConfigItem(int, CargoThreshold, ${MyShip.CargoCapacity})
}

/* ************************************************************************* */
objectdef obj_Configuration_Defense
{
	variable string SetName = "Defense"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Defense: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}


	Define_ConfigItem(bool, DetectLowStanding, TRUE)
	Define_ConfigItem(float, MinimumAllianceStanding, 0.0)
	Define_ConfigItem(float, MinimumCorpStanding, 0.0)
	Define_ConfigItem(float, MinimumPilotStanding, 0.0)
}

/* ************************************************************************* */
objectdef obj_Configuration_Combat
{
	variable string SetName = "Combat"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Combat: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(bool, RunOnLowAmmo, TRUE)
	Define_ConfigItem(bool, RunOnLowCap, FALSE)
	Define_ConfigItem(bool, RunOnLowTank, TRUE)
	Define_ConfigItem(bool, RunToStation, FALSE)
	Define_ConfigItem(bool, UseWhiteList, FALSE)
	Define_ConfigItem(bool, UseBlackList, TRUE)
	Define_ConfigItem(bool, ChainSpawns, TRUE)
	Define_ConfigItem(bool, ChainSolo, TRUE)
	Define_ConfigItem(bool, UseBeltBookmarks, FALSE)
	Define_ConfigItem(int, MinChainBounty, 1500000)
	Define_ConfigItem(int, MaxMissileRange, 10000)
	Define_ConfigItem(bool, LaunchCombatDrones, TRUE)
	Define_ConfigItem(int, MinimumDronesInSpace, 3)
	Define_ConfigItem(int, MinimumArmorPct, 35)
	Define_ConfigItem(int, MinimumShieldPct, 25)
	Define_ConfigItem(int, MinimumCapPct, 5)
	Define_ConfigItem(bool, AlwaysShieldBoost, FALSE)
	Define_ConfigItem(bool, RunIfTargetJammed, FALSE)
	Define_ConfigItem(bool, QuitIfWarpScrambled, TRUE)
	/* Todo: These need UI controls. */
	Define_ConfigItem(int, ArmorPctReady, 50)
	Define_ConfigItem(int, ShieldPctReady, 80)
	Define_ConfigItem(int, CapacitorPctReady, 80)
	Define_ConfigItem(int, ArmorPctEnable, 100)
	Define_ConfigItem(int, ArmorPctDisable, 98)
	Define_ConfigItem(int, ShieldPctEnable, 99)
	Define_ConfigItem(int, ShieldPctDisable, 95)
	Define_ConfigItem(int, CapacitorPctEnable, 20)
	Define_ConfigItem(int, CapacitorPctDisable, 80)
	Define_ConfigItem(bool, ConserveDrones, TRUE)
	Define_ConfigItem(int, MaxDroneRange, 15000)
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
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Hauler: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(string, HaulerMode, "Service Fleet Members")
	Define_ConfigItem(bool, MultiSystemSupport, FALSE)
	Define_ConfigItem(bool, PopJetCans, TRUE)
	Define_ConfigItem(string, DropOffBookmark, "")
	Define_ConfigItem(string, MiningSystemBookmark, "")
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
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Salvager: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
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
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Labels: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(string, SafeSpotPrefix, "Safe:")
	Define_ConfigItem(string, OreBeltPrefix, "Belt:")
	Define_ConfigItem(string, IceBeltPrefix, "Ice Belt: ")
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
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Freighter: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(string, FreighterMode, "Source and Destination")
	Define_ConfigItem(string, RegionName, "")
	Define_ConfigItem(string, Destination, "")
	Define_ConfigItem(string, SourceBookmarkPrefix, "")
}

/* ************************************************************************* */
objectdef obj_Config_FleetMembers
{
	variable string SetName = "FleetMembers"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Config_FleetMembers: Initialized", LOG_MINOR]
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.Ref:AddSetting["${Me.Name}", "${Me.Name}"]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
}

/* ************************************************************************* */
objectdef obj_Config_Whitelist
{
	variable string SetName = "Whitelist"

	method Initialize()
	{
		variable string OLD_DATA_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Whitelist.xml"

		; Check for old "Charname Blacklist.xml" file and import it, then remove it
		declare FP filepath ${BaseConfig.CONFIG_PATH}
		if ${FP.FileExists["${Me.Name} Whitelist.xml"]}
		{
			Logger:Log["obj_Config_Whitelist: Importing old config: ${OLD_DATA_FILE}"]
			This.Ref:Import[${OLD_DATA_FILE}]
			rm "${OLD_DATA_FILE}"
		}

		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Config_Whitelist: Initialized", LOG_MINOR]
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		if !${This.Ref.FindSet[Pilots](exists)}
		{
			This.Ref:AddSet[Pilots]
			This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
		}

		if !${This.Ref.FindSet[Corporations](exists)}
		{
			This.Ref:AddSet[Corporations]
			This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
		}

		if !${This.Ref.FindSet[Alliances](exists)}
		{
			This.Ref:AddSet[Alliances]
			This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
		}
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref PilotsRef()
	{
		return ${This.Ref.FindSet[Pilots]}
	}

	member:settingsetref CorporationsRef()
	{
		return ${This.Ref.FindSet[Corporations]}
	}

	member:settingsetref AlliancesRef()
	{
		return ${This.Ref.FindSet[Alliances]}
	}
}

/* ************************************************************************* */
objectdef obj_Config_Blacklist
{
	variable string SetName = "Blacklist"

	method Initialize()
	{
		variable string OLD_DATA_FILE = "${BaseConfig.CONFIG_PATH}/${Me.Name} Blacklist.xml"

		; Check for old "Charname Blacklist.xml" file and import it, then remove it
		declare FP filepath ${BaseConfig.CONFIG_PATH}
		if ${FP.FileExists["${Me.Name} Blacklist.xml"]}
		{
			Logger:Log["obj_Config_Blacklist: Importing old config: ${OLD_DATA_FILE}"]
			This.Ref:Import[${OLD_DATA_FILE}]
			rm "${OLD_DATA_FILE}"
		}

		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			Logger:Log["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		Logger:Log["obj_Config_Whitelist: Initialized", LOG_MINOR]
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		if !${This.Ref.FindSet[Pilots](exists)}
		{
			This.Ref:AddSet[Pilots]
			This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
		}

		if !${This.Ref.FindSet[Corporations](exists)}
		{
			This.Ref:AddSet[Corporations]
			This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
		}

		if !${This.Ref.FindSet[Alliances](exists)}
		{
			This.Ref:AddSet[Alliances]
			This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
		}
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref PilotsRef()
	{
		return ${This.Ref.FindSet[Pilots]}
	}

	member:settingsetref CorporationsRef()
	{
		return ${This.Ref.FindSet[Corporations]}
	}

	member:settingsetref AlliancesRef()
	{
		return ${This.Ref.FindSet[Alliances]}
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

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref AgentRef(string name)
	{
		return ${This.Ref.FindSet[${name}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.Ref:AddSet["Fykalia Adaferid"]
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
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
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
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
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
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
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
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
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
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		Logger:Log["obj_Configuration_Missioneer: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(bool, RunCourierMissions, TRUE)
	Define_ConfigItem(bool, RunTradeMissions, FALSE)
	Define_ConfigItem(bool, RunMiningMissions, FALSE)
	Define_ConfigItem(bool, RunKillMissions, FALSE)
	Define_ConfigItem(string, SmallHauler, "")
	Define_ConfigItem(string, LargeHauler, "")
	Define_ConfigItem(string, MiningShip, "")
	Define_ConfigItem(string, CombatShip, "")
	Define_ConfigItem(string, SalvageMode, None)
	Define_ConfigItem(string, SalvageShip, "")
	Define_ConfigItem(string, LargeHauler, "")
	Define_ConfigItem(bool, AvoidLowSec, TRUE)
	Define_ConfigItem(int, SmallHaulerLimit, 600)
}

