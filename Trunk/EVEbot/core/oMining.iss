function GetRoids(string prefroid)
{
	RoidCount:Set[0]
	LavishSettings[Roids]:Import[${Script.CurrentDirectory}/config/roids.xml]
	while ${RoidCount} <= 0
	{
		if ${RoidType${RoidTypeCnt}(exists)}
		{
			RoidCount:Set[${EVE.GetEntities[Roids,CategoryID,25,${RoidType${RoidTypeCnt}}]}]
			RoidTypeCnt:Inc
			waitframe
		}
		else
		{
			call UpdateHudStatus "No Asteroids Available in Belt"
			RoidTypeCnt:Set[1]
			return NOROIDS
		}		
	}
	;call UpdateHudStatus "DEBUG: Asteroid Type: ${RoidType${RoidTypeCnt:Dec}}"
		
	
	;call UpdateHudStatus "DEBUG: RoidCount ${RoidCount}"
	;call UpdateHudStatus "DEBUG: Roids[1] ${Roids[1]}"
}

function GetBelts()
{
	BeltCount:Set[${EVE.GetEntities[Belts,GroupID,9]}]
	;call UpdateHudStatus "DEBUG: BeltCount ${BeltCount}"
}

function ActivateMiningLasers()
{
   variable int ModulesCount = 0
   variable index:module Modules
   variable int i = 1
   
   ModulesCount:Set[${Me.Ship.GetModules[Modules]}]
   
   if (${ModulesCount} < 1)
   {
       call UpdateHudStatus "ERROR:  You appear to have no modules on this ship!  How did that happen?!"
 	   	 play:Set[FALSE]
	  	 return      
   }
   
   do
   {
      if (${Modules.Get[${i}].MiningAmount} > 0)
      {
          if !${Modules.Get[${i}].IsActive}
          {
          	wait 5
          	call UpdateHudStatus "Powering Up: ${Modules.Get[${i}].ToItem.Name}"
          	Modules.Get[${i}]:Click
          	wait 5
          }
		  else
		  {
		  	wait 5
          	call UpdateHudStatus "Powering Down: ${Modules.Get[${i}].ToItem.Name} to start it again"
          	Modules.Get[${i}]:Click
		    wait 20
          	call UpdateHudStatus "Powering Up: ${Modules.Get[${i}].ToItem.Name}"
          	Modules.Get[${i}]:Click
          	wait 5
		  }
      }
      wait 2
   }
   while ${i:Inc} <= ${ModulesCount}
      
   return
}

function Mine()
{
	declare curBelt int
	declare RoidCnt int 1
	declare HighSlot1 bool True
	declare bHighSlot1 bool ${aHighSlot1}
	aHighSlot1:${Me.Ship.Module[HiSlot1].IsActive}
	RoidTypeCnt:Set[1]

	call GetBelts
	if (${BeltCount} <= 0)
	{
		echo "Error: oMining:Mine --> No asteroid belt in the area..."
		play:Set[FALSE]
		return
	}
	else
	{
		curBelt:Set[1]
	}
	call UpdateHudStatus "Setting roid belt ${Belts[${curBelt}].Name} with id ${Belts[${curBelt}]}"
	wait 20
	
	if ${Belts[${curBelt}].Distance} > 30000
	{
	   call UpdateHudStatus "Warping to roid belt: ${Belts[${curBelt}].Name}"
	   call WarpTo ${Belts[${curBelt}]}
	}
	
	Call LaunchDrones
	wait 5
	;don't use that if you have offensive med or low slot...
	;call ActivateDefense
	
	
	call UpdateHudStatus "Opening Cargo Hold for mining..."
  EVE:Execute[OpenCargoHoldOfActiveShip]
    	
	call GetRoids
	wait 10
	
 
	
	
	while ${Me.Ship.UsedCargoCapacity} <= ${Math.Calc[${Me.Ship.CargoCapacity}*0.90]}
	{
		if (${Me.ToEntity.ShieldPct} > 35)
		{
	  	;call UpdateHudStatus "Update: Cargo Capacity at ${Me.Ship.UsedCargoCapacity} of ${Me.Ship.CargoCapacity}"
			wait 10
			if ((${Roids[${RoidCnt}]} > 0) && ${Entity[${Roids[${RoidCnt}]}](exists)} && ${Roids[${RoidCnt}]} != NULL)
			{
		  	wait 10
				if ${Roids[${RoidCnt}].IsLockedTarget}
				{
					wait 60
					;call DefendAndDestroy
					;call TrainSkills
				}
				else
				{
			  	if (${Entity[${Roids[${RoidCnt}]}].Distance} > 9000)
			  	{
				   	  call UpdateHudStatus "Setting roid to ${Roids[${RoidCnt}].Name} with id ${Roids[${RoidCnt}]} -- calling Approach..."
			 	    	Roids[${RoidCnt}]:Approach[3000]
				
				    	while (${Entity[${Roids[${RoidCnt}]}].Distance} > 9000)
				    	{
					  	  wait 20
				    	}
							EVE:Execute[CmdStopShip]
					}
					wait 3
					call UpdateHudStatus "Locking roid target"
					Roids[${RoidCnt}]:LockTarget
					wait 3
				
					do
					{
						wait 25
						call UpdateHudStatus tick....
					}
					while ${Roids[${RoidCnt}].BeingTargeted}
				
					wait 20
					call ActivateMiningLasers
					wait 60
				}
			}
			else
			{
				call GetRoids ${RoidType1}
				wait 60
			}
		}
		else
		{
			do
			{
				Roids[${RoidCnt}]:UnlockTarget
			}
			while (${Me.GetTargets} > 0)
			call UpdateHudStatus "Since, we're not mining, we're gonna close cargo"
  		EVE:Execute[OpenCargoHoldOfActiveShip]
			return COMBAT
		}	
	}
	
	call UpdateHudStatus "End waiting, cargo is full"
	
	call UpdateHudStatus "Finished Mining...closing cargo hold"
  EVE:Execute[OpenCargoHoldOfActiveShip]	
}