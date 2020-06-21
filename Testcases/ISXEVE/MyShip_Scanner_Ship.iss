#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test retrieval of ship scanner module results

	Revision $Id$

	Requirements:
		1) In Space
		2) Inside a ship
		3) Have Ship Scanner module fitted
		4) Have target to scan
*/

function main()
{
	EVEWindow[ByCaption, "${Me.ActiveTarget.Name} Scan Result"]:Close
	MyShip.Scanners.Ship[${MyShip.Module[MedSlot3].ID}]:StartScan[${Me.ActiveTarget}]
	wait 30 ${EVEWindow[ByCaption, "${Me.ActiveTarget.Name} Scan Result"](exists)}

	declarevariable Entities index:entity script
	declarevariable EntityIterator iterator script

	EVE:QueryEntities[Entities]
	Entities:GetIterator[EntityIterator]

	variable uint QueryID
	variable string Filter = "HasShipScannerResults != 1"

	QueryID:Set[${LavishScript.CreateQuery[${Filter}]}]
	if ${QueryID} == 0
	{
		UI:UpdateConsole["LavishScript.CreateQuery: '${Filter}' query addition FAILED"]
		return 0
	}

	Entities:RemoveByQuery[${QueryID}]

	declarevariable TestIndex index:string script
	declarevariable TestIterator iterator script

	if ${EntityIterator:First(exists)}
	do
	{
		echo ${EntityIterator.Value}: ${EntityIterator.Value.Name} ShipScannerCapacitorCapacity: ${EntityIterator.Value.ShipScannerCapacitorCapacity} ShipScannerCapacitorCharge: ${EntityIterator.Value.ShipScannerCapacitorCharge}
		EntityIterator.Value:GetShipScannerResults[TestIndex]
		TestIndex:GetIterator[TestIterator]

		if ${TestIterator:First(exists)}
		do
		{
			echo ${TestIterator.Value}
		}
		while ${TestIterator:Next(exists)}
	}
	while ${EntityIterator:Next(exists)}
}