/*
	Bookmark class

	Manages dynamic bookmarks for EVEBot

	-- CyberTech

*/

objectdef obj_Bookmarks
{
	variable index:string TemporaryBookMarks
	variable string StoredLocation = ""

	method Initialize()
	{
		Logger:Log["obj_Bookmarks: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

	method StoreLocation()
	{
		Logger:Log["Storing current location"]
		;This.StoredLocation:Set["${Me.Name} ${Math.Rand[500000]:Inc[100000]}"]
		This.StoredLocation:Set["${Math.Rand[5000]:Inc[1000]}"]

		/* Create the bookmark, but don't mark it as temporary, we'll handle it's cleanup thru RemoveStoredLocation */
		This:CreateBookMark[FALSE, "${This.StoredLocation}"]
	}

	member:bool CheckForStoredLocation()
	{
		return ${StoredLocation.Length} != 0
	}

	method RemoveStoredLocation()
	{
		if ${This.StoredLocationExists}
		{
			EVE.Bookmark["${This.StoredLocation}"]:Remove
			StoredLocation:Set[""]
		}
	}

	member StoredLocationExists()
	{
		if ${This.StoredLocation.Length} > 0
		{
			return ${EVE.Bookmark["${This.StoredLocation}"](exists)}
		}
		return FALSE
	}

	; Create a bookmark for the current location in space (or in station)
	method CreateBookMark(bool Temporary=FALSE, string Label="Default")
	{
		if ${Label.Equal["Default"]}
		{
			Label:Set["${Me.Name} ${Math.Rand[500000]:Inc[100000]}"]
		}

		EVE:CreateBookmark["${Label}"]
		if ${Temporary}
		{
			;Logger:Log["CreateBookMark: Label - ${Label} (Temporary)"]
			TemporaryBookMarks:Insert[${Label}]
		}
		else
		{
			;Logger:Log["CreateBookMark: Label - ${Label}"]
		}
	}

	member:int64 FindRandomBounceBookmark()
	{
		variable index:bookmark bm_index
		EVE:GetBookmarks[bm_index]

		variable string InstaQuery
		InstaQuery:Concat["SolarSystemID = ${Me.SolarSystemID}"]
		InstaQuery:Concat[" && Distance > WARP_RANGE"]
		InstaQuery:Concat[" && Distance > 500000"]
		InstaQuery:Concat[" && IsWarpAligned = 1"]
		bm_index:RemoveByQuery[${LSQueryCache[${InstaQuery}]}, FALSE]
		bm_index:Collapse

		if ${bm_index.Used} == 0
		{
			; No aligned bookmark found, so check for unaligned
			EVE:GetBookmarks[bm_index]

			InstaQuery:Set["SolarSystemID = ${Me.SolarSystemID}"]
			InstaQuery:Concat[" && Distance > WARP_RANGE"]
			InstaQuery:Concat[" && Distance > 500000"]
			bm_index:RemoveByQuery[${LSQueryCache[${InstaQuery}]}, FALSE]
			bm_index:Collapse

			if ${bm_index.Used} == 0
			{
				Logger:Log["FindRandomInstaUndock returning -1", LOG_DEBUG]
				return -1
			}
		}

		variable int RandomBM
		RandomBM:Set[${Math.Rand[${bm_index.Used}]:Inc[1]}]
		Logger:Log["FindRandomBounceBookmark returning ${bm_index[${RandomBM}].ID} ${bm_index[${RandomBM}].Label} ${bm_index[${RandomBM}].Distance}",LOG_DEBUG]
		return ${bm_index[${RandomBM}].ID}
	}

}