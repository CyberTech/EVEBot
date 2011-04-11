#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Modules
*/

function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int StartTime2

	declarevariable Modules index:module script
	declarevariable ModuleIterator iterator script

	variable obj_LSTypeIterator ItemTest = "module"

	ItemTest:ParseMembers

	MyShip:GetModules[Modules]
	variable float CallTime
	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	echo "MyShip:GetModules returned ${Modules.Used} modules in ${CallTime} seconds"

	Modules:GetIterator[ModuleIterator]
	if ${ModuleIterator:First(exists)}
	do
	{
		StartTime2:Set[${Script.RunningTime}]
		ItemTest:IterateMembers["ModuleIterator.Value", FALSE, FALSE]
		echo "Single ${ItemTest.TypeName} dump completed ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"
	}
	while ${ModuleIterator:Next(exists)}

	echo "MyShip:GetModules returned ${Modules.Used} modules in ${CallTime} seconds"
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
}