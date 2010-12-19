#define TESTCASE 1

#include ../Support/TestAPI.iss

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
	variable int StartTime = ${Script.RunningTime}
	variable int StartTime2

	declarevariable Entities index:cachedentity script
	declarevariable EntityIterator iterator script

	variable obj_LSTypeIterator ItemTest = "cachedentity"

	ItemTest:ParseMembers

	EVE:GetCachedEntities[Entities]
	variable float CallTime
	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	echo "EVE:GetCachedEntities returned ${Entities.Used} entities in ${CallTime} seconds"

	Entities:GetIterator[EntityIterator]
	if ${EntityIterator:First(exists)}
	do
	{
		StartTime2:Set[${Script.RunningTime}]
		ItemTest:IterateMembers["EntityIterator.Value", TRUE, FALSE]
		echo "Single ${ItemTest.TypeName} dump completed  ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"
	}
	while ${EntityIterator:Next(exists)}

	echo "EVE:GetCachedEntities returned ${Entities.Used} entities in ${CallTime} seconds"
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
}

variable obj_UI UI
function main()
{
	RunAtomicTestCase
}