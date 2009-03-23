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

	variable bool Initialized = false
	variable float RunTime
	variable float NextPulse2Sec = 0
	variable float NextPulse1Sec = 0
	variable float NextPulseHalfSec = 0

	variable collection:string StaticList
	variable collection:string ObjectList
	variable collection:string FastObjectList
	variable collection:string OneSecondObjectList

	method Initialize()
	{
		if ${StaticList.FirstKey(exists)}
		{
			This:UpdateList[StaticList]
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
		; Changing the /1000 is not going to make your script faster or your dog smarter. it will just break things.
		This.RunTime:Set[${Math.Calc[${Script.RunningTime}/1000]}]

		/* Process FastObjectList every half second */
		if ${This.RunTime} > ${This.NextPulseHalfSec}
		{
			/*
			if ${EVEBot(exists)} && !${EVEBot.SessionValid}
			{
				;	EVEBot object isn't fully up before we call this the first time -- we'll just assume
				;	the user isn't going to be starting evebot while jumping or undocking.

				return
			}
			*/
			This:UpdateList[FastObjectList]
			This.NextPulseHalfSec:Set[${This.RunTime}]
    		This.NextPulseHalfSec:Inc[0.5]
		}

		/* Process ObjectList every 1 second */
		if ${This.RunTime} > ${This.NextPulse1Sec}
		{
			This:UpdateList[OneSecondObjectList]
			This.NextPulse1Sec:Set[${This.RunTime}]
    		This.NextPulse1Sec:Inc[2.0]
		}

		/* Process ObjectList every 2 seconds */
		if ${This.RunTime} > ${This.NextPulse2Sec}
		{
			This:UpdateList[ObjectList]
			This.NextPulse2Sec:Set[${This.RunTime}]
    		This.NextPulse2Sec:Inc[2.0]
		}
	}

	method UpdateList(string ListVar)
	{
		variable string temp

		if ${${ListVar}.FirstKey(exists)}
		{
			do
			{
				temp:Set[${${${ListVar}.CurrentValue}}]
				;redirect -append "crash.txt" echo "[${${ListVar}.CurrentKey}]: ${${ListVar}.CurrentValue} New: ${temp}"
				;echo "[${${ListVar}.CurrentKey}]: ${${ListVar}.CurrentValue} New: ${temp}"
				if ${temp.NotEqual["NULL"]}
				{
					${${ListVar}.CurrentKey}:Set[${temp}]
				}
			}
			while ${${ListVar}.NextKey(exists)}
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

	variable obj_Cache_Me_ToEntity ToEntity

	variable string Name
	variable int CharID
	variable int ShipID
	variable int StationID

	variable int MaxLockedTargets
	variable int MaxActiveDrones
	variable float64 DroneControlDistance
	variable int SolarSystemID
	variable int AllianceID
	variable int CorporationID
	variable string CorporationTicker

	method Initialize()
	{
		StaticList:Set["Name", "Me.Name"]
		StaticList:Set["CharID", "Me.CharID"]
			;TODO Yes, this causes a problem where if we join an alliance while evebot is running we dont notice. oh well.
		StaticList:Set["AllianceID", "Me.AllianceID"]
		StaticList:Set["CorporationID", "Me.CorporationID"]
		StaticList:Set["CorporationTicker", "Me.CorporationTicker"]

		ObjectList:Set["ShipID", "Me.ShipID"]
		ObjectList:Set["MaxLockedTargets", "Me.MaxLockedTargets"]
		ObjectList:Set["MaxActiveDrones", "Me.MaxActiveDrones"]
		ObjectList:Set["DroneControlDistance", "Me.DroneControlDistance"]
		ObjectList:Set["SolarSystemID", "Me.SolarSystemID"]

		;FastObjectList:Set["GetTargets", "Me.GetTargets"]

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

objectdef obj_Cache_MyShip inherits obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable float ArmorPct
	variable float StructurePct
	variable float ShieldPct
	variable float CapacitorPct
	variable float CargoCapacity
	variable int MaxLockedTargets
	variable float MaxTargetRange

	method Initialize()
	{
		FastObjectList:Set["ArmorPct", "MyShip.ArmorPct"]
		FastObjectList:Set["StructurePct", "MyShip.StructurePct"]
		FastObjectList:Set["ShieldPct", "MyShip.ShieldPct"]
		FastObjectList:Set["CapacitorPct", "MyShip.CapacitorPct"]

		ObjectList:Set["CargoCapacity", "MyShip.CargoCapacity"]
		ObjectList:Set["MaxLockedTargets", "MyShip.MaxLockedTargets"]
		ObjectList:Set["MaxTargetRange", "MyShip.MaxTargetRange"]

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
		OneSecondObjectList:Set["_Time", "EVETime.Time"]
		This[parent]:Initialize
	}

	method Shutdown()
	{
		This[parent]:Shutdown
	}

	member Time()
	{
		return ${This._Time}
	}
}