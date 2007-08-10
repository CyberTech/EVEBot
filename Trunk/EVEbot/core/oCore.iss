variable string Version = "EVEBot 0.93 $Rev$"


function UpdateHudStatus(string StatusMessage)
{
	UIElement[StatusConsole@Status@EvEBotOptionsTab@EVEBot]:Echo["${Time}: ${StatusMessage}"]
	redirect -append "./config/logs/OutputLog-${Me.Name}.txt" Echo "[${Time.Time24}] ${StatusMessage}"

	#ifdef DEBUG
		call Debug "${StatusMessage}"
	#endif
}



function UpdateStatStatus(string StatusMessage)
{
	redirect -append "./config/logs/StatsLog-${Me.Name}.txt" Echo "[${Time.Time24}] ${StatusMessage}"
}
