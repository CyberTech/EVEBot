#define TESTCASE 1

#include Scripts/EVEBotDev/Support/TestAPI.iss

/*
	Test DoGetAgents
	Shiva
*/

variable obj_UI UI
function main()
{
		variable index:being AgentIndex
		variable int RTime = ${Script.RunningTime}

		EVE:DoGetAgents[AgentIndex]
		echo "- DoGetAgents took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms. (Used: ${AgentIndex.Used})"

		variable iterator AgentIterator
		AgentIndex:GetIterator[AgentIterator]

		;echo ${AgentIndex.ExpandComma}

		if ${AgentIterator:First(exists)}
		{
			do
			{
				/*
					Shiva : being Datatype
					int CharID, string Name, bool IsOnline, bool IsNPC, bool IsPC
				 */
				;echo AgentIterator.Value.CharID ${AgentIterator.Value.CharID} ; Shiva: Same as ${AgentIterator.Value}
				;echo AgentIterator.Value.Name ${AgentIterator.Value.Name}
				;echo AgentIterator.Value.IsOnline ${AgentIterator.Value.IsOnline} ; Will Always return false (It's an NPC)
				;echo AgentIterator.Value.IsNPC ${AgentIterator.Value.IsNPC} ; Will Always return true (It's an NPC)
				;echo AgentIterator.Value.IsPC ${AgentIterator.Value.IsPC} ; Will Always return false (It's a *duh* NPC)

				/*
					Shiva: Agent Datatype
					int ID, string Name, int TypeID, string Division, int DivisionID, int Level, int Quality,
					int CorporationID, int FactionID, float StandingTo, interstellar Solarsystem, string Station,
					int StationID, int Index
				 */
				echo Agent[id,${AgentIterator.Value}].ID ${Agent[id,${AgentIterator.Value}].ID}
				echo Agent[id,${AgentIterator.Value}].TypeID ${Agent[id,${AgentIterator.Value}].TypeID}
				echo Agent[id,${AgentIterator.Value}].Division ${Agent[id,${AgentIterator.Value}].Division}
				echo Agent[id,${AgentIterator.Value}].DivisionID ${Agent[id,${AgentIterator.Value}].DivisionID}
				echo Agent[id,${AgentIterator.Value}].Level ${Agent[id,${AgentIterator.Value}].Level}
				echo Agent[id,${AgentIterator.Value}].Quality ${Agent[id,${AgentIterator.Value}].Quality}
				echo Agent[id,${AgentIterator.Value}].CorporationID ${Agent[id,${AgentIterator.Value}].CorporationID}
				echo Agent[id,${AgentIterator.Value}].FactionID ${Agent[id,${AgentIterator.Value}].FactionID}
				echo Agent[id,${AgentIterator.Value}].StandingTo ${Agent[id,${AgentIterator.Value}].StandingTo}
				echo Agent[id,${AgentIterator.Value}].Solarsystem ${Agent[id,${AgentIterator.Value}].Solarsystem}
				echo Agent[id,${AgentIterator.Value}].Station ${Agent[id,${AgentIterator.Value}].Station}
				echo Agent[id,${AgentIterator.Value}].StationID ${Agent[id,${AgentIterator.Value}].StationID}
				echo Agent[id,${AgentIterator.Value}].Index ${Agent[id,${AgentIterator.Value}].Index}
			}
			while ${AgentIterator:Next(exists)}
		}
}