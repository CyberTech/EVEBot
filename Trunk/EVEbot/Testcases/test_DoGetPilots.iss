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
		EVE:DoGetPilots[PilotIndex]
		variable iterator PilotIterator
		PilotIndex:GetIterator[PilotIterator]

		if ${PilotIterator:First(exists)}
		{
			do
			{
				echo PilotIterator.Value.Name ${PilotIterator.Value.Name}
				echo PilotIterator.Value.CharID ${PilotIterator.Value.CharID}
				echo PilotIterator.Value.ToEntity(exists) ${PilotIterator.Value.ToEntity(exists)}
				echo PilotIterator.Value.ToEntity.IsPC ${PilotIterator.Value.ToEntity.IsPC}
				echo PilotIterator.Value.ToEntity.Distance ${PilotIterator.Value.ToEntity.Distance}
				echo PilotIterator.Value.ToFleetMember ${PilotIterator.Value.ToFleetMember}
			}
			while ${PilotIterator:Next(exists)}
		}
}