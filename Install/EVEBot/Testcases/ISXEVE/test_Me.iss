#define TESTCASE 1

#include ../Support/TestAPI.iss
/*
	Test: Me (character datatype)
	Requirements: Logged in

*/
function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	variable obj_LSTypeIterator ItemTest = "character"

	ItemTest:ParseMembers
	ItemTest.ExcludedMembers:Add["Corporation"]
	ItemTest:IterateMembers["Me"]
	;ItemTest:WriteTestScript["Me"]

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}