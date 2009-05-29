/*
	Bookmark class

	Base class for bookmark lists

	-- CyberTech

*/

objectdef obj_Bookmark
{
	variable string SVN_REVISION = "$Rev: 803 $"
	variable int Version
	variable string LogPrefix

	variable index:bookmark Bookmarks
	variable iterator BookmarkIterator
	variable string BookmarkPrefix
	variable bool CheckSystemID

	method Reset(string _BookmarkPrefix = "", bool _CheckSystemID = TRUE)
	{
		variable int Pos
		variable int Used
		if ${_BookmarkPrefix.Length} > 0
		{
			This.BookmarkPrefix:Set[${_BookmarkPrefix}]
			This.CheckSystemID:Set[${_CheckSystemID}]
		}

		Bookmarks:Clear
		EVE:DoGetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
#if EVEBOT_DEBUG
		UI:UpdateConsole["${LogPrefix}: Found ${Bookmarks.Used} total bookmarks, filtering by prefix '${This.BookmarkPrefix}'", LOG_DEBUG]
#endif
		Used:Set[${Bookmarks.Used}]
		for(Pos:Set[1]; ${Pos} <= ${Used}; Pos:Inc)
		{
			if (${This.CheckSystemID} && ${Bookmarks[${Pos}].SolarSystemID} != ${_Me.SolarSystemID})
			{
#if EVEBOT_DEBUG
				UI:UpdateConsole["${LogPrefix}: Ignoring Out-of-System Bookmark: ${Bookmarks[${Pos}].Label}", LOG_DEBUG]
#endif
				Bookmarks:Remove[${Pos}]
				continue
			}

			if ${Bookmarks[${Pos}].Label.Left[${This.BookmarkPrefix.Length}].NotEqual["${This.BookmarkPrefix}"]}
			{
#if EVEBOT_DEBUG
				UI:UpdateConsole["${LogPrefix}: Ignoring Bookmark: ${Bookmarks[${Pos}].Label}", LOG_DEBUG]
#endif
				Bookmarks:Remove[${Pos}]
				continue
			}
		}
		Bookmarks:Collapse
		BookmarkIterator:First
	}

	method ValidateList()
	{
		if ${Bookmarks.Used} == 0
		{
			This:Reset
		}

		if ${Bookmarks.Get[1](exists)} && ${Bookmarks.Get[1].SolarSystemID} != ${_Me.SolarSystemID}
		{
#if EVEBOT_DEBUG
			UI:UpdateConsole["${LogPrefix}: System changed, resetting", LOG_DEBUG]
#endif
			This:Reset
		}
	}

	member:int Count()
	{
		return ${Bookmarks.Used}
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

	member:bool AtBookmark()
	{
		variable iterator TempIterator
#if EVEBOT_DEBUG
		UI:UpdateConsole["${LogPrefix} DEBUG: obj_Safespots.IsAtSafespot: ME_X = ${Me.ToEntity.X}", LOG_DEBUG]
		UI:UpdateConsole["${LogPrefix} DEBUG: obj_Safespots.IsAtSafespot: ME_Y = ${Me.ToEntity.Y}", LOG_DEBUG]
		UI:UpdateConsole["${LogPrefix} DEBUG: obj_Safespots.IsAtSafespot: ME_Z = ${Me.ToEntity.Z}", LOG_DEBUG]
#endif

		Bookmarks:GetIterator[TempIterator]
		if ${TempIterator:First(exists)}
		{
			do
			{
#if EVEBOT_DEBUG
				UI:UpdateConsole["${LogPrefix} DEBUG: AtBookmark: Label = ${TempIterator.Value.Label}", LOG_DEBUG]
				UI:UpdateConsole["${LogPrefix} DEBUG: AtBookmark:  ItemID = ${TempIterator.Value.ItemID}", LOG_DEBUG]
				UI:UpdateConsole["${LogPrefix} DEBUG: AtBookmark:  BM_X = ${TempIterator.Value.X}", LOG_DEBUG]
				UI:UpdateConsole["${LogPrefix} DEBUG: AtBookmark:  BM_Y = ${TempIterator.Value.Y}", LOG_DEBUG]
				UI:UpdateConsole["${LogPrefix} DEBUG: AtBookmark:  BM_Z = ${TempIterator.Value.Z}", LOG_DEBUG]
				UI:UpdateConsole["${LogPrefix} DEBUG: AtBookmark:  DIST = ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${TempIterator.Value.X}, ${TempIterator.Value.Y}, ${TempIterator.Value.Z}]}", LOG_DEBUG]
#endif
				; Are we within warp range of the bookmark?
				if ${TempIterator.Value.ItemID} > -1
				{
            		UI:UpdateConsole["DEBUG: obj_Safespots.IsAtSafespot: ItemID = ${TempIterator.Value.ItemID}"]
					if ${Me.ToEntity.DistanceTo[${TempIterator.Value.ItemID}]} < WARP_RANGE
					{
						return TRUE
					}
				}
				elseif ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${TempIterator.Value.X}, ${TempIterator.Value.Y}, ${TempIterator.Value.Z}]} < WARP_RANGE
				{
					return TRUE
				}
			}
			while ${TempIterator:Next(exists)}
		}

		return FALSE
	}

	function WarpToNext()
	{
		This:ValidateList[]

		if !${BookmarkIterator:Next(exists)}
		{
			BookmarkIterator:First
		}

		if ${BookmarkIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${BookmarkIterator.Value.ID}
		}
		else
		{
			UI:UpdateConsole["${LogPrefix} ERROR: WarpToNext found an invalid bookmark!"]
		}
	}

	; TODO: MoveToRandomBeltBookMark ->
	function WarpToRandom()
	{
		variable int RandomBelt

		if ${beltIndex.Used} > 0
		{
			RandomBelt:Set[${Math.Rand[${Math.Calc[${beltIndex.Used}-1]}]:Inc[1]}]
			while ${RandomBelt} > 0
			{
				This:Next
			}

#if EVEBOT_DEBUG
			UI:UpdateConsole["${LogPrefix}: MoveToRandomBeltBookMark: call Ship.WarpToBookMark ${beltIterator.Value.ID}"]
#endif
			call Ship.WarpToBookMark ${beltIndex[${RandomBelt}].ID}
		}
	}
}