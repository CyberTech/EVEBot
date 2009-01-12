#include core/defines.iss

/* Base Requirements */
#include core/obj_EVEBot.iss
#include core/obj_Configuration.iss

/* Cache Objects */
#include core/obj_Cache.iss

/* Support File Includes */
#include core/obj_BaseClass.iss
#include core/obj_EVEDB.iss
#include core/obj_Skills.iss
#include core/obj_Asteroids.iss
#include core/obj_Drones.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss
#include core/obj_Bookmarks.iss
#include core/obj_Jetcan.iss
#include core/obj_Social.iss
#include core/obj_Gang.iss
#include core/obj_Assets.iss
#include core/obj_IRC.iss
#include core/obj_Safespots.iss
#include core/obj_Belts.iss
#include core/obj_Targets.iss
#include core/obj_Sound.iss
#include core/obj_Agents.iss
#include core/obj_Combat.iss
#include core/obj_Missions.iss
#include core/obj_Market.iss
#include core/obj_Items.iss
#include core/obj_Autopilot.iss

/* Behavior/Mode Includes */
#include Behaviors/obj_Courier.iss
#include Behaviors/obj_StealthHauler.iss
#include Behaviors/obj_Hauler.iss
#include Behaviors/obj_Miner.iss
#include Behaviors/obj_Freighter.iss
#include Behaviors/obj_Ratter.iss
#include Behaviors/obj_Scavenger.iss
#include Behaviors/obj_Missioneer.iss

/* All variables that would normally be defined script scope should be defined global scope to simplify threads */

/* Cache Objects */
variable(global) obj_Cache_Me _Me
variable(global) obj_Cache_EVETime _EVETime

/* Script-Defined Support Objects */
variable(global) obj_EVEBot EVEBot
variable(global) obj_EVEBotUI UI
variable(global) obj_Configuration_BaseConfig BaseConfig
variable(global) obj_Configuration Config
variable(global) obj_Config_Whitelist Whitelist
variable(global) obj_Config_Blacklist Blacklist

/* EVE Database Exports */
variable(global) obj_EVEDB_Stations EVEDB_Stations
variable(global) obj_EVEDB_StationID EVEDB_StationID
variable(global) obj_EVEDB_Spawns EVEDB_Spawns
variable(global) obj_EVEDB_Items EVEDB_Items

/* Core Objects */
variable(global) obj_Asteroids Asteroids
variable(global) obj_Ship Ship
variable(global) obj_Station Station
variable(global) obj_Cargo Cargo
variable(global) obj_Skills Skills
variable(global) obj_Bookmarks Bookmarks
variable(global) obj_JetCan JetCan
variable(global) obj_CorpHangerArray CorpHangarArray
variable(global) obj_Social Social
variable(global) obj_Fleet Fleet
variable(global) obj_Assets Assets
variable(global) obj_IRC ChatIRC
variable(global) obj_Safespots Safespots
variable(global) obj_Belts Belts
variable(global) obj_Targets Targets
variable(global) obj_Sound Sound
variable(global) obj_Agents Agents
variable(global) obj_Missions Missions
variable(global) obj_Market Market
variable(global) obj_Autopilot Autopilot

/* Script-Defined Behavior Objects */
variable(global) index:string BotModules
variable(global) obj_Miner Miner
variable(global) obj_OreHauler Hauler
variable(global) obj_Freighter Freighter
variable(global) obj_Ratter Ratter
variable(global) obj_Missioneer Missioneer

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
	Turbo 20

	runscript Threads/Targeting.iss
	runscript Threads/Defense.iss
	runscript Threads/Offense.iss

	variable iterator BotModule
	BotModules:GetIterator[BotModule]

	variable iterator VariableIterator
	VariableScope:GetIterator[VariableIterator]

	/* 	This code iterates thru the variables list, looking for classes that have been
		defined with an SVN_REVISION variable.  It then converts that to a numeric
		Version(int), which is then used to calculate the highest version (VersionNum),
		for display on the UI. -- CyberTech
	*/
	;echo "Listing EVEBot Class Versions:"
	if ${VariableIterator:First(exists)}
	do
	{

		if ${VariableIterator.Value(exists)} && \
			${VariableIterator.Value(type).Name.Left[4].Equal["obj_"]} && \
			${VariableIterator.Value.SVN_REVISION(exists)} && \
			${VariableIterator.Value.Version(exists)}
		{
			VariableIterator.Value.Version:Set[${VariableIterator.Value.SVN_REVISION.Token[2, " "]}]
			;echo " ${VariableIterator.Value.ObjectName} Revision ${VariableIterator.Value.Version}"
			if ${VersionNum} < ${VariableIterator.Value.Version}
			{
				VersionNum:Set[${VariableIterator.Value.Version}]
			}
		}
	}
	while ${VariableIterator:Next(exists)}
	AppVersion:Set["${APP_NAME} Version ${VersionNum}"]

	UI:Reload


#if USE_ISXIRC
	call ChatIRC.Connect
#endif

	UI:UpdateConsole["-=Paused: Press Run-="]
	Script:Pause

	while ${EVEBot.Paused}
	{
		wait 10
	}

	while TRUE
	{
		if ${BotModule:First(exists)}
		do
		{
			while ${EVEBot.Paused}
			{
				wait 10
			}
			echo "call ${BotModule.Value}.ProcessState"
			call ${BotModule.Value}.ProcessState
			waitframe
		}
		while ${BotModule:Next(exists)}
	}
}
