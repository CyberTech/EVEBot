#include ./core/oPixel.iss
#include ./core/oCombat.iss
#include ./core/oFitting.iss
#include ./core/oItem.iss
#include ./core/oMarket.iss
#include ./core/oSkills.iss
#include ./core/oSpace.iss
#include ./core/oBase.iss
#include ./core/oMining.iss
#include ./core/oCore.iss

function LoadEvebotGUI()
{
ui -load ./interface/eveskin/eveskin.xml
ui -load ./interface/evebotgui.xml
call SetupHudStatus
call UpdateHudStatus "Started EVEBot ${Version}"
}

function atexit()
{
ui -unload ./interface/eveskin/eveskin.xml
ui -unload ./interface/evebotgui.xml
}

function BotState()
{
	if ${Me.InStation}
	{
	  Return "BASE"
	}
	
	;if ${Me.GetTargetedBy[EntitiesTargetingMe]} > 0
	;{
	; Return "COMBAT"
	;}
	
	if ${Me.Ship.UsedCargoCapacity} != ${Me.Ship.CargoCapacity}
	{
	 Return "MINE"
	}
	
	if ${Me.Ship.UsedCargoCapacity} == ${Me.Ship.CargoCapacity}
	{
	 Return "CARGOFULL"
	}
	Return "None"
}

function main()
{
echo "Eve Bot starting"
	
call LoadPixels
call LoadEvebotGUI
call UpdateHudStatus "Loading Coo"
declare station int script
declare belt int script
declare roid int script
declare play bool script TRUE
declare botstate string
EVE:Execute[CmdStopShip]
Script[EvEBot]:Pause
Console EVEStatus@Main@EVEBotTab@EvEBot

	while ${play}
	{
		call BotState
		botstate:Set[${Return}]
		
		switch ${botstate}
		{
			case BASE
			call UpdateHudStatus "I'm in the station"
			call TransferToHangar	
			call StackAll
			call Undock
				break
			case MINE
			call UpdateHudStatus "Mining"
			call Mine
				break
			case CARGOFULL
			station:Set[${Entity[CategoryID,3].ID}]
			call UpdateHudStatus "Setting main station ${Entity[CategoryID,3].Name} with id ${Entity[CategoryID,3].ID}"
			call UpdateHudStatus "My ship is full"
			call ReturnToBase ${station}
				break
		}
		wait 15
	}
}