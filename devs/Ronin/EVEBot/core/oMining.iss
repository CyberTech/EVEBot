function GetRoid()
{
	declare tempchk bool
	if ${Entity[CategoryID,25](exists)}
	{
		if ${Entity[CategoryID,25,Scordite](exists)}
		{
			roid:Set[${Entity[CategoryID,25,Scordite].ID}]
			tempchk:Set[TRUE]
		}
		else
		{	
			if ${Entity[CategoryID,25,Pyroxeres](exists)}
			{
				roid:Set[${Entity[CategoryID,25,Pyroxeres].ID}]
				tempchk:Set[TRUE]
			}
			else
			{
				roid:Set[${Entity[CategoryID,25,Veldspar].ID}]
				tempchk:Set[TRUE]
			}
		}
		if !${tempchk}
		{
			roid:Set[${Entity[CategoryID,25].ID}]
		}
	}
	else
	{
	Return "Empty"
	}
}

function GetRoids(string prefroid)
{
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


function FindLasers(int Laser)
{
	variable string MiningType=Ore
	variable string LaserName=${Me.Ship.Module[HiSlot${Laser}]}
	LavishSettings[Lasers]:Import[${Script.CurrentDirectory}/config/lasers.xml]
	variable string ourlaser=${LavishSettings[Lasers].FindSet[${MiningType}].FindSetting[${LaserName}]}
	;call UpdateHudStatus "Debug: ourlaser = ${ourlaser}"
	
	call UpdateHudStatus "Checking for Laser"
	if ${ourlaser(exists)}
	{
		call UpdateHudStatus "Found Mining Laser"
		Lasers:Set[TRUE]
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
	variable int Laser=0
	
	if (${Slot0Value} > 0)
	{

		call FindLasers ${Laser}
		Laser:Set[1]
		while ${Laser} < 3
		{
			if (${Lasers} > 0) && !${Me.Ship.Module[HiSlot${Math.Calc[${Laser}-1]}].IsActive}
			{
				call UpdateHudStatus "Powering Up Laser ${Laser}"
				EVE:Execute[CmdActivateHighPowerSlot${Laser}]
				wait 10
			}
			Laser:Inc
		}
	}
}

function GetBelts()
{
	BeltCount:Set[${EVE.GetEntities[Belts,GroupID,9]}]
	;call UpdateHudStatus "DEBUG: BeltCount ${BeltCount}"
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
	call UpdateHudStatus "Warping to roid belt: ${Belts[${curBelt}].Name}"
	call WarpTo ${Belts[${curBelt}]} 10000
	call GetRoids
	echo ${Roids[${RoidCnt}]}
	call UpdateHudStatus "Setting roid to ${Roids[${RoidCnt}].Name} with id ${Roids[${RoidCnt}]} -- calling Orbit..."
	wait 10
	
	while ${Me.Ship.UsedCargoCapacity} <= ${Math.Calc[${Me.Ship.CargoCapacity}-3]}
	{
		if (${Roids[${RoidCnt}]} > 0) && ${Entity[id,${Roids[${RoidCnt}]}](exists)} && ${Roids[${RoidCnt}]}!=NULL
		{
			if ${Roids[${RoidCnt}].IsLockedTarget}
			{
				wait 50
				;call DefendAndDestroy
				;call TrainSkills
			}
			else
			{
				call Orbit ${Roids[${RoidCnt}]} 9000
				Roids[${RoidCnt}]:LockTarget
				call UpdateHudStatus "Locking roid target"

				do
				{
					wait 20
				}
				while ${Roids[${RoidCnt}].BeingTargeted}

				wait 10
				call ActivateLaser
				wait 20
			}
		}
		else
		{
			call GetRoids ${RoidType1}
			wait 10
		}
	}
	call UpdateHudStatus "End waiting, cargo is full"
}