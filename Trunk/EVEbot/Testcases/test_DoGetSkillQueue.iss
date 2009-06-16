#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Me:DoGetSkillQueue
	Test queuedskill (Being) Member Iteration


	Revision $Id$

	Requirements:
		Populated Skill Queue
		Skill Queue Window Must be open
*/

variable obj_UI UI
function main()
{
		variable index:queuedskill SkillQueueIndex
		Me:DoGetSkillQueue[SkillQueueIndex]

		variable iterator Skill
		SkillQueueIndex:GetIterator[Skill]

		echo "Skills Queued Me:DoGetSkillQueue: ${SkillQueueIndex.Used}"
		echo "Skills Queued Me.GetSkillQueue: ${Me.GetSkillQueue}"
		echo "Skills Queued Me.GetSkillQueue[]: ${Me.GetSkillQueue[SkillQueueIndex]}"

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