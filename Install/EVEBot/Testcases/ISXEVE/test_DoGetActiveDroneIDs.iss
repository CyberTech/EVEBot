#define TESTCASE 1

#include Scripts/EVEBotDev/Support/TestAPI.iss

/*
 *	Test GetActiveDroneIDs [Shiva]
 *	Requires:	Must be in space.
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "int64"
	variable string MethodStr = "Me:GetActiveDroneIDs"

	#include "../_Testcase_MethodStr_Body.iss"
}