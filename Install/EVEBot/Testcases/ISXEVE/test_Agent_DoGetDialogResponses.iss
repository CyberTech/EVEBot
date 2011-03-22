#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test GetAgents
	Shiva
*/

variable obj_UI UI
function main()
{
	variable int EVEAgentIndex = 4130
	variable index:dialogstring dsIndex
	variable iterator dsIterator

	echo Agent[${EVEAgentIndex}].Name ${Agent[${EVEAgentIndex}].Name}
	echo Agent[${EVEAgentIndex}].ID ${Agent[${EVEAgentIndex}].ID}
	echo Agent[${EVEAgentIndex}].TypeID ${Agent[${EVEAgentIndex}].TypeID}
	echo Agent[${EVEAgentIndex}].Division ${Agent[${EVEAgentIndex}].Division}
	echo Agent[${EVEAgentIndex}].DivisionID ${Agent[${EVEAgentIndex}].DivisionID}
	echo Agent[${EVEAgentIndex}].Level ${Agent[${EVEAgentIndex}].Level}
	echo Agent[${EVEAgentIndex}].Quality ${Agent[${EVEAgentIndex}].Quality}
	echo Agent[${EVEAgentIndex}].CorporationID ${Agent[${EVEAgentIndex}].CorporationID}
	echo Agent[${EVEAgentIndex}].FactionID ${Agent[${EVEAgentIndex}].FactionID}
	echo Agent[${EVEAgentIndex}].StandingTo ${Agent[${EVEAgentIndex}].StandingTo}
	echo Agent[${EVEAgentIndex}].Solarsystem ${Agent[${EVEAgentIndex}].Solarsystem}
	echo Agent[${EVEAgentIndex}].Station ${Agent[${EVEAgentIndex}].Station}
	echo Agent[${EVEAgentIndex}].StationID ${Agent[${EVEAgentIndex}].StationID}
	echo Agent[${EVEAgentIndex}].Index ${Agent[${EVEAgentIndex}].Index}

	Agent[${EVEAgentIndex}]:GetDialogResponses[dsIndex]

	dsIndex:GetIterator[dsIterator]

	if (${dsIterator:First(exists)})
	{
		do
		{
			UI:UpdateConsole["obj_Agents: dsIterator.Value.Text: ${dsIterator.Value.Text}"]

		}
		while ${dsIterator:Next(exists)}
	}
}