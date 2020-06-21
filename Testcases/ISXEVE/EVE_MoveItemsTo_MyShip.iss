#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Test moving all items from station hangar to ship cargo
 *
 *	Revision $Id$
 *
 *	Tests:
 *		EVE:MoveItemsTo (MyShip dest)
 *		Station:GetHangarItems
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

	MyShip:Open
	EVE:Execute[OpenHangarFloor]
	Wait 100

	Me.Station:GetHangarItems[MyCargo]
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