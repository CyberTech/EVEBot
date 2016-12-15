#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
 *	Test retrieval of character's market orders
 *
 *	Revision $Id: test_DoGetMyOrders.iss 1190 2009-06-16 21:46:32Z cybertech $
 *
 *	Requirements:
 *
 */

function main()
{
	variable index:myorder OrderIndex

	variable int RTime = ${Script.RunningTime}
	Me:UpdateMyOrders
	echo "- UpdateMyOrders took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."

	wait 10

	RTime:Set[${Script.RunningTime}]
	while !${Me:GetMyOrders[OrderIndex](exists)}
	{
		wait 10
	}
	echo "- GetMyOrders took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms for ${OrderIndex.Used} orders"


	variable iterator OrderIterator
	OrderIndex:GetIterator[OrderIterator]

	if ${OrderIterator:First(exists)}
	{
		do
		{
			echo "==============================================================="
			echo OrderIterator.Value.Price               : ${OrderIterator.Value.Price}
			echo OrderIterator.Value.InitialQuantity     : ${OrderIterator.Value.InitialQuantity}
			echo OrderIterator.Value.QuantityRemaining   : ${OrderIterator.Value.QuantityRemaining}
			echo OrderIterator.Value.MinQuantityToBuy    : ${OrderIterator.Value.MinQuantityToBuy}
			echo OrderIterator.Value.ID                  : ${OrderIterator.Value.ID}
			echo OrderIterator.Value.TimeStampWhenIssued : ${OrderIterator.Value.TimeStampWhenIssued}
			echo OrderIterator.Value.DateWhenIssued      : ${OrderIterator.Value.DateWhenIssued}
			echo OrderIterator.Value.TimeWhenIssued      : ${OrderIterator.Value.TimeWhenIssued}
			echo OrderIterator.Value.Duration            : ${OrderIterator.Value.Duration}
			echo OrderIterator.Value.StationID           : ${OrderIterator.Value.StationID}
			echo OrderIterator.Value.Station             : ${OrderIterator.Value.Station}
			echo OrderIterator.Value.RegionID            : ${OrderIterator.Value.RegionID}
			echo OrderIterator.Value.Region              : ${OrderIterator.Value.Region}
			echo OrderIterator.Value.SolarSystemID       : ${OrderIterator.Value.SolarSystemID}
			echo OrderIterator.Value.SolarSystem         : ${OrderIterator.Value.SolarSystem}
			echo OrderIterator.Value.Range               : ${OrderIterator.Value.Range}
			echo OrderIterator.Value.TypeID              : ${OrderIterator.Value.TypeID}
			echo OrderIterator.Value.Name                : ${OrderIterator.Value.Name}
			echo OrderIterator.Value.IsContraband        : ${OrderIterator.Value.IsContraband}
			echo OrderIterator.Value.IsCorp              : ${OrderIterator.Value.IsCorp}
			echo OrderIterator.Value.IsSellOrder         : ${OrderIterator.Value.IsSellOrder}
			echo OrderIterator.Value.IsBuyOrder          : ${OrderIterator.Value.IsBuyOrder}
		}
		while ${OrderIterator:Next(exists)}
	}
}