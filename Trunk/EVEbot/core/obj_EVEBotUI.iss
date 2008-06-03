
objectdef obj_EVEBotUI
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	;; global variables (used in UI display)
	variable string CharacterName
	variable string MyTarget
	variable string MyRace
	variable string MyCorp

	variable time NextPulse
	variable time NextMsgBoxPulse
	variable int PulseIntervalInSeconds = 4
	variable int PulseMsgBoxIntervalInSeconds = 15

	variable string LogFile
	variable string StatsLogFile
	variable string CriticalLogFile
	variable bool Reloaded = FALSE
	variable queue:string ConsoleBuffer
			
	method Initialize()
	{
		This.CharacterName:Set[${Me.Name}]
		This.MyRace:Set[${Me.ToPilot.Type}]
		This.MyCorp:Set[${Me.Corporation}]
		This.LogFile:Set["./config/logs/${Me.Name}.log"]
		This.CriticalLogFile:Set["./config/logs/${Me.Name}_Critical.log"]
		This.StatsLogFile:Set["./config/logs/${Me.Name}_Stats.log"]

		ui -load interface/eveskin/eveskin.xml
		ui -load interface/evebotgui.xml

		This:InitializeLogs

		Event[OnFrame]:AttachAtom[This:Pulse]
		This:UpdateConsole["obj_EVEBotUI: Initialized", LOG_MINOR]
	}

	method Reload()
	{
		ui -reload interface/evebotgui.xml
		This:WriteQueueToLog
		This.Reloaded:Set[TRUE]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
		ui -unload interface/evebotgui.xml
		ui -unload interface/eveskin/eveskin.xml
	}

	method Pulse()
	{	
	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
		    if ${Me.Name(exists)}
		    {
    			This:Update_Display_Values
		    }

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
			EVE:CloseAllMessageBoxes
			EVE:CloseAllChatInvites

			if ${Me.Name(exists)}
			{
				Config.Common:SetAutoLoginCharID[${Me.CharID}]
			}

    		This.NextMsgBoxPulse:Set[${Time.Timestamp}]
    		This.NextMsgBoxPulse.Second:Inc[${This.PulseMsgBoxIntervalInSeconds}]
    		This.NextMsgBoxPulse:Update
		}

	}

	method Update_Display_Values()
	{
 
		; Some variables just aren't going to change...they should be set initially and left alone
   
		if (${Me.ActiveTarget(exists)})
		{
			This.MyTarget:Set[${Me.ActiveTarget}]
		}
		else
		{
			This.MyTarget:Set[None]
		}
   }
   
	member Runtime()
	{
		DeclareVariable RunTime float ${Math.Calc[${Script.RunningTime}/1000/60]}
		
		DeclareVariable Hours string ${Math.Calc[(${RunTime}/60)%60].Int.LeadingZeroes[2]}
		DeclareVariable Minutes string ${Math.Calc[${RunTime}%60].Int.LeadingZeroes[2]}
		DeclareVariable Seconds string ${Math.Calc[(${RunTime}*60)%60].Int.LeadingZeroes[2]}
		
		return "${Hours}:${Minutes}:${Seconds}"
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
		
		if ${StatusMessage(exists)}
		{
			msg:Set["${Time.Time24}: "]
				
			for (Count:Set[1]; ${Count}<=${Indent}; Count:Inc)
			{
  				msg:Concat[" "]
  			}
  			msg:Concat[${StatusMessage}]
  				
			if ${This.Reloaded}
			{
				if ${Level} > LOG_MINOR
				{
					UIElement[StatusConsole@Status@EvEBotOptionsTab@EVEBot]:Echo[${msg}]
				}
				redirect -append "${This.LogFile}" Echo ${msg}
				if ${Level} == LOG_CRITICAL
				{
					redirect -append "${This.CriticalLogFile}" Echo ${msg}
				}
			}
			else
			{
				; Just queue the lines till we reload the UI after config data is loaded
				This.ConsoleBuffer:Queue[${msg}]
			}
		}
	}

	method WriteQueueToLog()
	{
		while ${This.ConsoleBuffer.Peek(exists)}
		{
			UIElement[StatusConsole@Status@EvEBotOptionsTab@EVEBot]:Echo[${This.ConsoleBuffer.Peek}]
			redirect -append "${This.LogFile}" Echo "${This.ConsoleBuffer.Peek}"
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
		redirect -append "${This.LogFile}" echo "** Evebot ${Version} starting on ${Time.Date} at ${Time.Time24}"

		redirect -append "${This.CriticalLogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.CriticalLogFile}" echo "** Evebot ${Version} starting on ${Time.Date} at ${Time.Time24}"

		This:UpdateConsole["Starting EVEBot ${Version}"]

		redirect -append "${This.StatsLogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.StatsLogFile}" echo "** Evebot ${Version} starting on ${Time.Date} at ${Time.Time24}"
	}	
}
