#define TESTCASE 1

/*
	Test EVEBot ItemDB Loading & Members

	Revision $Id: test_evebot_itemdb.iss 1200 2009-06-17 00:36:15Z gliderpro $

	Requirements:
		None

*/

#include ../../Support/TestAPI.iss
#include ../Branches/Dev/core/obj_Station.iss


function main()
{
	echo "obj_EVEDB_StationID: Member Test Case:"

	declarevariable stationdb obj_EVEDB_StationID

	echo StationID: ${stationdb.StationID[Eiluvodi VI - Moon 14 - CBD Corporation Storage]}
	echo StationID: ${stationdb.StationID[Edmalbrurdus I - Republic University School]}
}
