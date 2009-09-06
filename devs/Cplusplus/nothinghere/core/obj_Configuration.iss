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

/* ************************************************************************* */
objectdef obj_Configuration_BaseConfig
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
	variable string ORG_CONFIG_FILE = "evebot.xml"
	variable string NEW_CONFIG_FILE = "${_Me.Name} Config.xml"
	variable string CONFIG_FILE = "${_Me.Name} Config.xml"
	variable settingsetref BaseRef
	
	method Initialize()
	{	
		LavishSettings[EVEBotSettings]:Clear
		LavishSettings:AddSet[EVEBotSettings]
		LavishSettings[EVEBotSettings]:AddSet[${_Me.Name}]

		; Check new config file first, then fallball to original name for import

		CONFIG_FILE:Set["${CONFIG_PATH}/${NEW_CONFIG_FILE}"]

		if !${CONFIG_PATH.FileExists[${NEW_CONFIG_FILE}]}
		{
			UI:UpdateConsole["${CONFIG_FILE} not found - looking for ${ORG_CONFIG_FILE}"]
			UI:UpdateConsole["Configuration will be copied from ${ORG_CONFIG_FILE} to ${NEW_CONFIG_FILE}"]
			
			LavishSettings[EVEBotSettings]:Import[${CONFIG_PATH}/${ORG_CONFIG_FILE}]
		}
		else
		{
			UI:UpdateConsole["Configuration file is ${CONFIG_FILE}"]
			LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]
		}		

		BaseRef:Set[${LavishSettings[EVEBotSettings].FindSet[${_Me.Name}]}]
		UI:UpdateConsole["obj_Configuration_BaseConfig: Initialized", LOG_MINOR]
	}
	
	method Shutdown()
	{
		This:Save[]
		LavishSettings[EVEBotSettings]:Clear
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
	variable obj_Configuration_Miner Miner
	variable obj_Configuration_Hauler Hauler
	variable obj_Configuration_Salvager Salvager
	variable obj_Configuration_Labels Labels
	variable obj_Configuration_Freighter Freighter
	variable obj_Configuration_Agents Agents
	variable obj_Configuration_Missioneer Missioneer
	
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
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Common: Initialized", LOG_MINOR]
	}
	
	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		
		; We use both so we have an ID to use to set the default selection in the UI.
		This.CommonRef:AddSetting[Bot Mode,1]
		This.CommonRef:AddSetting[Bot Mode Name,MINER]
		This.CommonRef:AddSetting[Home Station,1]
		This.CommonRef:AddSetting[Use Development Build,FALSE]
		This.CommonRef:AddSetting[Drones In Bay,0]
		This.CommonRef:AddSetting[Login Name, ""]
		This.CommonRef:AddSetting[Login Password, ""]
		This.CommonRef:AddSetting[AutoLogin, TRUE]
		This.CommonRef:AddSetting[AutoLoginCharID, 0]
		This.CommonRef:AddSetting[Maximum Runtime, 0]
		This.CommonRef:AddSetting[Use Sound, FALSE]
		This.CommonRef:AddSetting[Disable 3D, FALSE]
		This.CommonRef:AddSetting[TrainFastest, TRUE]
	}

	member:int BotMode()
	{
		return ${This.CommonRef.FindSetting[Bot Mode, 1]}
	}

	method SetBotMode(int value)
	{
		This.CommonRef:AddSetting[Bot Mode, ${value}]
	}

	member:string BotModeName()
	{
		return ${This.CommonRef.FindSetting[Bot Mode Name, MINER]}
	}
	
	method SetBotModeName(string value)
	{
		This.CommonRef:AddSetting[Bot Mode Name,${value}]
	}

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
		return ${This.CommonRef.FindSetting[TrainFastest, TRUE]}
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ice_Types](exists)}
		{
			UI:UpdateConsole["obj_Configuration_Miner: Initialized ICE Types"]
			This:Set_Default_Values_Ice[]
		}
	}

	member:settingsetref MinerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	member:settingsetref LocationsRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Locations]}
	}
	member:settingsetref OreTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Types]}
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

		This.MinerRef:AddSet[ORE_Types]
		This.MinerRef:AddSet[ORE_Volumes]
		;create the set to contain the list of systems, we do not populate it as having default systems for evebot to mine it would be dumb
		UI:UpdateConsole["obj_Miner: Adding location set", LOG_MINOR]
		This.MinerRef:AddSet[Locations]
		UI:UpdateConsole["obj_Miner: ${This.LocationsRef.Name}", LOG_MINOR]
		UI:UpdateConsole["obj_Miner: ${This.MinerRef.Name}", LOG_MINOR]
		This.LocationsRef:AddSetting[Jita,1]
		
		This.MinerRef:AddSetting[Restrict To Belt, NO]
		This.MinerRef:AddSetting[Restrict To Ore Type, NONE]
		This.MinerRef:AddSetting[JetCan Naming, 1]
		This.MinerRef:AddSetting[Bookmark Last Position, TRUE]
		This.MinerRef:AddSetting[Distribute Lasers, TRUE]
		This.MinerRef:AddSetting[Use Mining Drones, FALSE]
		This.MinerRef:AddSetting[Avoid Player Range, 10000]
		This.MinerRef:AddSetting[Standing Detection, FALSE]
		This.MinerRef:AddSetting[Lowest Standing, 0]
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

		This:Set_Default_Values_Ice[]
		
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
		if !${_Me.InStation}
		{
			if (${threshold} == 0) || \
				(${threshold} > ${_Me.Ship.CargoCapacity})
			{
				if ${Ship.MiningAmountPerLaser} > 0
				{
					threshold:Set[${Math.Calc[${_Me.Ship.CargoCapacity} / ${Ship.MiningAmountPerLaser}].Int}]
					threshold:Set[${Math.Calc[(${threshold} * ${Ship.MiningAmountPerLaser}) * 0.99]}]
					if ${This.MinerRef.FindSetting[Cargo Threshold, 0]} > ${_Me.Ship.CargoCapacity}
					{
						;UI:UpdateConsole["ERROR: Mining Cargo Threshold is set higher than ship capacity: Using dynamic value of ${threshold}"]
					}
				}
				else
				{
					;UI:UpdateConsole["ERROR: Unable to retrieve Ship.MiningAmountPerLaser"]
					;UI:UpdateConsole["ERROR: Mining Cargo Threshold is set higher than ship capacity: Using cargo capacity"]
					threshold:Set[${_Me.Ship.CargoCapacity}]
				}
			}
		}
		return ${threshold}
	}

	method SetCargoThreshold(int value)
	{	
		This.MinerRef:AddSetting[Cargo Threshold, ${value}]
	}
	;New settings for location cycling
	member:int LocationTime(string SystemName)
	{
		return ${This.LocationsRef.FindSetting[${SystemName},0]}
	}
	method SetLocationTime(string SystemName , int value)
	{
		This.LocationsRef:AddSetting[${SystemName} , ${value}]
	}
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
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Combat: Initialized", LOG_MINOR]
	}

	member:settingsetref CombatRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

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
		This.CombatRef:AddSetting[Use Whitelist, FALSE]
		This.CombatRef:AddSetting[Use Blacklist, FALSE]
		This.CombatRef:AddSetting[Chain Spawns, TRUE]
		This.CombatRef:AddSetting[Chain Solo, TRUE]
		This.CombatRef:AddSetting[Use Belt Bookmarks, FALSE]
		This.CombatRef:AddSetting[Min Chain Bounty, 1500000]
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
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Hauler: Initialized", LOG_MINOR]
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

	member:string DropOffBookmark()
	{
		return ${This.HaulerRef.FindSetting[Drop Off Bookmark, ""]}
	}
	
	method SetDropOffBookmark(string Bookmark)
	{
		This.HaulerRef:AddSetting[Drop Off Bookmark,${Bookmark}]
	}

	member:string MiningSystemBookmark()
	{
		return ${This.HaulerRef.FindSetting[Mining System Bookmark, ""]}
	}
	
	method SetMiningSystemBookmark(string Bookmark)
	{
		This.HaulerRef:AddSetting[Mining System Bookmark,${Bookmark}]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Salvager: Initialized", LOG_MINOR]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Labels: Initialized", LOG_MINOR]
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
	}
	
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
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Freighter: Initialized", LOG_MINOR]
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
	variable string DATA_FILE = "${BaseConfig.CONFIG_PATH}/${_Me.Name} Whitelist.xml"
	variable settingsetref BaseRef

	method Initialize()
	{	
		LavishSettings[EVEBotWhitelist]:Clear
		LavishSettings:AddSet[EVEBotWhitelist]
		This.BaseRef:Set[${LavishSettings[EVEBotWhitelist]}]
		UI:UpdateConsole["obj_Config_Whitelist: Loading ${DATA_FILE}"]
		This.BaseRef:Import[${This.DATA_FILE}]
		
		if !${This.BaseRef.FindSet[Pilots](exists)}
		{
			This.BaseRef:AddSet[Pilots]
			This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
		}

		if !${This.BaseRef.FindSet[Corporations](exists)}
		{
			This.BaseRef:AddSet[Corporations]
			This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
		}

		if !${This.BaseRef.FindSet[Alliances](exists)}
		{
			This.BaseRef:AddSet[Alliances]
			This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
		}

		UI:UpdateConsole["obj_Config_Whitelist: Initialized", LOG_MINOR]
	}
	
	method Shutdown()
	{
		This:Save[]
		LavishSettings[EVEBotWhitelist]:Clear
	}

	method Save()
	{
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
	variable string DATA_FILE = "${BaseConfig.CONFIG_PATH}/${_Me.Name} Blacklist.xml"
	variable settingsetref BaseRef

	method Initialize()
	{	
		LavishSettings[EVEBotBlacklist]:Clear
		LavishSettings:AddSet[EVEBotBlacklist]
		This.BaseRef:Set[${LavishSettings[EVEBotBlacklist]}]
		UI:UpdateConsole["obj_Config_Blacklist: Loading ${DATA_FILE}"]
		This.BaseRef:Import[${This.DATA_FILE}]
		
		if !${This.BaseRef.FindSet[Pilots](exists)}
		{
			This.BaseRef:AddSet[Pilots]
			This.PilotsRef:AddSetting[Sample_Pilot_Comment, 0]
		}

		if !${This.BaseRef.FindSet[Corporations](exists)}
		{
			This.BaseRef:AddSet[Corporations]
			This.CorporationsRef:AddSetting[Sample_Corporation_Comment, 0]
		}

		if !${This.BaseRef.FindSet[Alliances](exists)}
		{
			This.BaseRef:AddSet[Alliances]
			This.AlliancesRef:AddSetting[Sample_Alliance_Comment, 0]
		}

		UI:UpdateConsole["obj_Config_Blacklist: Initialized", LOG_MINOR]
	}
	
	method Shutdown()
	{
		This:Save[]
		LavishSettings[EVEBotBlacklist]:Clear
	}

	method Save()
	{
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Agents: Initialized", LOG_MINOR]
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
		;UI:UpdateConsole["obj_Configuration_Agents: AgentIndex ${name}"]
		return ${This.AgentRef[${name}].FindSetting[AgentIndex,9591]}
	}
	
	method SetAgentIndex(string name, int value)
	{
		;UI:UpdateConsole["obj_Configuration_Agents: SetAgentIndex ${name} ${value}"]
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
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
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
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
		if !${This.AgentsRef.FindSet[${name}](exists)}
		{
			This.AgentsRef:AddSet[${name}]
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
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Missioneer: Initialized", LOG_MINOR]
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

