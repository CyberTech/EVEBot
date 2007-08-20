function GetRoid()
{

	if ${Entity[CategoryID,25,Scordite](exists)}
	{
		roid:Set[${Entity[CategoryID,25,Scordite].ID}]
	}
	else
	{	
		if ${Entity[CategoryID,25,Pyroxeres](exists)}
		{
			roid:Set[${Entity[CategoryID,25,Pyroxeres].ID}]
		}
		else
		{
			if ${Entity[CategoryID,25,Plag](exists)}
			{
				roid:Set[${Entity[CategoryID,25,Plag].ID}]
			}
			else
			{
				roid:Set[${Entity[CategoryID,25,Veldspar].ID}]
			}			
		}
	}
}

function FindLasers(int Laser)
{
	;Variables and Lavish Settings
	
	variable string MiningType=Ore
	variable int LaserAddition=${Math.Calc[${Laser}+1]}
	variable string LaserName=${Me.Ship.Module[HiSlot${Laser}]}
	LavishSettings[Lasers]:Import[${Script.CurrentDirectory}/config/lasers.xml]
	variable string ourlaser=${LavishSettings[Lasers].FindSet[${MiningType}].FindSetting[${LaserName}]}
		
	call UpdateHudStatus "Checking for Laser"
	if ${ourlaser(exists)}
		{
			call UpdateHudStatus "Found Laser"
			if ${Me.Ship.Module[HiSlot${Laser}].IsActive}
				{
				call UpdateHudStatus "Laser is already active"
				}
			else
				{
				EVE:Execute[CmdActivateHighPowerSlot${LaserAddition}]
				call UpdateHudStatus "Powering up Laser"
				}
		}
		else
		{
		call UpdateHudStatus "Didn't find Mining Laser"
		}
}

function ActivateLaser(int LaserNum)
{
	variable int Laser=${LaserNum}
	declare SlotValue bool ${Me.Ship.Module[HiSlot${Laser}].IsActivatable}
	

	if (${SlotValue} > 0)
		{
		wait 10
		call FindLasers ${Laser}
		}
		else
		{
		call UpdateHudStatus "No Lasers in Slot ${Laser}"
		}
}

function Mine()
{	
	belt:Set[${Entity[GroupID,9].ID}]
	if (${belt} <= 0)
	{
	   echo "Error: oMining:Mine --> No asteroid belt in the area..."
	   play:Set[FALSE]
	   return
	}
	
	call UpdateHudStatus "Setting roid belt ${Entity[id,${belt}].Name} with id ${Entity[id,${belt}].ID}"
	wait 20	
	
	call UpdateHudStatus "About to warp, this is a log check"
	call WarpTo ${belt}
	call UpdateHudStatus "Warp Command Given"
	
	call GetRoid

	call UpdateHudStatus "Setting roid to ${Entity[id,${roid}].Name} with id ${Entity[id,${roid}].ID} -- calling Orbit..."
	
	wait 10
	
	while ${Me.Ship.UsedCargoCapacity} <= ${Math.Calc[${Me.Ship.CargoCapacity}-3]}
	{
		if (${roid} > 0) && ${Entity[ID,${roid}](exists)}
		{
			if ${Entity[ID,${roid}].IsLockedTarget}
			{
				wait 50
				;call DefendAndDestroy
				;call TrainSkills
			}
				else
			{
			
					wait 10
					
					;if ${Me.GetTargets} > 0
					;{
					;UnlockTarget
					;}
					
					;wait 10
					
					;if ${Me.GetTargets} > 0
					;{
					;UnlockTarget
					;}
					
					;wait 10
					call Orbit ${roid} 9000
					
					Entity[ID,${roid}]:LockTarget
					call UpdateHudStatus "Locking roid target"
					do
					{
						wait 20
					}
					while ${Entity[ID,${roid}].BeingTargeted}
					
					wait 30
					call ActivateLaser 0
					wait 30
					call ActivateLaser 1
					wait 30
					call ActivateLaser 2
					wait 30
			}
		}
		else
		{
		    call GetRoid
			wait 10
		}
	}
	call UpdateHudStatus "End waiting, cargo is full"
; we don't need that ...
;	if (${roid} > 0)
;	{
;		Entity[ID,${roid}]:UnlockTarget 
;		call UpdateHudStatus "Unlocking target"
;	}
}