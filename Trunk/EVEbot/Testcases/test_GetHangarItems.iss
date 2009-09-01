#define TESTCASE 1

#include ../Support/TestAPI.iss

/*
 *	Test DoGetHangarItems
 *
 *	Requirements:
 *		Docked, have items in station hangar
 *
 */

function main()
{
	variable int i = 1
	variable index:item HangarItems

	EVE:Execute[OpenHangarFloor]
	wait 15
	Me.Station:DoGetHangarItems[HangarItems]
	echo Populated HangarItems List:: ${HangarItems.Used} items total

	do
	{
		echo ${HangarItems.Get[${i}].Name}
	}
	while ${i:Inc} <= ${HangarItems.Used}

	echo "Script finished."
}