#define TESTCASE 1
#include ../../Support/TestAPI.iss

/*
	Test Me:GetTargeting

	Revision $Id$

	Requirements:
		You: Be targeting things
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "entity"
	variable string MethodStr = "Me:GetTargeting"

	#include "../_Testcase_MethodStr_Body.iss"
}