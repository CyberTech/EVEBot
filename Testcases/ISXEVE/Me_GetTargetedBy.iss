#define TESTCASE 1
#include ../../Support/TestAPI.iss

/*
	Test Me:GetTargetedBy

	Revision $Id$

	Requirements:
		You: Be targeted by other players or NPCs
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "entity"
	variable string MethodStr = "Me:GetTargetedBy"

	#include "../_Testcase_MethodStr_Body.iss"
}