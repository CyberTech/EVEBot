variable string Version = 0.81x

function SetupHudStatus()
{
	;declare StatusLine1 string global "."
	;declare StatusLine2 string global "."
	;declare StatusLine3 string global "."
	;declare StatusLine4 string global "."
	;declare StatusLine5 string global "."
	;declare StatusLine6 string global "."
	;declare StatusLine7 string global "."
	;declare StatusLine8 string global "."
	;declare StatusLine9 string global "."
	;declare StatusLine10 string global "."
	;declare StatusLine11 string global "."
	;declare StatusLine12 string global "."
	;declare StatusLine13 string global "."
	;declare StatusLine14 string global "."
	;declare StatusLine15 string global "."
	;declare StatusLine16 string global "."
	;declare StatusLine17 string global "."
	;declare StatusLine18 string global "."
	;declare StatusLine19 string global "."
	;declare StatusLine20 string global "."
	;declare StatusLine21 string global "."
	;declare StatusLine22 string global "."
	;declare StatusLine23 string global "."
	;declare StatusLine24 string global "."
	;declare StatusLine25 string global "."
	redirect -append "./config/logs/OutputLog.txt" echo "-------------------------------------------------"
	redirect -append "./config/logs/OutputLog.txt" echo "  Evebot Session time ${Time.Date} at ${Time.Time24}  "
	redirect -append "./config/logs/OutputLog.txt" echo "  Evebot Session for  ${Me.Name} "
	redirect -append "./config/logs/OutputLog.txt" echo "-------------------------------------------------"

}

function UpdateHudStatus(string StatusMessage)
{
	;StatusLine25:Set["${StatusLine24}"]
	;StatusLine24:Set["${StatusLine23}"]
	;StatusLine23:Set["${StatusLine22}"]
	;StatusLine22:Set["${StatusLine21}"]
	;StatusLine21:Set["${StatusLine20}"]
	;StatusLine20:Set["${StatusLine19}"]
	;StatusLine19:Set["${StatusLine18}"]
	;StatusLine18:Set["${StatusLine17}"]
	;StatusLine17:Set["${StatusLine16}"]
	;StatusLine16:Set["${StatusLine15}"]
	;StatusLine15:Set["${StatusLine14}"]
	;StatusLine14:Set["${StatusLine13}"]
	;StatusLine13:Set["${StatusLine12}"]
	;StatusLine12:Set["${StatusLine11}"]
	;StatusLine11:Set["${StatusLine10}"]
	;StatusLine10:Set["${StatusLine9}"]
	;StatusLine9:Set["${StatusLine8}"]
	;StatusLine8:Set["${StatusLine7}"]
	;StatusLine7:Set["${StatusLine6}"]
	;StatusLine6:Set["${StatusLine5}"]
	;StatusLine5:Set["${StatusLine4}"]
	;StatusLine4:Set["${StatusLine3}"]
	;StatusLine3:Set["${StatusLine2}"]
	;StatusLine2:Set["${StatusLine1}"]
	;StatusLine1:Set["${Time}: ${StatusMessage}"]
	UIElement[EVEStatus@Main@EVEBotTab@EvEBot]:Echo["${Time}: ${StatusMessage}"]
	redirect -append "./config/logs/OutputLog.txt" Echo "[${Time.Time24}] ${StatusMessage}"

	#ifdef DEBUG
		call Debug "${StatusMessage}"
	#endif
}