#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test FleetMember Iteration, FleetMember.ToEntity, FleetMember.ToPilot

	Revision $Id$

	Requirements:
		You: In Space
		Other1: In Fleet, In Space, on Grid
		Other2: In Space, Off Grid
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "fleetmember"
	variable string MethodStr = "Me.Fleet:GetMembers"

	#include "../_Testcase_MethodStr_Body.iss"
}