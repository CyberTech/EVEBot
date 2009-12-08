#define TESTCASE 1

#include ../Support/TestAPI.iss

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
				echo EntityIterator.Value.ID ${EntityIterator.Value.ID}
				echo EntityIterator.Value.ShieldPct ${EntityIterator.Value.ShieldPct}
				echo EntityIterator.Value.ArmorPct ${EntityIterator.Value.ArmorPct}
				echo EntityIterator.Value.IsLockedTarget ${EntityIterator.Value.IsLockedTarget}
				echo EntityIterator.Value.IsActiveTarget ${EntityIterator.Value.IsActiveTarget}
				echo EntityIterator.Value.BeingTargeted ${EntityIterator.Value.BeingTargeted}
				echo EntityIterator.Value.BeingTargeted ${EntityIterator.Value.BeingTargeted}
				echo EntityIterator.Value.IsTargetingMe ${EntityIterator.Value.IsTargetingMe}

}
			while ${EntityIterator:Next(exists)}
		}
}