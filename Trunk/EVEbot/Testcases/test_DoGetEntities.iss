#define TESTCASE 1

#include ../Support/TestAPI.iss

/*
	Test Entity Iteration

*/

variable obj_UI UI
function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int StartTime2

	declarevariable Entities index:entity script
	declarevariable EntityIterator iterator script

	variable obj_LSTypeIterator ItemTest = "entity"

	ItemTest:ParseMembers

	EVE:DoGetEntities[Entities]
	echo "EVE:DoGetEntities returned ${Entities.Used} entities  in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"

	Entities:GetIterator[EntityIterator]
	if ${EntityIterator:First(exists)}
	do
	{
		StartTime2:Set[${Script.RunningTime}]
		ItemTest:IterateMembers["EntityIterator.Value"]
		echo "Single entity dump completed  ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"
	}
	while ${EntityIterator:Next(exists)}

	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
}