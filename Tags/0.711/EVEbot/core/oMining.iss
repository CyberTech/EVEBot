function Mine()
{
	station:Set[${Entity[CategoryID,3].ID}]
	echo "Setting main station ${Entity[CategoryID,3].Name} with id ${Entity[CategoryID,3].ID}"
	belt:Set[${Entity[GroupID,9].ID}]
	echo "Setting roid belt ${Entity[GroupID,9].Name} with id ${Entity[GroupID,9].ID}"
	
	call Wrapping ${belt}
	
	roid:Set[${Entity[CategoryID,25].ID}]
	echo "Setting roid belt ${Entity[CategoryID,25].Name} with id ${Entity[[CategoryID,25].ID}"
	
	call Orbit ${roid}

	Entity[ID,${roid}]:LockTarget
	echo "Locking roid target"
	EVE:Execute[CmdActivateHighPowerSlot1]
	echo "Activating Mining Laser, waiting for full cargo..."
		while ${Me.Ship.CargoCapacity} > ${Me.Ship.UsedCargoCapacity}
		{
		wait 50
		}
	echo "End waiting, cargo is full"
	Entity[ID,${roid}]:UnlockTarget
	echo "Unlocking target"
}