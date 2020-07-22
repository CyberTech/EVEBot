/*
	EVEBot class

	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.

	-- CyberTech

*/

objectdef obj_EVEBot inherits obj_BaseClass
{
	variable bool ReturnToStation = FALSE
	variable bool _Paused = FALSE
	variable bool Disabled = FALSE			/* If true, ALL functionality should be disabled  - everything. no pulses, no nothing */
	variable bool Loaded					/* Set true once the bot is fully loaded */
	variable int LastSessionFrame
	variable bool LastSessionResult
	variable index:string Threads

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		PulseTimer:SetIntervals[4.0,5.0]
		This:SetVersion

		LavishScript:RegisterEvent[EVENT_EVEBOT_ONFRAME]
		LavishScript:RegisterEvent[EVENT_EVEBOT_ONFRAME_INSPACE]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method EndBot()
	{
		Logger:Log["\aoEVEBot\ax shutting down...", LOG_ECHOTOO]

		variable int i
		for (i:Set[1]; ${i} <= ${Threads.Used}; i:Inc)
		{
			Logger:Log[" Stopping ${Threads.Get[${i}]} thread...",LOG_ECHOTOO]
			if ${Script[${Threads.Get[${i}]}](exists)}
			{
				endscript ${Threads.Get[${i}]}
			}
		}
		Logger:Log[" Shutdown complete", LOG_ECHOTOO]
		Script:End
	}

	method Pulse()
	{
		if !${This.Loaded} || ${This.Disabled}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			ISXEVE:Debug_LogMsg["${This.LogPrefix}", "============================================= Pulse Start"]
			if !${This.SessionValid}
			{
				This.PulseTimer:Update
				ISXEVE:Debug_LogMsg["${This.LogPrefix}", "============================================= Pulse End"]
				return
			}

			if (${Config.Common.DisableUI} || (${Config.Common.DisableScreenWhenBackgrounded} && !${Display.Foreground})) && \
				${EVE.IsUIDisplayOn}
			{
				EVE:ToggleUIDisplay
				Logger:Log["Disabling UI Rendering"]
			}
			elseif !${Config.Common.DisableUI} && !${EVE.IsUIDisplayOn}
			{
				EVE:ToggleUIDisplay
				Logger:Log["Enabling UI Rendering"]
			}

			; TODO - ISXEVE Bug - 3D disable only works in space 2011/07/17
			if ${Me.InSpace}
			{
				if (${Config.Common.Disable3D} || (${Config.Common.DisableScreenWhenBackgrounded} && !${Display.Foreground})) && \
					${EVE.Is3DDisplayOn}
				{
					EVE:Toggle3DDisplay
					Logger:Log["Disabling 3D Rendering"]
				}
				elseif !${Config.Common.Disable3D} && !${EVE.Is3DDisplayOn}
				{
					EVE:Toggle3DDisplay
					Logger:Log["Enabling 3D Rendering"]
				}
			}

			if !${This._Paused}
			{
				if ${EVEWindow[ByName,modal].Text.Find["The daily downtime will begin in"](exists)}
				{
					EVEWindow[ByName,modal]:ClickButtonOK
				}
				EVE:CloseAllMessageBoxes
				EVE:CloseAllChatInvites

				/*
					TODO
						[15:52] <CyberTechWork> the downtime check could be massively optimized
						[15:52] <CyberTechWork> by calcing how long till downtime and setting a timed event to call back
						[15:52] <CyberTechWork> don't know why we didn't think of that in the first place
				*/
				if !${This.ReturnToStation} && ${Me(exists)}
				{
					if ( ${This.GameHour} == 10 && \
						( ${This.GameMinute} >= 50 && ${This.GameMinute} <= 57) )
					{
						Logger:Log["EVE downtime approaching, pausing operations", LOG_CRITICAL]
						This.ReturnToStation:Set[TRUE]
					}
					else
					{
						variable int Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int}

						;;; Logger:Log["DEBUG: ${Config.Common.MaxRuntime} ${Hours}"]
						if ${Config.Common.MaxRuntime} > 0 && ${Config.Common.MaxRuntime} <= ${Hours}
						{
							Logger:Log["Maximum runtime exceeded, pausing operations", LOG_CRITICAL]
							This.ReturnToStation:Set[TRUE]
						}
					}
				}

				if ${Me.InSpace} && !${Station.Docked}
				{
					Event[EVENT_EVEBOT_ONFRAME_INSPACE]:Execute
				}

				Event[EVENT_EVEBOT_ONFRAME]:Execute

			}

			This.PulseTimer:Update
			ISXEVE:Debug_LogMsg["${This.LogPrefix}", "============================================= Pulse End"]
		}
	}

	member:bool SessionValid()
	{
		if ${This.LastSessionFrame} == ${Script.RunningTime}
		{
			return ${This.LastSessionResult}
		}

		if ${ISXEVE.IsSafe} && (${Me.InSpace} || ${Me.InStation})
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
			${Script.Paused}
		{
			return TRUE
		}

		if !${This.SessionValid}
		{
			return TRUE
		}

		return FALSE
	}

	method Pause(string Reason)
	{
		Logger:Log["\agPaused\ax: ${Reason}", LOG_ECHOTOO]
		This._Paused:Set[TRUE]
		Script:Pause
	}

	method Resume(string Reason)
	{
		Logger:Log["Resumed: ${Reason}", LOG_ECHOTOO]
		This._Paused:Set[FALSE]
		Script:Resume
	}

	method SetVersion(int Version=${VersionNum})
	{
		declarevariable tmpstr string
		if EVEBOT_DEBUG == 1
		{
			tmpstr:Set[" - Debugging (Objects: DEBUG_TARGET)"]
		}
		AppVersion:Set["${APP_NAME} Stable Revision${tmpstr}"]
		; TODO - pull branch out of Script.CurrentDirectory path
		;if ${APP_HEADURL.Find["EVEBot/branches/stable"]}
		;{
		;	AppVersion:Set["${APP_NAME} Stable Revision ${VersionNum}"]
		;}
		;else
		;{
		;	AppVersion:Set["${APP_NAME} Dev Revision ${VersionNum}"]
		;}
	}

	member:int GameHour()
	{
		variable string HourStr = ${EVETime.Time}
		variable string Hour = 00

		if ${HourStr(exists)}
		{
			 Hour:Set[${HourStr.Token[1, :]}]
		}
		return ${Hour}
	}

	member:int GameMinute()
	{
		variable string MinuteStr = ${EVETime.Time}
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

	member Runtime()
	{
		/* TODO - this is expensive (4-5fps for me), replace with something better -- CyberTech */
		DeclareVariable RunTime float ${Math.Calc[${Script.RunningTime}/1000/60]}

		DeclareVariable Hours string ${Math.Calc[(${RunTime}/60)%60].Int.LeadingZeroes[2]}
		DeclareVariable Minutes string ${Math.Calc[${RunTime}%60].Int.LeadingZeroes[2]}
		DeclareVariable Seconds string ${Math.Calc[(${RunTime}*60)%60].Int.LeadingZeroes[2]}

		return "${Hours}:${Minutes}:${Seconds}"
	}
}
