#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
 * 	Test moving all items from station hangar to ship cargo
 *
 *	Revision $Id$
 *
 *	Tests:
 *		EVE:MoveItemsTo (MyShip dest)
 *		Station:DoGetHangarItems
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

	echo "Version: ${ISXEVE.Version}"

	EVE:Execute[OpenCargoHoldOfActiveShip]
	EVE:Execute[OpenHangarFloor]
	Wait 100

	Me.Station:DoGetHangarItems[MyCargo]
	echo "Station Hangar contains ${MyCargo.Used} Items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Adding ID: ${CargoIterator.Value} ${CargoIterator.Value.ID}"
		IDList:Insert[${CargoIterator.Value.ID}]
	}
	while ${CargoIterator:Next(exists)}

	;IDList:Clear
	;IDList:Insert[${MyCargo[1].ID}]
	echo "Have ${IDList.Used} Items to move to ship cargo"

	EVE:MoveItemsTo[IDList, MyShip]
}