
#include ./core/functions.iss

function main()
{
echo "Neutro EveBot starting"
	
call LoadCoordinates
echo "Loading Coo"
variable index:entity EntitiesTargetingMe
echo "Declaring EntitiesTargetingMe"
declare station int script
declare belt int script
declare roid int script
declare play bool script TRUE
	while ${play}
	{
	
	if !${Me.InStation}
	{
		if ${Me.GetTargetedBy[EntitiesTargetingMe]} > 0 
		{	
			echo "Found ${Me.GetTargetedBy[EntitiesTargetingMe]} hostile ships"
				for (i:Set[1] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
				{
				Entity[ID,${EntitiesTargetingMe.Get[${i}].Id}]:Orbit
					while ${EntitiesTargetingMe.Get[${i}].Distance} > 1500
					{
					waitframe
					}
				Entity[ID,${EntitiesTargetingMe.Get[${i}].Id}]:LockTarget
				EVE:Execute[CmdActivateHighPowerSlot2]
					while ${Me.ActiveTarget} 
					;|| (${Me.Ship.HP} > 40)
					{
					waitframe
					}
				}
		}
	}
	
	if ${Me.Ship.UsedCargoCapacity} != ${Me.Ship.CargoCapacity} && !${Me.InStation}
	{
	echo "No more ennemy ships"
	station:Set[${Entity[CategoryID,3].ID}]
	echo "Setting main station ${Entity[CategoryID,3].Name} with id ${Entity[CategoryID,3].ID}"
	belt:Set[${Entity[GroupID,9].ID}]
	echo "Setting roid belt ${Entity[GroupID,9].Name} with id ${Entity[GroupID,9].ID}"
	
	Entity[ID,${belt}]:WarpTo
	wait 50
	echo "Wraping to ${Entity[GroupID,9].Name}"
		while ${Me.ToEntity.Mode}==3
		{
		waitframe
		}
	echo "Wrapping ends now"
	roid:Set[${Entity[CategoryID,25].ID}]
	echo "Setting roid belt ${Entity[CategoryID,25].Name} with id ${Entity[[CategoryID,25].ID}"
	Entity[ID,${roid}]:Orbit
	echo "Entering Orbit with belt, waiting..."
		while ${Entity[ID,${roid}].Distance} > 5500
		{
		waitframe
		}
		echo "Finish waiting, in orbit now"
	Entity[ID,${roid}]:LockTarget
	echo "Locking roid target"
	EVE:Execute[CmdActivateHighPowerSlot1]
	echo "Activating Mining Laser, waiting for full cargo..."
		while ${Me.Ship.CargoCapacity} > ${Me.Ship.UsedCargoCapacity}
		{
		wait 50
		}
	echo "End waiting, cargo is full"
	Entity[ID,${roid}]:UnlockTarget
	echo "Unlocking target"
	}
	
	if ${Me.Ship.UsedCargoCapacity} == ${Me.Ship.CargoCapacity} && !${Me.InStation}
	{
		echo "My ship is full"
		if ${Entity[ID,${station}].Distance}>=10000
		{
		echo "The distance is greater than 10000, warp to base"
		Entity[ID,${station}]:WarpTo
		wait 50
		echo "Warping, waiting..."
				while ${Me.ToEntity.Mode}==3
				{
				waitframe
				}
		echo "Waiting ends"
		}
		wait 60
		echo "we should be in docking range"
		Entity[ID,${station}]:Dock
		echo "Docking, waiting 5 sec"
		wait 400
	}
	
	if ${Me.InStation}
	{
		echo "I'm in the station"
		while !${Display.GetPixel[CargoHoldItem1].Hex.Equal[29221b]}
		{
		echo "Transfering item1 to hangar"
		Mouse:SetPosition[CargoHoldItem1]
		wait 20
		Mouse:HoldLeft
		wait 10
		Mouse:SetPosition[HangarDrop]
		wait 10
		Mouse:ReleaseLeft
		}
		
		while !${Display.GetPixel[CargoHoldItem2].Hex.Equal[28221b]}
		{
		echo "Transfering item2 to hangar"
		Mouse:SetPosition[CargoHoldItem2]
		wait 20
		Mouse:HoldLeft
		wait 10
		Mouse:SetPosition[HangarDrop]
		wait 10
		Mouse:ReleaseLeft
		}
		
		while !${Display.GetPixel[CargoHoldItem3].Hex.Equal[27211a]}
		{
		echo "Transfering item3 to hangar"
		Mouse:SetPosition[CargoHoldItem3]
		wait 20
		Mouse:HoldLeft
		wait 10
		Mouse:SetPosition[HangarDrop]
		wait 10
		Mouse:ReleaseLeft
		} 
	
	echo "Stacking all..."
	Mouse:SetPosition[HangarDrop]
	wait 10
	Mouse:RightClick
	wait 10
	Mouse:SetPosition[StackAll]
	wait 20
	Mouse:LeftClick
	wait 30
	echo "Staking done"
	echo "Undocking"
	Me:Undock
	wait 200
	}
	}
}