#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test MyShip:GetOreHoldCargo
 *
 *
 *	Requirements:
 *		Have items in ship ore hold
 *
 */


function main()
{
	variable obj_LSTypeIterator ItemTest = "item"
	variable string MethodStr = "MyShip:GetOreHoldCargo"

  if !${MyShip.HasOreHold}
  {
    echo "Test skipped - MyShip.HasOreHold == false"
    return
  }
	MyShip:Open
	wait 15

	#include "../_Testcase_MethodStr_Body.iss"
}