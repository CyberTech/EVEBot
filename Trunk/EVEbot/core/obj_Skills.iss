objectdef obj_SkillData
{
	variable string Name
	variable float64 TimeToTrain 
	variable int Level

	method Initialize(string _Name, float64 _TimeToTrain, int _Level = -1)
	{
		This.Name:Set[${_Name}]
		This.TimeToTrain:Set[${_TimeToTrain}]
		This.Level:Set[${_Level}]
	}
}

objectdef obj_Skills inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable file SkillFile = "${BaseConfig.CONFIG_PATH}/${_Me.Name} Training.txt"
	variable index:skill OwnedSkills
	variable index:obj_SkillData SkillQueue
	variable index:obj_SkillData SkillFilter

	variable time NextPulse
	variable int PulseIntervalInSeconds = 15

	variable string CurrentlyTrainingSkill
	variable string NextInLine

	method Initialize()
	{
		UI:UpdateConsole["obj_Skills: Initialized", LOG_MINOR]

		if ${This.SkillFile:Open[readonly](exists)} || ${Config.Common.TrainSkillsByTime}
		{
			This:UpdateSkillFilter
			This:UpdateSkills
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
				; Only call the expensive stuff if we're not training a skill, or if we're not in trainfastest
				; mode, since that iterates the entire skill list and is slow.
				if !${Me.SkillCurrentlyTraining(exists)}
				{
					if !${This.NextSkill.Equal[None]} && \
						!${Me.Skill[${This.NextInLine}].IsTraining}
					{
						This:Train[${This.NextInLine}]
					}
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
		elseif ${SkillName.NotEqual[${Me.SkillCurrentlyTraining.Name}]}
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
		variable iterator skillIterator
		
		This:UpdateSkills
		This.SkillQueue:GetIterator[skillIterator]
		if ${skillIterator:First(exists)}
		{
			do
			{
				;; EVETime ticks are 0.1 microseconds
				;; skill time is in minutes
				variable int64 endTime = ${EVETime.AsInt64}
				UI:UpdateConsole["DEBUG: endTime  = ${endTime}", LOG_MINOR]
				UI:UpdateConsole["DEBUG: ${skillIterator.Value.Name} >> ${skillIterator.Value.TimeToTrain}", LOG_MINOR]
				endTime:Inc[${Math.Calc[${skillIterator.Value.TimeToTrain}*10000000*60].Round}]
				UI:UpdateConsole["DEBUG: endTime+ = ${endTime}", LOG_MINOR]
				UI:UpdateConsole["DEBUG: endTime >> ${EVETime[${endTime}].Time}", LOG_MINOR]
				;; Skip skills that end during downtime           
				
				variable int hour
				hour:Set[${EVETime[${endTime}].Time.Token[1, :]}]
				UI:UpdateConsole["DEBUG: hour >> ${hour}", LOG_MINOR]
				
				;;; do not switch to a skill that ends between DT and 8AM PST
				;;; I need my beauty rest -- GP
				if ${hour} < 11 || ${hour} > 15
				{
					UI:UpdateConsole["DEBUG: NextInLine >> ${skillIterator.Value.Name}", LOG_MINOR]
					This.NextInLine:Set[${skillIterator.Value.Name}]
					return ${This.NextInLine}
				}
			}
			while ${skillIterator:Next(exists)}
		}

		UI:UpdateConsole["Error: None of the skills specified were found (or all were already to requested level)", LOG_CRITICAL]
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
	
	method UpdateSkillFilter()
	{
		variable string ReadSkillName
		variable string ReadSkillLevel
		variable string ReadLine
		variable string temp
		
		This.SkillFilter:Clear
		
		temp:Set[${This.SkillFile.Read}]
		while !${This.SkillFile.EOF} && ${temp(exists)}
		{
			/* Sometimes we randomly get a NULL back at the begining of the file. */
			if !${temp.Equal[NULL]}
			{
				/* Remove \r\n from data.  Should really be checking it's not just \n terminated as well. */
				ReadLine:Set[${temp.Left[${Math.Calc[${temp.Length} - 2]}]}]


				ReadSkillName:Set[${This.RemoveNumerals[${ReadLine}]}]
				ReadSkillLevel:Set[${This.SkillLevel[${ReadLine}]}]

				;;UI:UpdateConsole["DEBUG: ReadSkillName: ${ReadSkillName} - ReadSkillLevel: ${ReadSkillLevel}", LOG_MINOR]

				if ${Me.Skill[${ReadSkillName}](exists)}
				{
					if ${Me.Skill[${ReadSkillName}].Level} < ${ReadSkillLevel}
					{
						This.SkillFilter:Insert[${ReadSkillName}, 0, ${ReadSkillLevel}]
					}
					else
					{
						UI:UpdateConsole["DEBUG: Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Done", LOG_MINOR]
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Skill not known", LOG_MINOR]
				}
			}
			temp:Set[${This.SkillFile.Read}]
		}

		This.SkillFile:Close
		This:Sort[SkillFilter, Level]

		variable int idx1 
		variable int idx2
		;;;for (idx1:Set[1] ; ${idx1} <= ${This.SkillFilter.Used} ; idx1:Inc)
		;;;{
		;;;	UI:UpdateConsole["DEBUG: ${idx1}: ${This.SkillFilter.Get[${idx1}].Name} ${This.SkillFilter.Get[${idx1}].Level}", LOG_MINOR]
		;;;}

		UI:UpdateConsole["DEBUG: num skills in filter = ${This.SkillFilter.Used}", LOG_MINOR]
		for (idx1:Set[1] ; ${idx1} <= ${This.SkillFilter.Used} ; idx1:Inc)
		{
			ReadSkillName:Set[${This.SkillFilter.Get[${idx1}].Name}]
			;;UI:UpdateConsole["DEBUG: Removing duplicates: Skill at ${idx1} is ${ReadSkillName}", LOG_MINOR]
			for (idx2:Set[${Math.Calc[${idx1}+1]}] ; ${idx2} <= ${This.SkillFilter.Used} ; idx2:Inc)
			{
				;;;UI:UpdateConsole["DEBUG: idx2 = ${idx2}", LOG_MINOR]
				if ${ReadSkillName.Equal[${This.SkillFilter.Get[${idx2}].Name}]}
				{
					;;;UI:UpdateConsole["DEBUG: Found duplicate skill at ${idx2}", LOG_MINOR]
					This.SkillFilter:Remove[${idx1}]
					This.SkillFilter:Collapse
					idx1:Dec
					break
				}
			}
		}

		;;;for (idx1:Set[1] ; ${idx1} <= ${This.SkillFilter.Used} ; idx1:Inc)
		;;;{
		;;;	UI:UpdateConsole["DEBUG: ${idx1}: ${This.SkillFilter.Get[${idx1}].Name} ${This.SkillFilter.Get[${idx1}].Level}", LOG_MINOR]
		;;;}
	}
	
	method UpdateSkills()
	{
		variable iterator skillIterator
		variable string currentlyTraining
		
		Me:DoGetSkills[This.OwnedSkills]
		This.SkillQueue:Clear
		
		This.OwnedSkills:GetIterator[skillIterator]
		if ${skillIterator:First(exists)}
		{
			currentlyTraining:Set[${Me.SkillCurrentlyTraining.Name}]
			UI:UpdateConsole["DEBUG: currentlyTraining = ${currentlyTraining}", LOG_MINOR]
			
			do
			{
				if ${skillIterator.Value.TimeToTrain} > 0 && ${currentlyTraining.NotEqual[${skillIterator.Value.Name}]}
				{
					;;UI:UpdateConsole["DEBUG: ${skillIterator.Value.Name} ${skillIterator.Value.Level}", LOG_MINOR]
					variable int maxLevelToTrain
					maxLevelToTrain:Set[${This.SkillFilteredLevel["${skillIterator.Value.Name}"]}]
					;;;UI:UpdateConsole["DEBUG: maxLevelToTrain = ${maxLevelToTrain}", LOG_MINOR]	
					;;;UI:UpdateConsole["DEBUG: currentLevel = ${skillIterator.Value.Level}", LOG_MINOR]	
					if ${maxLevelToTrain} > ${skillIterator.Value.Level}
					{
						;;;UI:UpdateConsole["DEBUG: Queueing ${skillIterator.Value.Name} up to level ${maxLevelToTrain}", LOG_MINOR]	
						SkillQueue:Insert[${skillIterator.Value.Name}, ${skillIterator.Value.TimeToTrain}]
					}
				}
			}
			while ${skillIterator:Next(exists)}
		}

		This:Sort[SkillQueue, TimeToTrain]

		;;;This.SkillQueue:GetIterator[skillIterator]
		;;;if ${skillIterator:First(exists)}
		;;;{
		;;;	do
		;;;	{
		;;;		UI:UpdateConsole["DEBUG: ${skillIterator.Value.Name} >> ${skillIterator.Value.TimeToTrain}", LOG_MINOR]
		;;;	}
		;;;	while ${skillIterator:Next(exists)}
		;;;}
	}

	member(int) SkillFilteredLevel(string SkillName)
	{
		if ${This.SkillFilter.Used} == 0
		{
			return 5	
		}
		
		variable int idx
		variable string name
		variable int level

		for (idx:Set[1] ; ${idx} <= ${This.SkillFilter.Used} ; idx:Inc)
		{
			name:Set[${This.SkillFilter.Get[${idx}].Name}]
			if ${name.Equal[${SkillName}]}
			{
				level:Set[${This.SkillFilter.Get[${idx}].Level}]
				if ${level} > ${Me.Skill[${SkillName}].Level}
				{
					UI:UpdateConsole["DEBUG: SkillFilteredLevel found skill at ${idx} (${name} ${level})", LOG_MINOR]
					return ${level}
				}
				else
				{
					UI:UpdateConsole["obj_Skills.SkillFilteredLevel removing invalid filter at ${idx} (${name} ${level})"]
					This.SkillFilter:Remove[${idx}]
					This.SkillFilter:Collapse
					break
				}
			}
		}
		
		return 0
	}
}