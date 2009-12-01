#include ../core/defines.iss
#include ../core/obj_EVEDB.iss

/*
	EVE Database Thread

	Loads XML files containing EVE Database dumps.  Only threaded so that it reduces load time.

	-- CyberTech

*/

function main()
{
	/* EVE Database Exports */
	declarevariable EVEDB_Stations obj_EVEDB_Stations global
	declarevariable EVEDB_StationID obj_EVEDB_StationID global
	declarevariable EVEDB_Spawns obj_EVEDB_Spawns global
	declarevariable EVEDB_Items obj_EVEDB_Items global

	EVEBot.Threads:Insert[${Script.Filename}]
	while !${EVEBot.Loaded}
	{
		waitframe
	}
	while ${Script[EVEBot](exists)}
	{
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}