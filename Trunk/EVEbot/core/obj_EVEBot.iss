/*
	EVEBot class
	
	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.
	
	-- CyberTech
	
*/

objectdef obj_EVEBot
{
	variable bool ReturnToStation = FALSE
	variable bool Paused = FALSE
	
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_EVEBot: Initialized"]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		FrameCounter:Inc
		variable int IntervalInSeconds = 4
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			if !${This.ReturnToStation}
			{
				if (${This.GameHour} == 10 && \
					${This.GameMinute} >= 50) 
				{
					UI:ConsoleLog["EVE downtime approaching, pausing operations"]
					This.ReturnToStation:Set[TRUE]
				}
			}
			FrameCounter:Set[0]
		}
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
