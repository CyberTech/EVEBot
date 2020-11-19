#define EVEBOT_TESTCASE 1

;#include ../../Support/TestAPI.iss
#include ../../Branches/Stable/EVEBot.iss

/*
 *	Asteroid Belt iteration and warping
 *
 *	Tests:
 *		Belts.WarpToNext
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
    echo At Belt: ${Belts.AtBelt} @ Distance: ${Belts.Distance} Total: ${Belts.Total} Named: ${Belts.Name}
    call Belts.WarpToNext 150000
    wait 10
  }
}
