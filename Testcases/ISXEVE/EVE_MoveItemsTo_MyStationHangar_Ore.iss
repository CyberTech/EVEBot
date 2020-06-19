#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Test moving all ORE from ship cargo and ship ore hangar to station hangar
 *
 *	Revision $Id$
 *
 *	Tests:
 *		EVE:MoveItemsTo (Hangar dest)
 *		MyShip:GetCargo
 		MyShip:GetOreHoldCargo
 *
 *	Requirements:
 *		You: In station
 *		Cargo: In ship cargo
 */
 
function main()
{
	variable index:item MyCargo
	variable iterator CargoIterator
	variable index:int64 IDList

	echo "Version: $ISXEVE.Version}"

	if !${EVEWindow[Inventory](exists)}
	{
		echo "Opening Inventory..."
		EVE:Execute[OpenInventory]
		wait 2
	}

	EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
	Wait 10

	MyShip:GetCargo[MyCargo]
	MyCargo:RemoveByQuery[${LavishScript.CreateQuery["CategoryID == CATEGORYID_ORE"]}, FALSE]
	MyCargo:Collapse
	echo "Ship Cargo contains ${MyCargo.Used} matching items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Adding ID: ${CargoIterator.Value} ${CargoIterator.Value.ID}"
		IDList:Insert[${CargoIterator.Value.ID}]
	}
	while ${CargoIterator:Next(exists)}

	EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold]:MakeActive
	Wait 10

	MyShip:GetOreHoldCargo[MyCargo]
	MyCargo:RemoveByQuery[${LavishScript.CreateQuery["CategoryID == CATEGORYID_ORE"]}, FALSE]
	MyCargo:Collapse
	echo "Ship Ore Cargo contains ${MyCargo.Used} matching items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Adding ID: ${CargoIterator.Value} ${CargoIterator.Value.ID}"
		IDList:Insert[${CargoIterator.Value.ID}]
	}
	while ${CargoIterator:Next(exists)}

	echo "Have ${IDList.Used} Items to move to station hangar"

	EVE:MoveItemsTo[IDList, MyStationHangar]
	EVEWindow[Inventory].ChildWindow[${Me.Station.ID}, StationItems]:MakeActive
}