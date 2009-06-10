/* Explanation of room numbers -

they are intended to be used when the salvaging part of the bot is completed so we can inform our salvager which areas are clear

room 0 is always the area that is where the mission bookmark is
rooms are divided by a warp , so using an acceleration gate or warping to another boookmark would mean whereever you land is room 1
*/

objectdef obj_MissionCombat
{
	variable string SVN_REVISION = "$Rev: 988 $"
	variable int Version
	variable obj_MissionCommands MissionCommands
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable string CurrentState
	variable string CurrentCommand

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
		;Event[OnFrame]:AttachAtom[This:Pulse]
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
		;Event[OnFrame]:DetachAtom[This:Pulse]
	}

	/* All of this should be getting called from Behaviors/obj_Missioneer.iss so
	it will be handling the getting and turning in of missions. However, we do
	need to handle going to locations for objectives. */
	method SetState()
	{
		/* we reset to idle of the defense thread runs away, thus resetting the state machine to its entry point, processstate does not get called untill the defense thread stops hiding */
		if ${Defense.Hide}
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Defense hiding , resetting state to idle"]
			#endif
			This.CurrentState:Set["Idle"]
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
			case "Idle":
			; missionID is set to 0 when complete Agents.TurnInMission successfully
			if ${This.MissionID != 0}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCombat - MissionID found, setting state to arming"]
				#endif
				This.CurrentState:Set["Arming"]
			}
			break
			case "Arming":
			; TODO (this is a really big one)
			; MAKE EVEBOT EQUIP ITSELF!
			;if ${This.Armed}
			;{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - setting state from arming to goto mission"]
			#endif
			This.CurrentState:Set["GotoMission"]
			;}
			;else
			;{
			;call This.Rearm
			;}
			break
			case "GotoMission":
			if ${This.MissionID != 0}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCombat - Calling WarpToEncounter, MissionID ${This.MissionID}"]
				#endif
				call WarpToEncounter ${This.MissionID}
				;we assume that warptoencounter succeded and we are now sitting at the first acceleration gate
				;todo - check it actually succeded

				;lets find the name of the mission we are running and see if we can match it to a set of commands in the database
				variable string missLevel = ${Agent[id,${agentID}].Level}
				variable string missionName = ${MissionCache.Name[${agentID}]}
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCombat - Checking for mission in database - Mission Name : ${missonName} , Mission Level : ${missLevel}"]
				#endif
				if ${MissionDatabase.MissionCommands[${missionName},${missLevel}].Children(exists)}
				{
					#if EVEBOT_DEBUG
					UI:UpdateConsole["DEBUG: obj_MissionCombat - Mission found in database , checking commands exist for it"]
					#endif
					;if we get here we can assume there are some command associate with the mission so we set the command iterator to the first one
					CommandIterator = MissionDatabase.MissionCommands[${missionName},${missLevel}]:GetSetIterator[CommandIterator]
					;one final check to make sure we really do have commands
					if ${CommandIterator:First(exists)}
					{
						#if EVEBOT_DEBUG
						UI:UpdateConsole["DEBUG: obj_MissionCombat - Commands found, changing state to RunCommands"]
						#endif
						;light is green! the first location in a mission is always room number 0
						roomNumber:Set[0]
						This.CurrentState:Set["RunCommands"]
					}
					else
					{
						;well we found the mission but no commands exist for it, abort
						#if EVEBOT_DEBUG
						UI:UpdateConsole["DEBUG: obj_MissionCombat - Commands not found , changing state to Abort "]
						#endif
						This.CurrentState::Set["Abort"]
					}
				}
				else
				{
					;we could not find the mission in the database! Abort!
					#if EVEBOT_DEBUG
					UI:UpdateConsole["DEBUG: obj_MissionCombat - Mission not found, changing state to Abort "]
					#endif
					This.CurrentState:Set["Abort"]
				}
			}
			else
			{
				;we get here if for some reason we lost the missionID, revert to idle state
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCombat - Have no mission ID in state GotoMisison, reverting to Idle state "]
				#endif
				This.CurrentState:Set["Idle"]
			}
			break
			case "RunCommands":
			;we should be at the mission at the very first gate or simply in the encounter area
			;we should also have some commands to iterator over
			;first we call the method that decides what command we should be executing
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Executing Runcommands state"]
			#endif
			This:SetCommandState
			;next we call the method that executes said command
			;commands return true or false based on whether they complete or not, commands that do not complete in one go
			;simply get called again untill they complete
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Attempting to process command ${CurrentCommand}"]
			#endif
			if ${This:ProcessCommand}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCombat - ${CurrentCommand} successfully completed, moving onto next command"]
				#endif
				;then we move the iterator onto the next command
				if !${CommandIterator:Next(exists)}
				{
					;the next command in the list does not exist!
					;if everything went smoothly  the mission should be in the complete state
					#if EVEBOT_DEBUG
					UI:UpdateConsole["DEBUG: obj_MissionCombat - Ran out of commands ,setting state to MissionComplete "]
					#endif
					This.CurrentState:Set["MissionComplete"]
				}
				else
				{
					#if EVEBOT_DEBUG
					UI:UpdateConsole["DEBUG: obj_MissionCombat - Next command is ${CommandIterator.Value.FindAttribute["Action"].String} "]
					#endif
				}
			}
			else
			{
				;getting here means we need to process the command again as it did not complete
				;todo -
				;add a limit to the number of times we get here before we decide something has gone wrong
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCombat - command did not complete , will attempt again next pulse "]
				#endif
			}
			break
			case "MissionComplete":
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Warping to Agent Home Base  "]
			#endif
			call This.WarpToHomeBase ${This.MissionID}
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Arrived at agent home base (we hope), attempting to turn in mission"]
			#endif
			call Agents.TurnInMission
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Mission turned in (probably) setting state to idle"]
			#endif
			This.MissionID:Set[0]
			This.CurrentState:Set["Idle"]
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
			case "Abort":
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Aborting mission, warpign to home base"]
			#endif
			call This.WarpToHomeBase ${This.MissionID}
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Attempting to quit mission"]
			#endif
			call Agent.QuitMission
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCombat - Quit mission (hopefully) , setting state to idle"]
			#endif
			This.MissionID:Set[0]
			This.CurrentState:Set["Idle"]
			break
		}
		/* Somewhere in here will be a call to a method in this class that will
		process the objective command. It will not be done from the FSM. */
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
								call Ship.WarpToBookMark ${mbIterator.Value}
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
			switch ${This.${CommandIterator.Value.FindAttribute["Action"].String}}
			{
				case "Approach":
				{
					CurrentCommand:Set["Approach"]
				}
				case "UseGateStructure":
				{
					CurrentCommand:Set["UseGateStructure"]
				}
				case "NextRoom":
				{
					CurrentCommand:Set["NextRoom"]
				}
				case "TargetAggros":
				{
					CurrentCommand:Set["TargetAggros"]
				}
				case "WaitAggro":
				{
					CurrentCommand:Set["WaitAggro"]
				}
				case "KillAgressors":
				{
					CurrentCommand:Set["KillAgressors"]
				}
				case "ClearRoom":
				{
					CurrentCommand:Set["ClearRoom"]
				}
				case "Kill":
				{
					CurrentCommand:Set["Kill"]
				}
				case "Waves":
				{
					CurrentCommand:Set["Waves"]
				}
				case "WaitTargetQueueZero":
				{
					CurrrentCommand:Set["WaitTargetQueueZero"]
				}
				case "PullNearest"
				{
					CurrentCommand:Set["PullNearest"]
				}
				case "CheckContainers":
				{
					CurrentCommand:Set["CheckContainers"]
				}
				case "CheckWrecks":
				{
					CurrentCommand:Set["CheckWrecks"]
				}
			}
		}
		else
		{
			;if our command iterator is not valid ,we either ran out of commands or we have not been given any
			CurrentCommand:Set["Idle"]
		}
	}

	function:bool ProccessState()
	{
		switch ${This.CurrentState}
		{
			case "Approach":
			{
				return ${MissionCommands.Approach[${CommandIterator.Value.FindAttribute["Target"].String}]}
				break
			}
			case "ApproachBreakOnCombat":
			{
				return ${MissionCommands.ApproachBreakOnCombat[${CommandIterator.Value.FindAttribute["Target"].String}]}
				break
			}
			case "UseGateStructure":
			{
				return ${MissionCommands.UseGateStructure[${CommandIterator.Value.FindAttribute["Target"].String}]}
				break
			}
			case "NextRoom":
			{
				return ${MissionCommands.NextRoom[]}
				break
			}
			case "TargetAggros":
			{
				return ${MissionCommands.TargetAggros[]}
				break
			}
			case "WaitAggro":
			{
				return ${MissionCommands.Approach[${CommandIterator.Value.FindAttribute["TimeOut"].Int}]}
				break
			}
			case "KillAggressors":
			{
				return ${MissionCommands.KillAgressors[]}
				break
			}
			case "ClearRoom":
			{
				return ${MissionCommands.ClearRoom[]}
				break
			}
			case "Kill":
			{
				return ${MissionCommands.Kill[${CommandIterator.Value.FindAttribute["Target"].String}]}
				break
			}
			case "Waves":
			{
				return ${MissionCommands.Waves[${CommandIterator.Value.FindAttribute["TimeOut"].Int}]}
				break
			}
			case "WaitTargetQueueZero":
			{
				return ${MissionCommands.WaitTargetQueueZero[]}
				break
			}
			case "PullNearest":
			{
				return ${MissionCommands.PullNearest[]}
				break
			}
			case "CheckContainers":
			{
				return ${MissionCommands.CheckContainers[${CommandIterator.Value.FindAttribute["GroupID"]}, ${CommandIterator.Value.FindAttribute["Target"].String}]}
				break
			}
			case "CheckWrecks":
			{
				return  ${MissionCommands.CheckContainers[${CommandIterator.Value.FindAttribute["GroupID"]}, ${CommandIterator.Value.FindAttribute["Target"].String} , ${CommandIterator.Value.FindAttribute["WreckName"]}]}
				break
			}
			case Idle:
			{
				return TRUE
			}
		}
	}
}

