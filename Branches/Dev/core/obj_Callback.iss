objectdef obj_Callback inherits obj_BaseClass
{
	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		PulseTimer:SetIntervals[2.0,3.0]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if !${Config.Common.Callback}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			if ${EVEBot.SessionValid}
			{
				;uplink UpdateClient "${Me.Name}" "${MyShip.ShieldPct}" "${MyShip.ArmorPct}" "${MyShip.CapacitorPct}" "${Defense.Hide}" "${Defense.HideReason}" "${Me.ActiveTarget.Name}" "${EVEBot.Paused}" "${Config.Common.Behavior}"  "${MyShip}" "${Session}"
			}

			This.PulseTimer:Update
		}

	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}
}