function Undock()
{
	call UpdateHudStatus "Undocking"
	EVE:Execute[CmdExitStation]	
	call UpdateHudStatus "Waiting while ship exits the station"
	do
	{
		wait 20
	}
	while ${Me.InStation}
	wait 20
}

function WarpTo(int Id)
{
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; Bring Drones Back In!
   variable index:int MyDrones
   variable int DronesInSpaceCount
   DronesInSpaceCount:Set[${EVE.GetEntityIDs[MyDrones,OwnerID,${Me.CharID},CategoryID,18]}]
  
   while (${DronesInSpaceCount} > 0)
   {
   echo Drones in space:: ${DronesInSpaceCount}
   EVE:DronesReturnToDroneBay[MyDrones]
   wait 200
   DronesInSpaceCount:Set[${EVE.GetEntityIDs[MyDrones,OwnerID,${Me.CharID},CategoryID,18]}]
   wait 10
   }
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	call UpdateHudStatus "Entity ${Id} : WarpTo succesfully called ... waiting for arrival"
	wait 120
	do
	{
		wait 20
	}
	while (${Me.ToEntity.Mode} == 3)
	
	call UpdateHudStatus "Finished warping..."
	
}

function ReturnToBase(int Id)
{        
  ; RETURNTOBASE CONTINUED

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


	if ${Entity[ID,${Id}].Distance} >= 10000
	{
	  call UpdateHudStatus "The distance is greater than 10000, warp to base"
		call WarpTo ${Id}
	}
}
	
function Dock()
{
  variable int WaitCount = 0

	stationloc:Set[${Entity[CategoryID,3].ID}]
	call UpdateHudStatus "Setting main station ${Entity[id,${stationloc}].Name} with ID ${stationloc}"
	wait 10
  ;;;;;;;;;;;;;;;;;;
  ;;; Sanity Checks
	if (${stationloc} <= 0)
	{
	   echo "Error: oSpace::Dock --> Id is <= 0 (${stationloc}) Getting a new one..."
		stationloc:Set[${Entity[CategoryID,3].ID}]
	}
	if (!${Entity[ID,${stationloc}].Name(exists)})
	{
	   echo "Error: oSpace::Dock --> No entity matched the ID given, getting another one..."
	   stationloc:Set[${Entity[CategoryID,3].ID}]
	}
	;;;;;;;;;;;;;;;;;;

while !${Me.InStation}
{
	if ${Entity[ID,${stationloc}].Distance} >= 10000
	{
	  call UpdateHudStatus "Calling ReturnToBase"
		call ReturnToBase ${stationloc}
		do
		{ 
		   wait 20
		}
		while ${Entity[ID,${stationloc}].Distance} >= 10000
	}
	elseif (${Entity[ID,${stationloc}].Distance} < 10000 && ${Entity[ID,${stationloc}].Distance} > 100)
	{
		call UpdateHudStatus "Approaching Base"
		Entity[ID,${stationloc}]:Approach
		do
		{
			wait 20
		}
		while ${Entity[ID,${stationloc}].Distance} > 100
	}
	elseif (${Entity[ID,${stationloc}].Distance} <= 100 && ${Me.ToEntity.Mode} != 3)
	{
		call UpdateHudStatus "In Docking Range ... Docking"
		Entity[ID,${stationloc}]:Dock
		call UpdateHudStatus "Docking, waiting..."
		do
		{
		   wait 20
		   WaitCount:Inc[20]
		}
		while (!${Me.InStation} && ${WaitCount} < 200)
		WaitCount:Set[0]
		if (!${Me.InStation})
		{
		  call UpdateHudStatus "First Attempt at docking with failed...trying again."
		  Entity[CategoryID,3]:Dock
			do
			{
		  	 wait 20
		  	 WaitCount:Inc[20]
			}
			while (!${Me.InStation} && ${WaitCount} < 200)
			WaitCount:Set[0]
		}
		if (!${Me.InStation})
		{
		  call UpdateHudStatus "Second Attempt at docking with failed...trying one last time."
		  Entity[CategoryID,3]:Dock
			do
			{
		  	 wait 20
		  	 WaitCount:Inc[20]
			}
			while (!${Me.InStation} && ${WaitCount} < 200)
			WaitCount:Set[0]
		}		
		wait 20
		call UpdateHudStatus "Finished Docking"
	}
}

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
 
	GoalDistance:Set[${Math.Calc[${Distance}+1000]}]
	call UpdateHudStatus "Entering Orbit with ${Id}, waiting until distance is <= ${GoalDistance}"
 
	do
	{
	  wait 20
	}	
	while ${Entity[ID,${Id}].Distance} > ${GoalDistance}
 
	call UpdateHudStatus "Wait Complete.  Distance to roid is ${Entity[ID,${Id}].Distance}"
	; ************ possibility of a crash here ***********
	wait 20
	call UpdateHudStatus "After the final wait"
	call UpdateHudStatus "Finish waiting, in orbit now"
}

function CheckOrbit(int id, int Distance)
{
	if ${Entity[ID,${id}].Distance} > ${GoalDistance}
	{
	call UpdateHudStatus "Wtf getting out of orbit, calling orbit again..."
	Entity[ID,${id}]:Orbit[${Distance}]
	}
}

function Transport()
{
	if ${Triolet.CanList.Get[1](exists)}
	{
		call UpdateHudStatus "There is a can somewhere!"
		if ${Entity[ID,${Triolet.CanList.Get[1]}].Distance} >= 10000
		{
		call UpdateHudStatus "Warping to that can!"
		call WarpTo ${Entity[ID,${Triolet.CanList.Get[1]}]}
		}
		elseif ${Entity[ID,${Triolet.CanList.Get[1]}].Distance} < 10000
		{
			call UpdateHudStatus "Approaching Can..."
			Entity[ID,${Triolet.CanList.Get[1]}]:Approach
			do
			{
				wait 20
			}
			while ${Entity[ID,${Triolet.CanList.Get[1]}].Distance} > 800
		}
		call UpdateHudStatus "Transfering can ore to my hauler!"
		call TransferToHauler
		if ${Me.Ship.UsedCargoCapacity} >= ${Math.Calc[${Me.Ship.CargoCapacity}*0.80]}
		{
		call Dock
		}
		if ${Me.InStation}
		{
			call UpdateHudStatus "I'm in the station"
			call TransferToHangar
			call Undock
			wait 50
		}
		else
		{
			return
		}
	}
}