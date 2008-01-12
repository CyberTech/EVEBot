/*
	EVEBot class
	
	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.
	
	-- CyberTech
	
*/

objectdef obj_EVEBot
{
	variable bool ReturnToStation = FALSE
	variable bool Paused = FALSE
	variable int FrameCounter

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
		EVEWindow[addressbook]:Close
		
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_EVEBot: Initialized"]
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
		
		FrameCounter:Inc
		variable int IntervalInSeconds = 4
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
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
					UI:UpdateConsole["EVE downtime approaching, pausing operations"]
					This.ReturnToStation:Set[TRUE]
				}
				else
				{
					variable int Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int}

					;;; UI:UpdateConsole["DEBUG: ${Config.Common.MaxRuntime} ${Hours}"]
					if ${Config.Common.MaxRuntime} > 0 && ${Config.Common.MaxRuntime} <= ${Hours}
					{
						UI:UpdateConsole["Maximum runtime exceeded, pausing operations"]
						This.ReturnToStation:Set[TRUE]
					}
				}
			}
			FrameCounter:Set[0]
		}
	}
		
	method Pause()
	{
		UI:UpdateConsole["Paused"]
		This.Paused:Set[TRUE]
	}
	
	method Resume()
	{
		UI:UpdateConsole["Resumed"]
		This.Paused:Set[FALSE]
	}
	
	member:int GameHour()
	{
		variable string Hour = ${EVE.Time[short].Token[1, :]}
		variable int HourInt = ${Hour}	
		return ${HourInt}	
	}
	
	member:int GameMinute()
	{
		variable string Minute = ${EVE.Time[short].Token[2, :]}
		variable int MinuteInt = ${Minute}	
		return ${MinuteInt}	
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
