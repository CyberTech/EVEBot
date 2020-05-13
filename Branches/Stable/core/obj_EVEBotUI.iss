
objectdef obj_EVEBotUI
{
	variable time NextPulse
	variable time NextMsgBoxPulse
	variable int PulseIntervalInSeconds = 60
	variable int PulseMsgBoxIntervalInSeconds = 15

	variable string LogFile
	variable string StatsLogFile
	variable string CriticalLogFile
	variable bool Reloaded = FALSE
	variable queue:string ConsoleBuffer
	variable string PreviousMsg

	method Initialize()
	{
		declare FP filepath "${Script.CurrentDirectory}"
		if !${FP.FileExists["Config"]}
		{
			FP:MakeSubdirectory["Config"]
		}
		FP:Set["${Script.CurrentDirectory}/Config"]
		if !${FP.FileExists["Logs"]}
		{
			FP:MakeSubdirectory["Logs"]
		}
		This.LogFile:Set["./Config/Logs/${Me.Name}.log"]
		This.CriticalLogFile:Set["./Config/Logs/${Me.Name}_Critical.log"]
		This.StatsLogFile:Set["./Config/Logs/${Me.Name}_Stats.log"]

		ui -load interface/eveskin/eveskin.xml
		ui -load interface/evebotgui.xml

		This:InitializeLogs
		This:LogSystemStats

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This:UpdateConsole["obj_EVEBotUI: Initialized", LOG_MINOR]
	}

	method Reload()
	{
		ui -reload interface/evebotgui.xml
		This:WriteQueueToLog
		This.Reloaded:Set[TRUE]

		if ${UIElement[EVEBot].X} <= -${Math.Calc[${UIElement[EVEBot].Width} * 0.66].Int} || \
			${UIElement[EVEBot].X} >= ${Math.Calc[${Display.Width} - ${UIElement[EVEBot].Width}]}
		{
			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${UIElement[EVEBot].X} > ${Display.Width}"
			echo "    You may fix this with 'UIElement[EVEbot]:SetX[${Math.Calc[${Display.Width}/2].Int}]"
			echo "----"
		}

		if ${UIElement[EVEBot].Y} <= 1 || \
			${UIElement[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${UIElement[EVEBot].Height}]}
		{
			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${UIElement[EVEBot].Y} > ${Display.Height}"
			echo "    You may fix this with 'UIElement[EVEbot]:SetY[${Math.Calc[${Display.Height}/2].Int}]"
			echo "----"
		}
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		ui -unload interface/evebotgui.xml
		ui -unload interface/eveskin/eveskin.xml
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
    		This:LogSystemStats
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}

		if ${EVEBot.Paused}
		{
			return
		}

	    if ${Time.Timestamp} > ${This.NextMsgBoxPulse.Timestamp}
		{
			if ${EVEWindow[ByName, "modal"].Text.Find["The daily downtime will begin in"](exists)}
			{
				EVEWindow[ByName, "modal"]:ClickButtonOK
			}
			EVE:CloseAllMessageBoxes
			EVE:CloseAllChatInvites

			if ${Me(exists)}
			{
				Config.Common:SetAutoLoginCharID[${Me.CharID}]
			}

    		This.NextMsgBoxPulse:Set[${Time.Timestamp}]
    		This.NextMsgBoxPulse.Second:Inc[${This.PulseMsgBoxIntervalInSeconds}]
    		This.NextMsgBoxPulse:Update
		}

	}

	method LogSystemStats()
	{
		;This:UpdateConsole["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024].Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}

	member Runtime()
	{
		DeclareVariable RunTime float ${Math.Calc[${Script.RunningTime}/1000/60]}

		DeclareVariable Hours string ${Math.Calc[(${RunTime}/60)%60].Int.LeadingZeroes[2]}
		DeclareVariable Minutes string ${Math.Calc[${RunTime}%60].Int.LeadingZeroes[2]}
		DeclareVariable Seconds string ${Math.Calc[(${RunTime}*60)%60].Int.LeadingZeroes[2]}

		return "${Hours}:${Minutes}:${Seconds}"
	}

	method UpdateConsoleIRC(string StatusMessage, int Level=LOG_STANDARD, int Indent=0)
	{
		This:UpdateConsole["${StatusMessage}", ${Level}, ${Indent}]
		ChatIRC:QueueMessage["${StatusMessage}"]
	}

	method UpdateConsole(string StatusMessage, int Level=LOG_STANDARD, int Indent=0)
	{
		/*
			Level = LOG_MINOR - Minor - Log, do not print to screen.
			Level = LOG_STANDARD - Standard, Log and Print to Screen
			Level = LOG_CRITICAL - Critical, Log, Log to Critical Log, and print to screen
		*/
		variable string msg
		variable int Count
		variable bool Filter = FALSE

		if ${StatusMessage(exists)}
		{
			if ${StatusMessage.Escape.Equal["${This.PreviousMsg.Escape}"]}
			{
				Filter:Set[TRUE]
			}
			else
			{
				This.PreviousMsg:Set["${StatusMessage.Escape}"]
			}

			msg:Set["${Time.Time24}: "]

			for (Count:Set[1]; ${Count}<=${Indent}; Count:Inc)
			{
  				msg:Concat[" "]
  			}
  			msg:Concat["${StatusMessage.Escape}"]

			if ${This.Reloaded}
			{
				if ${Level} > LOG_MINOR && !${Filter}
				{
					UIElement[StatusConsole@Status@EvEBotOptionsTab@EVEBot]:Echo["${msg}"]
				}
				redirect -append "${This.LogFile}" Echo "${msg}"
				if ${Level} == LOG_CRITICAL
				{
					ChatIRC:QueueMessage["${msg}"]
					redirect -append "${This.CriticalLogFile}" Echo "${msg}"
				}
			}
			else
			{
				; Just queue the lines till we reload the UI after config data is loaded
				This.ConsoleBuffer:Queue["${msg}"]
			}
		}
	}

	method WriteQueueToLog()
	{
		while ${This.ConsoleBuffer.Peek(exists)}
		{
			UIElement[StatusConsole@Status@EvEBotOptionsTab@EVEBot]:Echo[${This.ConsoleBuffer.Peek.Escape}]
			redirect -append "${This.LogFile}" Echo "${This.ConsoleBuffer.Peek.Escape}"
			This.ConsoleBuffer:Dequeue
		}
	}

	method UpdateStatStatus(string StatusMessage)
	{
		redirect -append "${This.StatsLogFile}" Echo "[${Time.Time24}] ${StatusMessage}"
	}

	method InitializeLogs()
	{

		redirect -append "${This.LogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.LogFile}" echo "** ${AppVersion} starting on ${Time.Date} at ${Time.Time24}"

		redirect -append "${This.CriticalLogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.CriticalLogFile}" echo "** ${AppVersion} starting on ${Time.Date} at ${Time.Time24}"

		This:UpdateConsole["Starting ${AppVersion}"]

		redirect -append "${This.StatsLogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.StatsLogFile}" echo "** ${AppVersion} starting on ${Time.Date} at ${Time.Time24}"
	}
}
