#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Test moving all items from ship cargo to station hangar
 *
 *	Revision $Id$
 *
 *	Tests:
 *		Item:Moveto (Myship dest)
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

	if !${EVEWindow[Inventory](exists)}
	{
		echo "Opening Inventory..."
		EVE:Execute[OpenInventory]
		wait 2
	}

	EVEWindow[Inventory].ChildWindow[${Me.Station.ID}, StationItems]:MakeActive
	Wait 10

	Me.Station:GetHangarItems[MyCargo]
	echo "Station Hangar contains ${MyCargo.Used} Items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Moving ID: ${CargoIterator.Value} ${CargoIterator.Value.ID} Count: ${CargoIterator.Value.Quantity}"
		CargoIterator.Value:MoveTo[MyShip, CargoHold, ${CargoIterator.Value.Quantity}]
		;CargoIterator.Value:MoveTo[MyShip]
	}
	while ${CargoIterator:Next(exists)}

	EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
}