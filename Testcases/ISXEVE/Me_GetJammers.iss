#define TESTCASE 1
#include ../../Support/TestAPI.iss

/*
	Test GetJammers

	Revision $Id$

	Requirements:
		You: In Space
		Other1: Jamming you
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "jammer"
	variable string MethodStr = "Me:GetJammers"

	#include "../_Testcase_MethodStr_Body.iss"
}