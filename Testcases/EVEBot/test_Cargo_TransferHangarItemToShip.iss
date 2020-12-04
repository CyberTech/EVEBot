#define EVEBOT_TESTCASE 1

;#include ../../Support/TestAPI.iss
#include ../../Branches/Stable/EVEBot.iss

/*
	Test EVEBot obj_Cargo.TransferHangarItemToShip

	Requirements:
		None

*/

function main()
{
  cd "../../Branches/Stable/EVEBot.iss"
  call evebot_main
  while !${EVEBot.Loaded}
  {
    wait 1
  }

	echo "obj_Cargo.TransferHangarItemToShip: Test Case:"

	declarevariable EVEBot obj_EVEBot global
	declarevariable Ship obj_Ship global
	declarevariable Station obj_Station global
	declarevariable Cargo obj_Cargo global

	call Cargo.TransferHangarItemToShip
}
