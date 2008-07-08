/* Cache Objects */
#include core/obj_Cache.iss

/* Cache Objects */
variable(global) obj_Cache_Me _Me
variable(global) obj_Cache_EVETime _EVETime

function atexit()
{
	;redirect profile.txt Script:DumpProfiling
}

function main()
{
	;Script:Unsquelch
	;Script:EnableDebugLogging[debug.txt]
	;Script[EVEBot]:EnableProfiling

	/* Set Turbo to lowest value to try and avoid overloading the EVE Python engine */

	run EVEBot/EVEBot.iss
	wait 10
	while ${Script[EVEBot](exists)}
	{
		waitframe
	}
	echo "EVEBot exited, unloading EVEBotCache"
}
