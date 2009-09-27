/*
	FleetManager Class

	Handles automatic fleet building and arrangement decisions

	-- CyberTech

*/

objectdef obj_FleetManager
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string LogPrefix

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]
		UI:UpdateConsole["${LogPrefix}: Initialized"]
		Event[OnFrame]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		return
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

}