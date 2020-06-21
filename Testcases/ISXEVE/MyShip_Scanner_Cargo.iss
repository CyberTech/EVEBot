#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test retrieval of cargo scanner module results

	Revision $Id: MyShip_Scanner_Ship.iss 2869 2013-08-19 20:56:22Z CyberTech $

	Requirements:
		1) In Space
		2) Inside a ship
		3) Have Cargo Scanner module fitted
		4) Have target to scan
*/

function main()
{
	EVEWindow[ByCaption, "${Me.ActiveTarget.Name} Cargo Scan Results"]:Close
	MyShip.Scanners.Cargo[${MyShip.Module[MedSlot4].ID}]:StartScan[${Me.ActiveTarget}]
	wait 50

	declarevariable Entities index:entity script
	declarevariable EntityIterator iterator script

	EVE:QueryEntities[Entities]
	Entities:GetIterator[EntityIterator]

	variable uint QueryID
	variable string Filter = "HasCargoScannerResults != 1"

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
		echo ${EntityIterator.Value}: ${EntityIterator.Value.Name}
		EntityIterator.Value:GetCargoScannerResults[TestIndex]
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