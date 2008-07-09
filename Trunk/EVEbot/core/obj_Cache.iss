/*
	Cache class

	Caches isxeve result data:
		StaticList: collection of var/member pairs which are initialized once.
		ObjectList: collection of var/member pairs which are retrieved every 2 seconds
		FastObjectList: collection of var/member pairs which are retrieved every 1/2 second

*/

objectdef obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable int FrameCount = 0
	variable float FrameInterval = 0
	variable int FrameCountHalfSec = 0
	variable float FrameIntervalHalfSec = 0
	
	variable collection:string StaticList
	variable collection:string ObjectList
	variable collection:string FastObjectList


	method Initialize()
	{
		UI:UpdateConsole["obj_Cache: Initialized", LOG_MINOR]
		if ${StaticList.FirstKey(exists)}
		{
			This:UpdateStaticList
		}

		This:Pulse
		Event[OnFrame]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	/* Runs every other frame, and updates one member per run */
	method Pulse()
	{
		variable string temp
		
		/* Process FastObjectList every half second */
		if ${FrameCountHalfSec} < ${FrameIntervalHalfSec}
		{
			FrameCountHalfSec:Inc
		}
		else
		{
			FrameCountHalfSec:Set[0]
			FrameIntervalHalfSec:Set[${Math.Calc[${Display.FPS} * 0.5]}]
		
			if ${FastObjectList.FirstKey(exists)}
			{
				do
				{
					;redirect -append "crash.txt" echo "[${FastObjectList.CurrentKey}]: ${FastObjectList.CurrentValue}"
					temp:Set[${${FastObjectList.CurrentValue}}]
					if ${temp.NotEqual["NULL"]}
					{
						${FastObjectList.CurrentKey}:Set[${temp}]
					}
					;redirect -append "crash.txt" echo "    ${${FastObjectList.CurrentKey}}"
				}
				while ${FastObjectList.NextKey(exists)}
			}
		}

		/* Process ObjectList every 2 seconds */
		if ${FrameCount} < ${FrameInterval}
		{
			FrameCount:Inc
		}
		else
		{
			FrameCount:Set[0]
			FrameInterval:Set[${Math.Calc[${Display.FPS} * 2.5]}]
		
			if ${ObjectList.FirstKey(exists)}
			{
				do
				{
					;redirect -append "crash.txt" echo "[${ObjectList.CurrentKey}]: ${ObjectList.CurrentValue}"
					temp:Set[${${ObjectList.CurrentValue}}]
					if ${temp.NotEqual["NULL"]}
					{
						${ObjectList.CurrentKey}:Set[${temp}]
					}
					;redirect -append "crash.txt" echo "${${ObjectList.CurrentKey}}"
				}
				while ${ObjectList.NextKey(exists)}
			}
		}
	}

	method UpdateStaticList()
	{
		if ${StaticList.FirstKey(exists)}
		{
			do
			{
				;echo "[${StaticList.CurrentKey}]: ${StaticList.CurrentValue}"
				if ${${StaticList.CurrentValue}(exists)}
				{
					${StaticList.CurrentKey}:Set[${${StaticList.CurrentValue}}]
				}
				;echo ${${StaticList.CurrentKey}}
			}
			while ${StaticList.NextKey(exists)}
		}
	}
}

objectdef obj_Cache_Me inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable obj_Cache_Me_Ship Ship
	variable obj_Cache_Me_ToEntity ToEntity
	
	variable string Name
	variable int CharID
	variable int ShipID
	variable int StationID
	
	variable bool InStation = FALSE
	variable int GetTargets
	variable int GetTargeting
	variable int GetTargetedBy
	variable int MaxLockedTargets
	variable int MaxActiveDrones
	variable float64 DroneControlDistance
	variable int SolarSystemID
	variable int AllianceID
	variable int CorporationID
	variable string CorporationTicker
	variable bool AutoPilotOn = FALSE

	method Initialize()
	{
		UI:UpdateConsole["obj_Cache_Me: Initialized", LOG_MINOR]

		StaticList:Set["Name", "Me.Name"]
		StaticList:Set["CharID", "Me.CharID"]

		ObjectList:Set["ShipID", "Me.ShipID"]
		
		ObjectList:Set["MaxLockedTargets", "Me.MaxLockedTargets"]
		ObjectList:Set["MaxActiveDrones", "Me.MaxActiveDrones"]
		ObjectList:Set["DroneControlDistance", "Me.DroneControlDistance"]
		ObjectList:Set["SolarSystemID", "Me.SolarSystemID"]
		ObjectList:Set["AllianceID", "Me.AllianceID"]
		ObjectList:Set["CorporationID", "Me.CorporationID"]
		ObjectList:Set["CorporationTicker", "Me.CorporationTicker"]

		FastObjectList:Set["StationID", "Me.StationID"]
		FastObjectList:Set["InStation", "Me.InStation"]
		FastObjectList:Set["AutoPilotOn", "Me.AutoPilotOn"]
		FastObjectList:Set["GetTargets", "Me.GetTargets"]
		FastObjectList:Set["GetTargeting", "Me.GetTargeting"]
		FastObjectList:Set["GetTargetedBy", "Me.GetTargetedBy"]

		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}
}

objectdef obj_Cache_Me_ToEntity inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool IsCloaked
	variable bool IsWarpScrambled
	variable int Mode

	method Initialize()
	{
		UI:UpdateConsole["obj_Cache_Me_ToEntity: Initialized", LOG_MINOR]

		FastObjectList:Set["IsCloaked", "Me.ToEntity.IsCloaked"]
		FastObjectList:Set["IsWarpScrambled", "Me.ToEntity.IsWarpScrambled"]
		FastObjectList:Set["Mode", "Me.ToEntity.Mode"]

		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}
}

objectdef obj_Cache_Me_Ship inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable float ArmorPct
	variable float StructurePct
	variable float ShieldPct
	variable float CapacitorPct
	variable float UsedCargoCapacity
	variable float CargoCapacity
	variable int MaxLockedTargets
	variable float MaxTargetRange
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Cache_Me_Ship: Initialized", LOG_MINOR]

		FastObjectList:Set["ArmorPct", "Me.Ship.ArmorPct"]
		FastObjectList:Set["StructurePct", "Me.Ship.StructurePct"]
		FastObjectList:Set["ShieldPct", "Me.Ship.ShieldPct"]
		FastObjectList:Set["CapacitorPct", "Me.Ship.CapacitorPct"]
		ObjectList:Set["UsedCargoCapacity", "Me.Ship.UsedCargoCapacity"]
		ObjectList:Set["CargoCapacity", "Me.Ship.CargoCapacity"]
		ObjectList:Set["MaxLockedTargets", "Me.Ship.MaxLockedTargets"]
		ObjectList:Set["MaxTargetRange", "Me.Ship.MaxTargetRange"]

		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}
}

objectdef obj_Cache_EVETime inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string _Time

	method Initialize()
	{
		UI:UpdateConsole["obj_Cache_EVETime: Initialized", LOG_MINOR]

		ObjectList:Set["Time", "EVETime.Time"]
		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}

	member Time()
	{
		return This._Time
	}
}