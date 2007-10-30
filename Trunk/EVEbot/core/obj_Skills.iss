objectdef obj_Skills
{
	variable file SkillFile = "${Script.CurrentDirectory}/config/${Me.Name} Training.txt"
	variable index:skill OwnedSkills
	variable int FrameCounter
	variable string NextInLine
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Skills: Initialized"]
		Me:DoGetSkills[This.OwnedSkills]

		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		FrameCounter:Inc
		variable int IntervalInSeconds = 10
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			echo ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
			if !${This.NextSkill.Equal[None]} && \
				!${Me.Skill[${This.NextSkill}].IsTraining}
			{
				Me:DoGetSkills[This.OwnedSkills]
				This:Train[${This.NextInLine}]
			}
			FrameCounter:Set[0]
		}
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
		
		variable iterator Skills
		
		This.OwnedSkills:GetIterator[Skills]
		
		if ${Skills:First(exists)}
		do
		{
			if ${Skills.Value.IsTraining}
			{
				Switch ${Skills.Value.Level}
				{
					case 0
						return "${Skills.Value.Name} I"
						break
					case 1
						return "${Skills.Value.Name} II"
						break
					case 2
						return "${Skills.Value.Name} III"
						break
					case 3
						return "${Skills.Value.Name} IV"
						break
					case 4
						return "${Skills.Value.Name} V"
						break
					case 5
						return "${Skills.Value.Name} Complete"
						break
				}
				return "${Skills.Value.Name} NULL"
			}
		}
		while ${Skills:Next(exists)}

		return "None"
	}
		
	member(string) NextSkill()
	{
		variable string ReadSkillName
		variable string ReadSkillLevel
		variable string ReadLine

		if !${This.SkillFile:Open[readonly](exists)}
		{
			echo missing skill file ${SkillFile}
			return "None"
		}
		
		variable string temp = ${SkillFile.Read}

		while !${This.SkillFile.EOF} && ${temp(exists)}
		{
			/* Remove \r\n fron data.  Should really be checking it's not just \n terminated as well. */
			ReadLine:Set[${temp.Left[${Math.Calc[${temp.Length} - 2]}]}]
			
			ReadSkillName:Set[${This.RemoveNumerals[${ReadLine}]}]
			ReadSkillLevel:Set[${This.SkillLevel[${ReadLine}]}]

			echo Potential Skill: ${ReadSkillName} @ Level ${ReadSkillLevel}
			if ${Me.Skill[${ReadSkillName}](exists)} && \
				${Me.Skill[${ReadSkillName}].Level} < ${ReadSkillLevel}
			{
				This.NextInLine:Set[${ReadSkillName}]
				SkillFile:Close
				return "${ReadSkillName}"
			}	
			temp:Set[${SkillFile.Read}]
		}

		UI:UpdateConsole["Error: None of the skills specified were found; or all were already to requested level"]
		SkillFile:Close
		return "None"
	}

	
	member(bool) Training(string SkillName)
	{
		if ${SkillName(exists)}
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
	
	member(string) RemoveNumerals(string SkillName)
	{	
		if ${SkillName.Right[2].Equal[" I"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 2]}]}
		}
		elseif ${SkillName.Right[3].Equal[" II"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 3]}]}
		}
		elseif ${SkillName.Right[4].Equal[" III"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 4]}]}
		}
		elseif ${SkillName.Right[3].Equal[" IV"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 3]}]}
		}
		elseif ${SkillName.Right[2].Equal[" V"]}
		{
			return ${SkillName.Left[${Math.Calc[${SkillName.Length} - 2]}]}
		}
		return "uh?"
	}
	
	member(int) SkillLevel(string SkillName)
	{
		variable string NumeralList[5]
		variable int i
		
		NumeralList[1]:Set["V"]
		NumeralList[2]:Set["IV"]
		NumeralList[3]:Set["III"]
		NumeralList[4]:Set["II"]
		NumeralList[5]:Set["I"]
		
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