#define TESTCASE 1
#include ../../Support/TestAPI.iss

/*
	Test Me:GetTargets

	Revision $Id$

	Requirements:
		You: Have targets
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "entity"
	variable string MethodStr = "Me:GetTargets"

	#include "../_Testcase_MethodStr_Body.iss"
}