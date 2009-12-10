#define TESTCASE 1

#include ../Support/TestAPI.iss
/*
 *	Test DoGetStationsWithAssets
 *
 *	Requirements:
 *		Open assets window
 *
 */


function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	declarevariable Stations index:int script
	variable iterator StationIterator

	if !${EVEWindow[ByCaption,"ASSETS"](exists)}
	{
		EVE:Execute[OpenAssets]
		wait 50
	}

	StartTime:Set[${Script.RunningTime}]
	Me:DoGetStationsWithAssets[Stations]
	echo "Me:DoGetStationsWithAssets returned ${Stations.Used} stations"

	Stations:GetIterator[StationIterator]
	if ${StationIterator:First(exists)}
	do
	{
		echo "  Station ID: ${StationIterator.Value}"
	}
	while ${StationIterator:Next(exists)}

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of DoGetStationsWithAssets completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}