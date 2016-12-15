/*
	Belt Bookmark Class

	Belt-bookmark access.  Inherits obj_Bookmark

	-- CyberTech

*/

objectdef obj_BeltBookmarks inherits obj_Bookmarks
{
	variable string SVN_REVISION = "$Rev$"
	variable set EmptyBelts

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This:Reset
		;PulseTimer:SetIntervals[0.5,1.0]
		;Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Reset()
	{
		; TODO - Check mode, use ratter prefix, hauler prefix, etc.
		if ${Config.Miner.IceMining}
		{
			This[parent]:Reset["${Config.Labels.IceBeltPrefix}", TRUE]
		}
		else
		{
			This[parent]:Reset["${Config.Labels.OreBeltPrefix}", TRUE]
		}
		Logger:Log["${LogPrefix}: Found ${Bookmarks.Used} bookmarks in this system"]
	}

	; Checks the belt name against the empty belt list.
	member IsBeltEmpty(string BeltName)
	{
		if ${This.EmptyBelts.Contains["${BeltName}"]}
		{
			Logger:Log["${LogPrefix}:IsBeltEmpty - ${BeltName} - TRUE", LOG_DEBUG]
			return TRUE
		}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method MarkBeltEmpty(string BeltName)
	{
		EmptyBelts:Add["${BeltName}"]
		Logger:Log["${LogPrefix}: Excluding empty belt ${BeltName}"]
	}
}