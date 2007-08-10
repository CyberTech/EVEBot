#define QUANTITY_THRESHOLD 10000

/* the hauler code is used for its can-lookup function */
#include ../core/obj_Hauler.iss

function main()
{
	; The name we want our container to have
	variable string ContainerName = "Cargo Container"
	variable index:item MyCargo
	variable int EndScript = 0
	variable int id
	variable int canOpen = 0

	Declare Hauler obj_Hauler "" ""

	canOpen:Set[0]
	do
	{
		if ${Me.Ship.Cargo[1](exists)}
		{
			id:Set[${Hauler.NearestMatchingJetCan}]

			echo "DEBUG: can ID = ${id}"
			if ${Entity[${id}](exists)}
			{
				if ${canOpen} == 0
				{
					echo "Opening Can"
					Entity[${ContainerName}]:OpenCargo
					wait 100
					canOpen:Set[1]
				}
				echo "Moving ${Me.Ship.Cargo[1].Name} to ${Entity[${ContainerName}].ID}"
				Me.Ship.Cargo[1]:MoveTo[${Entity[${ContainerName}].ID}]
				wait 100
				echo "Stacking cargo"
				Entity[${ContainerName}]:StackAllCargo
				wait 50
				
				echo "JetCan contains ${Entity[${ContainerName}].UsedCargoCapacity} m^3 of stuff."
				if ${Entity[${ContainerName}].UsedCargoCapacity} > QUANTITY_THRESHOLD
				{
					relay all -event EVEBot_Miner_Full ${Me.CharID}
				}
				
			}  
			else
			{
				echo "New Can"
				canOpen:Set[0]
				Me.Ship.Cargo[1]:Jettison
				wait 100
			}            
		}

		echo "Starting 10 second sleep"
		wait 100


		echo "Is laser #1 active?"
		wait 5
		if !${Me.Ship.Module[HiSlot0].IsActive}
		{
			echo "Locking Target on ${Entity[CategoryID,25]}"
			Entity[CategoryID,25]:LockTarget
			wait 100
			echo "Powering on laser #1"
			Me.Ship.Module[HiSlot0]:Click
			wait 50
		}

		echo "Is laser #2 active?"
		wait 5
		if !${Me.Ship.Module[HiSlot1].IsActive}
		{
			echo "Locking Target on ${Entity[CategoryID,25]}"
			Entity[CategoryID,25]:LockTarget
			wait 100
			echo "Powering on laser #2"
			Me.Ship.Module[HiSlot1]:Click
			wait 50
		}


	}
	while ${EndScript} == 0

	echo Script Ended
}