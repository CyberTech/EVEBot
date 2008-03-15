objectdef obj_Belts
{
	variable index:entity beltIndex
	variable iterator beltIterator

	method Initialize()
	{		
		UI:UpdateConsole["obj_Belts: Initialized"]
	}
	
	method ResetBeltList()
	{
		EVE:DoGetEntities[beltIndex, GroupID, GROUPID_ASTEROID_BELT]
		beltIndex:GetIterator[beltIterator]	
		UI:UpdateConsole["obj_Belts: ResetBeltList found ${beltIndex.Used} belts in this system."]
	}
	
    member:bool IsAtBelt()
	{
		; Are we within 150km off the belt?
		; TODO - Why are we calling math.distance w/6 object calls instead of ${beltIterator.Value.Distance} -- CyberTech
		; GP: Because I copied it from Da_Teach.
		; ONLY WORKS FOR ENTITY BOOKMARKS if ${Entity[OwnerID,${Me.CharID},CategoryID,CATEGORYID_SHIP].DistanceTo[${beltIterator.Value.ID}]} < 150000
		if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${beltIterator.Value.X}, ${beltIterator.Value.Y}, ${beltIterator.Value.Z}]} < 150000
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