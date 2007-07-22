variable string Version = 0.899.1 - .90

function SetupHudStatus()
{
	redirect -append "./config/logs/OutputLog.txt" echo "-------------------------------------------------"
	redirect -append "./config/logs/OutputLog.txt" echo "  Evebot Session time ${Time.Date} at ${Time.Time24}  "
	redirect -append "./config/logs/OutputLog.txt" echo "  Evebot Session for  ${Me.Name} "
	redirect -append "./config/logs/OutputLog.txt" echo "-------------------------------------------------"

}

function UpdateHudStatus(string StatusMessage)
{
	UIElement[EVEStatus@Main@EVEBotTab@EvEBot]:Echo["${Time}: ${StatusMessage}"]
	redirect -append "./config/logs/OutputLog.txt" Echo "[${Time.Time24}] ${StatusMessage}"

	#ifdef DEBUG
		call Debug "${StatusMessage}"
	#endif
}
