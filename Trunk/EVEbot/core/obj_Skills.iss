objectdef obj_Skills
{
	variable file SkillFile = "${Me}SkillsTraining.txt"
	variable index:skill OwnedSkills
	variable int FrameCounter
	variable string ReadLine = "None"
	variable string NextInLine
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Skills: Initialized"]
		This:GetOtherSkills
		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		FrameCounter:Inc
		variable int IntervalInSeconds = 5
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			if ${This.ReadLine.Equal[${This.CurrentlyTraining}]} && !${This.ReadLine.Equal[None]}
			{
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
		
		for (i:Set[1] ; ${i} <= ${This.OwnedSkills.Used} ; i:Inc)	
		{
				Skills:Next
				if ${Skills.Value.IsTraining}
				{
					if ${Skills.Value.Level} == 1
					{
						return "${Skills.Value.Name} II\r\n"
					}
					
					if ${Skills.Value.Level} == 2
					{
						return "${Skills.Value.Name} III\r\n"
					}
					
					if ${Skills.Value.Level} == 3
					{
						return "${Skills.Value.Name} IV\r\n"
					}
					
					if ${Skills.Value.Level} == 4
					{
						return "${Skills.Value.Name} V\r\n"
					}
					
					if ${Skills.Value.Level} == 0
					{
						return "${Skills.Value.Name} I\r\n"
					}
		
					if ${Skills.Value.Level} == 5
					{
						"${Skills.Value.Name} COMPLETE"
					}
					
					return "${Skills.Value.Name} NULL"
				}
		}
		return "None"
	}
	
	method GetOtherSkills()
	{
		Me:DoGetSkills[OwnedSkills]
	}
	
	member(string) NextSkill()
	{
		variable int i
		variable index:skill SkillList
		variable string ReadSkillName
		variable string ReadSkillLevel
		
		if !${SkillFile.Open}
		{
			if !${SkillFile:Open(exists)}
			{
				UI:UpdateConsole["Error: Couldn't open skill file"]
				return "None"
			}
		}
		
		if !${This.ReadLine.Equal[None]} && !${This.ReadLine.Equal[${This.CurrentlyTraining}]}
		{
				return "${This.ReadLine}"
		}
		
		if ${Me.GetSkills[SkillList]}
		{			
			if ${SkillFile.Read(exists)}
			{
				This.ReadLine:Set[${SkillFile.Read}]
				
				ReadSkillName:Set[${This.RemoveNumerals[${ReadLine}]}]
				ReadSkillLevel:Set[${This.SkillLevel[${ReadLine}]}]
				for (i:Set[1] ; ${i} <= ${Me.GetSkills} ; i:Inc)
				{
					if ${SkillList[${i}].Name.Equal[${ReadSkillName}]} && ${SkillList[${i}].Level} < ${ReadSkillLevel}
					{
						This.NextInLine:Set[${SkillList[${i}].Name}]
					}
				}
			return "${This.ReadLine}"
		}
		SkillFile:Close
		return "None"
	}
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
		return "uh?"
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