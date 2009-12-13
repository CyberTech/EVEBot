objectdef obj_Callback
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Callback: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if !${Config.Common.Callback}
		{
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${EVEBot.SessionValid}
			{
				uplink UpdateClient "${Me.Name}" "${_MyShip.ShieldPct}" "${_MyShip.ArmorPct}" "${_MyShip.CapacitorPct}" "${Defense.Hide}" "${Defense.HideReason}" "${Me.ActiveTarget.Name}" "${EVEBot.Paused}" "${Config.Common.BotMode}"  "${MyShip}" "${Session}"
			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}
}