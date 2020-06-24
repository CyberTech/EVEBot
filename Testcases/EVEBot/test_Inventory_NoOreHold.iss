#define TESTCASE 1

/*
	Test EVEBot Inventory - Activate returns false if given inventory doesn't exist

	Revision $Id$

	Requirements:
		None

*/

#include ../../Support/TestAPI.iss
#include ../../Branches/Stable/core/obj_Inventory.iss

function main()
{
	echo "obj_Inventory: Validate that witch to invalid hold returns false:"

	declarevariable Inventory obj_Inventory script

	call Inventory.ShipOreHold.Activate
	if ${Return}
  {
		echo "Failed - Does this ship have an ore hold?  MyShip.HasOreHold=${MyShip.HasOreHold}. Pick a ship without."
  }
  else
  {
    echo "Activate returned false, confirming with IsCurrent"
    if ${Inventory.ShipOreHold.IsCurrent}
    {
      echo "Failed: IsCurrent should be false"
    }
    else
    {
      echo "Passed"
    }
  }
}


