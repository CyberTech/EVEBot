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
	variable obj_LSTypeIterator ItemTest = "attacker"
	variable string MethodStr = "Me:GetAttackers"

	#include "../_Testcase_MethodStr_Body.iss"
}