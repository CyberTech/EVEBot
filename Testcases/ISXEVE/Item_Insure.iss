#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 *	Test Item:GetInsuranceQuotes, where item is a ship
 *
 *  Revision $Id$
 *
 *	Requirements:
 *		Docked
 *		Ships in ship hangar
 *		Kestrel in ship hangar, uninsured (cancel insurance if needed)
 *		Insurance window open
 *		Enough isk (80k) to cover insuring a kestrel
 *
 */

function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	declarevariable HangarShips index:item script
	variable collection:float Quotes

	EVE:Execute[OpenShipHangar]
	wait 15
	Me.Station:GetHangarShips[HangarShips]
	echo "Me.Station:GetHangarShips returned ${HangarShips.Used} ships"

	variable int i
	for (i:Set[1]; ${i} <= ${HangarShips.Used}; i:Inc)
	{
		if ${HangarShips.Get[${i}].TypeID} == 602
		{
			HangarShips.Get[${i}]:GetInsuranceQuotes[Quotes]
			echo "Insurance Quotes for ${HangarShips.Get[${i}].Name} ${HangarShips.Get[${i}].TypeID}"
			echo " " Platinum Cost: ${Quotes.Element["Platinum"]}
			HangarShips.Get[${i}]:Insure[${Quotes.Element["Platinum"]}]
		}
	}

	echo "Close and re-open the insurance window, and the ship should now be insured"

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of method Item:Insure completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}