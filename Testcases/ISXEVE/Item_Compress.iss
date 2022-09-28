#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Test Opening Compression window
 *
 *	Revision $Id$
 *
 *	Tests:
 *		Trying to open compression window in station
 *		
 *
 *	Requirements:
 *		You: In station
 *		Ore: In Mining Ore Hold
 */

 function main()
{
	variable index:item MyOre
	variable iterator OreIterator
	variable index:int64 IDList


	if !${EVEWindow[Inventory](exists)}
	{
		echo "Opening Inventory..."
		EVE:Execute[OpenInventory]
		wait 2
	}

	EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold]:MakeActive
	Wait 10

	EVEWindow[Inventory].ActiveChild:GetItems[MyOre]
	echo "Ship Mining Hold contains ${MyOre.Used}"

	MyOre:GetIterator[OreIterator]
	if ${OreIterator:First(exists)}
	{
		do
		{
			if (${OreIterator.Value.Name.Equal[Veldspar]})
            {
                echo "Try to open compression window"    
                OreIterator.Value:Compress
            }
		}
		 while ${OreIterator:Next(exists)}
	}


}