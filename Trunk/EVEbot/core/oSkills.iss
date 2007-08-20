/*
	Variables:
		file SkillFile														;The file your skill list is read from
																							;Should be formated with one skill per line, with skill name and roman
																								numeral level (same way EveMon saves to .txt, with all options off)

	Methods:
		Train(string SkillName)										;Starts training the skill if you have it
		
	Members:
		string CurrentlyTraining()								;Returns the name of your currently training skill
		bool Training(string SkillName = NULL)		;Returns true/false if your are training any skill, or are training a specific skill
		string NextSkill()												;Returns the next skill from your skill file that you can train
		string RemoveNumerals(string SkillName)		;Returns the SkillName, sans roman numeral level
		int SkillLevel(string SkillName)					;Returns the decimal equivalent of the roman numeral level on the skill name
		
		
*/

objectdef obj_Skills
{
	variable file SkillFile = "SkillsToTrain.txt"
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Skills: Initialized"]
	}

	method Train(string SkillName)
	{
		if !${Me.Skill[${SkillName}](exists)}
		{
			echo "Error: Don't have skill ${SkillName}"
			return
		}
		if !${This.Training} || ${SkillName.NotEqual[${This.CurrentlyTraining}]}
		{
			echo "Training ${SkillName}"
			Me.Skill[${SkillName}]:StartTraining
		}		
	}	
	
	member(string) CurrentlyTraining()
	{
		variable int i
		variable index:skill SkillList
		if ${Me.GetSkills[SkillList]}
		{
			for (i:Set[1] ; ${i} <= ${Me.GetSkills} ; i:Inc)
			{
				if ${SkillList[${i}].IsTraining}
				{
					return ${SkillList[${i}].Name}
				}
			}
		}
		return ""
	}
	
	member(bool) Training(string SkillName = NULL)
	{
		if ${SkillName.NotEqual[NULL]}
		{
			if ${Me.Skill[${SkillName}](exists)} && ${Me.Skill[${SkillName}].IsTraining}
			{
				return TRUE
			}
		}
		else
		{
			variable int i
			variable index:skill SkillList
			if ${Me.GetSkills[SkillList]}
			{
				for (i:Set[1] ; ${i} <= ${Me.GetSkills} ; i:Inc)
				{
					if ${SkillList[${i}].IsTraining}
					{
						return TRUE
					}
				}
			}
		}
		return FALSE
	}
	
	member(string) NextSkill()
	{
		variable int i
		variable index:skill SkillList
		variable string ReadLine
		variable string ReadSkillName
		variable string ReadSkillLevel
		
		if !${SkillFile.Open}
		{
			if !${SkillFile:Open(exists)}
			{
				echo "Error: Couldn't open skill file"
				return
			}
		}
		
		if ${Me.GetSkills[SkillList]}
		{
			ReadLine:Set[${SkillFile.Read}]
			do
			{
				ReadSkillName:Set[${This.RemoveNumerals[${ReadLine}]}]
				ReadSkillLevel:Set[${This.SkillLevel[${ReadLine}]}]
				for (i:Set[1] ; ${i} <= ${Me.GetSkills} ; i:Inc)
				{
					if ${SkillList[${i}].Name.Equal[${ReadSkillName}]} && ${SkillList[${i}].Level} < ${ReadSkillLevel}
					{
						SkillFile:Close
						return ${SkillList[${i}].Name}
					}
				}			
			}
			while (${ReadLine:Set[${SkillFile.Read}].NotEqual[NULL]})
		}
		SkillFile:Close
		return "NULL"
	}
	
	member(string) RemoveNumerals(string SkillName)
	{
		variable string ReturnVal
		
		SkillName:Set[${SkillName.Left[${Math.Calc[${SkillName.Length} - 3]}]}]
		
		if ${SkillName.Right[3].Equal[" II"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 3]}]}
		}
		elseif ${SkillName.Right[2].Equal[" I"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 2]}]}
		}
		elseif ${SkillName.Right[1].Equal[" "]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 1]}]}
		}
		return ""
	}
	
	member(int) SkillLevel(string SkillName)
	{
		variable string NumeralList[5]
		variable int i
		
		NumeralList[1]:Set["I"]
		NumeralList[2]:Set["II"]
		NumeralList[3]:Set["III"]
		NumeralList[4]:Set["IV"]
		NumeralList[5]:Set["V"]
		SkillName:Set[${SkillName.Left[${Math.Calc[${SkillName.Length} - 2]}]}]
		
		for (i:Set[1] ; ${i} <= 5 ; i:Inc)
		{
			if ${SkillName.Right[${NumeralList[${i}].Length}].Equal[${NumeralList[${i}]}]}
			{
				return ${i}
			}
		}
		return 0
	}
}