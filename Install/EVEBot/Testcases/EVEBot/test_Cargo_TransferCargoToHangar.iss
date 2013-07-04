#define TESTCASE 1

/*
	Test EVEBot obj_Cargo.TransferCargoToStationHangar

	Revision $Id$

	Requirements:
		None

*/

#include Scripts/EVEBot/Support/TestAPI.iss
#include ../../Branches/Stable_Patches/core/obj_EVEBot.iss
#include ../../Branches/Stable_Patches/core/obj_Drones.iss
#include ../../Branches/Stable_Patches/core/obj_Ship.iss
#include ../../Branches/Stable_Patches/core/obj_Station.iss
#include ../../Branches/Stable_Patches/core/obj_Cargo.iss


function main()
{
	echo "obj_Cargo.TransferCargoToStationHangar: Test Case:"

	declarevariable EVEBot obj_EVEBot global
	declarevariable Ship obj_Ship global
	declarevariable Station obj_Station global
	declarevariable Cargo obj_Cargo global

	call Cargo.TransferCargoToStationHangar
}
