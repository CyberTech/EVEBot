#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Bookmark Members

	Revision $Id$

	Requirements:
		You:
		Bookmarks
		People & Places window must have been opened at least once
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "bookmark"
	variable string MethodStr = "EVE:GetBookmarks"

	#include "../_Testcase_MethodStr_Body.iss"
}
