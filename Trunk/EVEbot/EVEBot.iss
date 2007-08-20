#include core/defines.iss

/* unconverted files */
#include core/oCombat.iss
#include core/oSkills.iss
#include core/oSpace.iss

/* Base Requirements */
#include core/obj_AutoPatcher.iss
#include core/obj_Misc.iss
#include core/obj_Configuration.iss

/* Support File Includes */
#include core/obj_Asteroids.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss

/* Behavior/Mode Includes */
#include core/obj_Hauler.iss
#include core/obj_Miner.iss
#include core/obj_Combat.iss

/* Declare all script or global variables here */
variable bool play
variable float GoalDistance
variable bool ForcedReturn

/* This variable is updated by the bot classes and */
/* is used to display the current state on the UI. */
variable string botstate 

/* Script-Defined Support Objects */
variable obj_EVEBotUI UI
variable obj_Misc Misc
variable obj_Configuration Config
;variable obj_AutoPatcher AutoPatcher

/* Core Objects */
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_Skills Skills

/* Script-Defined Behavior Objects */
variable obj_Miner Miner
variable obj_OreHauler Hauler
variable obj_Combat Combat
;variable obj_Salvager Salvager

function atexit()
{
	;redirect profile.txt Script:DumpProfiling
}

function main()
{
	UI:Reload
	;Script:Unsquelch
	;Script:EnableDebugLogging[debug.txt]
	;Script[EVEBot]:EnableProfiling

	/* Set Turbo to lowest value to try and avoid overloading the EVE Python engine */
	Turbo 20
	if !${ISXEVE(exists)}
	{
		echo "ISXEVE must be loaded to use this script."
		return
	}
   
	while !${ISXEVE.IsReady}
	{
		waitframe
	}
		
	Ship:UpdateModuleList[]
	
	EVE:Execute[CmdStopShip]

	UI:UpdateConsole["-=Paused: Press Run-="]
	Script[EVEBot]:Pause

	play:Set[TRUE]

	variable string BotType
	BotType:Set["Miner"]
	;BotType:Set["Hauler"]
	
	/* This is the main processing loop for EVEBOT  */
	/* Please do not add bot logic here.  It should */
	/* be encapulated in a bot class instead.       */
  	while ${play}
	{
		call ${BotType}.ProcessState
		wait 15
	}
}

atom(global) forcedreturn()
{
	/* echo "forcedreturn" */
	ForcedReturn:Set[TRUE]
}
