#include core/defines.iss

/* Base Requirements */
#include core/obj_EVEBot.iss
#include core/obj_Configuration.iss

/* Support File Includes */
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

/* Behavior/Mode Includes */
#include Behaviors/obj_Courier.iss
#include Behaviors/obj_StealthHauler.iss
#include Behaviors/obj_Hauler.iss
#include Behaviors/obj_Miner.iss
#include Behaviors/obj_Fighter.iss
#include Behaviors/obj_Freighter.iss
#include Behaviors/obj_Ratter.iss
#include Behaviors/obj_Scavenger.iss

/* Script-Defined Support Objects */
variable obj_EVEBot EVEBot
variable obj_EVEBotUI UI
variable obj_Configuration_BaseConfig BaseConfig
variable obj_Configuration Config
variable obj_Config_Whitelist Whitelist
variable obj_Config_Blacklist Blacklist
variable obj_EVEDB_Stations EVEDB_Stations
variable obj_EVEDB_Spawns EVEDB_Spawns

/* Core Objects */
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_Skills Skills
variable obj_Bookmarks Bookmarks
variable obj_JetCan JetCan
variable obj_CorpHangerArray CorpHangarArray
variable obj_Social Social
variable obj_Fleet Fleet
variable obj_Assets Assets
variable obj_IRC ChatIRC
variable obj_Safespots Safespots
variable obj_Belts Belts
variable obj_Targets Targets
variable obj_Sound Sound
variable obj_Agents Agents

/* Script-Defined Behavior Objects */
variable index:string BotModules
variable obj_Miner Miner
variable obj_OreHauler Hauler
variable obj_Freighter Freighter
variable obj_Ratter Ratter
;variable obj_Salvager Salvager

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
			
	UI:Reload
	UI:UpdateConsole["-=Paused: Press Run-="]
	Script:Pause
	
	while ${EVEBot.Paused}
	{
		wait 10
	}
	
	variable iterator BotModule
	BotModules:GetIterator[BotModule]
	
	while TRUE
	{
		if ${BotModule:First(exists)}
		do
		{
			while ${EVEBot.Paused}
			{
				wait 10
			}
			call ${BotModule.Value}.ProcessState
			wait 10
		}
		while ${BotModule:Next(exists)}
		waitframe
	}
}
