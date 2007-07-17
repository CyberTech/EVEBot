#include ./core/oCombat.iss
#include ./core/oFitting.iss
#include ./core/oItem.iss
#include ./core/oMarket.iss
#include ./core/oSkills.iss
#include ./core/oSpace.iss
#include ./core/oStation.iss
#include ./core/oMining.iss
#include ./core/oCore.iss
#include ./core/oBase.iss

;; Declear all script or global variables here
variable(script) int stationloc
variable(script) int belt
variable(script) int roid
variable(script) bool play
variable(script) string botstate
variable(script) float GoalDistance
variable(script) bool Lasers
variable(script) index:entity Belts
variable(script) index:entity Roids
variable(script) index:item MyCargo
variable(script) int MyCargoCount
variable(script) int BeltCount
variable(script) int RoidCount
variable(script) string RoidType1
variable(script) string RoidType2
variable(script) string RoidType3
variable(script) string RoidType4
variable(script) int RoidTypeCnt

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
	
	if ${Me.Ship.UsedCargoCapacity} <= ${Math.Calc[${Me.Ship.CargoCapacity}*0.90]}
	{
	 	botstate:Set["MINE"]
		return
	}
	
	if ${Me.Ship.UsedCargoCapacity} > ${Math.Calc[${Me.Ship.CargoCapacity}*0.90]}
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
	LavishSettings:AddSet[Roids]
	LavishSettings[Roids]:Import[${Script.CurrentDirectory}/config/Roids.xml]
	RoidType1:Set[${LavishSettings[Roids].FindSet[Asteroids].FindSetting[1]}]
	RoidType2:Set[${LavishSettings[Roids].FindSet[Asteroids].FindSetting[2]}]
	RoidType3:Set[${LavishSettings[Roids].FindSet[Asteroids].FindSetting[3]}]
	RoidType4:Set[${LavishSettings[Roids].FindSet[Asteroids].FindSetting[4]}]
	variable int i = 1

	call LoadEvebotGUI
	wait 20
	Console EVEStatus@Main@EVEBotTab@EvEBot
	EVE:Execute[CmdStopShip]
	call UpdateHudStatus "Please be sure that your Ship's Cargo Hold is *CLOSED*"
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
				;while ${Me.Ship.GetCargo[MyCargo,CategoryID,25]}>0 || ${Me.Ship.GetCargo[MyCargo,CategoryID,4]}>0
				;{
				;	call TransferToHangar
				;	wait 10
				;}
				call Undock
				wait 50
				break
			case MINE
				call UpdateHudStatus "Mining"
				call Mine
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