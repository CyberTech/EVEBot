#include ./core/oPixel.iss
#include ./core/oCombat.iss
#include ./core/oFitting.iss
#include ./core/oItem.iss
#include ./core/oMarket.iss
#include ./core/oSkills.iss
#include ./core/oSpace.iss
#include ./core/oBase.iss
#include ./core/oMining.iss

function BotState()
{
	if ${Me.InStation}
	{
	  Return "BASE"
	}
	
	if ${Me.GetTargetedBy[EntitiesTargetingMe]} > 0
	{
	 Return "COMBAT"
	}
	
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
echo "Loading Coo"
variable index:entity EntitiesTargetingMe
echo "Declaring EntitiesTargetingMe"
declare station int script
declare belt int script
declare roid int script
declare play bool script TRUE
declare botstate string

	while ${play}
	{
		call BotState
		botstate:Set[${Return}]
		
		switch ${botstate}
		{
			case BASE
			echo "I'm in the station"
			call TransferToHangar	
			call StackAll
			call Undock
				break
			case COMBAT
			call DefendAndDestroy
				break
			case MINE
			echo "No ennemy ships, mining"
			call Mine
				break
			case CARGOFULL
			echo "My ship is full"
			call ReturnToBase ${station}
				break
		}
	}
}