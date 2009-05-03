#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Entity Iteration

*/

variable obj_UI UI
function main()
{
		variable index:entity EntityIndex
		variable int RTime = ${Script.RunningTime}
		EVE:DoGetEntities[EntityIndex]
		echo "- DoGetEntities took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms. (Used: ${EntityIndex.Used})"
		variable iterator EntityIterator
		EntityIndex:GetIterator[EntityIterator]
	
		if ${EntityIterator:First(exists)}
		{
			do
			{
				echo EntityIterator.Value.Name ${EntityIterator.Value.Name}
			}
			while ${EntityIterator:Next(exists)}
		}
}