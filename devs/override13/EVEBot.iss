
#include ./core/oCombat.iss
#include ./core/oFitting.iss
#include ./core/oItem.iss
#include ./core/oMarket.iss
#include ./core/oSkills.iss
#include ./core/oSpace.iss
#include ./core/oBase.iss
#include ./core/oMining.iss
#include ./core/oCore.iss

;; Declear all script or global variables here
variable(script) int stationa
variable(script) int belt
variable(script) int roid
variable(script) bool play
variable(script) string botstate

function LoadEvebotGUI()
{
	ui -load ./interface/eveskin/eveskin.xml
	ui -load ./interface/evebotgui.xml
	call SetupHudStatus
	call UpdateHudStatus "Started EVEBot ${Version}.."
	call UpdateHudStatus "Please Hold Loading Main Function.."
}

function atexit()
{
	ui -unload ./interface/eveskin/eveskin.xml
	ui -unload ./interface/evebotgui.xml
}

function SetBotState()
{
	if ${Me.InStation}
	{
	  botstate:Set["BASE"]
	  return
	}
	
	
	if ${Me.Ship.UsedCargoCapacity} <= ${Math.Calc[${Me.Ship.CargoCapacity}-3]}
	{
	 	botstate:Set["MINE"]
		return
	}
	
	if ${Me.Ship.UsedCargoCapacity} >= ${Math.Calc[${Me.Ship.CargoCapacity}-3]}
	{
	  botstate:Set["CARGOFULL"]
	  return
	}
	botstate:Set["None"]
}

function main()
{
  if !${ISXEVE(exists)}
  {
     echo ISXEVE must be loaded to use this script.
     return
  }
   
  do
  {
     waitframe
  }
  while !${ISXEVE.IsReady}


	call LoadEvebotGUI
	wait 20
	Console EVEStatus@Main@EVEBotTab@EvEBot
	EVE:Execute[CmdStopShip]
	call UpdateHudStatus "Completed Main Function"
	call UpdateHudStatus "Bot is now Paused"
	call UpdateHudStatus "Please Press Play"
	Script[EVEBot]:Pause
	play:Set[TRUE]

	while ${play}
	{
		call SetBotState
		echo "${botstate}"
		
		switch ${botstate}
		{
			case BASE
				call UpdateHudStatus "I'm in the station"
				call TransferToHangar
				call Undock
				wait 50
				break
			case MINE
				call UpdateHudStatus "Mining"
				call Mine
				break
			case CARGOFULL
				stationa:Set[${Entity[CategoryID,3].ID}]
				call UpdateHudStatus "Setting main station ${Entity[id,${stationa}].Name} with ID ${stationa}"
				call UpdateHudStatus "My ship is full"
				call Dock ${stationa}
				wait 40
				break
		}
		
		wait 15
	}
}