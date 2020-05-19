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
	echo EVE.Agent[${EVEAgentIndex}].Name ${EVE.Agent[${EVEAgentIndex}].Name}
	echo EVE.Agent[${EVEAgentIndex}].ID ${EVE.Agent[${EVEAgentIndex}].ID}
	echo EVE.Agent[${EVEAgentIndex}].AgentTypeID ${EVE.Agent[${EVEAgentIndex}].AgentTypeID}
	echo EVE.Agent[${EVEAgentIndex}].Division ${EVE.Agent[${EVEAgentIndex}].Division}
	echo EVE.Agent[${EVEAgentIndex}].DivisionID ${EVE.Agent[${EVEAgentIndex}].DivisionID}
	echo EVE.Agent[${EVEAgentIndex}].Level ${EVE.Agent[${EVEAgentIndex}].Level}
	echo EVE.Agent[${EVEAgentIndex}].Quality ${EVE.Agent[${EVEAgentIndex}].Quality}
	echo EVE.Agent[${EVEAgentIndex}].CorporationID ${EVE.Agent[${EVEAgentIndex}].CorporationID}
	echo EVE.Agent[${EVEAgentIndex}].FactionID ${EVE.Agent[${EVEAgentIndex}].FactionID}
	echo EVE.Agent[${EVEAgentIndex}].StandingTo ${EVE.Agent[${EVEAgentIndex}].StandingTo}
	echo EVE.Agent[${EVEAgentIndex}].Solarsystem ${EVE.Agent[${EVEAgentIndex}].Solarsystem}
	echo EVE.Agent[${EVEAgentIndex}].Station ${EVE.Agent[${EVEAgentIndex}].Station}
	echo EVE.Agent[${EVEAgentIndex}].StationID ${EVE.Agent[${EVEAgentIndex}].StationID}
	echo EVE.Agent[${EVEAgentIndex}].Index ${EVE.Agent[${EVEAgentIndex}].Index}

	EVE.Agent[${EVEAgentIndex}]:GetDialogResponses[dsIndex]

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