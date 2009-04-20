objectdef obj_Belts
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string LogPrefix

	variable index:entity beltIndex
	variable iterator beltIterator

	variable set EmptyBelts

	method Initialize()
	{
		This[parent]:Initialize
		LogPrefix:Set["obj_Belts(${This.ObjectName})"]
		UI:UpdateConsole["${LogPrefix}: Initialized"]
	}

	method ResetBeltList()
	{
		EVE:DoGetEntities[beltIndex, GroupID, GROUP_ASTEROIDBELT]
		beltIndex:GetIterator[beltIterator]
		beltIterator:First
		UI:UpdateConsole["${LogPrefix}: ResetBeltList found ${beltIndex.Used} belts in this system.", LOG_DEBUG]
	}

	; Checks the belt name against the empty belt list.
	member IsBeltEmpty(string BeltName)
	{
		if ${This.EmptyBelts.Contains["${BeltName}"]}
		{
			UI:UpdateConsole["DEBUG: ${LogPrefix}:IsBeltEmpty - ${BeltName} - TRUE", LOG_DEBUG]
			return TRUE
		}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method MarkBeltEmpty(string BeltName)
	{
		EmptyBelts:Add["${BeltName}"]
		UI:UpdateConsole["Excluding empty belt ${BeltName}"]
	}

	member:int Count()
	{
		return ${beltIndex.Used}
	}

	member:bool AtBelt()
	{
		; Check if there is a belt closer than warp range.
		if (${beltIndex.Used} == 0)
		{
			This:ResetBeltList
			if (${This.Count} == 0)
			{
				return FALSE
			}
		}

		if !${beltIterator.Value.IsValid}
		{
			return FALSE
		}

		if ${beltIterator.Value.ItemID} > -1
		{
			if ${Me.ToEntity.DistanceTo[${beltIterator.Value.ItemID}]} < WARP_RANGE
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${beltIterator.Value.X}, ${beltIterator.Value.Y}, ${beltIterator.Value.Z}]} < WARP_RANGE
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
		}

		if !${beltIterator:Next(exists)}
		{
			beltIterator:First
		}
	}

	function WarpTo(int WarpInDistance=0)
	{
		call This.WarpToNext ${WarpInDistance}
	}

	function WarpToRandom(int WarpInDistance=0)
	{
		variable int RandomBelt

		if ${beltIndex.Used} > 0
		{
			RandomBelt:Set[${Math.Rand[${Math.Calc[${beltIndex.Used}-1]}]:Inc[1]}]
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

		if ${beltIterator.Value(exists)}
		{

			variable int NearestGate
			variable float DistanceToGate
			NearestGate:Set[${Entity[fromID,${beltIterator.Value.ID},Radius,SCANNER_RANGE,GroupID,GROUP_STARGATE].ID}]
			if ${NearestGate(exists)} && ${NearestGate} > 0
			{
				DistanceToGate:Set[${Entity[${beltIterator.Value.ID}].DistanceTo[${NearestGate}]}]
				if ${DistanceToGate} < ${Math.Calc[SCANNER_RANGE/2]}
				{
					; TODO - This needs to do a count of belts within range of the gate and make a decision if it's safe enough.
					; I really, really hate this solution, it relies on the % chance the hostile will pick the wrong belt
					; when they see you on scanner. -- CyberTech
					UI:UpdateConsole["obj_Belts: Skipping belt ${beltIterator.Value.Name} - too close to gate (${Entity[${NearestGate}].Name} - ${DistanceToGate}"]
					call This.WarpToNext ${WarpInDistance}
					return
				}
			}

			call Ship.WarpToID ${beltIterator.Value.ID} ${WarpInDistance}
		}
		else
		{
			UI:UpdateConsole["${LogPrefix}: WarpToNext ERROR: beltIterator does not exist"]
		}
	}
}
