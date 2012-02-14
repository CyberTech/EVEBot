/*
	Ammospots Object
	
	Creates an index of ammo bookmarks that exist in current system.
	Code copied from obj_Safespots.iss and modified.
	
	-- NoOne

*/
objectdef obj_Ammospots
{
	variable string SVN_REVISION = "$Rev: 2045 $"
	variable int Version

	variable index:bookmark AmmoSpots
	variable iterator AmmoSpotIterator

	method Initialize()
	{
		UI:UpdateConsole["obj_Ammospots: Initialized", LOG_MINOR]
	}

	method ResetAmmoSpotList()
	{
		AmmoSpots:Clear
		EVE:GetBookmarks[AmmoSpots]

		variable int idx
		idx:Set[${AmmoSpots.Used}]

		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set[${Config.Combat.AmmoBookmark}]

			variable string Label
			Label:Set["${AmmoSpots.Get[${idx}].Label.Escape}"]
			if ${Label.Left[${Prefix.Length}].NotEqual[${Prefix}]}
			{
				AmmoSpots:Remove[${idx}]
			}
			elseif ${AmmoSpots.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
			{
				AmmoSpots:Remove[${idx}]
			}

			idx:Dec
		}
		AmmoSpots:Collapse
		AmmoSpots:GetIterator[AmmoSpotIterator]

		UI:UpdateConsole["ResetAmmoSpotList found ${AmmoSpots.Used} ammospots in this system."]
	}

	function WarpToNextAmmoSpot()
	{
		if ${AmmoSpots.Used} == 0
		{
			This:ResetAmmoSpotList
		}

		if ${AmmoSpots.Get[1](exists)} && ${AmmoSpots.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:ResetAmmoSpotList
		}

		if !${AmmoSpotIterator:Next(exists)}
		{
			AmmoSpotIterator:First
		}

		if ${AmmoSpotIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${AmmoSpotIterator.Value.ID}
		}
		else
		{
			UI:UpdateConsole["ERROR: obj_Ammospots.WarpToNextAmmoSpot found an invalid bookmark!"]
		}
	}

	member:bool IsAtAmmospot()
	{
		if ${AmmoSpots.Used} == 0
		{
			This:ResetAmmoSpotList
		}

		; Are we within warp range of the bookmark?
		if ${AmmoSpotIterator.Value.ItemID} > -1
		{
			if ${Me.ToEntity.DistanceTo[${AmmoSpotIterator.Value.ItemID}]} < WARP_RANGE
			{
				return TRUE
			}
		}
		elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${AmmoSpotIterator.Value.X}, ${AmmoSpotIterator.Value.Y}, ${AmmoSpotIterator.Value.Z}]} < WARP_RANGE
		{
			return TRUE
		}

		return FALSE
	}
	
	function WarpTo()
	{
		call This.WarpToNextAmmoSpot
	}
	
	; Does an Ammo Bookmark exist in this system?
	member:bool IsThereAmmospotBookmark()
	{
		if ${AmmoSpots.Used} == 0
		{
			This:ResetAmmoSpotList
		}
		; Check one last time after resetting list
		if ${AmmoSpots.Used} == 0
		{
			return FALSE
		}
		return TRUE
	}
}

