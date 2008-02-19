/*
	Cache class
	
	Object to handle caching member data.
	
	-- GliderPro
	
*/

objectdef obj_Cache
{
	variable string m_ObjectName
	variable string m_CachedMembers
	
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Cache: Initialized"]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		FrameCounter:Inc

		variable int IntervalInSeconds = 2
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			FrameCounter:Set[0]
			
			/* iterate through the registered members and cache them */
		}
	}

	/* return the cached data */
	member GetMember(string memberName)
	{
		return NULL
	}
	
	/* register an object for caching */
	method SetObject(string objectName)
	{
	}

	/* register a member for caching */
	method RegisterMember(string memberName)
	{
	}


}

objectdef obj_ShipCache inherits obj_Cache
{
	method Initialize()
	{
		This[parent]:Initialize
		
		This:SetObject["Me.Ship"]
		This:RegisterMember["ArmorPct"]
		This:RegisterMember["ShieldPct"]
		
		UI:UpdateConsole["obj_ShipCache: Initialized"]
	}
	
	method Shutdown()
	{
		This[parent]:Shutdown
	}
	
	member:float ArmorPct()
	{
		return This.GetMember[ArmorPct]
	}
	
	member:float ShieldPct()
	{
		return This.GetMember[ShieldPct]
	}
}