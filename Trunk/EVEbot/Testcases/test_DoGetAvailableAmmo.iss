#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
 *	Test DoGetAvailableAmmo [Shiva]
 *
 *	Requirements:
 *		Cargohold having been opened prior.
 *		Must be in space.
 *
 */

function main()
{
	if ${Me.InStation}
	{
		echo Can't be done while in a station.
		endscript test_dogetavailableammo.iss
	}

	variable index:item AmmoIndex
	variable index:module ModuleIndex

	MyShip:DoGetModules[ModuleIndex]

	variable iterator ModuleIterator

	ModuleIndex:GetIterator[ModuleIterator]

	if ${ModuleIterator:First(exists)}
	{
		do
		{
			if ${ModuleIterator.Value.Charge(exists)}
			{
				ModuleIterator.Value:DoGetAvailableAmmo[AmmoIndex]

				echo ${ModuleIterator.Value.ToItem.Name} has ${AmmoIndex.Used} types of ammo in cargo.

				variable iterator AmmoIterator
				AmmoIndex:GetIterator[AmmoIterator]

				if ${AmmoIterator:First(exists)}
				{
					do
					{
						echo - ${AmmoIterator.Value.Name}
					}
					while ${AmmoIterator:Next(exists)}
				}
			}
			else
				echo ${ModuleIterator.Value.ToItem.Name} doesn't use charges.
		}
		while ${ModuleIterator:Next(exists)}
	}
	else
	{
		echo None of your Modules require charges.
	}
}