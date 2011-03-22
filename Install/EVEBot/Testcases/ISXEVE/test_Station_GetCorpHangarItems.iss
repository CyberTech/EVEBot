#define TESTCASE 1

#include ../../Support/TestAPI.iss
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
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	declarevariable HangarItems index:item script
	variable obj_LSTypeIterator ItemTest = "item"

	ItemTest:ParseMembers
	;ItemTest:PrintKnownMembers
	;ItemTest:PrintKnownMethods

	Me.Station:OpenCorpHangar
	wait 15
	Me.Station:GetCorpHangarItems[HangarItems]
	echo "Me.Station:GetCorpHangarItems returned ${HangarItems.Used} items"
	ItemTest:IterateMembers["HangarItems.Get[1]"]

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}