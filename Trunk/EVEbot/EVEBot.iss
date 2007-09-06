#include core/defines.iss

/* unconverted files */
#include core/oSpace.iss

/* Base Requirements */
#include core/obj_AutoPatcher.iss
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

/* Behavior/Mode Includes */
#include core/obj_Hauler.iss
#include core/obj_Miner.iss
#include core/obj_Fighter.iss

/* Declare all script or global variables here */
variable bool play = FALSE

/* Script-Defined Support Objects */
variable obj_EVEBotUI UI
variable obj_EVEBot EVEBot
variable obj_Configuration_BaseConfig BaseConfig
variable obj_Configuration Config
;variable obj_AutoPatcher AutoPatcher

/* Core Objects */
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_Skills Skills
variable obj_Combat Combat
variable obj_Bookmarks Bookmarks
variable obj_JetCan JetCan

/* Script-Defined Behavior Objects */
variable index:string BotModules
variable obj_Miner Miner
variable obj_OreHauler Hauler
variable obj_CombatFighter Fighter
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
	
	variable iterator BotModule
	BotModules:GetIterator[BotModule]
	
	while TRUE
	{
		if ${BotModule:First(exists)}
		do
		{
			call ${BotModule.Value}.ProcessState
			wait 10
			while !${play}
			{
				wait 10
			}
		}
		while ${BotModule:Next(exists)}
		waitframe
	}
}
