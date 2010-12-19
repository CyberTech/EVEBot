function main()
{
	variable index:item MyCargo
	variable iterator CargoIterator
	variable index:int64 IDList

	echo "Version: ${ISXEVE.Version}"

	EVE:Execute[OpenCargoHoldOfActiveShip]
	EVE:Execute[OpenHangarFloor]
	Wait 100

	Me.Station:DoGetHangarItems[MyCargo]
	echo "Hangar contains ${MyCargo.Used} Items"

	MyCargo:GetIterator[CargoIterator]
	if ${CargoIterator:First(exists)}
	do
	{
		echo "Adding ID: ${CargoIterator.Value} ${CargoIterator.Value.ID}"
		IDList:Insert[${CargoIterator.Value.ID}]
	}
	while ${CargoIterator:Next(exists)}

	IDList:Clear
	IDList:Insert[${MyCargo[1].ID}]
	echo "Have ${IDList.Used} Items to move"

	EVE:MoveItemsTo[IDList, MyShip]
}