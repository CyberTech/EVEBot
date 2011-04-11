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
		variable index:queuedskill SkillQueueIndex
		Me:GetSkillQueue[SkillQueueIndex]

		variable iterator Skill
		SkillQueueIndex:GetIterator[Skill]

		echo "Skills Queued Me:GetSkillQueue: ${SkillQueueIndex.Used}"

		if ${Skill:First(exists)}
		{
			do
			{
				echo Skill.Value.TrainingTo ${Skill.Value.TrainingTo}
				echo Skill.Value.ToSkill ${Skill.Value.ToSkill}
				;Skill.Value:Remove
			}
			while ${Skill:Next(exists)}
		}
}