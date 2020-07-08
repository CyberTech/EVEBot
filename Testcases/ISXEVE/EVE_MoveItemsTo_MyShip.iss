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

	if !${EVEWindow[Inventory](exists)}
	{
		echo "Opening Inventory..."
		EVE:Execute[OpenInventory]
		wait 2
	}

	EVEWindow[Inventory].ChildWindow[${Me.Station.ID}, StationItems]:MakeActive
	Wait 10

	Me.Station:GetHangarItems[MyCargo]
	;MyCargo:RemoveByQuery[${LavishScript.CreateQuery["CategoryID == CATEGORYID_CHARGE"]}, FALSE]
	;MyCargo:Collapse
	echo "Station Hangar contains ${MyCargo.Used} matching items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Adding ID: ${CargoIterator.Value} ${CargoIterator.Value.ID}"
		IDList:Insert[${CargoIterator.Value.ID}]
	}
	while ${CargoIterator:Next(exists)}

	echo "Have ${IDList.Used} Items to move to ship cargo"

	EVE:MoveItemsTo[IDList, MyShip, CargoHold]
	EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
}