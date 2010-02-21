/*
	PulseTimer Object

	Provides timers with optional randomization.

	Generally used in on-frame pulses to delay 1 or more activities.

	-- CyberTech (cybertech@gmail.com

	Maintenance location for this is in the EVEBot repository at
		https://www.isxgames.com/EVEBot/Trunk/EVEbot/core/Lib/obj_PulseTimer.iss

	Example:
			variable obj_PulseTimer PulseTimer
			; Set the timer to have random durations from 0.5 to 1.0 seconds.
			This.PulseTimer:SetIntervals[0.5,1.0]
			if ${This.PulseTimer.Ready}
			{
				;do stuff
				;reset timer, include randomization
				This.PulseTimer:Update
				;OR
				; Update timer, disable randomization, timer duration will be the minimum interval (0.5, as above)
				This.PulseTimer:Update[FALSE]
			}

	Members:
		bool Ready()
			Returns true if the timer is expired/ready
	Methods:
		Expire()
			Expires the timer so the next call to Ready() will be true
		Increase(float)
			Increases the current timer by (float) seconds
		Update(bool)
			Resets the timer. If the parameter is false, timer randomization is not used.
*/

objectdef obj_PulseTimer
{
	variable string SVN_REVISION = "$Rev: 1264 $"
	variable int Version
	variable string LogPrefix
	variable time NextPulse

	variable float MinPulseInterval = 2.0
	variable float MaxPulseInterval = 8.0


	method SetIntervals(float MinInterval, float MaxInterval)
	{
		LogPrefix:Set["${This.ObjectName}"]

		This.MinPulseInterval:Set[${MinInterval}]
		This.MaxPulseInterval:Set[${MaxInterval}]
	}

	method SetMinInterval(float Interval)
	{
		This.MinPulseInterval:Set[${Interval}]
	}

	method SetMaxInterval(float Interval)
	{
		This.MaxPulseInterval:Set[${Interval}]
	}

	method Update(bool Randomize=TRUE)
	{
		This.NextPulse:Set[${Time.Timestamp}]

		if ${Config.Common.Randomize} && ${Randomize}
		{
			This.NextPulse.Second:Inc[${Math.Rand[${This.MaxPulseInterval}]:Inc[${This.MinPulseInterval}]}]
		}
		else
		{
			This.NextPulse.Second:Inc[${This.MinPulseInterval}]
		}
		This.NextPulse:Update
	}

	method Increase(float Delay=0.0)
	{
		This.NextPulse:Set[${Time.Timestamp}]
		This.NextPulse.Second:Inc[${Delay}]
		This.NextPulse:Update
	}

	method Expire()
	{
		This.NextPulse:Set[${Time.Timestamp}]
	}

	member:bool Ready()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			return TRUE
		}

		return FALSE
	}
}