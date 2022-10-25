#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Read what is in the probe scanner window
 *
 *	
 *
 *	Tests:
 *		Trying to find what the different anom anmes are
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
            echo ${Time}: ------------------ ${MyAnomalies_Iterator.Value.Name} ------------------
            echo ${Time}: ID: ${MyAnomalies_Iterator.Value}
            echo ${Time}: Difficulty: ${MyAnomalies_Iterator.Value.Difficulty}
            echo ${Time}: DungeonID: ${MyAnomalies_Iterator.Value.DungeonID}
            echo ${Time}: DungeonName: ${MyAnomalies_Iterator.Value.DungeonName}
            echo ${Time}: Faction: ${MyAnomalies_Iterator.Value.Faction}
            echo ${Time}: FactionID: ${MyAnomalies_Iterator.Value.FactionID}
            echo ${Time}: Group: ${MyAnomalies_Iterator.Value.Group}
            echo ${Time}: GroupID: ${MyAnomalies_Iterator.Value.GroupID}
            echo ${Time}: IsWarpable: ${MyAnomalies_Iterator.Value.IsWarpable}
            echo ${Time}: ScanStrength: ${MyAnomalies_Iterator.Value.ScanStrength}
            echo ${Time}: SignalStrength: ${MyAnomalies_Iterator.Value.SignalStrength}
            echo ${Time}: ToEntity.Distance: ${Entity[${MyAnomalies_Iterator.Value}].Distance}       
        }
        while ${MyAnomalies_Iterator:Next(exists)}
    }


}