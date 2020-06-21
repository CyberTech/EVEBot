#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test retrieval of directional scan results

	Revision $Id$

	Requirements:
		1) In Space
		2) Inside a ship
*/

function main()
{
	declarevariable ResultIndex index:scannerdirectionalresult script
	declarevariable TestIterator iterator script
	variable obj_LSTypeIterator ItemTest = "scannerdirectionalresult"
	variable int RTime

	ResultIndex:GetIterator[TestIterator]
	ItemTest:ParseMembers

	RTime:Set[${Script.RunningTime}]

	if !${MyShip.Scanners.Directional:StartScan[](exists)}
	{
		echo "StartScan Failed!"
		Script:End
	}
	else
	{
		echo "- StartDirectionalScan took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."
	}

	wait 5

	while !${MyShip.Scanners.Directional:GetScanResults[ResultIndex](exists)}
	{
		echo "Waiting for scanner results..."
		wait 20
	}
	echo "- GetScanResults returned ${ResultIndex.Used} directional results in ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."
	variable uint QueryID
	variable string Filter = "ToEntity.Distance < 1"

	QueryID:Set[${LavishScript.CreateQuery[${Filter}]}]
	if ${QueryID} == 0
	{
		UI:UpdateConsole["LavishScript.CreateQuery: '${Filter}' query addition FAILED"]
		return 0
	}

	ResultIndex:RemoveByQuery[${QueryID}, true]

	if ${TestIterator:First(exists)}
	do
	{
		echo ${TestIterator.Value.ToEntity.Name}
		ItemTest:IterateMembers["TestIterator.Value"]
	}
	while ${TestIterator:Next(exists)}

	echo "- GetScanResults returned ${ResultIndex.Used} directional results in ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."
}