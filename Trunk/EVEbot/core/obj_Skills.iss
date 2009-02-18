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
	variable int PrevSkillFileSize = -1

	variable index:skill OwnedSkills
	variable index:obj_SkillData SkillQueue
	variable index:obj_SkillData SkillFilter

	variable time NextPulse
	variable int PulseIntervalInSeconds = 15

	variable string CurrentlyTrainingSkill
	variable string NextInLine

	method Initialize()
	{
		if !${This.SkillFile.Size(exists)}
		{
			; Create an empty skillfile to make it easier for the user
			This.SkillFile:Open
			This.SkillFile:Truncate
			This.SkillFile:Close
		}
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Skills: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${Config.Common.TrainSkills} && ${Me(exists)}
			{
				if (${This.PrevSkillFileSize} == -1) || \
					 (${This.SkillFile.Size} != ${This.PrevSkillFileSize})
				{
					; Skillfile has not yet been checked or has changed
					if ${This.SkillFile.Size} > 0
					{
						UI:UpdateConsole["obj_Skill: Reloading skillfile"]
						This:UpdateSkillFileQueue[]
					}
					This.PrevSkillFileSize:Set[${This.SkillFile.Size}]
				}

				; TODO - CyberTech - need to detect other char on account training a skill
				if !${Me.SkillCurrentlyTraining(exists)}
				{
					; We're not training a skill, so update the character skill list
					This:UpdateSkills
					if !${This.NextSkill.Equal[None]} && \
						!${Me.Skill[${This.NextInLine}].IsTraining}
					{
						This:Train[${This.NextInLine}]
					}
				}
				CurrentlyTrainingSkill:Set[${This.CurrentlyTraining}]

			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
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
				;UI:UpdateConsole["DEBUG: endTime  = ${endTime}", LOG_DEBUG]
				;UI:UpdateConsole["DEBUG: ${skillIterator.Value.Name} >> ${skillIterator.Value.TimeToTrain}", LOG_DEBUG]
				endTime:Inc[${Math.Calc[${skillIterator.Value.TimeToTrain}*10000000*60].Round}]
				;UI:UpdateConsole["DEBUG: endTime+ = ${endTime}", LOG_DEBUG]
				;UI:UpdateConsole["DEBUG: endTime >> ${EVETime[${endTime}].Time}", LOG_DEBUG]
				;; Skip skills that end during downtime

				variable int hour
				hour:Set[${EVETime[${endTime}].Time.Token[1, :]}]
				;UI:UpdateConsole["DEBUG: hour >> ${hour}", LOG_DEBUG]

				;;; do not switch to a skill that ends between DT and 8AM PST
				;;; I need my beauty rest -- GP
				if ${hour} < 11 || ${hour} > 15
				{
					;UI:UpdateConsole["DEBUG: NextInLine >> ${skillIterator.Value.Name}", LOG_DEBUG]
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

	method UpdateSkillFileQueue()
	{
		variable string ReadSkillName
		variable string ReadSkillLevel
		variable string ReadLine
		variable string temp

		This.SkillFilter:Clear
		if !${This.SkillFile:Open[readonly](exists)}
		{
			UI:UpdateConsole["obj_Skills: Unable to open skillfile!", LOG_CRITICAL]
			return
		}

		do
		{
			temp:Set[${This.SkillFile.Read}]

			; Sometimes we randomly get a NULL back at the begining of the file.
			if ${temp(exists)} && !${temp.Equal[NULL]}
			{
				ReadLine:Set[${temp.Replace[\r, ""]}]
				ReadLine:Set[${ReadLine.Replace[\n, ""]}]

				ReadSkillName:Set[${This.RemoveNumerals[${ReadLine}]}]
				ReadSkillLevel:Set[${This.SkillLevel[${ReadLine}]}]

				UI:UpdateConsole["DEBUG: ReadSkillName: ${ReadSkillName} - ReadSkillLevel: ${ReadSkillLevel}", LOG_DEBUG]

				if ${Me.Skill[${ReadSkillName}](exists)}
				{
					if ${Me.Skill[${ReadSkillName}].Level} < ${ReadSkillLevel}
					{
						This.SkillFilter:Insert[${ReadSkillName}, 0, ${ReadSkillLevel}]
					}
					else
					{
						UI:UpdateConsole["DEBUG: Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Done", LOG_DEBUG]
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Skill not known", LOG_DEBUG]
				}
			}
		}
		while ${This.SkillFile.EOF(exists)} && !${This.SkillFile.EOF}

		This.SkillFile:Close
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
			;UI:UpdateConsole["DEBUG: currentlyTraining = ${currentlyTraining}", LOG_DEBUG]

			do
			{
				if ${skillIterator.Value.TimeToTrain} > 0 && ${currentlyTraining.NotEqual[${skillIterator.Value.Name}]}
				{
					;;UI:UpdateConsole["DEBUG: ${skillIterator.Value.Name} ${skillIterator.Value.Level}", LOG_DEBUG]
					variable int maxLevelToTrain
					maxLevelToTrain:Set[${This.SkillFilteredLevel["${skillIterator.Value.Name}"]}]
					;;;UI:UpdateConsole["DEBUG: maxLevelToTrain = ${maxLevelToTrain}", LOG_MINOR]
					;;;UI:UpdateConsole["DEBUG: currentLevel = ${skillIterator.Value.Level}", LOG_DEBUG]
					if ${maxLevelToTrain} > ${skillIterator.Value.Level}
					{
						;;;UI:UpdateConsole["DEBUG: Queueing ${skillIterator.Value.Name} up to level ${maxLevelToTrain}", LOG_DEBUG]
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
		;;;		UI:UpdateConsole["DEBUG: ${skillIterator.Value.Name} >> ${skillIterator.Value.TimeToTrain}", LOG_DEBUG]
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