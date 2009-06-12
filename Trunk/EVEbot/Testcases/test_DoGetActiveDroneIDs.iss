#define TESTCASE 1

#include Scripts/EVEBotDev/Support/TestAPI.iss

/*
 *	Test DoGetActiveDroneIDs [Shiva]
 *	Requires:	Must be in space.
 */

variable obj_UI UI

function main()
{
	variable index:int ActiveDroneIDsIndex

	Me:DoGetActiveDroneIDs[ActiveDroneIDsIndex]

	echo ActiveDroneIDsIndex.Used: ${ActiveDroneIDsIndex.Used}

	variable iterator ActiveDroneIDsIterator
	ActiveDroneIDsIndex:GetIterator[ActiveDroneIDsIterator]

	echo  [${ActiveDroneIDsIndex.ExpandComma}]

	if ${ActiveDroneIDsIterator:First(exists)}
	{
		do
		{
			echo Drone: [ID: ${ActiveDroneIDsIterator.Value}] [Name: ${Entity[${ActiveDroneIDsIterator.Value}].Name}] [Mode: ${Entity[${ActiveDroneIDsIterator.Value}].Mode}]

		}
		while ${ActiveDroneIDsIterator:Next(exists)}
	}
	else
	{
		echo No Drones out atm. Try again.
	}
}