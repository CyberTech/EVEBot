#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test GetAnomalies method of the systemscanner datatype

	Revision $Id: MyShip_Scanner_Ship.iss 2869 2013-08-19 20:56:22Z CyberTech $

	Requirements:
		1) In Space
		2) Inside a ship
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "systemanomalies"
	variable string MethodStr = "MyShip.Scanners.System:GetAnomalies"

	#include "../_Testcase_MethodStr_Body.iss"
}