#define TESTCASE 1
#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Me:GetTargets

	Revision $Id$

	Requirements:
		You: Have targets
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "jammer"
	variable string MethodStr = "Me:GetJammers"

	#include "../_Testcase_MethodStr_Body.iss"
}