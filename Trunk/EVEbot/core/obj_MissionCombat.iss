/* Explanation of room numbers -

they are intended to be used when the salvaging part of the bot is completed so we can inform our salvager which areas are clear

room 0 is always the area that is where the mission bookmark is
rooms are divided by a warp , so using an acceleration gate or warping to another boookmark would mean whereever you land is room 1
*/

objectdef obj_MissionCombat
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable obj_MissionCommands MissionCommands
	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable string CurrentState = "IDLE"
	variable string CurrentCommand = "Idle"

	variable int roomNumber = 0
	variable index:string targetBlacklist
	variable index:string priorityTargets
	variable string lootItem
	variable bool CommandComplete = FALSE
	variable bool MissionComplete = FALSE
	variable bool MissionUnderway = FALSE
	;variable Time timeout
	variable iterator CommandIterator
	variable int FailureCount = 0
	variable int MissionID = 0
	variable obj_MissionDatabase MissionDatabase
	method Initialize()
	{
		;attach our pulse atom to the onframe even so we fire the pulse every frame
		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	method Pulse()
	{
		if !${Config.Common.BotMode.Equal[Missioneer]}
		{
			; finish if we are not running missions, should be we finish if we are not running a combat mission
			return
		}
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				; if evebot is not paused we should figure out what state we want to be in
				This:SetState
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
	method Shutdown()
	{
		; detach the atom when we get garbaged
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	/* All of this should be getting called from Behaviors/obj_Missioneer.iss so
	it will be handling the getting and turning in of missions. However, we do
	need to handle going to locations for objectives. */
	method SetState()
	{
		/* we reset to idle of the defense thread runs away, thus resetting the state machine to its entry point, processstate does not get called untill the defense thread stops hiding */
		if ${Defense.Hide}
		{
			This.CurrentState:Set["Idle"]
		}
		else
		{
		}
		; We dont use setstate for anything else because there is no way to tell if we are in the mission,
		; which means we could get stuck in infinite loops trying to warp to the mission as you cant warp from inside a mission to its start
		; the best way to solve this would be to have amadeus implement a member in isxeve indicating if we are in a deadspace or not
		; a hack would be to have failure states for warptobookmark and have warptobookmark watch for the "cannot warp in deadspace" message - warpprepare means this is even more terrible

		; For now we just have the states themselves decide what the correct state transition is
		; STATES -

		; ARMING - Go to equipment station and equip the right things for the mission - transitions to gotomission when ship is properly equipped
		; GOTOMISSION - get to the mission - transition to commands when at the location (for now it calls warptobookmark then assumes we reached the mission)
		; RUNCOMMANDS - find commands , execute them in order - transition to mission complete when we have no commands left
		; MISSIONCOMPLETE - hand the mission in - transitions to abort if we have tried to hand the mission in too many times (ie something went wrong) , otherwise goes back to idle
		; ABORT - Mission failed to complete too many times, something went wrong so we abandon the mission - transitions to idle when finished

	}

	function ProcessState()
	{
		switch ${This.CurrentState}
		{
			case IDLE
			UI:UpdateConsole["DEBUG: obj_MissionCombat - ${This.MissionID}"]
			;missionID is set to 0 when complete Agents.TurnInMission successfully
			if ${This.MissionID} != 0
			{
				UI:UpdateConsole["DEBUG: obj_MissionCombat - MissionID found, setting state to arming",LOG_DEBUG]
				This.CurrentState:Set["ARMING"]
			}
			else
			{
				UI:UpdateConsole["DEBUG: obj_MissionCombat - fffffffff"]
			}
			break

			case ARMING
			{
				; TODO (this is a really big one)
				; MAKE EVEBOT EQUIP ITSELF!
				;if ${This.Armed}
				;{

				UI:UpdateConsole["DEBUG: obj_MissionCombat - setting state from arming to goto mission",LOG_DEBUG]

				This.CurrentState:Set["GOTOMISSION"]
				;}
				;else
				;{
				;call This.Rearm
				;}

				break
			}
			case GOTOMISSION
			{
				if ${This.MissionID} != 0
				{
					UI:UpdateConsole["DEBUG: obj_MissionCombat - Calling WarpToEncounter, MissionID ${This.MissionID}",LOG_DEBUG]

					call WarpToEncounter ${This.MissionID}
					;we assume that warptoencounter succeded and we are now sitting at the first acceleration gate
					;todo - check it actually succeded

					;lets find the name of the mission we are running and see if we can match it to a set of commands in the database
					variable string missLevel = ${Agent[id,${This.MissionID}].Level}
					variable string missionName = ${Missions.MissionCache.Name[${This.MissionID}]}

					UI:UpdateConsole["DEBUG: obj_MissionCombat - Checking for mission in database - Mission Name : ${missionName} , Mission Level : ${missLevel}",LOG_DEBUG]

					if ${MissionDatabase.MissionCommands[${missionName},${missLevel}].Children(exists)}
					{

						UI:UpdateConsole["DEBUG: obj_MissionCombat - Mission found in database , checking commands exist for it",LOG_DEBUG]

						;if we get here we can assume there are some command associate with the mission so we set the command iterator to the first one
						MissionDatabase.MissionCommands[${missionName},${missLevel}]:GetSetIterator[CommandIterator]
						;one final check to make sure we really do have commands
						if ${CommandIterator:First(exists)}
						{

							UI:UpdateConsole["DEBUG: obj_MissionCombat - Commands found, changing state to RunCommands",LOG_DEBUG]

							;light is green! the first location in a mission is always room number 0
							roomNumber:Set[0]
							This.CurrentState:Set["RUNCOMMANDS"]
						}
						else
						{
							;well we found the mission but no commands exist for it, abort

							UI:UpdateConsole["DEBUG: obj_MissionCombat - Commands not found , changing state to Abort ",LOG_DEBUG]

							This.CurrentState::Set["ABORT"]
						}
					}
					else
					{
						;we could not find the mission in the database! Abort!

						UI:UpdateConsole["DEBUG: obj_MissionCombat - Mission not found, changing state to Abort ",LOG_DEBUG]
						This.CurrentState:Set["ABORT"]
					}
				}
				else
				{
					;we get here if for some reason we lost the missionID, revert to idle state

					UI:UpdateConsole["DEBUG: obj_MissionCombat - Have no mission ID in state GotoMisison, reverting to Idle state ",LOG_DEBUG]
					This.CurrentState:Set["IDLE"]
				}

				break
			}
			case RUNCOMMANDS
			{
				;we should be at the mission at the very first gate or simply in the encounter area
				;we should also have some commands to iterator over
				;first we call the method that decides what command we should be executing

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Executing Runcommands state",LOG_DEBUG]
				This:SetCommandState

				;next we call the method that executes said command
				;commands return true or false based on whether they complete or not, commands that do not complete in one go
				;simply get called again until they complete

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Attempting to process command 	${CommandIterator.Value.FindAttribute["Action"].String}",LOG_DEBUG]

				if ${This.ProccessCommand}
				{

					UI:UpdateConsole["DEBUG: obj_MissionCombat - ${CurrentCommand} successfully completed, moving onto next command",LOG_DEBUG]


					if !${CommandIterator:Next(exists)}
					{
						;the next command in the list does not exist!
						;if everything went smoothly  the mission should be in the complete state

						UI:UpdateConsole["DEBUG: obj_MissionCombat - Ran out of commands ,setting state to MissionComplete ",LOG_DEBUG]

						This.CurrentState:Set["MISSIONCOMPLETE"]
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCombat - Next command is ${CommandIterator.Value.FindAttribute["Action"].String} ",LOG_DEBUG]
					}
				}
				else
				{
					;getting here means we need to process the command again as it did not complete
					;todo -
					;add a limit to the number of times we get here before we decide something has gone wrong

					UI:UpdateConsole["DEBUG: obj_MissionCombat - command did not complete , will attempt again next pulse ",LOG_DEBUG]

				}

				break
			}
			case MISSIONCOMPLETE
			{
				This.MissionCommands:MissionComplete[]
				UI:UpdateConsole["DEBUG: obj_MissionCombat - Warping to Agent Home Base  ",LOG_DEBUG]

				call This.WarpToHomeBase ${This.MissionID}

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Arrived at agent home base (we hope), attempting to turn in mission",LOG_DEBUG]

				call Agents.TurnInMission

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Mission turned in (probably) setting state to idle",LOG_DEBUG]

				This.MissionID:Set[0]
				This.CurrentState:Set["IDLE"]
				;			if ${StillHaveTheMission}
				;			{
				;				if ${FailureCount > FailureThreshhold}
				;				{
				;					This.CurrentState:Set["Abort"]
				;					return
				;				}
				;				FailureCount:Inc
				;			}
				break
			}
			case ABORT
			{

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Aborting mission, warpign to home base",LOG_DEBUG]

				call This.WarpToHomeBase ${This.MissionID}

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Attempting to quit mission",LOG_DEBUG]

				call Agents.QuitMission

				UI:UpdateConsole["DEBUG: obj_MissionCombat - Quit mission (hopefully) , setting state to idle",LOG_DEBUG]

				This.MissionID:Set[0]
				This.CurrentState:Set["IDLE"]
				break
			}
		}
	}

	function WarpToEncounter(int agentID)
	{
		variable index:agentmission amIndex
		variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["dungeon"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value} FALSE
								return
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}

	method SetCommandState()
	{
		; we have an iterator that should be set to the first command in a series of commands in a mission
		if ${CommandIterator.IsValid}
		{
			;we find whatever action is to be taken , it should be an attribute called "Action"
			switch ${CommandIterator.Value.FindAttribute["Action"].String}
			{
				case Approach
				{
					CurrentCommand:Set["Approach"]
					break
				}
				case ApproachBreakOnCombat
				{
					CurrentCommand:Set["ApproachBreakOnCombat"]
					break
				}
				case UseGateStructure
				{
					CurrentCommand:Set["UseGateStructure"]
					break
				}
				case NextRoom
				{
					CurrentCommand:Set["NextRoom"]
					break
				}
				case TargetAggros
				{
					CurrentCommand:Set["TargetAggros"]
					break
				}
				case WaitAggro
				{
					CurrentCommand:Set["WaitAggro"]
					break
				}
				case KillAgressors
				{
					CurrentCommand:Set["KillAgressors"]
					break
				}
				case ClearRoom
				{
					CurrentCommand:Set["ClearRoom"]
					break
				}
				case Kill
				{
					CurrentCommand:Set["Kill"]
					break
				}
				case Waves
				{
					CurrentCommand:Set["Waves"]
					break
				}
				case "WaitTargetQueueZero"
				{
					CurrrentCommand:Set["WaitTargetQueueZero"]
					break
				}
				case Pull
				{
					CurrentCommand:Set["Pull"]
					break
				}
				case CheckContainers
				{
					CurrentCommand:Set["CheckContainers"]
					break
				}
			}
		}
		else
		{
			;if our command iterator is not valid ,we either ran out of commands or we have not been given any
			CurrentCommand:Set["Idle"]
		}
	}

	member:bool ProccessCommand()
	{
		variable settingsetref currentCommandref
		currentCommandref:Set[${CommandIterator.Value.GUID}]

		variable int IDCache
		UI:UpdateConsole["DEBUG: obj_MissionCombat - current command : ${This.CurrentCommand} !",LOG_DEBUG]

		switch ${This.CurrentCommand}
		{
			case Approach
			{
				IDCache:Set[${This.FindID[${currentCommandref.FindAttribute["Target"].String}]}]

				return ${MissionCommands.Approach[${IDCache}]}
				break
			}
			case ApproachBreakOnCombat
			{
				IDCache:Set[${This.FindID[${currentCommandref.FindAttribute["Target"].String}, ${currentCommandref.FindAttribute["CategoryID"].String}]}]

				return ${MissionCommands.ApproachBreakOnCombat[${IDCache},${currentCommandref.FindAttribute["Distance"].String}]}
				break
			}
			case ActivateGate
			{
				IDCache:Set[${This.FindID[${currentCommandref.FindAttribute["Target"].String}]}]

				return ${MissionCommands.ActivateGate[${IDCache}]}
				break
			}
			case NextRoom
			{
				return ${MissionCommands.NextRoom}
				break
			}
			case TargetAggros
			{
				MissionCommands:TargetAggros[]
				break
			}
			case WaitAggro
			{
				return ${MissionCommands.WaitAggro[${currentCommandref.FindAttribute["AggroCount"].Int}]}
				break
			}
			case KillAggressors
			{
				return ${MissionCommands.KillAgressors[]}
				break
			}
			case ClearRoom
			{
				return ${MissionCommands.ClearRoom[]}
				break
			}
			case Kill
			{
				return ${MissionCommands.Kill[${currentCommandref.FindAttribute["Target"].String}, ${currentCommandref.FindAttribute["CategoryID",CATEGORYID_ENTITY]}]}
				break
			}
			case Waves
			{
				return ${MissionCommands.Waves[${currentCommandref.FindAttribute["TimeOut"].Int}]}
				break
			}
			case Pull
			{
				return ${MissionCommands.Pull[${currentCommandref.FindAttribute["Target","NONE"]}]}
				break
			}
			case CheckContainers
			{
				return ${MissionCommands.CheckContainers[${currentCommandref.FindAttribute["GroupID",GROUPID_CARGO_CONTAINER]}, ${currentCommandref.FindAttribute["Target"].String}, ${currentCommandref.FindAttribute["WreckName","NONE"]}]}
				break
			}
			case Idle
			{
				return TRUE
				break
			}
		}
	}

	function WarpToHomeBase(int agentID)
	{
		variable index:agentmission amIndex
		variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["obj_Missions: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["agenthomebase"]} || \
							${mbIterator.Value.LocationType.Equal["objective"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value} FALSE
								return
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}
	member:int FindID(string entityName,int CatID = CATEGORYID_ENTITY)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		EVE:DoGetEntities[targetIndex, CategoryID, ${CatID}]
		targetIndex:GetIterator[targetIterator]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.Name.Equal[${entityName}]}
				{
					return ${targetIterator.Value.ID}
				}
			}
			while ${targetIterator:Next(exists)}
		}
		UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find ${entityName}",LOG_DEBUG]
		return 0
	}
}