objectdef obj_Belts inherits obj_BaseClass
{
	variable index:entity beltIndex
	variable iterator beltIterator
	variable set EmptyBelts
	variable collection:time UnsafeBelts

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This[parent]:Initialize
		;PulseTimer:SetIntervals[0.5,1.0]
		;Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	member:bool Valid()
	{
		if ${beltIterator.IsValid} && ${beltIterator.Value(exists)}
		{
			return TRUE
		}
		return FALSE
	}

	method ResetBeltList()
	{
		/* TODO
				beltsubstring:Set["ASTEROID BELT"]
		if ${Config.Miner.IceMining}
		{
			beltsubstring:Set["ICE FIELD"]
		}

		EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT && Name =- \"${beltsubstring}\""]
		*/
		EVE:QueryEntities[beltIndex, "GroupID = GROUP_ASTEROIDBELT"]
		if ${Config.Common.SortBeltsRandom}
		{
			This:Randomize[beltIndex]
		}
		else
		{
			This:Sort[beltIndex, Name]
		}

		beltIndex:GetIterator[beltIterator]
		beltIterator:First
		Logger:Log["obj_Belts: ResetBeltList found ${beltIndex.Used} belts in this system.", LOG_DEBUG]
	}

	member:int EmptyBeltCount()
	{
		return ${This.EmptyBelts.Used}
	}

	; Checks the belt name against the empty belt list.
	member:bool IsMarkedEmpty(string BeltName)
	{
		if !${This.Valid}
		{
			return FALSE
		}

		if ${This.EmptyBeltCount} == 0
		{
			return FALSE
		}

		if ${This.EmptyBelts.Contains[${BeltName}]}
		{
			Logger:Log["${LogPrefix}:IsMarkedEmpty: ${BeltName} - TRUE", LOG_DEBUG]
			return TRUE
		}
		return FALSE
	}

	; Adds the current belt iteratorto the empty belt list
	method MarkEmpty()
	{
		if !${This.Valid}
		{
			return
		}

		EmptyBelts:Add["${beltIterator.Value.Name}"]
		Logger:Log["${LogPrefix}: Excluding empty belt ${beltIterator.Value.Name}"]
	}

	member:int UnsafeBeltCount()
	{
		return ${This.UnsafeBelts.Used}
	}

	; Checks the belt name against the empty belt list.
	member:bool IsMarkedUnsafe(string BeltName)
	{
		if !${This.Valid}
		{
			return FALSE
		}

		if ${This.UnsafeBeltCount} == 0
		{
			return FALSE
		}

		variable uint qid
		; 30 minutes
		variable time oldestlegal = ${Math.Calc[${Time.Timestamp} - 1800]}
		qid:Set[${LavishScript.CreateQuery[Timestamp < ${oldestlegal.Timestamp}]}]

		Logger:Log["${LogPrefix}:IsMarkedUnsafe: ${This.UnsafeBelts.Used} unsafe belts", LOG_DEBUG]
		This.UnsafeBelts:EraseByQuery[${qid}, TRUE]
		Logger:Log["${LogPrefix}:IsMarkedUnsafe: ${This.UnsafeBelts.Used} unsafe belts after expiring", LOG_DEBUG]
		LavishScript:FreeQuery[${qid}]

		if ${This.UnsafeBelts.FirstKey(exists)}
		{
			do
			{
				if ${This.UnsafeBelts.CurrentKey.Equals[${BeltName}]}
				{
					Logger:Log["${LogPrefix}:IsMarkedUnsafe: ${BeltName} - TRUE", LOG_DEBUG]
					return TRUE
				}
			}
			while ${This.UnsafeBelts.NextKey(exists)}
		}

		return FALSE
	}

	; Adds the current belt iteratorto the empty belt list
	method MarkUnsafe()
	{
		if !${This.Valid}
		{
			return
		}

		UnsafeBelts:Set["${beltIterator.Value.Name}", ${Time.Timestamp}]
		Logger:Log["${LogPrefix}: Excluding unsafe belt ${beltIterator.Value.Name}"]
	}

	member:int Total()
	{
		return ${beltIndex.Used}
	}

	member:string Name()
	{
		if !${This.Valid}
		{
			return ""
		}

		return ${beltIterator.Value.Name}
	}

	member:int64 Distance()
	{
		if !${Me.InSpace} || !${This.Valid}
		{
			return INVALID_DISTANCE
		}

		; Are we within 150km of the bookmark?
		if ${beltIterator.Value.ID} > -1
		{
			return ${Me.ToEntity.DistanceTo[${beltIterator.Value.ID}]}
		}
		else 
		{
			return ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${beltIterator.Value.X}, ${beltIterator.Value.Y}, ${beltIterator.Value.Z}]}
		}
	}

	member:bool AtBelt()
	{
		if ${This.Distance} <= WARP_RANGE
		{
			return TRUE
		}

		return FALSE
	}

	method Next()
	{
		if ${beltIndex.Used} == 0
		{
			This:ResetBeltList
			if ${beltIndex.Used} == 0
			{
				Logger:Log["${LogPrefix}:Next: No belts found", LOG_ERROR]
				return
			}
		}

		if !${beltIterator:Next(exists)}
		{
			Logger:Log["${LogPrefix}:Next: Resetting iterator", LOG_ERROR]
			beltIterator:First
		}
		variable int avail
		avail:Set[${This.Total}]
		while ${avail} > 0
		{
			if ${This.IsMarkedEmpty[${beltIterator.Value.Name}]}
			{
				Logger:Log["${LogPrefix}:Next: Skipping empty belt ${beltIterator.Value.Name}", LOG_MINOR]
				beltIterator:Next
				avail:Dec
				continue
			}
			if ${This.IsMarkedUnsafe[${beltIterator.Value.Name}]}
			{
				Logger:Log["${LogPrefix}:Next: Skipping unsafe belt ${beltIterator.Value.Name}", LOG_MINOR]
				beltIterator:Next
				avail:Dec
				continue
			}
			break
		}
		if ${This.Valid}
		{
			Logger:Log["${LogPrefix}:Next: Setting current belt to ${beltIterator.Value.Name}", LOG_DEBUG]
		}
		else
		{
			Logger:Log["${LogPrefix}:Next: All belts marked empty or unsafe, returning to station"]
			call ChatIRC.Say "All belts marked empty!"
			EVEBot.ReturnToStation:Set[TRUE]
			Logger:Log["${LogPrefix}:Next: HARD STOP: No belts available, all marked empty or unsafe"]
			relay all -event EVEBot_HARDSTOP "${Me.Name} - ${Config.Common.CurrentBehavior}"
		}
	}

	; Warp to the current belt iterator
	function WarpTo(int WarpInDistance=0)
	{
		if ${beltIterator.Value(exists)}
		{
			Logger:Log["${LogPrefix}:WarpTo: ${beltIterator.Value.Name}", LOG_DEBUG]
			Navigator:FlyToEntityID[${beltIterator.Value.ID}, ${WarpInDistance}]
			while ${Navigator.Busy}
			{
				wait 5
			}
		}
		else
		{
			Logger:Log["${LogPrefix}:WarpTo ERROR: Unable to find next belt"]
		}
	}

	; Find next available belt, then warp to it
	function WarpToNext(int WarpInDistance=0)
	{
		This:Next
		call This.WarpTo ${WarpInDistance}
	}
}
