/*
	Safespots class
	
	Safespot access.  Inherits obj_Bookmark
	
	-- CyberTech
	
*/

objectdef obj_Safespots inherits obj_Bookmark
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string LogPrefix

	method Initialize()
	{		
		LogPrefix:Set["obj_Safespots(${This.ObjectName})"]
		This:Reset
		UI:UpdateConsole["${LogPrefix}: Initialized"]
	}

	method Reset()
	{
		This[parent]:Reset["${Config.Labels.SafeSpotPrefix}"]
		UI:UpdateConsole["${LogPrefix}: Found ${Bookmarks.Used} safespots in this system"]
	}

	member:bool AtSafespot()
	{
		return ${This[parent].AtBookmark}
	}
}

