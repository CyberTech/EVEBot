#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test GetStationsWithAssets
 *
 *	Requirements:
 *		Open assets window
 *
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "int64"
	variable string MethodStr = "Me:GetStationsWithAssets"

	if !${EVEWindow[ByCaption,"ASSETS"](exists)}
	{
		EVE:Execute[OpenAssets]
		wait 50
	}

	#include "../_Testcase_MethodStr_Body.iss"
}