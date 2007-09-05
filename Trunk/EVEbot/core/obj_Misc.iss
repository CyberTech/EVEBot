/*
	Misc class
	
	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.
	
	-- CyberTech
	
*/

objectdef obj_Misc
{
	method Initialize()
	{
		UI:UpdateConsole["obj_Misc: Initialized"]
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
