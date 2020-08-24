#define TESTCASE 1
/*
	Test EVEBot Inventory proxy

	Revision $Id$

	Requirements:
		None

*/

#include ../../Support/TestAPI.iss
#include ../../Branches/Stable/core/obj_Inventory.iss

function main()
{
	echo "obj_Inventory: Member Test Case:"

	declarevariable Inventory obj_Inventory script

	;call Inventory.ShipCargo.Activate ${MyShip.ID}
	;if ${Return}
	;	Inventory.Current:DebugPrintInvData

/*
	call Inventory.ShipFleetHangar.Activate
	if ${Return}
		Inventory.Current:DebugPrintInvData

	call Inventory.ShipOreHold.Activate
	if ${Return}
		Inventory.Current:DebugPrintInvData

	call Inventory.ShipDroneBay.Activate
	if ${Return}
		Inventory.Current:DebugPrintInvData

	call Inventory.StationHangar.Activate ${Me.Station.ID}
	if ${Return}
		Inventory.Current:DebugPrintInvData

	call Inventory.StationCorpHangars.Activate ${Me.Station.ID}
	if ${Return}
		Inventory.Current:DebugPrintInvData

	call Inventory.CorporationDeliveries.Activate ${Me.Station.ID}
	if ${Return}
		Inventory.Current:DebugPrintInvData
*/

	call Inventory.OpenEntityFleetHangar ${Entity[Name = "OrcaPilot"].ID}
	call Inventory.EntityFleetHangar.Activate ${Return}
	if !${Return}
	{
		echo Failed to activate inventory, aborting test
		Script:End
	}

	Inventory.Current:DebugPrintInvData
	Inventory.Current:GetItems[]
	;Inventory.Current:GetItems[NULL, "CategoryID == CATEGORYID_CHARGE"]

	variable iterator iter
	Inventory.Current.Items:GetIterator[iter]
	if ${iter:First(exists)}
	do
	{
		echo ${iter.Value.ID} ${iter.Value.LocationID} ${iter.Value.SlotID}:${iter.Value.Slot} - ${iter.Value.Name}
	}
	while ${iter:Next(exists)}
}


