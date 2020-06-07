#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test Pilot Iteration, Pilot.ToEntity, Pilot.ToFleetMember

	Revision $Id$

	Requirements:
		You: In Space
		Other1: In Fleet, In Space, on Grid
		Other2: In Space, Off Grid
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "pilot"
	variable string MethodStr = "EVE:GetLocalPilots"

	#include "../_Testcase_MethodStr_Body.iss"
}