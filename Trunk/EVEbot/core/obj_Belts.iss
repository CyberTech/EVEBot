objectdef cls_Belts
{
	variable index:entity Belts
	variable iterator Belt

	method Initialize()
	{
		EVE:DoGetEntities[Belts, GroupID, GROUPID_ASTEROID_BELT]
		Belts:GetIterator[Belt]

		variable int Counter

		Counter:Set[0]
		if ${Belt:First(exists)}
		do
		{
			Counter:Inc[1]
		}
		while ${Belt:Next(exists)}

		echo "${Counter} belts found..."
	}
    member:bool IsAtBelt()
	{
		; Are we within 150km off the belt?
		if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${Belt.Value.X}, ${Belt.Value.Y}, ${Belt.Value.Z}]} < 150000
		{
			return TRUE
		}
		
		return FALSE
	}
	
	method NextBelt()
	{
		if !${Belt:Next(exists)}
			Belt:First(exists)

		return
	}
}