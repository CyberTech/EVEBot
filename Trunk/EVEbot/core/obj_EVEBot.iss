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
	
	method Initialize()
	{
		if !${ISXEVE(exists)}
		{
			echo "ISXEVE must be loaded to use ${APP_NAME}."
			Script:End
		}
		echo "Starting ${Version}"
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_EVEBot: Initialized"]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if !${ISXEVE(exists)} || \
			${Login(exists)} || \
			${CharSelect(exists)}
		{
			echo "EVEBot: Out of game, exiting to launcher"
			run EVEBot/Launcher.iss
			Script:End
		}
		
		FrameCounter:Inc
		variable int IntervalInSeconds = 4
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			if !${This.ReturnToStation}
			{
				if (${This.GameHour} == 10 && \
					${This.GameMinute} >= 50) 
				{
					UI:UpdateConsole["EVE downtime approaching, pausing operations"]
					UI:ConsoleLog["EVE downtime approaching, pausing operations"]
					This.ReturnToStation:Set[TRUE]
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
