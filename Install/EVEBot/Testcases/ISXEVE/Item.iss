#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss
/*
 *	Test MyShip:GetCarg
 *
 *	Revision $Id: Station_GetHangarItems.iss 2131 2012-01-09 21:21:12Z CyberTech $
 *
 *	Requirements:
 *		Have items in ship cargo
 *
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "item"
	variable string MethodStr = "MyShip:GetCargo"

	MyShip:Open
	wait 15

	#include "../_Testcase_MethodStr_Body.iss"
}