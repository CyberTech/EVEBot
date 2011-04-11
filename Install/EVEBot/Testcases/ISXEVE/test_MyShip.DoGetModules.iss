#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Modules
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "module"
	variable string MethodStr = "MyShip:GetModules"

	#include "../_Testcase_MethodStr_Body.iss"
}