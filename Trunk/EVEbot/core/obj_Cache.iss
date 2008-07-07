/*
	Cache class

	Caches isxeve result data:
		StaticList: collection of var/member pairs which are initialized once.
		ObjectList: collection of var/member pairs which are retrieved once per second

*/

objectdef obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool PulsePerSecond = FALSE
	variable time NextPulse
	variable int PulseIntervalInSeconds = 1
	variable int FrameCount = 0
	variable int FrameInterval = 15

	variable collection:string StaticList
	variable collection:string ObjectList


	method Initialize()
	{
		UI:UpdateConsole["obj_Cache: Initialized", LOG_MINOR]
		if ${StaticList.FirstKey(exists)}
		{
			This:UpdateStaticList
		}

		if ${ObjectList.FirstKey(exists)}
		{
			This:Pulse
		}

		if ${This.PulsePerSecond}
		{
			Event[OnFrame]:AttachAtom[This:PulsePerSecond]
		}
		else
		{
			Event[OnFrame]:AttachAtom[This:Pulse]
		}
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
		Event[OnFrame]:DetachAtom[This:PulsePerSecond]
	}

	/* Runs every other frame, and updates one member per run */
	method Pulse()
	{
		FrameInterval:Set[${Math.Calc[${Display.FPS} / ${ObjectList.Used} + 1]}]

		if ${FrameCount} < ${FrameInterval}
		{
			FrameCount:Inc
			return
		}

		FrameCount:Set[0]
		if !${ObjectList.NextKey(exists)}
		{
			if !${ObjectList.FirstKey(exists)}
			{
				return
			}
		}
		;redirect -append "crash.txt" echo "[${ObjectList.CurrentKey}]: ${ObjectList.CurrentValue}"
		if ${${ObjectList.CurrentValue}(exists)}
		{
			${ObjectList.CurrentKey}:Set[${${ObjectList.CurrentValue}}]
		}

		;redirect -append "crash.txt" echo "${${ObjectList.CurrentKey}}  - Mem: ${System.MemoryUsage}"
	}

	/* This self-limits to once per second, and refreshes all data at that time */
	method PulsePerSecond()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${ObjectList.FirstKey(exists)}
			{
				do
				{
					;echo "[${ObjectList.CurrentKey}]: ${ObjectList.CurrentValue}"
					if ${${ObjectList.CurrentValue}(exists)}
					{
						${ObjectList.CurrentKey}:Set[${${ObjectList.CurrentValue}}]
					}
					;echo ${${ObjectList.CurrentKey}}
				}
				while ${ObjectList.NextKey(exists)}
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
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
		ObjectList:Set["InStation", "Me.InStation"]
		ObjectList:Set["GetTargets", "Me.GetTargets"]
		ObjectList:Set["GetTargeting", "Me.GetTargeting"]
		ObjectList:Set["GetTargetedBy", "Me.GetTargetedBy"]
		ObjectList:Set["MaxLockedTargets", "Me.MaxLockedTargets"]
		ObjectList:Set["MaxActiveDrones", "Me.MaxActiveDrones"]
		ObjectList:Set["DroneControlDistance", "Me.DroneControlDistance"]
		ObjectList:Set["SolarSystemID", "Me.SolarSystemID"]
		ObjectList:Set["AllianceID", "Me.AllianceID"]
		ObjectList:Set["CorporationID", "Me.CorporationID"]
		ObjectList:Set["CorporationTicker", "Me.CorporationTicker"]
		ObjectList:Set["AutoPilotOn", "Me.AutoPilotOn"]

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

		ObjectList:Set["IsCloaked", "Me.ToEntity.IsCloaked"]
		ObjectList:Set["IsWarpScrambled", "Me.ToEntity.IsWarpScrambled"]
		ObjectList:Set["Mode", "Me.ToEntity.Mode"]

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

		ObjectList:Set["ArmorPct", "Me.Ship.ArmorPct"]
		ObjectList:Set["StructurePct", "Me.Ship.StructurePct"]
		ObjectList:Set["ShieldPct", "Me.Ship.ShieldPct"]
		ObjectList:Set["CapacitorPct", "Me.Ship.CapacitorPct"]
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
		This.PulsePerSecond:Set[TRUE]
		This.PulseIntervalInSeconds:Set[1]
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