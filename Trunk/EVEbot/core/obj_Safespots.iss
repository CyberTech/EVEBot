objectdef cls_Safespot
{

	method Initialize()
	{
		if ${EVE.Bookmark[SafespotBookmark](exists)}
		{
			echo "Safespot found: ${EVE.Bookmark[SafespotBookmark]}" 
		}
		else
		{
			echo "Safespot not found!"
		}
	}

	member:bool IsAtSafespot()
	{
		; Are we within 150km off th bookmark?
		if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${EVE.Bookmark[SafespotBookmark].X}, ${EVE.Bookmark[SafespotBookmark].Y}, ${EVE.Bookmark[SafespotBookmark].Z}]} < 150000
		{
			return TRUE
		}
		
		return FALSE
	}
	
	method WarpTo()
	{
		EVE.Bookmark[SafespotBookmark]:WarpTo[0]
	}
}

