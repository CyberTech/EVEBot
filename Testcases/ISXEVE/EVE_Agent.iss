#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test eveagent datatype

	Revision $Id: EVE_GetAgents.iss 2130 2012-01-09 20:53:35Z CyberTech $

	Requirements:
		None

*/

function main()
{
	variable int EVEAgentIndex = 4130
	variable obj_LSTypeIterator ItemTest = "eveagent"

	ItemTest:ParseMembers
	;ItemTest.ExcludedMembers:Add["Corporation"]
	ItemTest:IterateMembers["EVE.Agent[${EVEAgentIndex}]"]
}