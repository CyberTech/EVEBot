#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Buddy (Being) Member Iteration

	Revision $Id$

	Requirements:
		You:
		Buddy List: Populated
		People & Places window must have been opened at least once, to the buddies tab
*/

variable obj_UI UI
function main()
{
	variable int StartTime = ${Script.RunningTime}

	declarevariable Beings index:being script
	declarevariable Buddy iterator script

	variable obj_LSTypeIterator ItemTest = "being"

	ItemTest:ParseMembers

	EVE:GetBuddies[Beings]
	variable float CallTime
	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	echo "EVE:GetBuddies returned ${Beings.Used} buddies in ${CallTime} seconds"

	Beings:GetIterator[Buddy]
	if ${Buddy:First(exists)}
	do
	{
		ItemTest:IterateMembers["Buddy.Value"]
	}
	while ${Buddy:Next(exists)}

	echo "EVE:GetBuddies returned ${Beings.Used} buddies in ${CallTime} seconds"
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
}