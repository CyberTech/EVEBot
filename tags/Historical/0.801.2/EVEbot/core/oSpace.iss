function Undock()
{
	echo "Undocking"
	Me:Undock
	echo "Waiting..."
		do
		{
		wait 20
		}
		while ${Me.InStation}
	wait 20
	EVE:Execute[CmdActivateMediumPowerSlot1]
	wait 10
	EVE:Execute[CmdActivateMediumPowerSlot2]
	wait 10
	EVE:Execute[CmdActivateLowPowerSlot1]
	wait 10
}

function Wrapping(int Id)
{
	Entity[ID,${Id}]:WarpTo
	wait 60
	echo "Warping, waiting..."
		while ${Me.ToEntity.Mode}==3
		{
		wait 30
		}
	echo "Waiting ends"
	wait 50
}

function ReturnToBase(int station)
{
	if ${Entity[ID,${station}].Distance}>=10000
	{
	  echo "The distance is greater than 10000, warp to base"
		call Wrapping ${station}
	}
	
	Entity[ID,${station}]:Approach
		do
		{
		wait 20
		}
		while ${Entity[ID,${station}].Distance} > 0

	echo "Calling docking, this is the actual distance : ${Entity[ID,${station}].Distance}, this is my station : ${station}"
	call Dock ${station}
}

function Dock(int station)
{
	echo "we should be in docking range"
	Entity[ID,${station}]:Dock
	echo "Docking, waiting..."
		do
		{
		wait 20
		}
		while !${Me.InStation}
	wait 20
	echo "End waiting"
}

function Orbit(int Id, int Distance)
{
	Entity[ID,${Id}]:Orbit[${Distance}]
	echo "Entering Orbit with ${Id}, waiting..."
		while ${Entity[ID,${Id}].Distance} > ${Math.Calc[${Distance}+500]}
		{
		wait 20
		}
	wait 40	
	echo "Finish waiting, in orbit now"
}