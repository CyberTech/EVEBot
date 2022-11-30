#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 * 	Read what is in the probe scanner window
 *
 *	
 *
 *	Tests:
 *		Testing what sites have been added to global AnomSites Iterator
 *		
 *
 *	Requirements:
 *		You: In spcae
 *		Probe Scanner window open and active
 */

 function main()
{
    variable iterator CurrentSites
    
    AnomSites:GetIterator[CurrentSites]
    
    if ${CurrentSites:First(exists)}
    {           
        do
        {           
            echo ${Time}: ------------------------------------
            echo ${Time}: Site In List: ${CurrentSites.Value}

        }
        while ${CurrentSites:Next(exists)}
    }

}