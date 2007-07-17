function Undock()
{
	call UpdateHudStatus "Undocking"
	Me:Undock
	call UpdateHudStatus "Waiting..."
	do
	{
		wait 40
	}
	while ${Me.InStation}
	wait 60
	waitframe
	
}

function WarpTo(int Id)
{
  ;;;;;;;;;;;;;;;;;;
  ;;; Sanity Checks
	if (${Id} <= 0)
	{
	   echo "Error: oSpace::WarpTo --> Id is <= 0 (${Id})"
	   play:Set[FALSE]
	   return
	}
	if (!${Entity[ID,${Id}](exists)})
	{
	   echo "Error: oSpace::WarpTo --> No entity matched the ID given."
	   play:Set[FALSE]
	   return
	}
	 ;;;;;;;;;;;;;;;;;;
	
	
	Entity[ID,${Id}]:WarpTo
	wait 100
	call UpdateHudStatus "Warping, waiting..."
	do
	{
		wait 40
	}
	while (${Me.ToEntity.Mode} == 3)
	
	call UpdateHudStatus "Finished warping..."
	waitframe

}

	
function Dock(int Id)
{
  ;;;;;;;;;;;;;;;;;;
  ;;; Sanity Checks
	if (${Id} <= 0)
	{
	   echo "Error: oSpace::Dock --> Id is <= 0 (${Id})"
	   play:Set[FALSE]
	   return
	}
	if (!${Entity[ID,${Id}](exists)})
	{
	   echo "Error: oSpace::Dock --> No entity matched the ID given."
	   play:Set[FALSE]
	   return
	}
	;;;;;;;;;;;;;;;;;;



	while ${Entity[ID,${Id}].Distance} >= 10000
	{
	  	call UpdateHudStatus "The distance is greater than 10000, warp to base"
		call WarpTo ${Id}
		wait 50
	}

	
	call UpdateHudStatus "Approaching Base"
	do
	{
		Entity[ID,${Id}]:Approach
		wait 40
	}
	while ${Entity[ID,${Id}].Distance} > 10

	
	call UpdateHudStatus "In Docking Range ... Docking"

	call UpdateHudStatus "Docking, waiting..."
	do
	{
		Entity[ID,${Id}]:Dock
		wait 60
	}
	while !${Me.InStation}
	wait 40
	waitframe
	call UpdateHudStatus "Finished Docking"
}

function Orbit(int Id, int Distance)
{
  ;;;;;;;;;;;;;;;;;;
  ;;; Sanity Checks
	if (${Id} <= 0)
	{
	   echo "Error: oSpace::Orbit --> Id is <= 0 (${Id})"
	   play:Set[FALSE]
	   return
	}
	if (!${Entity[ID,${Id}](exists)})
	{
	   echo "Error: oSpace::Orbit --> No entity matched the ID given."
	   play:Set[FALSE]
	   return
	}
	;;;;;;;;;;;;;;;;;;

	wait 20
	Entity[ID,${Id}]:Orbit[${Distance}]
	call UpdateHudStatus "Entering Orbit with ${Id}, waiting..."
	
	while ${Entity[ID,${Id}].Distance} > ${Math.Calc[${Distance}+500]}
	{
		wait 40
	}
	waitframe
	call UpdateHudStatus "Finish waiting, in orbit now"
}