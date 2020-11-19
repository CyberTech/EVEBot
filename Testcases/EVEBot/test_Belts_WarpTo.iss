#define EVEBOT_TESTCASE 1

;#include ../../Support/TestAPI.iss
#include ../../Branches/Stable/EVEBot.iss

/*
 *	Asteroid Belt iteration and warping
 *
 *	Tests:
 *		Belts.WarpTo
 *		Belts:Next
 *
 *	Requirements:
 *		You: In system with asteroid belts

 */

function main()
{
  cd "../../Branches/Stable/EVEBot.iss"
  call evebot_main
  while !${EVEBot.Loaded}
  {
    wait 1
  }

  call Station.Undock

  while TRUE
  {
    call Belts.WarpTo 150000
    wait 1
    echo At Belt: ${Belts.AtBelt} @ Distance: ${Belts.Distance} Total: ${Belts.Total} Named: ${Belts.Name}
    wait 10
    Belts:Next
  }
}
