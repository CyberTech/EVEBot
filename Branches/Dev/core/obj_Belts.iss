objectdef obj_Belts
{
	variable string LogPrefix

	variable iterator Belt_CacheIterator
	variable set EmptyBelts

	method Initialize()
	{
		This[parent]:Initialize
		LogPrefix:Set["obj_Belts(${This.ObjectName})"]
		
		EntityCache.EntityFilters.Get[${EntityCache.CacheID_Belts}].Entities:GetIterator[Belt_CacheIterator]
		Logger:Log["${LogPrefix}: Initialized"]
	}

	method ResetBeltList()
	{
		EntityCache.EntityFilters.Get[${EntityCache.CacheID_Belts}].Entities:GetIterator[Belt_CacheIterator]
		Belt_CacheIterator:First
		Logger:Log["${LogPrefix}: ResetBeltList found ${EntityCache.Count[${EntityCache.CacheID_Belts}]} belts in this system.", LOG_DEBUG]
	}

	; Checks the belt name against the empty belt list.
	member IsBeltEmpty(string BeltName)
	{
		if ${This.EmptyBelts.Contains["${BeltName}"]}
		{
			Logger:Log["DEBUG: ${LogPrefix}:IsBeltEmpty - ${BeltName} - TRUE", LOG_DEBUG]
			return TRUE
		}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method MarkBeltEmpty(string BeltName)
	{
		EmptyBelts:Add["${BeltName}"]
		Logger:Log["Excluding empty belt ${BeltName}"]
	}

	member:int Count()
	{
		return ${EntityCache.Count[${EntityCache.CacheID_Belts}]}
	}

	member:bool AtBelt()
	{
		; Check if there is a belt closer than warp range.
		if ${EntityCache.Count[${EntityCache.CacheID_Belts}]} == 0
		{
			return FALSE
		}

		if !${Belt_CacheIterator.IsValid}
		{
			This:ResetBeltList
		}

		if ${Belt_CacheIterator.Value.ID(exists)}
		{
			if ${Me.ToEntity.DistanceTo[${Belt_CacheIterator.Value.ID}]} < WARP_RANGE
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${Belt_CacheIterator.Value.X}, ${Belt_CacheIterator.Value.Y}, ${Belt_CacheIterator.Value.Z}]} < WARP_RANGE
		{
			return TRUE
		}

		return FALSE
	}

	method Next()
	{
		if ${EntityCache.Count[${EntityCache.CacheID_Belts}]} == 0
		{
			This:ResetBeltList
		}

		if !${Belt_CacheIterator:Next(exists)}
		{
			Belt_CacheIterator:First
		}
	}

	function WarpTo(int WarpInDistance=0)
	{
		call This.WarpToNext ${WarpInDistance}
	}

	function WarpToRandom(int WarpInDistance=0)
	{
		variable int RandomBelt

		if ${EntityCache.Count[${EntityCache.CacheID_Belts}]} > 0
		{
			RandomBelt:Set[${Math.Rand[${Math.Calc[${EntityCache.Count[${EntityCache.CacheID_Belts}]} - 1]}]:Inc[1]}]
			while ${RandomBelt} > 0
			{
				This:Next
			}
		}
		This:WarpToNext ${WarpInDistance}
	}

	function WarpToNext(int WarpInDistance=0)
	{
		This:Next

		if ${Belt_CacheIterator.Value(exists)}
		{
			/* Commented out -- uncomment if you wish to avoid belts within scan range of a gate
			
			variable int NearestGate
			variable float DistanceToGate
			NearestGate:Set[${Entity[fromID,${Belt_CacheIterator.Value.ID},Radius,SCANNER_RANGE,GroupID,GROUP_STARGATE].ID}]
			if ${NearestGate(exists)} && ${NearestGate} > 0
			{
				DistanceToGate:Set[${Entity[${Belt_CacheIterator.Value.ID}].DistanceTo[${NearestGate}]}]
				if ${DistanceToGate} < ${Math.Calc[SCANNER_RANGE/2]}
				{
					; TODO - This needs to do a count of belts within range of the gate and make a decision if it's safe enough.
					; I really, really hate this solution, it relies on the % chance the hostile will pick the wrong belt
					; when they see you on scanner. -- CyberTech
					Logger:Log["obj_Belts: Skipping belt ${Belt_CacheIterator.Value.Name} - too close to gate (${Entity[${NearestGate}].Name} - ${DistanceToGate}"]
					call This.WarpToNext ${WarpInDistance}
					return
				}
			}
			*/

			call Ship.WarpToID ${Belt_CacheIterator.Value.ID} ${WarpInDistance}
		}
		else
		{
			Logger:Log["${LogPrefix}: WarpToNext ERROR: Belt_CacheIterator does not exist"]
		}
	}
}
