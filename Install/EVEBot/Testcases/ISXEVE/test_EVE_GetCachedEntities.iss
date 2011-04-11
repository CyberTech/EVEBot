#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
 *	Cached Entity Retrieval and Member Access
 *
 *	Revision $Id$
 *
 *	Tests:
 *		EVE:GetCachedEntities
 *		cachedentity Members
 *
 *	Requirements:
 *		You: In Space
 */

atom RunAtomicTestCase()
{
	variable obj_LSTypeIterator ItemTest = "cachedentity"
	variable string MethodStr = "EVE:GetCachedEntities"

	#include "../_Testcase_MethodStr_Body.iss"
}

function main()
{
	RunAtomicTestCase
}