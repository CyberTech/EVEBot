#define TESTCASE 1

/*
	Test EVEBot ItemDB Loading & Members

	Revision $Id$

	Requirements:
		None

*/

#include Scripts/EVEBot/Support/TestAPI.iss
#include ../Branches/Dev/core/obj_EVEDB.iss


function main()
{
	echo "obj_EVEDB_Items: Member Test Case:"

	declarevariable itemdb obj_EVEDB_Items

	echo TypeID: ${itemdb.TypeID[Tritanium]}
	echo Name: ${itemdb.Name[34]}
	echo Metalevel: ${itemdb.Metalevel[34]}
	echo Volume: ${itemdb.Volume[34]}
	echo Capacity: ${itemdb.Capacity[34]}
	echo GroupID: ${itemdb.GroupID[34]}
	echo PortionSize: ${itemdb.PortionSize[34]}
	echo BasePrice: ${itemdb.BasePrice[34]}
}
