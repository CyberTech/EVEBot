#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test DoGetHangarItems
 *
 *	Revision $Id$
 *
 *	Requirements:
 *		Docked, have items in station hangar
 *
 */


function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	declarevariable HangarItems index:item script
	variable obj_LSTypeIterator ItemTest = "item"

	ItemTest:ParseMembers
	;ItemTest:PrintKnownMembers
	;ItemTest:PrintKnownMethods

	EVE:Execute[OpenHangarFloor]
	wait 15
	Me.Station:DoGetHangarItems[HangarItems]
	echo "Me.Station:DoGetHangarItems returned ${HangarItems.Used} items"
	ItemTest:IterateMembers["HangarItems.Get[1]"]

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}