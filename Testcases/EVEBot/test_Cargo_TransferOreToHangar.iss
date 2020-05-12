#define TESTCASE 1

/*
	Test EVEBot obj_Cargo.TransferCargoToStationHangar

	Revision $Id$

	Requirements:
		None

*/

#include ../../Support/TestAPI.iss
#include ../../Branches/Stable/core/obj_EVEBot.iss
#include ../../Branches/Stable/core/obj_Drones.iss
#include ../../Branches/Stable/core/obj_Ship.iss
#include ../../Branches/Stable/core/obj_Station.iss
#include ../../Branches/Stable/core/obj_Cargo.iss


function main()
{
	echo "obj_Cargo.TransferOreToStationHangar: Test Case:"

	declarevariable EVEBot obj_EVEBot global
	declarevariable Ship obj_Ship global
	declarevariable Station obj_Station global
	declarevariable Cargo obj_Cargo global

	call Cargo.TransferOreToStationHangar
}
