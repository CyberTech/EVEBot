/*
	EVEBot class

	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.

	-- CyberTech

*/

objectdef obj_EVEBot
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool ReturnToStation = FALSE
	variable bool _Paused = FALSE
	variable time NextPulse
	variable int PulseIntervalInSeconds = 4
	variable int LastSessionFrame
	variable bool LastSessionResult

	method Initialize()
	{
		This:SetVersion
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_EVEBot: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${This.SessionValid}
			{
				return
			}

    		if ${Login(exists)} || \
    			${CharSelect(exists)}
    		{
    			This:Pause["Error: At login or character select screens - EVEBot must be restarted after login"]
    			Script:Pause
    			;run EVEBot/Launcher.iss charid or charname
    		}

			if ${Display.Foreground}
			{
				if ${Config.Common.DisableUI}
				{
					if ${EVE.IsUIDisplayOn}
					{
						EVE:ToggleUIDisplay
						UI:UpdateConsole["Disabling UI Rendering"]
					}
				}
				elseif !${EVE.IsUIDisplayOn}
				{
					EVE:ToggleUIDisplay
					UI:UpdateConsole["Enabling UI Rendering"]
				}

				if ${Config.Common.Disable3D}
				{
					if ${EVE.Is3DDisplayOn}
					{
						EVE:Toggle3DDisplay
						UI:UpdateConsole["Disabling 3D Rendering"]
					}
				}
				elseif !${EVE.Is3DDisplayOn}
				{
					EVE:Toggle3DDisplay
					UI:UpdateConsole["Enabling 3D Rendering"]
				}
			}
			elseif ${Config.Common.DisableScreenWhenBackgrounded}
			{
				if ${EVE.IsUIDisplayOn}
				{
					EVE:ToggleUIDisplay
					UI:UpdateConsole["Background EVE: Disabling UI Rendering"]
				}
				if ${EVE.Is3DDisplayOn}
				{
					EVE:Toggle3DDisplay
					UI:UpdateConsole["Background EVE: Disabling 3D Rendering"]
				}
			}

			if !${This._Paused}
			{

				/*
					TODO
						[15:52] <CyberTechWork> the downtime check could be massively optimized
						[15:52] <CyberTechWork> by calcing how long till downtime and setting a timed event to call back
						[15:52] <CyberTechWork> don't know why we didn't think of that in the first place
				*/
				if !${This.ReturnToStation} && ${Me(exists)}
				{
					if ( ${This.GameHour} == 10 && \
						( ${This.GameMinute} >= 50 || ${This.GameMinute} <= 57) )
					{
						UI:UpdateConsole["EVE downtime approaching, pausing operations", LOG_CRITICAL]
						This.ReturnToStation:Set[TRUE]
					}
					else
					{
						variable int Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int}

						;;; UI:UpdateConsole["DEBUG: ${Config.Common.MaxRuntime} ${Hours}"]
						if ${Config.Common.MaxRuntime} > 0 && ${Config.Common.MaxRuntime} <= ${Hours}
						{
							UI:UpdateConsole["Maximum runtime exceeded, pausing operations", LOG_CRITICAL]
							This.ReturnToStation:Set[TRUE]
						}
					}
				}

				if ${This.ReturnToStation} && ${Me(exists)}
				{
					if (${This.GameHour} == 10 && ${This.GameMinute} >= 58)
					{
						UI:UpdateConsole["EVE downtime approaching - Quitting Eve", LOG_CRITICAL]
						EVE:Execute[CmdQuitGame]
					}
				}
			}

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

	member:bool SessionValid()
	{
		if ${This.LastSessionFrame} == ${Script.RunningTime}
		{
			return ${This.LastSessionResult}
		}
		if ${EVE(exists)} && ${MyShip(exists)}
		{
			This.LastSessionFrame:Set[${Script.RunningTime}]
			This.LastSessionResult:Set[TRUE]
			return TRUE
		}

		This.LastSessionFrame:Set[${Script.RunningTime}]
		This.LastSessionResult:Set[FALSE]
		return FALSE
	}

	member:bool Paused()
	{
		if ${This._Paused} || \
			${Script.Paused} || \
			!${This.SessionValid}
		{
			return TRUE
		}

		return FALSE
	}

	method Pause(string ErrMsg)
	{
		UI:UpdateConsole["${ErrMsg}", LOG_CRITICAL]
		This._Paused:Set[TRUE]
	}

	method Resume()
	{
		UI:UpdateConsole["Resumed", LOG_CRITICAL]
		This._Paused:Set[FALSE]
		Script:Resume
	}

	method SetVersion(int Version=${VersionNum})
	{
		if ${APP_HEADURL.Find["EVEBot/branches/stable"]}
		{
			AppVersion:Set["${APP_NAME} Stable Revision ${VersionNum}"]
		}
		else
		{
			AppVersion:Set["${APP_NAME} Dev Revision ${VersionNum}"]
		}
	}

	member:int GameHour()
	{
		variable string HourStr = ${_EVETime.Time}
		variable string Hour = 00

		if ${HourStr(exists)}
		{
			 Hour:Set[${HourStr.Token[1, :]}]
		}
		return ${Hour}
	}

	member:int GameMinute()
	{
		variable string MinuteStr = ${_EVETime.Time}
		variable string Minute = 18

		if ${MinuteStr(exists)}
		{
			 Minute:Set[${MinuteStr.Token[2, :]}]
		}
		return ${Minute}
	}

	member:string MetersToKM_Str(float64 Meters)
	{
		if ${Meters(exists)} && ${Meters} > 0
		{
			return "${Math.Calc[${Meters} / 1000].Centi}km"
		}
		else
		{
			return "0km"
		}
	}

	member:string ISK_To_Str(float64 Total)
	{
		if ${Total(exists)}
		{
			if ${Total} > 1000000000
			{
				return "${Math.Calc[${Total}/100000000].Precision[3]}b isk"
			}
			elseif ${Total} > 1000000
			{
				return "${Math.Calc[${Total}/1000000].Precision[2]}m isk"
			}
			elseif ${Total} > 1000
			{
				return "${Math.Calc[${Total}/1000].Round}k isk"
			}
			else
			{
				return "${Total.Round} isk"
			}
		}

		return "0 isk"
	}
}
