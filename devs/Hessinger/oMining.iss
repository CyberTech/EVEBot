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
			roid:Set[${Entity[CategoryID,25,Veldspar].ID}]
		}
	}
}

function FindLasers()
{
	variable String MiningType = "Ore"
	call UpdateHudStatus "Debug: MiningType = ${MiningType}"
	variable String LaserName = "${Me.Ship.Module[HiSlot${Laser}]}"
	call UpdateHudStatus "Debug: Lasername = ${LaserName}"
	LavishSettings[Lasers]:Import[${Script.CurrentDirectory}/config/lasers.xml]
	call UpdateHudStatus "Debug" Imported XML"
	variable string ourlaser=${LavishSettings[Lasers].FindSet[${MiningType}].FindSetting[${LaserName}]}
	call UpdateHudStatus "Debug: ourlaser = ${ourlaser}"
	
	call UpdateHudStatus "Checking for Laser"
	if ${ourlaser(exists)}
		{
			call UpdateHudStatus "Found Mining Laser"
			Lasers:Set[TRUE]
			wait 20
		}
		else
		{
		call UpdateHudStatus "Didn't find Mining Laser"
		Lasers:Set[FALSE]
		
		}
}

function ActivateLaser()
{
declare Slot0Value bool ${Me.Ship.Module[HiSlot0].IsActivatable}
variable int Laser = "1"

wait 10
call UpdateHudStatus "Debug: Called Activate Laser"
wait 10
call UpdateHudStatus "Debug: About to check if my ships module is great then 0"
wait 10
if (${Slot0Value} > 0)
	{
		call UpdateHudStatus "Debug: It found a laser! Moving on!"
		wait 10
		call UpdateHudStatus "Debug: About to Look For a Laser"
		wait 30
		call FindLasers ${Laser}
		wait 50
		if (${Lasers} > 0)
						{
						echo "Powering Up Laser 1"
						EVE:Execute[CmdActivateHighPowerSlot1]
						}
	}
}

function Mine()
{	
declare HighSlot1 bool True
declare bHighSlot1 bool ${aHighSlot1}
aHighSlot1:${Me.Ship.Module[HiSlot1].IsActive}

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
					call Orbit ${roid} 12000
					
					Entity[ID,${roid}]:LockTarget
					call UpdateHudStatus "Locking roid target"
					do
					{
						wait 20
					}
					while ${Entity[ID,${roid}].BeingTargeted}
					
					wait 20
					call UpdateHudStatus "Debug: UpdateHudStatus Activate Laser"
					call ActivateLaser
	
					;wait 10
					;EVE:Execute[CmdActivateHighPowerSlot2]
					;call UpdateHudStatus "IMMA FIRIN MAH LAZOR!"
					wait 20
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