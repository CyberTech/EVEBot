#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss
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

	declarevariable Stations index:int64 script
	variable iterator StationIterator

	if !${EVEWindow[ByCaption,"ASSETS"](exists)}
	{
		EVE:Execute[OpenAssets]
		wait 50
	}

	StartTime:Set[${Script.RunningTime}]
	Me:GetStationsWithAssets[Stations]
	echo "Me:GetStationsWithAssets returned ${Stations.Used} stations"

	Stations:GetIterator[StationIterator]
	if ${StationIterator:First(exists)}
	do
	{
		echo "  Station ID: ${StationIterator.Value}"
	}
	while ${StationIterator:Next(exists)}

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of GetStationsWithAssets completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}