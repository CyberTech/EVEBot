#include core/defines.iss

/* unconverted files */
#include core/oSpace.iss

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
#include core/obj_Combat.iss
#include core/obj_Bookmarks.iss
#include core/obj_Jetcan.iss
#include core/obj_Social.iss
#include core/obj_Gang.iss
#include core/obj_Target.iss
#include core/obj_Assets.iss
#include core/obj_IRC.iss
#include core/obj_Safespots.iss

/* Behavior/Mode Includes */
#include core/obj_Hauler.iss
#include core/obj_Miner.iss
#include core/obj_Fighter.iss
#include core/obj_Freighter.iss
#include core/obj_Ratter.iss

/* Script-Defined Support Objects */
variable obj_EVEBot EVEBot
variable obj_EVEBotUI UI
variable obj_Configuration_BaseConfig BaseConfig
variable obj_Configuration Config
variable obj_Config_Whitelist Whitelist

/* Core Objects */
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_Skills Skills
variable obj_Combat Combat
variable obj_Bookmarks Bookmarks
variable obj_JetCan JetCan
variable obj_CorpHangerArray CorpHangarArray
variable obj_Social Social
variable obj_Fleet Fleet
variable obj_Assets Assets
variable obj_IRC ChatIRC
variable obj_Safespots Safespots

/* Script-Defined Behavior Objects */
variable index:string BotModules
variable obj_Miner Miner
variable obj_OreHauler Hauler
variable obj_CombatFighter Fighter
variable obj_Freighter Freighter
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
