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
	variable bool Paused = FALSE
	variable time NextPulse
	variable int PulseIntervalInSeconds = 4

	variable index:being Buddies
	variable int BuddiesCount = 0
	variable int MAX_BUDDIES = 1
	variable int checkPulse = 0
	variable int MAXCHECKPULSE = 20

	
	method Initialize()
	{
		if !${ISXEVE(exists)}
		{
			echo "ISXEVE must be loaded to use ${APP_NAME}."
			Script:End
		}
		echo "Starting ${Version}"

		EVE:Execute[OpenPeopleAndPlaces]
		This.BuddiesCount:Set[${EVE.GetBuddies[This.Buddies]}]
		UI:UpdateConsole["Populating Buddies List:: ${This.BuddiesCount} buddies total"]
		TimedCommand 50 EVEWindow[addressbook]:Close
		
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_EVEBot: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if !${ISXEVE(exists)}
		{
			echo "EVEBot: Out of game"
			;run EVEBot/Launcher.iss charid or charname
			;Script:End
		}
		
	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
    		if ${Login(exists)} || \
    			${CharSelect(exists)}
    		{
    			echo "EVEBot: Out of game"
    			;run EVEBot/Launcher.iss charid or charname
    			;Script:End
    		}
		    
			checkPulse:Inc[1]
			; 20 pulses in this if loop is ~ 1 minute
			if (${checkPulse} >= ${MAXCHECKPULSE} && ${Me.InStation(exists)} && !${Me.InStation})
			{
				variable int BuddyCounter = 1

				;UI:UpdateConsole["DEBUG: Stacking cargo..."]
				;Call Ship.StackAll
				;UI:UpdateConsole["DEBUG: Checking buddies..."]
				if (${BuddiesCount} > 0)
				{
					do
					{       
						buddyTest:Set[${This.Buddies.Get[${BuddyCounter}].Name}]
						buddyOnline:Set[${This.Buddies.Get[${BuddyCounter}].IsOnline}]
						;UI:UpdateConsole["DEBUG: ${buddyTest} (Online: ${buddyOnline})"]
					}
					while ${BuddyCounter:Inc} <= ${This.MAX_BUDDIES}
				}       
				checkPulse:Set[0]
			}

			;UI:UpdateConsole["Interval ${checkPulse}"]
			if !${This.ReturnToStation} && ${Me.Name(exists)}
			{
				if (${This.GameHour} == 10 && \
					${This.GameMinute} >= 50) 
				{
					UI:UpdateConsole["EVE downtime approaching, pausing operations", LOG_CRITICAL]
					This.ReturnToStation:Set[TRUE]
				}
				elseif (${This.GameHour} == 10 && \
					${This.GameMinute} >= 58) 
				{
					UI:UpdateConsole["EVE downtime approaching - Quitting Eve", LOG_CRITICAL]
					EVE:Execute[CmdQuitGame]
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

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.IntervalInSeconds}]
    		This.NextPulse:Update
		}
	}
		
	method Pause()
	{
		UI:UpdateConsole["Paused", LOG_CRITICAL]
		This.Paused:Set[TRUE]
	}
	
	method Resume()
	{
		UI:UpdateConsole["Resumed", LOG_CRITICAL]
		This.Paused:Set[FALSE]
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
			return "${Math.Calc[${Meters} / 1000].Centi} km"
		}
		else
		{
			return "0"
		}
	}
}
