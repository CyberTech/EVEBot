/*
	EVEBot class

	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.

	-- CyberTech

*/

objectdef obj_EVEBot inherits obj_BaseClass
{
	variable bool ReturnToStation = FALSE
	variable bool _Paused = TRUE						/* Initialize to true so that other modules see the bot as paused before we actually pause the script */
	variable bool Disabled = FALSE					/* If true, ALL functionality should be disabled  - everything. no pulses, no nothing */
	variable bool Loaded = FALSE						/* Set true once the bot is fully loaded */
	variable int LastSessionFrame
	variable bool LastSessionResult
	variable index:string Threads

	; My master variables
	variable obj_PulseTimer LastMasterQuery
	variable string MasterName
	variable bool IsMaster=FALSE

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		PulseTimer:SetIntervals[4.0,5.0]
		This:SetVersion

		LavishScript:RegisterEvent[EVENT_EVEBOT_ONFRAME]
		LavishScript:RegisterEvent[EVENT_EVEBOT_ONFRAME_INSPACE]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		LavishScript:RegisterEvent[EVEBot_Master_Query]
		Event[EVEBot_Master_Query]:AttachAtom[This:Event_Master_Query]

		LavishScript:RegisterEvent[EVEBot_Master_Notify]
		Event[EVEBot_Master_Notify]:AttachAtom[This:Event_Master_Notify]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		if ${Config.Miner.MasterMode}
		{
			relay all -event EVEBot_Master_Notify ""
		}

		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_Master_Query]:AttachAtom[This:Event_Master_Query]
		Event[EVEBot_Master_Notify]:DetachAtom[This:Event_Master_Notify]
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
			;ISXEVE:Debug_LogMsg["${This.LogPrefix}", "============================================= Pulse Start"]
			;if !${ISXEVE.IsSafe}
			;{
			;	This.PulseTimer:Update
			;	ISXEVE:Debug_LogMsg["${This.LogPrefix}", "============================================= Pulse End"]
			;	return
			;}

			if ${Config.Miner.GroupMode}
			{
				if ${This.MasterName.Length} == 0 && ${This.LastMasterQuery.Ready}
				{
					This.LastMasterQuery:SetIntervals[5.0,5.0]
					This.LastMasterQuery:Update
					relay all -event EVEBot_Master_Query
				}
			}

			if (${Config.Common.DisableUI} || (${Config.Common.DisableScreenWhenBackgrounded} && !${Display.Foreground})) && ${EVE.IsUIDisplayOn}
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
				if (${Config.Common.Disable3D} || (${Config.Common.DisableScreenWhenBackgrounded} && !${Display.Foreground})) && ${EVE.Is3DDisplayOn}
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

				;if ${Me.InSpace} && !${Station.Docked}
				;{
				;	Event[EVENT_EVEBOT_ONFRAME_INSPACE]:Execute
				;}

				; Call Pulse here, to avoid each Behavior triggering on pulse
				;${Config.Common.Behavior}:Pulse
				;Event[EVENT_EVEBOT_ONFRAME]:Execute

			}

			This.PulseTimer:Update
			;ISXEVE:Debug_LogMsg["${This.LogPrefix}", "============================================= Pulse End"]
		}
	}

	member:bool Paused()
	{
		if ${This._Paused} || \
			${Script.Paused}
		{
			return TRUE
		}

		if !${ISXEVE.IsSafe}
		{
			return TRUE
		}

		return FALSE
	}

	method Pause(string Reason)
	{
		This._Paused:Set[TRUE]
		This:PauseThreads
		Logger:Log["\agPaused\ax: ${Reason}", LOG_ECHOTOO]
		Script:Pause
	}

	method PauseThreads()
	{
		variable int i
		for (i:Set[1]; ${i} <= ${Threads.Used}; i:Inc)
		{
			Logger:Log[" Pausing ${Threads.Get[${i}]} thread..."]
			Script[${Threads.Get[${i}]}]:Pause
		}
	}

	method Resume(string Reason)
	{
		This.ReturnToStation:Set[FALSE]
		Script:Resume
		This:ResumeThreads
		This._Paused:Set[FALSE]

		Logger:Log["Resumed: ${Reason}", LOG_ECHOTOO]
	}

	method ResumeThreads()
	{
		variable int i
		for (i:Set[1]; ${i} <= ${Threads.Used}; i:Inc)
		{
			Logger:Log[" Resuming ${Threads.Get[${i}]} thread..."]
			Script[${Threads.Get[${i}]}]:Resume
		}
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

	function WaitForNavigator()
	{
		variable int Counter = 0

		while ${Navigator.Busy}
		{
			Logger:Log["EVEBot: Waiting for Navigator ${Navigator.Destinations.Peek.ToString} ${Counter}"]
			Counter:Inc[1]
			if (${Counter} > 40)
			{
				Logger:Log["Warning: Still waiting after ${Counter} iterations", LOG_CRITICAL]
				Counter:Set[0]
			}
			wait 5
		}
	}

	;This method is triggered by an event.  If triggered, lets Us figure out who is the master in group mode.
	method Event_Master_Notify(string MasterClaimer)
	{
		/*
			If I sent the message, process it.
			If it came from someone else, see if it conflicts with my UI settings. Only one mater is allowed
			Otherwise, accept the master designation
		 */
		if ${Me.Name.Equal[${MasterClaimer}]}
		{
			IsMaster:Set[TRUE]
			MasterName:Set[${Me.Name}]
			Logger:Log["${LogPrefix}: I am Master"]
		}
		else
		{
			MasterName:Set[${MasterClaimer}]
			if ${Config.Miner.MasterMode}
			{
				Logger:Log["${LogPrefix}: Hard Stop - There can be only one Master ERROR:${MasterClaimer} claims my role!", LOG_ERROR]
				This.CurrentState:Set["HARDSTOP"]
				relay all -event EVEBot_HARDSTOP "${Me.Name} - ${Config.Common.CurrentBehavior} (MasterConfigError)"
			}
			else
			{
				MasterName:Set[${MasterClaimer}]
				IsMaster:Set[FALSE]
				if ${MasterClaimer.Length} == 0
				{
					Logger:Log["${LogPrefix}: Fleet master unset"]
				}
				else
				{
					Logger:Log["${LogPrefix}: Fleet master set to '${MasterName}'"]
				}
			}
		}
	}

	; Someone is asking who the master is
	method Event_Master_Query()
	{
		if ${Config.Miner.MasterMode}
		{
			relay all -event EVEBot_Master_Notify "${Me.Name}"
		}
	}

}
