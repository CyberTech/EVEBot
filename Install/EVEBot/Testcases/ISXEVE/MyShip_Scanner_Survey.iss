#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test retrieval of survey scanner module results

	Revision $Id$

	Requirements:
		1) In Space
		2) Inside a ship
		3) Have Survey Scanner module fitted
		4) Have target to scan
*/

function main()
{
	EVEWindow[ByCaption, "Survey Scan Results"]:Close

	echo "Starting survey scan..."
	MyShip.Scanners.Survey[${MyShip.Module[MedSlot2].ID}]:StartScan
	MyShip.Module[MedSlot2]:Activate

	echo "Waiting for module cycle..."
	wait 50 ${EVEWindow[ByCaption, "Survey Scan Results"](exists)}
	wait 5

	declarevariable Entities index:entity script
	declarevariable EntityIterator iterator script

	EVE:QueryEntities[Entities]
	Entities:GetIterator[EntityIterator]

	variable uint QueryID
	variable string Filter = "SurveyScannerOreQuantity = -1"

	QueryID:Set[${LavishScript.CreateQuery[${Filter}]}]
	if ${QueryID} == 0
	{
		UI:UpdateConsole["LavishScript.CreateQuery: '${Filter}' query addition FAILED"]
		return 0
	}

	Entities:RemoveByQuery[${QueryID}, true]

	if ${EntityIterator:First(exists)}
	do
	{
		echo ${EntityIterator.Value}: ${EntityIterator.Value.Name} ${EntityIterator.Value.Distance} Ore: ${EntityIterator.Value.SurveyScannerOreQuantity}
	}
	while ${EntityIterator:Next(exists)}

	UI:UpdateConsole["EVE:QueryEntities: ${Entities.Used} asteroids"]

}