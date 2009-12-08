#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Pilot Iteration, Pilot.ToEntity, Pilot.ToFleetMember

	Revision $Id$

	Requirements:
		You: In Space
		Other1: In Fleet, In Space, on Grid
		Other2: In Space, Off Grid
*/

variable obj_UI UI
function main()
{
		variable index:pilot PilotIndex
		variable int RTime = ${Script.RunningTime}
		EVE:DoGetPilots[PilotIndex]
		echo "- DoGetPilots took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms."
		variable iterator PilotIterator
		PilotIndex:GetIterator[PilotIterator]



		if ${PilotIterator:First(exists)}
		{
			do
			{
				echo ${System.TickCount}: PilotIterator.Value.Name ${PilotIterator.Value.Name}
				echo ${System.TickCount}: PilotIterator.Value.CharID ${PilotIterator.Value.CharID}
				echo ${System.TickCount}: PilotIterator.Value.ToEntity(exists) ${PilotIterator.Value.ToEntity(exists)}
				echo ${System.TickCount}: PilotIterator.Value.ToEntity.IsPC ${PilotIterator.Value.ToEntity.IsPC}
				echo PilotIterator.Value.ToEntity.Distance ${PilotIterator.Value.ToEntity.Distance}
				echo PilotIterator.Value.ToFleetMember ${PilotIterator.Value.ToFleetMember}
			}
			while ${PilotIterator:Next(exists)}
		}
}