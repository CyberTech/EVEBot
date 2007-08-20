function Mine()
{
	belt:Set[${Entity[GroupID,9].ID}]
	call UpdateHudStatus "Setting roid belt ${Entity[GroupID,9].Name} with id ${Entity[GroupID,9].ID}"
	wait 20	

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
				call UpdateHudStatus "Setting roid to ${Entity[CategoryID,25].Name} with id ${Entity[CategoryID,25].ID}"
				
				call Orbit ${roid} 5000
				
				Entity[ID,${roid}]:LockTarget
				call UpdateHudStatus "Locking roid target"
				
				do
				{
				wait 20
				}
				while ${Entity[ID,${roid}].BeingTargeted}
				
				call UpdateHudStatus "Activating Mining Laser, waiting for full cargo..."
				EVE:Execute[CmdActivateHighPowerSlot1]
				wait 10
				EVE:Execute[CmdActivateHighPowerSlot2]
				wait 10
			}
		}
	call UpdateHudStatus "End waiting, cargo is full"
	Entity[ID,${roid}]:UnlockTarget
	call UpdateHudStatus "Unlocking target"
}