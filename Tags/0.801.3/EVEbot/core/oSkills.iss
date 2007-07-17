function TrainSkills()
{
variable string LearningSkill1 = ""
variable string LearningSkill2 = ""
variable string LearningSkill3 = ""
variable string LearningSkill4 = ""
call UpdateHudStatus "Setting LearningSkills 1-4"
variable int i = 1

	if !${Skill[${LearningSkill${i}}].IsTraining}
	{
		call UpdateHudStatus "I am not training this skill, so lets train it!"
		${Skill[${LearningSkill${i}}]}:StartTraining
		call UpdateHudStatus "Training..."
		i:Inc
	}
}