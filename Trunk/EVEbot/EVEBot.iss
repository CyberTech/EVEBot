#include core/defines.iss

/* unconverted files */
#include core/oCombat.iss
#include core/oSkills.iss
#include core/oSpace.iss
#include core/oCore.iss

/* Base Requirements */
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

/* Declare all script or global variables here */
variable bool play
variable string botstate
variable float GoalDistance
variable bool ForcedReturn

/* Script-Defined Support Objects */
variable obj_EVEBotUI UI
variable obj_Misc Misc
variable obj_Configuration Config
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_Skills Skills

/* Script-Defined Behavior Objects */
variable obj_Miner Miner
variable obj_OreHauler Hauler 
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
	;BotType:Set["Miner"]
	BotType:Set["Hauler"]
	variable int temp
	
  	while ${play}
	{
		;${BotType}:SetBotState not working
		
		Miner:SetBotState
		
		switch ${botstate}
		{
			case IDLE
				break
			case ABORT
				UI:UpdateConsole["Aborting operation: Returning to base"]
				Call Dock
				break
			case BASE
				call Cargo.TransferOreToHangar
				call Ship.Undock
				break
			case COMBAT
				UI:UpdateConsole["FIRE ZE MISSILES!!!"]
				call ShieldNotification
				break
			case MINE
				UI:UpdateConsole["Mining"]
				call Miner.Mine
				break
			case HAUL
				call UpdateHudStatus "Hauling"
				call Hauler.Haul
				break
			case CARGOFULL
				call Dock
				break
			case RUNNING
				call UpdateHudStatus "Running Away"
				call Dock
				ForcedReturn:Set[FALSE]
				break
		}
		
		wait 15
	}
}

atom(global) forcedreturn()
{
	/* echo "forcedreturn" */
	ForcedReturn:Set[TRUE]
}
