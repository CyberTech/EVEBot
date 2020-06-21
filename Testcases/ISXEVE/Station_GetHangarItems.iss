#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test GetHangarItems
 *
 *	Revision $Id$
 *
 *	Requirements:
 *		Docked, have items in station hangar
 *
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "item"
	variable string MethodStr = "Me.Station:GetHangarItems"

	EVE:Execute[OpenHangarFloor]
	wait 15

	#include "../_Testcase_MethodStr_Body.iss"
}