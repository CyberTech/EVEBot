#define TESTCASE 1
#include ../../Support/TestAPI.iss

/*
	Test GetAttackers

	Revision $Id$

	Requirements:
		You: In Space
		Other1: Shooting you
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "attacker"
	variable string MethodStr = "Me:GetAttackers"

	#include "../_Testcase_MethodStr_Body.iss"
}