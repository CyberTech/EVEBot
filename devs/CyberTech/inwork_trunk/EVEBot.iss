#include core/oCombat.iss
#include core/oSkills.iss
#include core/oSpace.iss
#include core/oMining.iss
#include core/oCore.iss

#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss

;; Declare all script or global variables here
; Used for throwaway return calls
variable int JunkInt
variable int stationloc
variable int belt
variable bool play
variable string botstate
variable float GoalDistance
variable oSkills Skills

; Script Settings & Setting Set Rerences
variable settingsetref EVEBotSettings
variable settingsetref OreTypes

; Script-Defined Objects
variable obj_Asteroids Asteroids
variable obj_Ship Ship
variable obj_Station Station
variable obj_Cargo Cargo
variable obj_EVEBotUI UI

function LoadEvebotGUI()
{
	ui -load interface/eveskin/eveskin.xml
	ui -load interface/evebotgui.xml
	call SetupHudStatus
	call UpdateHudStatus "Started EVEBot ${Version}.."
	call UpdateHudStatus "Please Hold Loading Main Function.."
}

function atexit()
{
	LavishSettings[EVEBotSettings]:Export[${Script.CurrentDirectory}/config/evebot.xml]
	LavishSettings[EVEBotSettings]:Remove
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
		
	if ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
	{
	 	botstate:Set["MINE"]
		return
	}
	
	if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
	{
		botstate:Set["CARGOFULL"]
		return
	}
	botstate:Set["None"]
}

function main()
{
	Turbo 20
	if !${ISXEVE(exists)}
	{
		echo ISXEVE must be loaded to use this script.
		return
	}
   
	while !${ISXEVE.IsReady}
	{
		waitframe
	}
	
  ; Start the daemon that sets global variables (for use with the HUD, etc)
  ;run "./core/EB_GlobalVariablesDaemon.iss" ${Script.Filename}
  	

	call LoadEvebotGUI
	wait 20 ${UIElement[evebot](exists)}
	;Console EVEStatus@Main@EVEBotTab@EvEBot

	; Initialize the settings sets.
	LavishSettings:AddSet[EVEBotSettings]
	LavishSettings[EVEBotSettings]:Import[${Script.CurrentDirectory}/config/evebot.xml]
	
	; Assign settingsref shortcuts
	EVEBotSettings:Set[${LavishSettings[EVEBotSettings]}]
	OreTypes:Set[${LavishSettings[EVEBotSettings].FindSet[Ore Types]}]
	;OreTypes:CommentSet# Set[text]
		
	Ship:UpdateModuleList[]
	
	EVE:Execute[CmdStopShip]
	call UpdateHudStatus "Please be sure that your Ships' Cargo Hold is *CLOSED*"
	call UpdateHudStatus "Completed Main Function"
	call UpdateHudStatus "Bot is now Paused - Please press Play"
	Script[EVEBot]:Pause
	play:Set[TRUE]

  	while ${play}
	{
		call SetBotState
		
		switch ${botstate}
		{
			case BASE
				call UpdateHudStatus "I'm in the station"
				call Cargo.TransferOreToHangar
				call Ship.Undock
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
