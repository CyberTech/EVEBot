#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 *	Test GetAssets (Listed as GetAssets) [Shiva]
 *
 *	Revision $Id$
 *
 *	Requirements:
 *		Open Assets window & Have a Station Micro-tabbed out.
 *
 *  Note: Only lists assets cache'd already :(
 *        Can't get around the 5 mins enforced min update time of assets.
 */

#define WITH_STATIONID 0

function main()
{
	variable obj_LSTypeIterator ItemTest = "item"
	variable string MethodStr = "Me:GetAssets"
	variable string MethodStrParam = "60012157"

	if !${EVEWindow[ByCaption,"ASSETS"](exists)}
	{
		EVE:Execute[OpenAssets]
		wait 50
	}

	#include "../_Testcase_MethodStr_Body.iss"
}