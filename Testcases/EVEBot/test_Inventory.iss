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

	variable iterator varscope
	declarevariable Inventory obj_Inventory script

	Inventory.VariableScope:GetIterator[varscope]

	call Inventory.ShipCargo.Activate
	if ${Return}
		Inventory.Current:DebugPrintInvData

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

}


