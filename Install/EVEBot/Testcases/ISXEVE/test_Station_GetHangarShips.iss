#define TESTCASE 1

#include ../Support/TestAPI.iss
/*
 *	Test GetHangarItems
 *
 *  Revision $Id$
 *
 *	Requirements:
 *		Docked
 *		Have items in station hangar
 *
 */


function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	declarevariable HangarShips index:item script
	variable obj_LSTypeIterator ItemTest = "item"

	ItemTest:ParseMembers
	;ItemTest:PrintKnownMembers
	;ItemTest:PrintKnownMethods

	EVE:Execute[OpenShipHangar]
	wait 15
	Me.Station:GetHangarShips[HangarShips]
	echo "Me.Station:GetHangarShips returned ${HangarShips.Used} ships"
	ItemTest:IterateMembers["HangarShips.Get[1]"]

/*
	;For testing AssembleShip
	variable int i
	for (i:Set[1]; ${i} <= ${HangarShips.Used}; i:Inc)
	{
		if ${HangarShips.Get[${i}].Quantity} > 1
		{
			HangarShips.Get[${i}]:AssembleShip
			return
		}
	}
	HangarShips.Get[1]:MakeActive
*/

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}