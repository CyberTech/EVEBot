/*
	Cache class
	
	Object to handle caching member data.
	
	-- GliderPro
	
*/

objectdef obj_Cache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string m_ObjectName
	variable string m_CachedMembers
	variable time NextPulse
	variable int PulseIntervalInSeconds = 10
	
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Cache: Initialized", LOG_MINOR]
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

	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.IntervalInSeconds}]
    		This.NextPulse:Update			
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
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	method Initialize()
	{
		This[parent]:Initialize
		
		This:SetObject["Me.Ship"]
		This:RegisterMember["ArmorPct"]
		This:RegisterMember["ShieldPct"]
		
		UI:UpdateConsole["obj_ShipCache: Initialized", LOG_MINOR]
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