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

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
	variable filepath DATA_PATH = "${Script.CurrentDirectory}/Data"

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${Me.Name}.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[EVEBotSettings]:Remove
		LavishSettings:AddSet[EVEBotSettings]

		; Check new config file first, then fallball to original name for import

		UI:UpdateConsole["Configuration file is ${CONFIG_FILE}"]
		LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]

		BaseRef:Set[${LavishSettings[EVEBotSettings]}]
		UI:UpdateConsole["obj_Configuration_BaseConfig: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Common: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(string, BotMode, MINER)
	Define_ConfigItem(bool, Callback, FALSE)
	Define_ConfigItem(int, MinimumDronesInBay, 0)
	Define_ConfigItem(string, HomeStation, NOTSET)
	Define_ConfigItem(string, LoginName, NOTSET)
	Define_ConfigItem(string, LoginPassword, NOTSET)
	Define_ConfigItem(bool, AutoLogin, FALSE)
	Define_ConfigItem(int64, AutoLoginCharID, 0)
	Define_ConfigItem(int, MaxRuntime, 0)
	Define_ConfigItem(string, IRCServer, "irc.lavishsoft.com")
	Define_ConfigItem(string, IRCChannel, "#EVEBot_${Math.Rand[999999]}")
	Define_ConfigItem(string, IRCUser, "Test${Math.Rand[5000]:Inc[1000]}")
	Define_ConfigItem(string, IRCPassword, "evebot")
	Define_ConfigItem(bool, UseSound, FALSE)
	Define_ConfigItem(bool, Disable3D, FALSE)
	Define_ConfigItem(bool, DisableUI, FALSE)
	Define_ConfigItem(bool, DisableScreenWhenBackgrounded, FALSE)
	Define_ConfigItem(bool, TrainSkills, TRUE)
}

/* ************************************************************************* */
objectdef obj_Configuration_Miner
{
	variable string SetName = "Miner"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Mercoxit_Types](exists)}
		{
			UI:UpdateConsole["obj_Configuration_Miner: Re-Initializing Asteroid Types"]
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

	member:settingsetref OreVolumesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Volumes]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This:Set_Default_Values_Ore[]
		This:Set_Default_Values_Mercoxit[]
		This:Set_Default_Values_Ice[]
	}

	method Set_Default_Values_Ore()
	{
		This.Ref:AddSet[ORE_Types]

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

		This.Ref:AddSet[ORE_Volumes]

		This.OreVolumesRef:AddSetting[Mercoxit,40]
		This.OreVolumesRef:AddSetting[Arkonor,16]
		This.OreVolumesRef:AddSetting[Bistot,16]
		This.OreVolumesRef:AddSetting[Crokite,16]
		This.OreVolumesRef:AddSetting[Spodumain,16]
		This.OreVolumesRef:AddSetting[Dark Ochre,8]
		This.OreVolumesRef:AddSetting[Gneiss,5]
		This.OreVolumesRef:AddSetting[Hedbergite,3]
		This.OreVolumesRef:AddSetting[Hemorphite,3]
		This.OreVolumesRef:AddSetting[Jaspet,2]
		This.OreVolumesRef:AddSetting[Kernite,1.2]
		This.OreVolumesRef:AddSetting[Omber,0.6]
		This.OreVolumesRef:AddSetting[Plagioclase,0.35]
		This.OreVolumesRef:AddSetting[Pyroxeres,0.3]
		This.OreVolumesRef:AddSetting[Scordite,0.15]
		This.OreVolumesRef:AddSetting[Veldspar,0.1]
	}

	method Set_Default_Values_Mercoxit()
	{
		This.Ref:AddSet[Mercoxit_Types]

		This.MercoxitTypesRef:AddSetting[Vitreous Mercoxit, 1]
		This.MercoxitTypesRef:AddSetting[Magma Mercoxit, 1]
		This.MercoxitTypesRef:AddSetting[Mercoxit, 1]
	}

	method Set_Default_Values_Ice()
	{
		This.Ref:AddSet[ICE_Types]

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
	Define_ConfigItem(int, CargoThreshold, ${_MyShip.CargoCapacity})
}

