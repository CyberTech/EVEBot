#define TESTCASE 1

#include Scripts/EVEBotDev/Support/TestAPI.iss

/*
 *	Test DoGetActiveDroneIDs [Shiva]
 *	Requires:	Must be in space.
 *	Note: Detects ALL drones in space that are in your window.
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
			echo  [Owner: ${Entity[${ActiveDroneIDsIterator.Value}].Owner.Name}] Drone: [ID: ${ActiveDroneIDsIterator.Value}] [Name: ${Entity[${ActiveDroneIDsIterator.Value}].Name}]

		}
		while ${ActiveDroneIDsIterator:Next(exists)}
	}
	else
		echo No Drones out atm. Try again.
}