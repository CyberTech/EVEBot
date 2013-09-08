#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test GetAgents
	Shiva
*/

function main()
{
	variable int EVEAgentIndex = 4130
	variable index:dialogstring dsIndex
	variable iterator dsIterator
/*
Known Dialogstrings
 UI/Agents/Dialogue/Buttons/ViewMission
 UI/Agents/Dialogue/Buttons/RequestMission
 UI/Agents/Dialogue/Buttons/AcceptMission
 UI/Agents/Dialogue/Buttons/AcceptThisChoice
 UI/Agents/Dialogue/Buttons/AcceptRemotely
 UI/Agents/Dialogue/Buttons/CompleteMission
 UI/Agents/Dialogue/Buttons/CompleteRemotely
 UI/Agents/Dialogue/Buttons/Continue
 UI/Agents/Dialogue/Buttons/DeclineMission
 UI/Agents/Dialogue/Buttons/DeferMission
 UI/Agents/Dialogue/Buttons/QuitMission
 UI/Agents/Dialogue/Buttons/StartResearch
 UI/Agents/Dialogue/Buttons/CancelResearch
 UI/Agents/Dialogue/Buttons/BuyDatacores
 UI/Agents/Dialogue/Buttons/LocateCharacter
 UI/Agents/Dialogue/Buttons/LocateCharacterAccept
 UI/Agents/Dialogue/Buttons/LocateCharacterReject
 UI/Common/Buttons/Yes
 UI/Common/Buttons/No
*/
	echo Agent[${EVEAgentIndex}].Name ${Agent[${EVEAgentIndex}].Name}
	echo Agent[${EVEAgentIndex}].ID ${Agent[${EVEAgentIndex}].ID}
	echo Agent[${EVEAgentIndex}].AgentTypeID ${Agent[${EVEAgentIndex}].AgentTypeID}
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