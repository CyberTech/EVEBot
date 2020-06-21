#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 *	Entity Retrieval and Member Access, using lavishscript RemoveByQuery method
 *
 *	Revision $Id$
 *
 *	Tests:
 *		EVE:QueryEntities
 *		ntity Members
 *
 *	Requirements:
 *		You: In Space
 */

function main()
{
	declarevariable Entities index:entity script
	declarevariable EntityIterator iterator script

	variable obj_LSTypeIterator ItemTest = "entity"

	variable int StartTime = ${Script.RunningTime}
	variable int StartTime2
	variable float CallTime

	ItemTest:ParseMembers

	;EVE:PopulateEntities[TRUE]
	;UI:UpdateConsole["EVE:PopulateEntities: ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"]

	EVE:QueryEntities[Entities]

	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	UI:UpdateConsole["EVE:QueryEntities: ${Entities.Used} entities in ${CallTime} seconds - Count should be ${EVE.EntitiesCount}"]

	Entities:GetIterator[EntityIterator]

	variable uint QueryID
	;variable string Filter = "Distance < 1000000"
	variable string Filter = "Distance > 200000"
	;variable string Filter = "CategoryID = 25"

	QueryID:Set[${LavishScript.CreateQuery[${Filter}]}]
	if ${QueryID} == 0
	{
		UI:UpdateConsole["LavishScript.CreateQuery: '${Filter}' query addition FAILED"]
		return 0
	}

	Entities:RemoveByQuery[${QueryID}, true]
	UI:UpdateConsole["Entities:RemoveByQuery: ${Entities.Used} entities after call"]

	StartTime2:Set[${Script.RunningTime}]
	if ${EntityIterator:First(exists)}
	do
	{
		;if ${EntityIterator.Value.Distance} < 200000
		;{
			;ItemTest:IterateMembers["EntityIterator.Value", TRUE, FALSE]
			echo ${EntityIterator.Value}: ${EntityIterator.Value.ID} ${EntityIterator.Value.Distance} ${EntityIterator.Value.CategoryID}
		;}
	}
	while ${EntityIterator:Next(exists)}
	;UI:UpdateConsole[" ${ItemTest.TypeName} * ${Entities.Used} completed  ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"]

	UI:UpdateConsole["EVE:QueryEntities: ${Entities.Used} entities in ${CallTime} seconds - Count should be ${EVE.EntitiesCount}"]
	UI:UpdateConsole["Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"]
}

