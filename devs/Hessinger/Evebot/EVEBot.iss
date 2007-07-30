#include core/defines.iss

#include core/oCombat.iss
#include core/oSkills.iss
#include core/oSpace.iss
#include core/oMining.iss
#include core/oCore.iss

#include core/obj_Configuration.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_Hauler.iss
#include core/obj_EVEBotUI.iss
#include core/obj_Combat.iss

;; Declare all script or global variables here
variable bool play
variable string botstate
variable float GoalDistance
variable obj_Skills Skills

; Script-Defined Objects
variable obj_EVEBotUI UI
variable obj_Configuration Config
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_Miner Miner
variable obj_Combat Combat
;variable obj_Salvager Salvager

function LoadEvebotGUI()
{
	call SetupHudStatus
	call UpdateHudStatus "Starting EVEBot ${Version}."
	call SetupStatStatus
	call UpdateStatStatus "Starting EVEBot ${Version}."
	wait 20 ${UIElement[evebot](exists)}
}

function atexit()
{
	;redirect profile.txt Script:DumpProfiling
}

function SetBotState()
{
	
	if ${Miner.Abort} && !${Me.InStation}
	{
		botstate:Set["ABORT"]
		return
	}

	if ${Miner.Abort}
	{
		botstate:Set["IDLE"]
		return
	}
	
	if ${Me.InStation}
	{
	  botstate:Set["BASE"]
	  return
	}
	
	if ${Math.Calc[(${Me.Ship.ShieldPct} + ${Me.Ship.ArmorPct})/2]} < 20
	{
		botstate:Set["REPAIR"]
		return
	}

	;Not even sure why this was still here -.- Hessinger
	;if (${Me.ToEntity.ShieldPct} < 99)
	;{
	;	botstate:Set["COMBAT"]
	;	return
	;}
	
	if ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
	{
	 	botstate:Set["MINE"]
		return
	}
	
	if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${ForcedSell}
	{
		botstate:Set["CARGOFULL"]
		return
	}

	botstate:Set["None"]
}

function main()
{
	;Script:Unsquelch
	;Script:EnableDebugLogging[debug.txt]
	;Script[EVEBot]:EnableProfiling

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
		
	call LoadEvebotGUI
	Ship:UpdateModuleList[]
	
	EVE:Execute[CmdStopShip]
	call UpdateHudStatus "Ensure that your ships' Cargo Hold is closed"
	call UpdateHudStatus "-=Paused: Press Run-="

	Script[EVEBot]:Pause

	play:Set[TRUE]

	/* The hauler object takes two parameters.     */
	/* The first is the name of the person you     */
	/* are hauling for.  The second is the name    */
	/* of a corporation you are hauling for.       */
	/* Only one of the two parameters may be used. */
	;Declare Hauler obj_OreHauler "Test User" ""
	;Declare Hauler obj_OreHauler "" "TestCorp"

  	while ${play}
	{
		call SetBotState
		
		switch ${botstate}
		{
			case IDLE
				break
			case ABORT
				call UpdateHudStatus "Aborting operation: Returning to base"
				Call Dock
				break
			case BASE
				call UpdateHudStatus "I'm in the station"
				call Cargo.TransferOreToHangar
				call Station.Repair
				call Ship.Undock
				break
			case REPAIR
				call UpdateHudStatus "Status: Repair Run"
				call Dock 
				wait 40
			;case COMBAT
			;	call UpdateHudStatus "Entering Combat"
			;	call Combat.Fight
			;	break
			case MINE
				call UpdateHudStatus "Mining"
				/* Comment out the call to Miner.Mine and  */
				/* replace with "call Hauler.Haul" to turn */
				/* this bot into a hauler bot.             */
				call Miner.Mine
				;call Hauler.Haul
				break
			case CARGOFULL
				call UpdateHudStatus "My ship is full"
				call Dock
				wait 40
				break
		}
		
		wait 15
	}
}