/* ************************************************************************* */
objectdef obj_Configuration_Defense
{
	variable string SetName = "Defense"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Defense: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Combat: Initialized", LOG_MINOR]
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
	Define_ConfigItem(bool, ShouldUseMissiles, FALSE)
	Define_ConfigItem(int, ArmorPctReady, 50)
	Define_ConfigItem(int, ShieldPctReady, 80)
	Define_ConfigItem(int, CapacitorPctReady, 80)
	Define_ConfigItem(int, ArmorPctEnable, 100)
	Define_ConfigItem(int, ArmorPctDisable, 98)
	Define_ConfigItem(int, ShieldPctEnable, 99)
	Define_ConfigItem(int, ShieldPctDisable, 95)
	Define_ConfigItem(int, CapacitorPctEnable, 20)
	Define_ConfigItem(int, CapacitorPctDisable, 80)
	Define_ConfigItem(int, MaximumDroneRange, 45000)
}

/* ************************************************************************* */
objectdef obj_Configuration_Hauler
{
	variable string SetName = "Hauler"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Hauler: Initialized", LOG_MINOR]
	}

	member:settingsetref Ref()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	Define_ConfigItem(string, HaulerMode, "Service Fleet Members")
	Define_ConfigItem(bool, MultiSystemSupport, FALSE)
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Salvager: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Labels: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Freighter: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Config_FleetMembers: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["obj_Config_Whitelist: Importing old config: ${OLD_DATA_FILE}"]
			This.Ref:Import[${OLD_DATA_FILE}]
			rm "${OLD_DATA_FILE}"
		}

		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Config_Whitelist: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["obj_Config_Blacklist: Importing old config: ${OLD_DATA_FILE}"]
			This.Ref:Import[${OLD_DATA_FILE}]
			rm "${OLD_DATA_FILE}"
		}

		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Config_Whitelist: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Agents: Initialized", LOG_MINOR]
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
		;UI:UpdateConsole["obj_Configuration_Agents: AgentIndex ${name}"]
		return ${This.AgentRef[${name}].FindSetting[AgentIndex,9591]}
	}

	method SetAgentIndex(string name, int value)
	{
		;UI:UpdateConsole["obj_Configuration_Agents: SetAgentIndex ${name} ${value}"]
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[AgentIndex,${value}]
	}

	member:int AgentID(string name)
	{
		;UI:UpdateConsole["obj_Configuration_Agents: AgentID ${name}"]
		return ${This.AgentRef[${name}].FindSetting[AgentID,3018920]}
	}

	method SetAgentID(string name, int value)
	{
		;UI:UpdateConsole["obj_Configuration_Agents: SetAgentID ${name} ${value}"]
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[AgentID,${value}]
	}

	member:int LastDecline(string name)
	{
		;UI:UpdateConsole["obj_Configuration_Agents: LastDecline ${name}"]
		return ${This.AgentRef[${name}].FindSetting[LastDecline,${Time.Timestamp}]}
	}

	method SetLastDecline(string name, int value)
	{
		;UI:UpdateConsole["obj_Configuration_Agents: SetLastDecline ${name} ${value}"]
		if !${This.Ref.FindSet[${name}](exists)}
		{
			This.Ref:AddSet[${name}]
		}

		This.AgentRef[${name}]:AddSetting[LastDecline,${value}]
	}

	member:int LastCompletionTime(string name)
	{
		;;;UI:UpdateConsole["obj_Configuration_Agents: LastCompletionTime ${name}"]
		return ${This.AgentRef[${name}].FindSetting[LastCompletionTime,0]}
	}

	method SetLastCompletionTime(string name, int value)
	{
		;;;UI:UpdateConsole["obj_Configuration_Agents: SetLastCompletionTime ${name} ${value}"]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
		}
		UI:UpdateConsole["obj_Configuration_Missioneer: Initialized", LOG_MINOR]
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

