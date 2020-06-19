#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Test moving all items from station hangar to ship fleet hangar
 *
 *	Revision $Id$
 *
 *	Tests:
 *		Item:Moveto (Myship dest)
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

	EVEWindow[Inventory].ChildWindow[${Me.StationID}, StationItems]:MakeActive
	Wait 10

	Me.Station:GetHangarItems[MyCargo]
	echo "Station Hangar contains ${MyCargo.Used} Items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
  ;do
	{
		echo "Moving ID: ${CargoIterator.Value} ${CargoIterator.Value.ID} Count: ${CargoIterator.Value.Quantity}"
		CargoIterator.Value:MoveTo["MyShip", "FleetHangar", ${CargoIterator.Value.Quantity}]
	}
  ;while ${CargoIterator:Next(exists)}

}