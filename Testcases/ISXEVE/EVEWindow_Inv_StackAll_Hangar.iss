#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test eveinvchildwindow:StackAll
 *
  *	Requirements:
 *		Have items in station hangar, with at least 1 stack split
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

	EVEWindow[Inventory].ChildWindow[${Me.Station.ID}, StationItems]:MakeActive
  wait 50

  variable index:item itemlist
  EVEWindow[Inventory].ActiveChild:GetItems[itemlist]
  variable int before
  before:Set[${itemlist.Used}]

  echo "Stacking ${before} items..."
  EVEWindow[Inventory].ActiveChild:StackAll
  wait 10

  EVEWindow[Inventory].ActiveChild:GetItems[itemlist]
  echo "${itemlist.Used} stacks found after stacking ${before} items"
}