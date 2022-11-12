#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test eveinvchildwindow:GetItems
 *
  *	Requirements:
 *		Have items in ship cargo
 *
 */


function main()
{
	if !${EVEWindow[Inventory](exists)}
	{
		echo "Opening Inventory..."
		EVE:Execute[OpenInventory]
		wait 2
	}

	EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipDroneBay]:MakeActive
  wait 50

  variable index:item itemlist
  EVEWindow[Inventory].ActiveChild:GetItems[itemlist]

  variable iterator iter
  itemlist:GetIterator[iter]
  if ${iter:First(exists)}
  do
  {
    echo ${iter.Value.ID} ${iter.Value.LocationID} ${iter.Value.SlotID}:${iter.Value.Slot} - ${iter.Value.Name}
  }
  while ${iter:Next(exists)}
}