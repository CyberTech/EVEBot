#define TESTCASE 1

/*
	Test EVEBot obj_Cargo.TransfeOreToHangar

	Revision $Id$

	Requirements:
		None

*/

#include ../Support/TestAPI.iss
#include ../core/obj_EVEBot.iss
#include ../core/obj_Drones.iss
#include ../core/obj_Ship.iss
#include ../core/obj_Station.iss
#include ../core/obj_Cargo.iss

variable obj_UI UI

function main()
{
	echo "obj_Cargo.TransfeOreToHangar: Test Case:"

	declarevariable EVEBot obj_EVEBot global
	declarevariable Ship obj_Ship global
	declarevariable Station obj_Station global
	declarevariable Cargo obj_Cargo global

	call Cargo.TransferOreToHangar
}
