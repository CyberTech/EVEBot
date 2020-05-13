/*
	FleetManager Class

	Handles automatic fleet building and arrangement decisions

	-- CyberTech

*/

objectdef obj_FleetManager
{
	variable string LogPrefix

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]
		Logger:Log["${LogPrefix}: Initialized"]
		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom[This:Pulse]
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