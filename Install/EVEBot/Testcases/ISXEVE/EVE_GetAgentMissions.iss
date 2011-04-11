#define TESTCASE 1
#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Agent Mission lists 

	Revision $Id$

	Requirements:
		You:
		Journal: Have missions in it
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "agentmission"
	variable string MethodStr = "EVE:GetAgentMissions"

	#include "../_Testcase_MethodStr_Body.iss"
}