#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test EVEWindow iteration, GetEVEWindows

	Revision $Id$

	Requirements:
		You: Windows open

*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "evewindow"
	variable string MethodStr = "EVE:GetEVEWindows"

	#include "../_Testcase_MethodStr_Body.iss"
}