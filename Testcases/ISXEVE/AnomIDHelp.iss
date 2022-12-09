#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Read what is in the probe scanner window
 *
 *	
 *
 *	Tests:
 *		Trying to find what the different anom name and id's are
 *		
 *
 *	Requirements:
 *		You: In spcae
 *		Probe Scanner window open and active
 */

 function main()
{
	variable index:systemanomaly MyAnomalies
    variable iterator MyAnomalies_Iterator
    
    MyShip.Scanners.System:GetAnomalies[MyAnomalies]
    MyAnomalies:GetIterator[MyAnomalies_Iterator]
    
    if ${MyAnomalies_Iterator:First(exists)}
    {           
        do
        {           
            echo ${Time}: ------------------------------------
            echo ${Time}: Difficulty: ${MyAnomalies_Iterator.Value.Difficulty}
            echo ${Time}: DungeonID: ${MyAnomalies_Iterator.Value.DungeonID}
            echo ${Time}: DungeonName: ${MyAnomalies_Iterator.Value.DungeonName}
            echo ${Time}: Faction: ${MyAnomalies_Iterator.Value.Faction}  
        }
        while ${MyAnomalies_Iterator:Next(exists)}
    }


}