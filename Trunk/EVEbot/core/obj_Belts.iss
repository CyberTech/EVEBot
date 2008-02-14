objectdef obj_Belts
{
	variable index:entity beltIndex
	variable iterator beltIterator

	method Initialize()
	{
		if ${Me.Station(exists)} && !${Me.Station}
		{
			This:ResetBeltList
		}
		
		UI:UpdateConsole["obj_Belts: Initialized."]
	}
	method ResetBeltList()
	{
		EVE:DoGetEntities[beltIndex, GroupID, GROUPID_ASTEROID_BELT]
		beltIndex:GetIterator[beltIterator]	
		UI:UpdateConsole["ResetBeltList found ${beltIndex.Used} belts in this system."]
	}
	
    member:bool IsAtBelt()
	{
		; Are we within 150km off the belt?
		if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${beltIterator.Value.X}, ${beltIterator.Value.Y}, ${beltIterator.Value.Z}]} < 150000
		{
			return TRUE
		}
		
		return FALSE
	}
	
	method NextBelt()
	{
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
			UI:UpdateConsole["obj_Belts: DEBUG: Warping to ${beltIterator.Value.Name}"]
			call Ship.WarpToID ${beltIterator.Value.ID}
		}
		else
		{
			UI:UpdateConsole["obj_Belts: DEBUG: ERROR: ${beltIterator.Value(exists)}"]
		}
	}
}