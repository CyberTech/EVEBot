#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
 *	Entity Retrieval and Member Access
 *
 *	Revision $Id$
 *
 *	Tests:
 *		EVE:QueryEntities
 *		Entity Members
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

	variable index:string MemberList
	MemberList:Insert[ID]
	MemberList:Insert[Name]
	;MemberList:Insert[GroupID]
	;MemberList:Insert[TypeID]
	;MemberList:Insert[CategoryID]
	;MemberList:Insert[ShieldPct]
	;MemberList:Insert[ArmorPct]
	;MemberList:Insert[StructurePct]
	MemberList:Insert[Distance]
	;MemberList:Insert[X]
	;MemberList:Insert[Y]
	;MemberList:Insert[Z]
	;MemberList:Insert[BeingTargeted]
	;MemberList:Insert[IsLockedTarget]
	;MemberList:Insert[IsNPC]
	;MemberList:Insert[IsPC]
	;MemberList:Insert[IsTargetingMe]

	variable iterator CurrentMember

	;EVE:PopulateEntities[TRUE]
	;UI:UpdateConsole["EVE:PopulateEntities: ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"]

	StartTime:Set[${Script.RunningTime}]
	EVE:QueryEntities[Entities]
	EVE:QueryEntities[Entities, Distance < 200000]
	EVE:QueryEntities[Entities, "CategoryID = 25"]

	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	UI:UpdateConsole["EVE:QueryEntities: ${Entities.Used} entities in ${CallTime} seconds"]

	Entities:GetIterator[EntityIterator]
	MemberList:GetIterator[CurrentMember]

	StartTime:Set[${Script.RunningTime}]
	if ${CurrentMember:First(exists)}
	do
	{
		StartTime2:Set[${Script.RunningTime}]
		if ${EntityIterator:First(exists)}
		do
		{
			;ItemTest:IterateMembers["EntityIterator.Value", TRUE, FALSE]
			if ${EntityIterator.Value.FleetTag.Equal[""]}
			{
				echo ${EntityIterator.Value}: ${EntityIterator.Value.ID} ${EntityIterator.Value.Distance} "Empty"
			}
			else
			{
				echo ${EntityIterator.Value}: ${EntityIterator.Value.ID} ${EntityIterator.Value.Distance} ${EntityIterator.Value.FleetTag}
			}

		}
		while ${EntityIterator:Next(exists)}
		UI:UpdateConsole["${ItemTest.TypeName}.${CurrentMember.Value}/Name/Distance * ${Entities.Used} completed  ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"]
	}
	while ${CurrentMember:Next(exists)}

	UI:UpdateConsole["EVE:QueryEntities returned ${Entities.Used} entities in ${CallTime} seconds"]
	UI:UpdateConsole["Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"]
}
