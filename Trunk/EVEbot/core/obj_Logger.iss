objectdef obj_Logger
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string LogFile
	variable string StatsLogFile
	variable string CriticalLogFile
	variable queue:string ConsoleBuffer
	variable string PreviousMsg

	variable bool Reloaded = FALSE

	method Initialize()
	{
		This.LogFile:Set["./config/logs/${Me.Name}.log"]
		This.CriticalLogFile:Set["./config/logs/${Me.Name}_Critical.log"]
		This.StatsLogFile:Set["./config/logs/${Me.Name}_Stats.log"]

		This:InitializeLogs
	}
	
	method LogIRC(string StatusMessage, int Level=LOG_STANDARD, int Indent=0)
	{
		This:Log["${StatusMessage}", ${Level}, ${Indent}]
		ChatIRC:QueueMessage["${StatusMessage}"]
	}

	method LogDebug(string StatusMessage)
	{
#if EVEBOT_DEBUG
		variable string msg
		msg:Set["DEBUG: "]
		msg:Concat["${StatusMessage}"]
		This:Log(${msg}, LOG_DEBUG, 0)
#endif						
	}
	
	method Log(string StatusMessage, int Level=LOG_STANDARD, int Indent=0)
	{
		/*
			Level = LOG_MINOR - Minor - Log, do not print to screen.
			Level = LOG_STANDARD - Standard, Log and Print to Screen
			Level = LOG_CRITICAL - Critical, Log, Log to Critical Log, and print to screen
			Level = LOG_ECHOTOO - Standard, Log, and print to screen
		*/
		variable string msg
		variable int Count
		variable bool Filter = FALSE

		if ${StatusMessage(exists)}
		{
			if ${Level} == LOG_DEBUG
			{
				if EVEBOT_DEBUG == 0
				{
					return
				}

				if ${String["All"].NotEqual[DEBUG_TARGET]} && !${StatusMessage.Token[1, " "].Find[DEBUG_TARGET](exists)}
				{
					return
				}
			}

			if ${StatusMessage.Equal["${This.PreviousMsg}"]}
			{
				Filter:Set[TRUE]
			}
			else
			{
				This.PreviousMsg:Set["${StatusMessage}"]
			}

			msg:Set["${Time.Time24}: "]

			for (Count:Set[1]; ${Count}<=${Indent}; Count:Inc)
			{
  				msg:Concat[" "]
  			}
  			msg:Concat["${StatusMessage}"]

			if ${This.Reloaded}
			{
				if ${Level} > LOG_MINOR && !${Filter}
				{
					UIElement[StatusConsole@Status@Tabs@EVEBot]:Echo["${msg}"]
				}

				if ${Level} == LOG_ECHOTOO
				{
					echo "${msg}"
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
				if ${Level} == LOG_ECHOTOO
				{
					echo "${msg}"
				}

				; Just queue the lines till we reload the UI after config data is loaded
				This.ConsoleBuffer:Queue["${msg}"]
			}
		}
	}

	; Dumps buffered log lines to the console
	method WriteQueue()
	{
		while ${This.ConsoleBuffer.Peek(exists)}
		{
			UIElement[StatusConsole@Status@Tabs@EVEBot]:Echo["${This.ConsoleBuffer.Peek}"]
			redirect -append "${This.LogFile}" Echo "${This.ConsoleBuffer.Peek}"
			This.ConsoleBuffer:Dequeue
		}
		This.Reloaded:Set[TRUE]
	}

	method UpdateStatStatus(string StatusMessage)
	{
		redirect -append "${This.StatsLogFile}" Echo "[${Time.Time24}] ${StatusMessage}"
	}

	method InitializeLogs()
	{
		redirect -append "${This.LogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.LogFile}" echo "** ${AppVersion} starting on ${Time.Date} at ${Time.Time24}"
		if EVEBOT_DEBUG == 1
		{
			redirect -append "${This.LogFile}" echo "** Debugging DEBUG_TARGET"
			redirect -append "${This.CriticalLogFile}" echo "** Debugging DEBUG_TARGET"
		}

		redirect -append "${This.CriticalLogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.CriticalLogFile}" echo "** ${AppVersion} starting on ${Time.Date} at ${Time.Time24}"

		This:Log["Starting ${AppVersion}"]

		redirect -append "${This.StatsLogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.StatsLogFile}" echo "** ${AppVersion} starting on ${Time.Date} at ${Time.Time24}"
	}
}