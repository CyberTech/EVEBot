function Mine()
{
	belt:Set[${Entity[GroupID,9].ID}]
	echo "Setting roid belt ${Entity[GroupID,9].Name} with id ${Entity[GroupID,9].ID}"
	
	call Wrapping ${belt}
	
	roid:Set[${Entity[CategoryID,25].ID}]
	echo "Setting roid to ${Entity[CategoryID,25].Name} with id ${Entity[CategoryID,25].ID}"
	
	call Orbit ${roid} 5000

	Entity[ID,${roid}]:LockTarget
	echo "Locking roid target"
	EVE:Execute[CmdActivateHighPowerSlot1]
	wait 20
	EVE:Execute[CmdActivateHighPowerSlot2]
	echo "Activating Mining Laser, waiting for full cargo..."
		while ${Me.Ship.CargoCapacity} > ${Me.Ship.UsedCargoCapacity}
		{
		wait 50
		;call DefendAndDestroy
		;call TrainSkills
		}
	echo "End waiting, cargo is full"
	Entity[ID,${roid}]:UnlockTarget
	echo "Unlocking target"
}