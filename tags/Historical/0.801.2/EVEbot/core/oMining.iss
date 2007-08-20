function Mine()
{
	belt:Set[${Entity[GroupID,9].ID}]
	echo "Setting roid belt ${Entity[GroupID,9].Name} with id ${Entity[GroupID,9].ID}"
	
	call Wrapping ${belt}
	roid:Set[0]

		while ${Me.Ship.CargoCapacity} > ${Me.Ship.UsedCargoCapacity.Round}
		{
			if ${Entity[ID,${roid}].IsLockedTarget}
			{
			wait 50
			;call DefendAndDestroy
			;call TrainSkills
			}
			else
			{
				roid:Set[${Entity[CategoryID,25].ID}]
				echo "Setting roid to ${Entity[CategoryID,25].Name} with id ${Entity[CategoryID,25].ID}"
				
				call Orbit ${roid} 5000
				
				Entity[ID,${roid}]:LockTarget
				echo "Locking roid target"
				
				do
				{
				wait 20
				}
				while ${Entity[ID,${roid}].BeingTargeted}
				
				echo "Activating Mining Laser, waiting for full cargo..."
				EVE:Execute[CmdActivateHighPowerSlot1]
				wait 10
				EVE:Execute[CmdActivateHighPowerSlot2]
				wait 10
			}
		}
	echo "End waiting, cargo is full"
	Entity[ID,${roid}]:UnlockTarget
	echo "Unlocking target"
}