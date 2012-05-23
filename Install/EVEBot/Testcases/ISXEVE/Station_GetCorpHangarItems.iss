#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss
/*
 *	Test GetCorpHangarItems
 *
 *	Revision $Id$
 *
 *	Requirements:
 *		Docked, have items in station corp hangar, not be in a public corporation
 *
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "item"
	variable string MethodStr = "Me.Station:GetCorpHangarItems"

	EVE:Execute[OpenHangarFloor]
	wait 15

	#include "../_Testcase_MethodStr_Body.iss"
}