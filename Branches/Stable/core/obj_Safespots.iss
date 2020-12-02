objectdef obj_Safespots
{
	variable index:bookmark SafeSpots
	variable iterator SafeSpotIterator

	method Initialize()
	{
		Logger:Log["obj_Safespots: Initialized", LOG_MINOR]
	}

	member Count()
	{
		return ${Safespots.Used}
	}

	method ResetSafeSpotList(bool SupressSpam=FALSE)
	{
		SafeSpots:Clear
		EVE:GetBookmarks[SafeSpots]

		variable int idx
		idx:Set[${SafeSpots.Used}]

		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set[${Config.Labels.SafeSpotPrefix}]

			variable string Label
			Label:Set["${SafeSpots.Get[${idx}].Label.Escape}"]
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
		SafeSpotIterator:First

		if !${SupressSpam}
		{
			Logger:Log["ResetSafeSpotList found ${SafeSpots.Used} safespots in this system."]
		}
	}

	; Returns bookmark id
	member:int64 NextSafeSpot()
	{
		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList
			if ${SafeSpots.Used} == 0
			{
				return -1
			}
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
			return ${SafeSpotIterator.Value.ID}
		}

		Logger:Log["ERROR: obj_Safespots.NextSafeSpot found an invalid bookmark!"]
		return -1
	}

	function WarpToNextSafeSpot()
	{
		variable int64 bmid
		bmid:Set[${This.NextSafeSpot}]
		if ${bmid} > 0
		{
			Navigator:FlyToBookmarkID[${bmid}, 0, FALSE]
		}
	}

	member:bool IsAtSafespot(bool SupressSpam=FALSE)
	{
		if ${SafeSpots.Used} == 0
		{
			This:ResetSafeSpotList[${SupressSpam}]
			if ${SafeSpots.Used} == 0
			{
				return FALSE
			}
		}

		; big debug block to get to the bottom of the "safe spot problem"
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: ItemID = ${SafeSpotIterator.Value.ItemID}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: SS_X = ${SafeSpotIterator.Value.X}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: SS_Y = ${SafeSpotIterator.Value.Y}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: SS_Z = ${SafeSpotIterator.Value.Z}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: ME_X = ${Me.ToEntity.X}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: ME_Y = ${Me.ToEntity.Y}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: ME_Z = ${Me.ToEntity.Z}"]
		;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: DIST = ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]}"]

		; Are we within warp range of the bookmark?
		if !${SafeSpotIterator.Value(exists)}
		{
			return FALSE
		}
		elseif ${SafeSpotIterator.Value.ItemID} > -1
		{
            ;Logger:Log["DEBUG: obj_Safespots.IsAtSafespot: ItemID = ${SafeSpotIterator.Value.ItemID}"]
			if ${Me.ToEntity.DistanceTo[${SafeSpotIterator.Value.ItemID}]} < WARP_RANGE
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${SafeSpotIterator.Value.X}, ${SafeSpotIterator.Value.Y}, ${SafeSpotIterator.Value.Z}]} < WARP_RANGE
		{
			return TRUE
		}

		return FALSE
	}

	function WarpTo(bool Wait=FALSE)
	{
		call This.WarpToNextSafeSpot
		if ${Wait}
		{
			while ${Navigator.Busy}
			{
				wait 10
			}
		}
	}
}

