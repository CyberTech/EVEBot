/*
	Bookmark class
	
	Manages dynamic bookmarks for EVEBot
	
	-- CyberTech
	
*/

objectdef obj_Bookmarks
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:string TemporaryBookMarks
	variable string StoredLocation = ""
		
	method Initialize()
	{
		UI:UpdateConsole["obj_Bookmarks: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}
	
	method StoreLocation()
	{
		UI:UpdateConsole["Storing current location"]
		;This.StoredLocation:Set["${Me.Name} ${Math.Rand[500000]:Inc[100000]}"]
		This.StoredLocation:Set["${Math.Rand[5000]:Inc[1000]}"]
		
		/* Create the bookmark, but don't mark it as temporary, we'll handle it's cleanup thru RemoveStoredLocation */
		This:CreateBookMark[FALSE, "${This.StoredLocation}"]
	}
	
	method RemoveStoredLocation()
	{
		if ${This.StoredLocationExists}
		{
			EVE.Bookmark["${This.StoredLocation}"]:Remove
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
	
	method CreateEntityBookMark(int32 ID, bool Temporary=FALSE, string Label="Default")
	{
		if !${Entity[${ID}](exists)}
		{
			UI:UpdateConsole["Debug: CreateBookMark: Invalid ID"]
			return
		}
		
		EntityName:Set[${Entity[${ID}].Name}
		
		if ${Label.Equal["Default"]}
		{
			Label:Set[${EntityName}]
			
		}
		;UI:UpdateConsole["CreateBookMark: Label - ${Label}"]
		
		EVE:CreateBookmark["${Label}"]
		
	}

	; Create a bookmark for the current location in space (or in station)
	method CreateBookMark(bool Temporary=FALSE, string Label="Default")
	{
		if ${Label.Equal["Default"]}
		{
			Label:Set["${Me.Name} ${Math.Rand[500000]:Inc[100000]}]
		}
		
		EVE:CreateBookmark["${Label}"]
		if ${Temporary}
		{
			;UI:UpdateConsole["CreateBookMark: Label - ${Label} (Temporary)"]
			TemporaryBookMarks:Insert[${Label}]
		}
		else
		{
			;UI:UpdateConsole["CreateBookMark: Label - ${Label}"]
		}
		
	}

}