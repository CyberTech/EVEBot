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
		EVE:DoGetEntities[beltIndex, GroupID, GROUP_ASTEROIDBELT]
		beltIndex:GetIterator[beltIterator]	
		UI:UpdateConsole["obj_Belts: ResetBeltList found ${beltIndex.Used} belts in this system.", LOG_DEBUG]
	}
	
    member:bool IsAtBelt()
	{
		; Are we within 150km of the bookmark?
		if ${beltIterator.Value.ItemID} > -1
		{
			if ${Me.ToEntity.DistanceTo[${beltIterator.ItemID}]} < 150000
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${beltIterator.Value.X}, ${beltIterator.Value.Y}, ${beltIterator.Value.Z}]} < 150000
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
	
	function WarpTo()
	{
		call This.WarpToNextBelt
	}
	
	function WarpToNextBelt()
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
			;call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}
			;;UI:UpdateConsole["obj_Belts: DEBUG: Warping to ${beltIterator.Value.Name}"]
			call Ship.WarpToID ${beltIterator.Value.ID}
		}
		else
		{
			UI:UpdateConsole["obj_Belts:WarpToNextBelt ERROR: beltIterator does not exist"]
		}
	}
}