function Undock()
{
	echo "Undocking"
	Me:Undock
	echo "Waiting 20 seconds"
	wait 200
}

function Wrapping(int Id)
{
	Entity[ID,${Id}]:WarpTo
	wait 50
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
	call Dock ${station}
}

function Dock(int station)
{
	echo "we should be in docking range"
	Entity[ID,${station}]:Dock
	echo "Docking, waiting 20 sec"
	wait 200
}

function Orbit(int Id)
{
	Entity[ID,${Id}]:Orbit
	echo "Entering Orbit with belt, waiting..."
		while ${Entity[ID,${Id}].Distance} > 5500
		{
		waitframe
		}
		echo "Finish waiting, in orbit now"
}