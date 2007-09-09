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

objectdef obj_Configuration_BaseConfig
{
	variable string CONFIG_FILE = "${Script.CurrentDirectory}/config/evebot.xml"
	variable settingsetref BaseRef
	
	method Initialize()
	{	
		LavishSettings[EVEBotSettings]:Clear
		LavishSettings:AddSet[EVEBotSettings]
		LavishSettings[EVEBotSettings]:AddSet[${Me.Name}]
		LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]
	
		BaseRef:Set[${LavishSettings[EVEBotSettings].FindSet[${Me.Name}]}]
		UI:UpdateConsole["obj_Configuration_BaseConfig: Initialized"]
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

objectdef obj_Configuration
{
	variable obj_Configuration_Common Common
	variable obj_Configuration_Combat Combat
	variable obj_Configuration_Miner Miner
	variable obj_Configuration_Hauler Hauler
	variable obj_Configuration_Salvager Salvager
	
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
		UI:UpdateConsole["obj_Configuration_Common: Initialized"]
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
	}

	member:int BotMode()
	{
		return ${This.CommonRef.FindSetting[Bot Mode, MINER]}
	}

	method SetBotMode(int value)
	{
		This.CommonRef:AddSetting[Bot Mode, ${value}]
	}

	member:string BotModeName()
	{
		return ${This.CommonRef.FindSetting[Bot Mode Name, MINER]}
	}
	
	method SetDronesInBay(int value)
	{
		This.CommonRef:AddSetting[Drones In Bay,${value}]
	}

	member:int DronesInBay()
	{
		return ${This.CommonRef.FindSetting[Drones In Bay, NOTSET]}
	}

	method SetBotModeName(string value)
	{
		This.CommonRef:AddSetting[Bot Mode Name,${value}]
	}

	member:string HomeStation()
	{
		return ${This.CommonRef.FindSetting[Home Station, NOTSET]}
	}

	method SetHomeStation(string StationName)
	{
		This.CommonRef:AddSetting[Home Station,${StationName}]
	}

	member:bool UseDevelopmentBuild()
	{
		return ${This.CommonRef.FindSetting[Use Development Build, FALSE]}
	}

	method SetUseDevelopmentBuild(bool setting)
	{
		This.CommonRef:AddSetting[Home Station,${setting}]
	}
	
	member:int OurAbortCount()
	{
		return ${AbortCount}
	}
	
	function IncAbortCount()
	{
		This.AbortCount:Inc
	}

}

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
		UI:UpdateConsole["obj_Configuration_Miner: Initialized"]
	}

	member:settingsetref MinerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref OreTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Types]}
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
		This.MinerRef:AddSetting[Restrict To Belt, NO]
		This.MinerRef:AddSetting[Restrict To Ore Type, NONE]
		This.MinerRef:AddSetting[Include Veldspar, TRUE]
		This.MinerRef:AddSetting[Stick To Spot, FALSE]
		This.MinerRef:AddSetting[Bookmark Last Position, FALSE]
		This.MinerRef:AddSetting[Use JetCan, FALSE]
		This.MinerRef:AddSetting[Distribute Lasers, TRUE]
		This.MinerRef:AddSetting[Use Mining Drones, FALSE]
		This.MinerRef:AddSetting[Avoid Player Range, 10000]
		This.MinerRef:AddSetting[Standing Detection, FALSE]
		This.MinerRef:AddSetting[Lowest Standing, 0]

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

	; TODO - members/methods for these - CyberTech
	
	;		This.MinerRef:AddSetting[Restrict To Belt, NO]
	;		This.MinerRef:AddSetting[Restrict To Ore Type, NONE]
	;		This.MinerRef:AddSetting[Avoid Players Distance, 10000]

	member:bool IncludeVeldspar()
	{
		return ${This.MinerRef.FindSetting[Include Veldspar, TRUE]}
	}

	method SetIncludeVeldspar(bool value)
	{	
		This.MinerRef:AddSetting[Include Veldspar, ${value}]
	}

	member:bool StickToSpot()
	{
		return ${This.MinerRef.FindSetting[Stick To Spot, FALSE]}
	}

	method SetStickToSpot(bool value)
	{	
		This.MinerRef:AddSetting[Stick To Spot, ${value}]
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

	member:bool UseJetCan()
	{
		return ${This.MinerRef.FindSetting[Use JetCan, FALSE]}
	}

	method SetUseJetCan(bool value)
	{	
		This.MinerRef:AddSetting[Use JetCan, ${value}]
	}
	
	member:bool UseMiningDrones()
	{
		return ${This.MinerRef.FindSetting[Mining Drones, FALSE]}
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
	
	method SetStandingDetection(int value)
	{
		This.MinerRef:AddSetting[Lowest Standing, ${value}]
	}
	
	
}

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
		UI:UpdateConsole["obj_Configuration_Combat: Initialized"]
	}

	member:settingsetref CombatRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CombatRef:AddSetting[UseCombatDrones,FALSE]
		This.CombatRef:AddSetting[MinimumDronesInSpace,3]
		This.CombatRef:AddSetting[MinimumArmorPct, 35]
		This.CombatRef:AddSetting[MinimumShieldPct, 25]
		This.CombatRef:AddSetting[AlwaysShieldBoost, FALSE]
	}
	
	member:bool UseCombatDrones()
	{
		return ${This.CombatRef.FindSetting[UseCombatDrones, FALSE]}
	}
	
	method SetUseCombatDrones(bool value)
	{
		This.CombatRef:AddSetting[UseCombatDrones,${value}]
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

	member:bool AlwaysShieldBoost()
	{
		return ${This.CombatRef.FindSetting[AlwaysShieldBoost, FALSE]}
	}
	
	method SetAlwaysShieldBoost(bool value)
	{
		This.CombatRef:AddSetting[AlwaysShieldBoost, ${value}]
	}
}

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
		UI:UpdateConsole["obj_Configuration_Hauler: Initialized"]
	}

	member:settingsetref HaulerRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

	}

}

objectdef obj_Configuration_Salvager
{
	variable string SetName = "Salvager"

	method Initialize()
	{	
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:UpdateConsole["Warning: ${This.SetName} settings missing - initializing"]
			This:Set_Default_Values[]
		}
		UI:UpdateConsole["obj_Configuration_Salvager: Initialized"]
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
