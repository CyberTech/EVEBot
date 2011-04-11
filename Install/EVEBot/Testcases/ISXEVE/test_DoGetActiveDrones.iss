#define TESTCASE 1

#include Scripts/EVEBotDev/Support/TestAPI.iss

/*
 *	Test GetActiveDroneIDs [Shiva]
 *	Requires:	Must be in space.
 *	Note: Detects ALL drones in space that are in your window.
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "activedrone"
	variable string MethodStr = "Me:GetActiveDrones"

	#include "../_Testcase_MethodStr_Body.iss"
}