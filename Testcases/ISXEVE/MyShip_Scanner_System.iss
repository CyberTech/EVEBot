#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test retrieval of system scanner modules and methods EXCEPT for GetAnomalies/GetSignatures

	Revision $Id$

	Requirements:
		1) In Space
		2) Inside a ship
*/

function main()
{
	echo "Enabling sensor overlay..."
	MyShip.Scanners.System:EnableSensorOverlay
	wait 10
	if ${MyShip.Scanners.System.IsSensorOverlayActive}
		echo MyShip.Scanners.System.IsSensorOverlayActive == TRUE (PASS)
	else
		echo MyShip.Scanners.System.IsSensorOverlayActive != TRUE (FAIL)

	echo "Disabling sensor overlay..."
	MyShip.Scanners.System:DisableSensorOverlay
	wait 10
	if ${MyShip.Scanners.System.IsSensorOverlayActive}
		echo MyShip.Scanners.System.IsSensorOverlayActive == TRUE (FAIL)
	else
		echo MyShip.Scanners.System.IsSensorOverlayActive != TRUE (PASS)	
}