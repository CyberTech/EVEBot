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

}