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

function main()
{
	variable obj_LSTypeIterator ItemTest = "being"
	variable string MethodStr = "EVE:GetBuddies"

	#include "../_Testcase_MethodStr_Body.iss"
}