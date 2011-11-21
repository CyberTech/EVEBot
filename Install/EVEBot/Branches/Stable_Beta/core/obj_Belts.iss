objectdef obj_Belts
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:entity beltIndex
	variable iterator beltIterator

	method Initialize()
	{		
		UI:UpdateConsole["obj_Belts: Initialized", LOG_MINOR]
	}
	
	method ResetBeltList()
	{
		EVE:PopulateEntities[TRUE]
		EVE:QueryEntities[beltIndex, "GroupID = GROUP_ASTEROIDBELT"]
		beltIndex:GetIterator[beltIterator]	
		UI:UpdateConsole["obj_Belts: ResetBeltList found ${beltIndex.Used} belts in this system.", LOG_DEBUG]
	}
	
    member:bool IsAtBelt()
	{
		; Are we within 150km of the bookmark?
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
	
	; TODO - logic is duplicated inside WarpToNextBelt -- CyberTech
	method NextBelt()
	{
		if ${beltIndex.Used} == 0 
		{
			This:ResetBeltList
		}		

		if !${beltIterator:Next(exists)}
			beltIterator:First(exists)

		return
	}
	
	function WarpTo(int WarpInDistance=0)
	{
		call This.WarpToNextBelt ${WarpInDistance}
	}
	
	function WarpToNextBelt(int WarpInDistance=0)
	{
		if ${beltIndex.Used} == 0 
		{
			This:ResetBeltList
		}		
		
		; This is for belt bookmarks only
		;if ${beltIndex.Get[1](exists)} && ${beltIndex.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		;{
		;	This:ResetBeltList
		;}
		
		if !${beltIterator:Next(exists)}
		{
			beltIterator:First
		}
		
		if ${beltIterator.Value(exists)}
		{
/*
			variable int64 NearestGate
			variable float DistanceToGate
			; fromID is not enabled in isxeve beta.
			NearestGate:Set[${Entity[fromID,${beltIterator.Value.ID} && Distance <= SCANNER_RANGE && GroupID = GROUP_STARGATE].ID}]
			if ${NearestGate(exists)} && ${NearestGate} > 0
			{
				DistanceToGate:Set[${Entity[${beltIterator.Value.ID}].DistanceTo[${NearestGate}]}]
				if ${DistanceToGate} < ${Math.Calc[SCANNER_RANGE/2]}
				{
					; TODO - This needs to do a count of belts within range of the gate and make a decision if it's safe enough.
					; I really, really hate this solution, it relies on the % chance the hostile will pick the wrong belt
					; when they see you on scanner. -- CyberTech
					UI:UpdateConsole["obj_Belts: Skipping belt ${beltIterator.Value.Name} - too close to gate (${Entity[${NearestGate}].Name} - ${DistanceToGate}"]
					call This.WarpToNextBelt ${WarpInDistance}
					return
				}
			}
*/
			;call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}
			;;UI:UpdateConsole["obj_Belts: DEBUG: Warping to ${beltIterator.Value.Name}"]
			call Ship.WarpToID ${beltIterator.Value.ID} ${WarpInDistance}
		}
		else
		{
			UI:UpdateConsole["obj_Belts:WarpToNextBelt ERROR: beltIterator does not exist"]
		}
	}
}