;	function:bool RunMission(settingsetref commandPile)
;	{
;		variable time breakTime
;		variable int  gateCounter = 0
;		variable int  doneCounter = 0
;		variable iterator CommandIterator
;		variable iterator ParameterIterator
;		while TRUE
;		{
;			commandPile:GetSetIterator[CommandIterator]
;			if ${CommandIterator:First(exists)}
;			{
;				do
;				{
;					if !${Combat.Fled}
;					{
;						CommandIterator.Value:GetSettingIterator[ParameterIterator]
;						if ${ParameterIterator:First(exists)}
;						{
;							do
;							{
;								if !${Defense.Hiding}
;								{
;									UI:UpdateConsole["obj_MissionCombat: DEBUG: Calling ${CommandIterator.Value.FindAttribute[Action].String} parameter : ${ParameterIterator.Value.String}"]
;									call This.${CommandIterator.Value.FindAttribute["Action"].String} "${ParameterIterator.Value.String}"
;								}
;								else
;								{
;									return FALSE
;								}
;							}
;							while ${ParameterIterator:Next(exists)}
;						}
;						else
;						{
;							if !${Defense.Hiding}
;							{
;								UI:UpdateConsole["obj_MissionCombat: DEBUG: Calling ${CommandIterator.Value.FindAttribute[Action].String}"]
;								call This.${CommandIterator.Value.FindAttribute["Action"].String}
;							}
;							else
;							{
;								return FALSE
;							}
;						}
;					}
;					else
;					{
;						break
;					}
;					wait 20 ; pause here as running stuff like checkcans after hostilecount reaches zero can be too fast sometimes
;				}
;				while ${CommandIterator:Next(exists)}
;				UI:UpdateConsole["obj_MissionCombat: DEBUG: Mission commands exhausted , mission complete? "]
;				return TRUE
;			}
;			UI:UpdateConsole["obj_MissionCombat: DEBUG: no commands for mission!"]
;			return FALSE
;		}
;	}
