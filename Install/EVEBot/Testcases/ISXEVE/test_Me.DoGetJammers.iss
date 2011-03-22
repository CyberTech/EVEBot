#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test GetJammers

	Revision $Id$

	Requirements:
		You: In Space
		Other1: Shooting you
*/

variable obj_UI UI
function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int StartTime2

	declarevariable Jammers index:jammer script
	declarevariable JammerIterator iterator script

	variable obj_LSTypeIterator JammerTest = "jammer"

	JammerTest:ParseMembers

	Me:GetJammers[Jammers]
	variable float CallTime
	CallTime:Set[${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]}]
	echo "Me:GetJammers returned ${Jammers.Used} modules in ${CallTime} seconds"

	Modules:GetIterator[ModuleIterator]
	if ${ModuleIterator:First(exists)}
	do
	{
		StartTime2:Set[${Script.RunningTime}]
		JammerTest:IterateMembers["JammerIterator.Value", TRUE, FALSE]
		echo "Single ${JammerTest.TypeName} dump completed ${Math.Calc[(${Script.RunningTime}-${StartTime2}) / 1000]} seconds"
	}
	while ${ModuleIterator:Next(exists)}

	echo "Me:GetJammers returned ${Jammers.Used} modules in ${CallTime} seconds"
	echo "Testing of datatype ${JammerTest.TypeName} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
}