#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
 *	Test:
 *		Item:GetInsuranceQuotes, where item is a ship
 *  	Item.Insured
 *		Item.InsuranceLeveL
 *
 *  Revision $Id$
 *
 *	Requirements:
 *		Docked
 *		Ships in ship hangar
 *		Insurance window open
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
	EVE:Execute[OpenInsurance]
	wait 15
	variable int i
	for (i:Set[1]; ${i} <= ${HangarShips.Used}; i:Inc)
	{
		HangarShips.Get[${i}]:GetInsuranceQuotes[Quotes]
		echo "Insurance Quotes for ${HangarShips.Get[${i}].Name}"
		echo " " Basic: ${Quotes.Element["Basic"]}
		echo " " Standard: ${Quotes.Element["Standard"]}
		echo " " Bronze: ${Quotes.Element["Bronze"]}
		echo " " Silver: ${Quotes.Element["Silver"]}
		echo " " Gold: ${Quotes.Element["Gold"]}
		echo " " Platinum: ${Quotes.Element["Platinum"]}
		echo "  Insured: ${HangarShips.Get[${i}].IsInsured}"
		echo "  InsuranceLevel: ${HangarShips.Get[${i}].InsuranceLevel}"
	}

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of method Item:GetInsuranceQuotes completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}