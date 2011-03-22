#define TESTCASE 1

#include ../Support/TestAPI.iss

/*
	Test Drone Launch, Recall, ID collection, activedrone member, engage

	Revision $Id$

	Requirements:
		You: In Space
		Other1: In Fleet, In Space, Targeted
*/

variable obj_UI UI
function main()
{
	variable index:int64 ActiveDroneIDList
	variable index:activedrone ActiveDroneList

	while TRUE
	{
		echo Drone Bay Capacity: ${Me.Ship.DronebayCapacity}
		echo Drones in Bay: ${Me.Ship.GetDrones}

		UI:UpdateConsole["Launching drones..."]
		Me.Ship:LaunchAllDrones
		wait 30

		echo "Drones in Space: ${Me.GetActiveDrones[ActiveDroneList]}"

		echo " Drone ID: ${ActiveDroneList.Get[1].ID}"
		echo " Drone Name: ${ActiveDroneList.Get[1].ToEntity}"
		echo " Drone Owner: ${ActiveDroneList.Get[1].Owner}"
		echo " Drone Controller: ${ActiveDroneList.Get[1].Owner}"

		echo " Engaging Drones..."
		;EVE:DronesEngageMyTarget[ActiveDroneIDList]

		Me:GetActiveDroneIDs[ActiveDroneIDList]
		while ${ActiveDroneIDList.Used}
		{
			echo " Recalling ${ActiveDroneIDList.Used} Drones..."
			EVE:DronesReturnToDroneBay[ActiveDroneIDList]
			wait 50
			Me:GetActiveDroneIDs[ActiveDroneIDList]
		}
		wait 20
	}
}