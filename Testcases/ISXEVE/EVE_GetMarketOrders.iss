#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test retrieval of market orders

	Revision $Id$

	Requirements:
		Open market window
*/

function main()
{
	declarevariable OrderIndex index:marketorder script
	declarevariable OrderIterator iterator script
	variable obj_LSTypeIterator ItemTest = "marketorder"
	variable int ItemTypeID = 11544
	ItemTest:ParseMembers

	variable int RTime

	RTime:Set[${Script.RunningTime}]
	EVE:FetchMarketOrders[${ItemTypeID}]
	echo "- FetchMarketOrders took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."

	wait 5

	OrderIndex:Clear
	RTime:Set[${Script.RunningTime}]
	while !${EVE:GetMarketOrders[OrderIndex, ${ItemTypeID}, "Sell"](exists)}
	{
		echo "Waiting for order update..."
		wait 10
	}
	echo "- GetMarketOrders returned ${OrderIndex.Used} sell orders in ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."

/*
	OrderIndex:Clear
	RTime:Set[${Script.RunningTime}]
	while !${EVE:GetMarketOrders[OrderIndex, ${ItemTypeID}, "Buy"](exists)}
	{
		echo "Waiting for order update..."
		wait 10
	}
	echo "- GetMarketOrders returned ${OrderIndex.Used} buy orders in ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."
*/

	echo ${OrderIndex.Get[1].Price}
	;endscript *
	OrderIndex:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	{
		do
		{
			ItemTest:IterateMembers["OrderIterator.Value", TRUE, FALSE]
		}
		while ${OrderIterator:Next(exists)}
	}
}