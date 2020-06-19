#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test Drone Launch, Recall, ID collection, activedrone member, engage

	Revision $Id$

	Requirements:
		You: In Space
		Other1: In Fleet, In Space, Targeted
*/

function main()
{
	variable index:int64 ActiveDroneIDList
	variable index:activedrone ActiveDroneList
	variable index:item DroneBayDrones

	while TRUE
	{
		UI:UpdateConsole["Drone Bay Capacity: ${MyShip.DronebayCapacity}"]

		MyShip:OpenCargo
		wait 30

		MyShip:GetDrones[DroneBayDrones]
		UI:UpdateConsole["Launching ${DroneBayDrones.Used} drones..."]
		EVE:LaunchDrones[DroneBayDrones]
		wait 50

		Me:GetActiveDrones[ActiveDroneList]
		UI:UpdateConsole["Drones in Space after 5 seconds: ${ActiveDroneList.Used}"]

		UI:UpdateConsole[" Drone 1 ID: ${ActiveDroneList.Get[1].ID}"]
		UI:UpdateConsole[" Drone 1 Name: ${ActiveDroneList.Get[1].ToEntity.Name}"]
		UI:UpdateConsole[" Drone 1 Type: ${ActiveDroneList.Get[1].ToEntity.Type}"]
		UI:UpdateConsole[" Drone 1 Owner: ${ActiveDroneList.Get[1].Owner}"]
		UI:UpdateConsole[" Drone 1 Controller: ${ActiveDroneList.Get[1].Owner}"]

		;UI:UpdateConsole[" Engaging Drones..."]
		;EVE:DronesEngageMyTarget[ActiveDroneIDList]

		wait 20
		Me:GetActiveDroneIDs[ActiveDroneIDList]
		while ${ActiveDroneIDList.Used}
		{
			UI:UpdateConsole[" Recalling ${ActiveDroneIDList.Used} Drones..."]
			EVE:DronesReturnToDroneBay[ActiveDroneIDList]
			wait 50
			Me:GetActiveDroneIDs[ActiveDroneIDList]
		}
		wait 20
		break
	}
}