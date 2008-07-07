objectdef obj_Skills
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable file SkillFile = "${BaseConfig.CONFIG_PATH}/${_Me.Name} Training.txt"
	variable index:skill OwnedSkills
	variable time NextPulse
	variable int PulseIntervalInSeconds = 5

	variable string CurrentlyTrainingSkill
	variable string NextInLine
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Skills: Initialized", LOG_MINOR]
		
		if ${This.SkillFile:Open[readonly](exists)}
		{
			Me:DoGetSkills[This.OwnedSkills]
			Event[OnFrame]:AttachAtom[This:Pulse]
			This.SkillFile:Close
		}
		else
		{
			This.SkillFile:Open
			This.SkillFile:Truncate
			This.SkillFile:Close
		}
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
		    if ${Me(exists)}
		    {
    			if !${This.NextSkill.Equal[None]} && \
    				!${Me.Skill[${This.NextSkill}].IsTraining}
    			{
    				Me:DoGetSkills[This.OwnedSkills]
    				This:Train[${This.NextInLine}]
    			}
    			
    			CurrentlyTrainingSkill:Set[${This.CurrentlyTraining}]

	    		This.NextPulse:Set[${Time.Timestamp}]
	    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
	    		This.NextPulse:Update
			}
		}
	}

	method Train(string SkillName)
	{
		if !${Me.Skill[${SkillName}](exists)}
		{
			echo "Error: Don't have skill ${SkillName}"
			return
		}
		if !${This.Training} 
		{
			UI:UpdateConsole["Training ${SkillName}"]
			Me.Skill[${SkillName}]:StartTraining
			CurrentlyTrainingSkill:Set[${SkillName}]
		}
		
		if ${SkillName.NotEqual[${Me.SkillCurrentlyTraining.Name}]}
		{
			UI:UpdateConsole["Changing skill to ${SkillName} from ${This.CurrentlyTraining}"]
			Me.Skill[${SkillName}]:StartTraining
			CurrentlyTrainingSkill:Set[${SkillName}]
		}
	}	
	
	member(string) CurrentlyTraining()
	{			
		if ${Me.SkillCurrentlyTraining(exists)}
		{
			variable string SkillName = ${Me.SkillCurrentlyTraining.Name}
			Switch ${Me.SkillCurrentlyTraining.Level}
			{
				case 0
					return "${SkillName} I"
					break
				case 1
					return "${SkillName} II"
					break
				case 2
					return "${SkillName} III"
					break
				case 3
					return "${SkillName} IV"
					break
				case 4
					return "${SkillName} V"
					break
				case 5
					return "${SkillName} Complete"
					break
			}
		}	

		return "None"
	}
		
	member(string) NextSkill()
	{
		variable string ReadSkillName
		variable string ReadSkillLevel
		variable string ReadLine

		if !${This.SkillFile:Open[readonly](exists)} || \
			${This.SkillFile.Size} == 0
		{
			return "None"
		}
		
		variable string temp
		temp:Set[${SkillFile.Read}]
		
		while !${This.SkillFile.EOF} && ${temp(exists)}
		{
			/* Sometimes we randomly get a NULL back at the begininng of the file. */
			if !${temp.Equal[NULL]}
			{
				/* Remove \r\n from data.  Should really be checking it's not just \n terminated as well. */
				ReadLine:Set[${temp.Left[${Math.Calc[${temp.Length} - 2]}]}]
			

				ReadSkillName:Set[${This.RemoveNumerals[${ReadLine}]}]
				ReadSkillLevel:Set[${This.SkillLevel[${ReadLine}]}]
				
				if ${Me.Skill[${ReadSkillName}](exists)}
				{
					if ${Me.Skill[${ReadSkillName}].Level} < ${ReadSkillLevel}
					{
						This.NextInLine:Set[${ReadSkillName}]
						SkillFile:Close
						return "${ReadSkillName}"
					}
					else
					{
						;echo "Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Done"
					}
				}
				else
				{
					;echo "Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Skill not known"
				}
			}
			temp:Set[${SkillFile.Read}]
		}

		UI:UpdateConsole["Error: None of the skills specified were found (or all were already to requested level)", LOG_CRITICAL]
		SkillFile:Close
		return "None"
	}

	
	member(bool) Training(string SkillName = "")
	{
		if ${SkillName.Length} > 0
		{
			/* TODO - this randomly fails for a skill that's being trained.  Amadeus informed */
			if ${Me.Skill[${SkillName}](exists)} && ${Me.Skill[${SkillName}].IsTraining}
			{
				return TRUE
			}
			else
			{
				;echo "DEBUG: obj_Skill:Training(${SkillName}) == (false) ${Me.Skill[${SkillName}].IsTraining} - ${Me.Skill[${SkillName}].Name}"
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
		return "Unknown"
	}
	
	member(int) SkillLevel(string SkillName)
	{
		if ${SkillName.Right[2].Equal[" I"]}
		{
			return 1
		}
		elseif ${SkillName.Right[3].Equal[" II"]}
		{
			return 2
		}
		elseif ${SkillName.Right[4].Equal[" III"]}
		{
			return 3
		}
		elseif ${SkillName.Right[3].Equal[" IV"]}
		{
			return 4
		}
		elseif ${SkillName.Right[2].Equal[" V"]}
		{
			return 5
		}
		return 0
	}
}