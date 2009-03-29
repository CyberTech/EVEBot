#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Buddy (Being) Member Iteration

	Revision $Id$

	Requirements:
		You:
		Buddy List: Populated
		People & Places window must have been opened at least once
*/

variable obj_UI UI
function main()
{
		variable index:being BeingIndex
		EVE:DoGetBuddies[BeingIndex]

		variable iterator Buddy
		BeingIndex:GetIterator[Buddy]

		echo "Buddies Detected: ${BeingIndex.Used}"
		if ${Buddy:First(exists)}
		{
			do
			{
				echo Buddy.Value.CharID ${Buddy.Value.CharID}
				echo Buddy.Value.Name ${Buddy.Value.Name}
				echo Buddy.Value.IsNPC ${Buddy.Value.IsNPC}
				echo Buddy.Value.IsPC ${Buddy.Value.IsPC}
				echo Buddy.Value.IsOnline ${Buddy.Value.IsOnline}
				;Buddy.Value:InviteToFleet
			}
			while ${Buddy:Next(exists)}
		}
}