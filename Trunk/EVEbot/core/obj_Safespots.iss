objectdef obj_Safespots
{
	variable index:bookmark SafeSpots
	variable iterator SafeSpotIterator

	method Initialize()
	{
		UI:UpdateConsole["obj_Safespots: Initialized"]
	}

	method ResetSafeSpotList()
	{
		SafeSpots:Clear
		EVE:DoGetBookmarks[SafeSpots]
	
		variable int idx
		idx:Set[${SafeSpots.Used}]
		
		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set[${Config.Labels.SafeSpotPrefix}]
			
			variable string Label
			Label:Set[${SafeSpots.Get[${idx}].Label}]			
			if ${Label.Left[${Prefix.Length}].NotEqual[${Prefix}]}
			{
				SafeSpots:Remove[${idx}]
			}
			elseif ${SafeSpots.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
			{
				SafeSpots:Remove[${idx}]
			}
			
			idx:Dec
		}		
		SafeSpots:Collapse
		SafeSpots:GetIterator[SafeSpotIterator]
		
		UI:UpdateConsole["ResetSafeSpotList found ${SafeSpots.Used} safespots in this system."]
	}
	
	function WarpToNextSafeSpot()
	{
		if ${SafeSpots.Used} == 0 
		{
			This:ResetSafeSpotList
		}		
		
		if ${SafeSpots.Get[1](exists)} && ${SafeSpots.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:ResetSafeSpotList
		}
		
		if !${SafeSpotIterator:Next(exists)}
		{
			SafeSpotIterator:First
		}
		
		if ${SafeSpotIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}
		}
	}

	member:bool IsAtSafespot()
	{
		if ${SafeSpots.Used} == 0 
		{
			This:ResetSafeSpotList
		}
		
		; Are we within 150km of the bookmark?
		if ${SafeSpotIterator.Value.ItemID}> > -1
		{
			if ${Me.ToEntity.DistanceTo[${SafeSpotIterator.ItemID}]} < 150000
			{
				return TRUE
			}
		}
		else if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} < 150000
		{
			return TRUE
		}
		return FALSE		
	}
	
	function WarpTo()
	{
		call This.WarpToNextSafeSpot
	}
}

