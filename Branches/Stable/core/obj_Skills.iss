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
	variable file SkillFile = "${BaseConfig.CONFIG_PATH}/${Me.Name} Training.txt"
	variable int PrevSkillFileSize = -1

	variable index:skill OwnedSkills
	variable index:obj_SkillData SkillQueue
	variable index:obj_SkillData SkillFileQueue

	variable string CurrentlyTrainingSkill = "-"
	variable string NextInLine = "None"

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		if !${This.SkillFile.Size(exists)}
		{
			; Create an empty skillfile to make it easier for the user
			This.SkillFile:Open
			This.SkillFile:Truncate
			This.SkillFile:Close
		}

		PulseTimer:SetIntervals[15.0,25.0]
		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		; Run even when paused
		if ${This.PulseTimer.Ready}
		{
			if ${EVEBot.SessionValid}
			{
				if ${Config.Common.TrainSkills} && ${Me(exists)}
				{
					if (${This.PrevSkillFileSize} == -1) || \
						 (${This.SkillFile.Size} != ${This.PrevSkillFileSize})
					{
						; Skillfile has not yet been checked or has changed
						if ${This.SkillFile.Size} > 0
						{
							Logger:Log["obj_Skill: Reloading skillfile"]
							This:UpdateSkillFileQueue[]
						}
						This.PrevSkillFileSize:Set[${This.SkillFile.Size}]
					}

					if !${Me.SkillCurrentlyTraining(exists)}
					{
						; We're not training a skill, so update the character skill list
						This:UpdateSkills
						if !${This.NextSkill.Equal[None]}
						{
							This:Train[${This.NextInLine}]
						}

						/* If we've already got a skill training on this account, turn off training */
						; 2020 - I don't think this window is modal anymore.
						;if ${EVEWindow[ByName,MessageBox](exists)} && \
						;	${EVEWindow[ByCaption,Information](exists)}
						;{
						;	Logger:Log["obj_Skill: Already training on another character on this account, detaching pulse and turning off TrainSkills"]
						;	Press Esc
						;	This:Shutdown[]
						;	Config.Common:TrainSkills[FALSE]
						;}
					}
				}

				if ${Me(exists)}
				{
					CurrentlyTrainingSkill:Set[${Me.SkillCurrentlyTraining}]
				}
			}

			This.PulseTimer:Update
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
			Logger:Log["Training ${SkillName}"]
			Me.Skill[${SkillName}]:StartTraining
		}
		elseif ${SkillName.NotEqual[${Me.SkillCurrentlyTraining.Name}]}
		{
			Logger:Log["Changing skill to ${SkillName} from ${This.CurrentlyTraining}"]
			Me.Skill[${SkillName}]:StartTraining
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

		This.SkillQueue:GetIterator[skillIterator]
		if ${skillIterator:First(exists)}
		{
			do
			{
				;; EVETime ticks are 0.1 microseconds
				;; skill time is in minutes
				variable int64 endTime = ${EVETime.AsInt64}
				;Logger:Log["DEBUG: endTime  = ${endTime}", LOG_DEBUG]
				;Logger:Log["DEBUG: ${skillIterator.Value.Name} >> ${skillIterator.Value.TimeToTrain}", LOG_DEBUG]
				endTime:Inc[${Math.Calc[${skillIterator.Value.TimeToTrain}*10000000*60].Round}]
				;Logger:Log["DEBUG: endTime+ = ${endTime}", LOG_DEBUG]
				;Logger:Log["DEBUG: endTime >> ${EVETime[${endTime}].Time}", LOG_DEBUG]
				;; Skip skills that end during downtime

				variable int hour
				hour:Set[${EVETime[${endTime}].Time.Token[1, :]}]
				;Logger:Log["DEBUG: hour >> ${hour}", LOG_DEBUG]

				;;; do not switch to a skill that ends between DT and 8AM PST
				;;; I need my beauty rest -- GP
				if ${hour} < 11 || ${hour} > 15
				{
					;Logger:Log["DEBUG: NextInLine >> ${skillIterator.Value.Name}", LOG_DEBUG]
					This.NextInLine:Set[${skillIterator.Value.Name}]
					return ${This.NextInLine}
				}
			}
			while ${skillIterator:Next(exists)}
		}

		Logger:Log["Error: None of the skills specified were found (or all were already to requested level)", LOG_CRITICAL]
		return "None"
	}


	member(bool) Training(string SkillName = "")
	{
		if ${SkillName.Length} > 0
		{
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
			if ${Me.SkillCurrentlyTraining(exists)}
			{
						return TRUE
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

		This.SkillFileQueue:Clear
		if !${This.SkillFile:Open[readonly](exists)}
		{
			Logger:Log["obj_Skills: Unable to open skillfile!", LOG_CRITICAL]
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

				Logger:Log["DEBUG: ReadSkillName: ${ReadSkillName} - ReadSkillLevel: ${ReadSkillLevel}", LOG_DEBUG]

				if ${Me.Skill[${ReadSkillName}](exists)}
				{
					if ${Me.Skill[${ReadSkillName}].Level} < ${ReadSkillLevel}
					{
						This.SkillFileQueue:Insert[${ReadSkillName}, 0, ${ReadSkillLevel}]
					}
					else
					{
						Logger:Log["DEBUG: Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Done", LOG_DEBUG]
					}
				}
				else
				{
					Logger:Log["DEBUG: Skill: ${ReadSkillName} to Level ${ReadSkillLevel}: Skill not known", LOG_DEBUG]
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

		Me:GetSkills[This.OwnedSkills]
		This.SkillQueue:Clear

		This.OwnedSkills:GetIterator[skillIterator]
		if ${skillIterator:First(exists)}
		{
			currentlyTraining:Set[${Me.SkillCurrentlyTraining.Name}]
			;Logger:Log["DEBUG: currentlyTraining = ${currentlyTraining}", LOG_DEBUG]

			do
			{
				if ${skillIterator.Value.TimeToTrain} > 0 && ${currentlyTraining.NotEqual[${skillIterator.Value.Name}]}
				{
					;;Logger:Log["DEBUG: ${skillIterator.Value.Name} ${skillIterator.Value.Level}", LOG_DEBUG]
					variable int maxLevelToTrain
					maxLevelToTrain:Set[${This.SkillFilteredLevel["${skillIterator.Value.Name}"]}]
					;;;Logger:Log["DEBUG: maxLevelToTrain = ${maxLevelToTrain}", LOG_DEBUG]
					;;;Logger:Log["DEBUG: currentLevel = ${skillIterator.Value.Level}", LOG_DEBUG]
					if ${maxLevelToTrain} > ${skillIterator.Value.Level}
					{
						Logger:Log["DEBUG: Queueing ${skillIterator.Value.Name} up to level ${maxLevelToTrain}", LOG_DEBUG]
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
		;;;		Logger:Log["DEBUG: ${skillIterator.Value.Name} >> ${skillIterator.Value.TimeToTrain}", LOG_DEBUG]
		;;;	}
		;;;	while ${skillIterator:Next(exists)}
		;;;}
	}

	member(int) SkillFilteredLevel(string SkillName)
	{
		if ${This.SkillFileQueue.Used} == 0
		{
			return 5
		}

		variable int idx
		variable string name
		variable int level

		for (idx:Set[1] ; ${idx} <= ${This.SkillFileQueue.Used} ; idx:Inc)
		{
			name:Set[${This.SkillFileQueue.Get[${idx}].Name}]
			if ${name.Equal[${SkillName}]}
			{
				level:Set[${This.SkillFileQueue.Get[${idx}].Level}]
				if ${level} > ${Me.Skill[${SkillName}].Level}
				{
					Logger:Log["DEBUG: SkillFilteredLevel found skill at ${idx} (${name} ${level})", LOG_MINOR]
					return ${level}
				}
				else
				{
					Logger:Log["obj_Skills.SkillFilteredLevel removing invalid filter at ${idx} (${name} ${level})"]
					This.SkillFileQueue:Remove[${idx}]
					This.SkillFileQueue:Collapse
					break
				}
			}
		}

		return 0
	}
}