#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Me:GetSkillQueue
	Test queuedskill (Being) Member Iteration


	Revision $Id$

	Requirements:
		Populated Skill Queue
		Skill Queue Window Must be open
*/

function main()
{
	variable obj_LSTypeIterator ItemTest = "queuedskill"
	variable string MethodStr = "Me:GetSkillQueue"

	#include "../_Testcase_MethodStr_Body.iss"
}