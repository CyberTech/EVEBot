#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test GetAgents

	Revision $Id$

	Requirements:
		You: Have Agents

*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "being"
	variable string MethodStr = "EVE:GetAgents"

	#include "../_Testcase_MethodStr_Body.iss"
}