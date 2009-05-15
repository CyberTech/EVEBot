#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Bookmark Members

	Revision $Id$

	Requirements:
		You:
		Bookmarks
		People & Places window must have been opened at least once
*/

variable obj_UI UI
function main()
{
	variable index:bookmark SafeSpots
	variable iterator SafeSpotIterator

	SafeSpots:Clear
	EVE:DoGetBookmarks[SafeSpots]

	SafeSpots:GetIterator[SafeSpotIterator]
	if ${SafeSpotIterator:First(exists)}
	do
	{
		echo "${SafeSpotIterator.Value.ID} - ${SafeSpotIterator.Value.Type} - ${SafeSpotIterator.Value.TypeID} - ${SafeSpotIterator.Value.SolarSystemID} ${Universe[${SafeSpotIterator.Value.SolarSystemID}].Name}"
	}
	while ${SafeSpotIterator:Next(exists)}
}
