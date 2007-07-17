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
variable(script) int MyCargoCount
variable(script) int BeltCount
variable(script) int RoidCount
variable(script) int RoidTypeCnt
variable(script) int RoidPrefCnt
variable(script) int RoidPrefTotal
variable(script) oSkills Skills


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
	
	if (${Me.ToEntity.ShieldPct} < 35)
		{
		botstate:Set["COMBAT"]
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
	RoidPrefTotal:Set[0]
	RoidPrefCnt:Set[1]
	do
	{
		DeclareVariable RoidType${RoidPrefCnt} string script
		RoidPrefTotal:Inc
	}
	while ${LavishSettings[Roids].FindSet[Asteroids].FindSetting[${RoidPrefCnt:Inc}](exists)}
	RoidPrefCnt:Set[1]
	do
	{
		RoidType${RoidPrefCnt}:Set[${LavishSettings[Roids].FindSet[Asteroids].FindSetting[${RoidPrefCnt}]}]
		echo "${RoidPrefCnt}) ${RoidType${RoidPrefCnt}}"
	}
	while ${RoidPrefCnt:Inc} <= ${RoidPrefTotal}
	
  ; Start the daemon that sets global variables (for use with the HUD, etc)
  run "./core/EB_GlobalVariablesDaemon.iss" ${Script.Filename}
  	

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
			case COMBAT
				call UpdateHudStatus "FIRE ZE MISSILES!!!"
				call ShieldNotification
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
			case RUNNING
				call Dock
				wait 40
				break
		}
		
		wait 15
	}
}
