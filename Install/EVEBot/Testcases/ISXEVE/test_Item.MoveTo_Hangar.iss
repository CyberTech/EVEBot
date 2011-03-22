#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
 * 	Test moving all items from station hangar to ship cargo
 *
 *	Revision $Id$
 *
 *	Tests:
 *		Item:Moveto (Hangar dest)
 *		MyShip:GetCargo
 *
 *	Requirements:
 *		You: In station
 *		Cargo: In station hangar
 */
 
 function main()
{
	variable index:item MyCargo
	variable iterator CargoIterator
	variable index:int64 IDList

	if !${Me.InStation}
	{
		echo "Must be docked"
		return
	}
	
	echo "Version: ${ISXEVE.Version}"

	EVE:Execute[OpenCargoHoldOfActiveShip]
	EVE:Execute[OpenHangarFloor]
	Wait 100

	MyShip:GetCargo[MyCargo]
	echo "Ship Cargo contains ${MyCargo.Used} Items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Moving ID: ${CargoIterator.Value} ${CargoIterator.Value.ID} Count: ${CargoIterator.Value.Quantity}"
		CargoIterator.Value:MoveTo[Hangar, ${CargoIterator.Value.Quantity}]
	}
	while ${CargoIterator:Next(exists)}
}