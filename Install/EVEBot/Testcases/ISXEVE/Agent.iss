#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Agent datatype

	Revision $Id: EVE_GetAgents.iss 2130 2012-01-09 20:53:35Z CyberTech $

	Requirements:
		None

*/

function main()
{
	variable int EVEAgentIndex = 4130
	variable obj_LSTypeIterator ItemTest = "agent"

	ItemTest:ParseMembers
	;ItemTest.ExcludedMembers:Add["Corporation"]
	ItemTest:IterateMembers["Agent[${EVEAgentIndex}]"]
}