objectdef obj_Belts
{
	variable index:entity Belts
	variable iterator Belt

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
		UI:UpdateConsole["ResetBeltList found ${Belts.Used} belts in this system."]
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
	
	function WarpTo()
	{
		call This.WarpToNextBelt
	}
	
	function WarpToNextBelt()
	{
		if ${Belts.Used} == 0 
		{
			This:ResetBeltList
		}		
		
		if ${Belts.Get[1](exists)} && ${Belts.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:ResetBeltList
		}
		
		if !${Belt:Next(exists)}
		{
			Belt:First
		}
		
		if ${Belt.Value(exists)}
		{
			;call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}
			call Ship.WarpToID ${Belt.Value.ID}
		}
	
	}
}