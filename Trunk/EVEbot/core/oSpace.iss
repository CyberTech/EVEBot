function Dock()
{
	variable int Counter = 0
	variable int StationID = ${Entity[CategoryID,3,${Config.Common.HomeStation}].ID}

	call UpdateHudStatus "Docking at ${StationID}:${Config.Common.HomeStation}"

  ;;;;;;;;;;;;;;;;;;
  ;;; Sanity Checks
	if (${StationID} <= 0)
	{
		call UpdateHudStatus "Error: oSpace::Dock --> Home Station unknown, going to nearest base"
		StationID:Set[${Entity[CategoryID,3].ID}]
	}

	if ${Entity[${StationID}].Distance} >= 10000
	{
	  call UpdateHudStatus "Warping to Station"
		call Ship.WarpToID ${StationID}
		do
		{ 
		   wait 20
		}
		while ${Entity[${StationID}].Distance} >= 10000
	}

	Entity[${StationID}]:Approach
	do
	{
		wait 20
	}
	while (${Entity[${StationID}].Distance} > 100)
	
	Counter:Set[0]
	call UpdateHudStatus "In Docking Range ... Docking"
	Entity[${StationID}]:Dock			
	do
	{
	   wait 20
	   Counter:Inc[20]
	   if (${Counter} > 200)
	   {
	      call UpdateHudStatus " - Docking atttempt failed ... trying again."
	      Entity[${StationID}]:Dock	
	      Counter:Set[0]
	   }
	}
	while (!${Me.InStation})					

	wait 20
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
	if (!${Entity[${Id}](exists)})
	{
	   echo "Error: oSpace::Orbit --> No entity matched the ID given."
	   play:Set[FALSE]
	   return
	}
	;;;;;;;;;;;;;;;;;;
 
	Entity[${Id}]:Orbit[${Distance}]
 
	GoalDistance:Set[${Math.Calc[${Distance}+1000]}]
	call UpdateHudStatus "Entering Orbit with ${Id}, waiting until distance is <= ${GoalDistance}"
 
	do
	{
	  wait 20
	}	
	while ${Entity[${Id}].Distance} > ${GoalDistance}
 
	call UpdateHudStatus "Wait Complete.  Distance to roid is ${Entity[${Id}].Distance}"
	; ************ possibility of a crash here ***********
	wait 20
	call UpdateHudStatus "After the final wait"
	call UpdateHudStatus "Finish waiting, in orbit now"
}

function CheckOrbit(int id, int Distance)
{
	if ${Entity[${id}].Distance} > ${GoalDistance}
	{
	call UpdateHudStatus "Wtf getting out of orbit, calling orbit again..."
	Entity[${id}]:Orbit[${Distance}]
	}
}