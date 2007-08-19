function Mine()
{
	belt:Set[${Entity[GroupID,9].ID}]
	if (${belt} <= 0)
	{
	   echo "Error: oMining:Mine --> No asteroid belt in the area..."
	   play:Set[FALSE]
	   return
	}
	
	call UpdateHudStatus "Setting roid belt ${Entity[id,${belt}].Name} with id ${Entity[id,${belt}].ID}"
	wait 20	
	
	call UpdateHudStatus "About to warp, this is a log check"
	call WarpTo ${belt}
	call UpdateHudStatus "Warp Command Given"
	wait 10

	while ${Me.Ship.CargoCapacity} > ${Me.Ship.UsedCargoCapacity.Round}
	{
		if (${roid} > 0)
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
				if (${roid} > 0)
				{
					call UpdateHudStatus "Setting roid to ${Entity[CategoryID,25].Name} with id ${Entity[CategoryID,25].ID} -- calling Orbit..."
					call Orbit ${roid} 5000
				
					Entity[ID,${roid}]:LockTarget
					call UpdateHudStatus "Locking roid target"
					do
					{
						wait 20
					}
					while ${Entity[ID,${roid}].BeingTargeted}
				
					echo "Activating Mining Laser, waiting for full cargo..."
					EVE:Execute[CmdActivateHighPowerSlot1]
					wait 10
					EVE:Execute[CmdActivateHighPowerSlot2]
					call UpdateHudStatus "IMMA FIRIN MAH LAZOR!"
					wait 20
				}
			}
		}
		else
		{
		    roid:Set[${Entity[CategoryID,25].ID}]
		}
	}
	call UpdateHudStatus "End waiting, cargo is full"
	if (${roid} > 0)
	{
		Entity[ID,${roid}]:UnlockTarget 
		call UpdateHudStatus "Unlocking target"
	}
}