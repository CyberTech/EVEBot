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
	
	;EVE:Execute[CmdActivateMediumPowerSlot1]
	;wait 10
	;EVE:Execute[CmdActivateLowPowerSlot1]
	;wait 10
	;EVE:Execute[CmdActivateMediumPowerSlot2]
}

function WarpTo(int Id, int Distance=0)
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
	if ${Entity[id,${Id}].Name.Find[Asteroid Belt]}>0 && ${Entity[id,${Id}].Distance} <= 30000
	{
	   return
	}
	 ;;;;;;;;;;;;;;;;;;
	
	
	Entity[ID,${Id}]:WarpTo[${Distance}]
	wait 100
	call UpdateHudStatus "Warping, waiting..."
	do
	{
		wait 20
	}
	while (${Me.ToEntity.Mode} == 3)
	
	call UpdateHudStatus "Finished warping..."
	wait 50

}

function ReturnToBase(int Id, bool nomsg=FALSE)
{
  ;;;;;;;;;;;;;;;;;;
  ;;; Sanity Checks
	if (${Id} <= 0)
	{
	   echo "Error: oSpace::ReturnToBase --> Id is <= 0 (${Id})"
	   play:Set[FALSE]
	   return
	}
	if (!${Entity[ID,${Id}](exists)})
	{
	   echo "Error: oSpace::ReturnToBase --> No entity matched the ID given."
	   play:Set[FALSE]
	   return
	}
	;;;;;;;;;;;;;;;;;;


	if ${Entity[ID,${Id}].Distance} >= 10000 && !${nomsg}
	{
	  call UpdateHudStatus "The distance is greater than 10000, warp to base"
		call WarpTo ${Id}
	}
	elseif ${Entity[ID,${Id}].Distance} >= 10000 && ${nomsg}
	{
		call WarpTo ${Id}
	}

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


	if ${Entity[ID,${Id}].Distance} >= 10000
	{
	  call UpdateHudStatus "The distance is greater than 10000, calling ReturnToBase"
		call ReturnToBase ${Id} 1
		do
		{ 
		   wait 20
		}
		while ${Entity[ID,${Id}].Distance} >= 10000
	}
	
	call UpdateHudStatus "Approaching Base"
	Entity[ID,${Id}]:Approach
	do
	{
		wait 20
	}
	while ${Entity[ID,${Id}].Distance} > 0

	
	call UpdateHudStatus "In Docking Range ... Docking"
	Entity[ID,${stationloc}]:Dock
	call UpdateHudStatus "Docking, waiting..."
	do
	{
		wait 20
	}
	while !${Me.InStation}
		
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
	if (!${Entity[ID,${Id}](exists)})
	{
	   echo "Error: oSpace::Orbit --> No entity matched the ID given."
	   play:Set[FALSE]
	   return
	}
	;;;;;;;;;;;;;;;;;;

	Entity[ID,${Id}]:Orbit[${Distance}]
	call UpdateHudStatus "Entering Orbit with ${Id}, waiting..."
	
	while ${Entity[ID,${Id}].Distance} > ${Math.Calc[${Distance}+500]}
	{
		wait 20
	}
	
	call UpdateHudStatus "Finish waiting, in orbit now"
}