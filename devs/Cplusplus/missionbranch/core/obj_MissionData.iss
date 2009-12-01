objectdef obj_MissionCache
{
	variable string SVN_REVISION = "$Rev: 1348 $"
	variable int Version

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${_Me.Name} Mission Cache.xml"
	variable string SET_NAME = "Missions"

	variable index:entity entityIndex
	variable iterator     entityIterator

	method Initialize()
	{
		LavishSettings[MissionCache]:Remove
		LavishSettings:AddSet[MissionCache]
		LavishSettings[MissionCache]:AddSet[${This.SET_NAME}]
		LavishSettings[MissionCache]:Import[${This.CONFIG_FILE}]
		UI:UpdateConsole["obj_MissionCache: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[MissionCache]:Export[${This.CONFIG_FILE}]
		LavishSettings[MissionCache]:Remove
	}

	member:settingsetref MissionsRef()
	{
		return ${LavishSettings[MissionCache].FindSet[${This.SET_NAME}]}
	}

	member:settingsetref MissionRef(int agentID)
	{
		return ${This.MissionsRef.FindSet[${agentID}]}
	}

	method AddMission(int agentID, string name)
	{
		This.MissionsRef:AddSet[${agentID}]
		This.MissionRef[${agentID}]:AddSetting[Name,"${name}"]
	}
	member:string Name(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[Name,FALSE]}
	}

	member:int FactionID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[FactionID,0]}
	}

	method SetFactionID(int agentID, int factionID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[FactionID,${factionID}]
	}

	member:int TypeID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[TypeID,0]}
	}

	method SetTypeID(int agentID, int typeID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[TypeID,${typeID}]
	}

	member:float Volume(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[Volume,0]}
	}

	method SetVolume(int agentID, float volume)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[Volume,${volume}]
	}

	member:bool LowSec(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[LowSec,FALSE]}
	}

	method SetLowSec(int agentID, bool isLowSec)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[LowSec,${isLowSec}]
	}
}

objectdef obj_MissionDatabase
{
	variable string SVN_REVISION = "$Rev: 1348 $"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/Mission Database.xml"
	variable string SET_NAME = "Mission Database"

	method Initialize()
	{
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import[${CONFIG_FILE}]
		UI:UpdateConsole["obj_MissionDatabase: Initialized", LOG_MINOR]

		;UI:UpdateConsole["obj_MissionDatabase: Dumping database...",LOG_MINOR]
		;This:DumpSet[${LavishSettings[${This.SET_NAME}]},1]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
	}
	member:settingsetref MissionCommands(string missionName,int missionLevel)
	{
		return ${LavishSettings["${This.SET_NAME}"].FindSet["${missionName}"].FindSet["${missionLevel}"].FindSet["Commands"]}
	}
	method DumpSet(settingsetref Set, uint Indent=1)
	{
		UI:UpdateConsole["${Set.Name} - ${Set.GUID}",LOG_MINOR,Indent]

		variable iterator Iterator
		Set:GetSetIterator[Iterator]

		Indent:Inc
		if ${Iterator:First(exists)}
		{
			do
			{
				This:DumpSet[${Iterator.Value.GUID},${Indent}]
			}
			while ${Iterator:Next(exists)}
		}
		else
		{
			This:DumpSettings[${Set.GUID},${Indent}]
			return
		}
	}

	method DumpSettings(settingsetref Set, uint Indent=1)
	{
		variable iterator Iterator
		Set:GetSettingIterator[Iterator]

		if ${Iterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["${sIndent}${Iterator.Key} - ${Iterator.Value}",LOG_MINOR,Indent]
			}
			while ${Iterator:Next(exists)}
		}
	}
}