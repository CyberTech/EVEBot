#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test GetAttackers

	Revision $Id$

	Requirements:
		You: In Space
		Other1: Shooting you
*/

function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int StartTime2

	declarevariable Attackers index:attacker script
	declarevariable AttackerIterator iterator script

	variable obj_LSTypeIterator AttackerTest = "attacker"

	AttackerTest:ParseMembers

	Me:GetAttackers[Attackers]
	variable float CallTime
	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	echo "Me:GetAttackers returned ${Attackers.Used} modules in ${CallTime} seconds"

	Modules:GetIterator[ModuleIterator]
	if ${ModuleIterator:First(exists)}
	do
	{
		StartTime2:Set[${Script.RunningTime}]
		AttackerTest:IterateMembers["AttackerIterator.Value", TRUE, FALSE]
		echo "Single ${AttackerTest.TypeName} dump completed ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"
	}
	while ${ModuleIterator:Next(exists)}

	echo "Me:GetAttackers returned ${Attackers.Used} modules in ${CallTime} seconds"
	echo "Testing of datatype ${AttackerTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
}