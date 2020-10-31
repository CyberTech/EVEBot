#define TESTCASE 1

#include ../../Support/TestAPI.iss
/*
 *	Test GetHangarItems
 *
 *	Revision $Id$
 *
 *	Requirements:
 *		Docked, have items in station hangar
 *
 */


function main()
{
	variable index:item Items
	variable string MethodStr = "Me.Station:GetHangarItems"

	EVE:Execute[OpenHangarFloor]
	wait 15

	Me.Station:GetHangarItems[Items]
	variable iterator ThisItem
	Items:GetIterator[ThisItem]
	if ${ThisItem:First(exists)}
	{
		do
		{
			; Freight Container 649 General Freight Container
			; Secure Cargo Container 340 Giant Secure Container
			if ${ThisItem.Value.Name.Equal["Calm Firestorm Filament"]}
			{
				echo "Activating ${ThisItem.Value.ID} ${ThisItem.Value.Name}"
				ThisItem.Value:UseAbyssalFilament
				break
			}
		}
		while ${ThisItem:Next(exists)}
	}
}