function Undock()
{
	echo "Undocking"
	Me:Undock
	echo "Waiting 20 seconds"
	wait 200
	EVE:Execute[CmdActivateMediumPowerSlot1]
	EVE:Execute[CmdActivateLowPowerSlot1]
}

function Wrapping(int Id)
{
	Entity[ID,${Id}]:WarpTo
	wait 100
	echo "Warping, waiting..."
		while ${Me.ToEntity.Mode}==3
		{
		waitframe
		}
	echo "Waiting ends"
}

function ReturnToBase(int station)
{
	if ${Entity[ID,${station}].Distance}>=10000
	{
	echo "The distance is greater than 10000, warp to base"
		call Wrapping ${station}
	}
	wait 60
	if ${Entity[ID,${station}].Distance}>=800
	{
	echo "Calling an orbit for ${station}, distance is ${Entity[ID,${station}].Distance}"
	call Orbit ${station} 500
	}
	if ${Entity[ID,${station}].Distance}<800
	{
	echo "Calling docking, this is the actual distance : ${Entity[ID,${station}].Distance}, this is my station : ${station}"
	call Dock ${station}
	}
}

function Dock(int station)
{
	echo "we should be in docking range"
	Entity[ID,${station}]:Dock
	echo "Docking, waiting 20 sec"
	wait 200
}

function Orbit(int Id, int Distance)
{
	Entity[ID,${Id}]:Orbit[${Distance}]
	echo "Entering Orbit with ${Id}, waiting..."
		while ${Entity[ID,${Id}].Distance} > ${Math.Calc[${Distance}+500]}
		{
		waitframe
		}
		echo "Finish waiting, in orbit now"
}