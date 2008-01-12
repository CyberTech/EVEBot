

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
	UI:UpdateConsole["Entering Orbit with ${Id}, waiting until distance is <= ${GoalDistance}"]
 
	do
	{
	  wait 20
	}	
	while ${Entity[${Id}].Distance} > ${GoalDistance}
 
	UI:UpdateConsole["Wait Complete.  Distance to roid is ${Entity[${Id}].Distance}"]
	; ************ possibility of a crash here ***********
	wait 20
	UI:UpdateConsole["After the final wait"]
	UI:UpdateConsole["Finish waiting, in orbit now"]
}

function CheckOrbit(int id, int Distance)
{
	if ${Entity[${id}].Distance} > ${GoalDistance}
	{
	UI:UpdateConsole["Wtf getting out of orbit, calling orbit again..."]
	Entity[${id}]:Orbit[${Distance}]
	}
}