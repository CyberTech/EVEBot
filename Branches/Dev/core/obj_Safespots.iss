/*
	Safespots class

	Safespot access.  Inherits obj_Bookmarks

	-- CyberTech

*/

objectdef obj_Safespots inherits obj_Bookmarks
{
	variable string SVN_REVISION = "$Rev$"

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This:Reset

		;PulseTimer:SetIntervals[0.5,1.0]
		;Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		;Event[EVENT_EVEBOT_ONFRAME]:DetachAtom
	}
	
	method Reset()
	{
		This[parent]:Reset["${Config.Labels.SafeSpotPrefix}", TRUE]
		Logger:Log["${LogPrefix}: Found ${Bookmarks.Used} safespots in this system"]
	}

	member:bool AtSafespot()
	{
		return ${This[parent].AtBookmark}
	}
}

