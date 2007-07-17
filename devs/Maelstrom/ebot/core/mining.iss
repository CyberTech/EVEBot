
function gotoasteroidbelt(int id, int d)
{
	if ${id} != 0
		call warpto ${id} ${d}
	else
		call warpto ${Entity[GroupID,9].ID} 0
}

function gotoasteroid(int id, int d)
{
	if ${id} != 0
		call approach ${id} ${d}
	else
		call approach ${Entity[CategoryID,25].ID} 9000
}

function mine()
{
	echo mining,mine: Mining Expedition Started
	call gotoasteroidbelt
	
	while ${Me.Ship.UsedCargoCapacity} < ${Math.Calc[${Me.Ship.CargoCapacity}-1]}
	{
		while ${Me.Ship.UsedCargoCapacity} < ${Math.Calc[${Me.Ship.CargoCapacity}-1]}
		{
			if ${Me.ActiveTarget.Distance} > 9000
				call gotoasteroid
			if !${Me.ActiveTarget(exists)}
			{
				echo mining,mine: No ActiveTarget
				call gotoasteroid
				if ${Me.ActiveTarget.Name.Find[Asteroid]} > 0 && ${Me.ActiveTarget.Distance} < 9000
				{
					echo mining,mine: EVE:Execute[CmdActivateHighPowerSlot1]
					EVE:Execute[CmdActivateHighPowerSlot1]
					wait 20
					echo mining,mine: EVE:Execute[CmdActivateHighPowerSlot2]
					EVE:Execute[CmdActivateHighPowerSlot2]
				}
			}
			wait 20
		}
		echo Mine: Cargo Check in 2 Seconds
		wait 20
	}
}
