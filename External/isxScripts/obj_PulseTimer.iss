/*
	obj_PulseTimer by CyberTech

		Provides timers with optional randomization.
		Generally used in on-frame pulses to delay 1 or more activities.

	-- CyberTech (cybertech@gmail.com

	Example:
			variable obj_PulseTimer PulseTimer
			; Set the timer to have random durations from 0.5 to 1.0 seconds.
			This.PulseTimer:SetIntervals[0.5,1.0]

			... later ...
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
		Extend(float)
			Extends the current timer by (float) seconds. This only affects the current iteration of the timer; after it expires, it will return to configured values.
		Update(bool)
			Resets the timer. If the parameter is false, timer randomization is not used.
*/

#ifndef EVENT_ONFRAME
	#if ${ISXEVE(exists)}
		#define EVENT_ONFRAME ISXEVE_OnFrame
	#else
		#define EVENT_ONFRAME OnFrame
	#endif
#endif

objectdef obj_PulseTimer
{
	variable int Version
	variable string LogPrefix
	variable int ExpireTime

	variable int MinPulseInterval = 2000
	variable int MaxPulseInterval = 8000

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]
	}

	method SetIntervals(float MinIntervalSeconds, float MaxIntervalSeconds)
	{
		This.MinPulseInterval:Set[${Math.Calc[${MinIntervalSeconds} * 1000]}]
		This.MaxPulseInterval:Set[${Math.Calc[${MaxIntervalSeconds} * 1000]}]
	}

	method SetMinInterval(float MinIntervalSeconds)
	{
		This.MinPulseInterval:Set[${Math.Calc[${MinIntervalSeconds} * 1000]}]
	}

	method SetMaxInterval(float MaxIntervalSeconds)
	{
		This.MaxPulseInterval:Set[${Math.Calc[${MaxIntervalSeconds} * 1000]}]
	}

	; Increase the timer period one time
	method Increase(float DelaySeconds=0.0)
	{
		This:Extend[${DelaySeconds}]
	}

	; Increase the timer period one time
	method Extend(float DelaySeconds=0.0)
	{
		This.ExpireTime:Set[${Script.RunningTime}]
		This.ExpireTime:Inc[${Math.Calc[${DelaySeconds} * 1000]}]
	}

	; Update (restart) the timer using its current interval settings
	method Update(bool Randomize=TRUE)
	{
		This.ExpireTime:Set[${Script.RunningTime}]

		; Config.Common is a configuration object used in my projects, this will use it if it exists otherwise rely
		; purely on the Randomize var.
		if ( (${Config.Common(exists)} && ${Config.Common.Randomize} && ${Randomize}) || \
			 (!${Config.Common(exists)} && ${Randomize}) \
			)
		{
			This.ExpireTime:Inc[${Math.Rand[${This.MaxPulseInterval}]:Inc[${This.MinPulseInterval}]}]
		}
		else
		{
			This.ExpireTime:Inc[${This.MinPulseInterval}]
		}
	}

	; Expire the timer
	; If there is a callback, force execution of the callback immedately
	method Expire()
	{
		This.ExpireTime:Set[${Script.RunningTime}]
	}

	; Is the timer expired/ready?
	member:bool Ready()
	{
		if ${Script.RunningTime} >= ${This.ExpireTime}
		{
			return TRUE
		}

		return FALSE
	}
}


objectdef obj_TimedCallBack inherits obj_PulseTimer
{
	variable int Version
	variable string LogPrefix

	variable string CallBack
	variable string CallBackParams
	variable string RepeatCallBack = FALSE

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]
	}

	method SetCallBack(string _CallBack="", string _Params="", bool _Repeat=FALSE)
	{
		This.CallBack:Set[${_CallBack}]
		This.CallBackParams:Set[${_Params}]
		This.RepeatCallBack:Set[${_Repeat}]
	}

	method Start()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
	}

	method Stop()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Script.RunningTime} >= ${This.ExpireTime}
		{
			${${This.CallBack}}[${This.CallBackParams}]
			if !${This.RepeatCallBack}
			{
				This:Stop[]
			}
		}
	}
}

