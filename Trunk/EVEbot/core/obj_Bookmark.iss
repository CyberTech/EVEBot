/*
	Bookmark class

	Base class for bookmark lists
	
	Users of this class are expected to overload Reset so that it calls This[parent]:Reset with the correct parameters.

	-- CyberTech

*/

objectdef obj_Bookmarks inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"

	variable index:bookmark Bookmarks
	variable iterator BookmarkIterator
	variable string BookmarkPrefix
	variable bool CheckSystemID

	variable set RecentlyUsed
	
	method Reset(string _BookmarkPrefix = "", bool _CheckSystemID = TRUE)
	{
		variable int Pos
		variable int Used
		if ${_BookmarkPrefix.Length} > 0
		{
			This.BookmarkPrefix:Set[${_BookmarkPrefix}]
			This.CheckSystemID:Set[${_CheckSystemID}]
		}
		else
		{
			Logger:Log["${LogPrefix}:Reset: ERROR: Called with no prefix, did someone forget to override the inherited function from obj_Bookmark?", LOG_CRITICAL]
			return
		}	

		This.RecentlyUsed:Clear
		This.Bookmarks:Clear
		
		; TODO - Enhance this in ISXEVE using query syntax
		EVE:DoGetBookmarks[Bookmarks]
		This.Bookmarks:GetIterator[BookmarkIterator]
		Logger:Log["${LogPrefix}: Found ${This.Bookmarks.Used} total bookmarks, filtering by prefix '${This.BookmarkPrefix}'", LOG_DEBUG]

		; We iterate this backwards to invalidating our index during removal
		Used:Set[${This.Bookmarks.Used}]
		for(Pos:Set[${Used}]; ${Pos} >= 1; Pos:Dec)
		{
			if (${This.CheckSystemID} && ${This.Bookmarks[${Pos}].SolarSystemID} != ${Me.SolarSystemID})
			{
				Logger:Log["${LogPrefix}: Ignoring Out-of-System Bookmark: ${This.Bookmarks[${Pos}].Label}", LOG_DEBUG]
				Bookmarks:Remove[${Pos}]
				continue
			}

			if ${This.Bookmarks[${Pos}].Label.Left[${This.BookmarkPrefix.Length}].NotEqual["${This.BookmarkPrefix}"]}
			{
				Logger:Log["${LogPrefix}: Ignoring Bookmark: ${This.Bookmarks[${Pos}].Label}", LOG_DEBUG]
				This.Bookmarks:Remove[${Pos}]
				continue
			}
		}
		
		This.Bookmarks:Collapse
		BookmarkIterator:First
	}

	method ValidateList()
	{
		if ${This.Bookmarks.Used} == 0
		{
			This:Reset
		}

; TODO - need another method of resetting this in the case where the caller didn't want to check systemid for the list - CT
		if ${This.Bookmarks.Get[1](exists)} && ${This.Bookmarks.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			Logger:Log["${LogPrefix}: System changed, resetting", LOG_DEBUG]
			This:Reset
		}
	}

	member:int Count()
	{
		return ${This.Bookmarks.Used}
	}

	method Next()
	{
		if ${This.Bookmarks.Used} == 0
		{
			This:Reset
		}

		if !${BookmarkIterator:Next(exists)}
		{
			BookmarkIterator:First
		}
	}

	member:bool AtBookmark()
	{
		variable iterator TempIterator
#if EVEBOT_DEBUG
		;Logger:Log["${LogPrefix} AtBookmark:", LOG_DEBUG]
		;Logger:Log["${LogPrefix}: ME_X = ${Me.ToEntity.X}", LOG_DEBUG]
		;Logger:Log["${LogPrefix}: ME_Y = ${Me.ToEntity.Y}", LOG_DEBUG]
		;Logger:Log["${LogPrefix}: ME_Z = ${Me.ToEntity.Z}", LOG_DEBUG]
#endif
; todo - check to see if we're INSIDE the station that was bookmarked, as well.

		Bookmarks:GetIterator[TempIterator]
		if ${TempIterator:First(exists)}
		{
			do
			{
#if EVEBOT_DEBUG
				;Logger:Log["${LogPrefix} DEBUG: AtBookmark: Label = ${TempIterator.Value.Label}", LOG_DEBUG]
				;Logger:Log["${LogPrefix} DEBUG: AtBookmark:  ItemID = ${TempIterator.Value.ItemID}", LOG_DEBUG]
				;Logger:Log["${LogPrefix} DEBUG: AtBookmark:  BM_X = ${TempIterator.Value.X}", LOG_DEBUG]
				;Logger:Log["${LogPrefix} DEBUG: AtBookmark:  BM_Y = ${TempIterator.Value.Y}", LOG_DEBUG]
				;Logger:Log["${LogPrefix} DEBUG: AtBookmark:  BM_Z = ${TempIterator.Value.Z}", LOG_DEBUG]
				;Logger:Log["${LogPrefix} DEBUG: AtBookmark:  DIST = ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${TempIterator.Value.X}, ${TempIterator.Value.Y}, ${TempIterator.Value.Z}]}", LOG_DEBUG]
#endif
				; Are we within warp range of the bookmark?
				if ${This.DistanceTo} > -1
				{
					Logger:Log["${LogPrefix}: ItemID = ${TempIterator.Value.ItemID}", LOG_DEBUG]
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

	method WarpToNext()
	{
		This:ValidateList[]

		if !${BookmarkIterator:Next(exists)}
		{
			BookmarkIterator:First
		}

		if ${BookmarkIterator.Value(exists)}
		{
			Logger:Log["${LogPrefix}:WarpToNext: ${BookmarkIterator.Value.Label}", LOG_DEBUG]
			Navigator:FlyToBookmark["${BookmarkIterator.Value.ID}"]
			This.RecentlyUsed:Add[${BookmarkIterator.Value.ID}]
		}
		else
		{
			Logger:Log["${LogPrefix}:WarpToNext: Invalid bookmark!"]
		}
	}

	method WarpToRandom()
	{
		This:ValidateList[]

		if !${This.Bookmarks.Used}
		{
			Logger:Log["${LogPrefix}:WarpToRandom: No bookmarks found", LOG_DEBUG]
			return
		}
	
		variable int Tries = 0
		variable set TestedBookmarks

		BookmarkIterator:First
		do
		{
			TestedBookmarkPositions:Add[${BookmarkIterator.Value.ID}]
		}
		while ${BookmarkIterator:Next(exists)}

		BookmarkIterator:Jump[${Math.Rand[${This.Bookmarks.Used:Dec}]:Inc[1]}]
		TestedBookmarkPositions:Remove[${BookmarkIterator.Value.ID}]
		
		while !${BookmarkIterator.Value(exists)} || \
				${This.RecentlyUsed.Contains[${BookmarkIterator.Value.ID}]} || \
				${This.DistanceTo} < WARP_RANGE
		{
			if ${TestedBookmarkPositions.Used} == 0
			{
				Logger:Log["${LogPrefix}:WarpToRandom: Exhausted bookmark list in WarpToRandom, failing", LOG_DEBUG]
				This:Reset
				return
			}

			BookmarkIterator:Jump[${Math.Rand[${This.Bookmarks.Used:Dec}]:Inc[1]}]
			TestedBookmarkPositions:Remove[${BookmarkIterator.Value.ID}]
		}

		Logger:Log["${LogPrefix}:WarpToRandom: ${BookmarkIterator.Value.Label}", LOG_DEBUG]
		Navigator:FlyToBookmarkID["${BookmarkIterator.Value.ID}"]

		; TODO - Enhance to store only the x most recently used bookmarks. Ensure that X isn't ever higher than Bookmarks/2 - CyberTech
		This.RecentlyUsed:Add[${BookmarkIterator.Value.ID}]
	}
	
	; TODO - Move this to the bookmark class once its created.
	member:float64 DistanceTo()
	{
		if ${BookmarkIterator.Value.ItemID} > -1 && ${Me.ToEntity(exists)}
		{
			return ${Me.ToEntity.DistanceTo[${BookmarkIterator.Value.ItemID}]}
		}
		elseif ${BookmarkIterator.Value.ToEntity(exists)}
		{
			return ${BookmarkIterator.Value.ToEntity.Distance}
		}
		else 
		{
			return ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${BookmarkIterator.Value.X}, ${BookmarkIterator.Value.Y}, ${BookmarkIterator.Value.Z}]}
		}
		
	}
}