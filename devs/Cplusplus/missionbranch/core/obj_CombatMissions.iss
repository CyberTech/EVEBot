objectdef obj_CombatMissions
{
	variable string SVN_REVISION = "$Rev: 1348 $"
	variable int Version
	variable string CurrentState = "IDLE"
	variable int TargetEntity = 0
	variable obj_MissionCommands MissionCommands
	
	method Initialize()
	{
		;Event[OnFrame]:AttachAtom[This:Pulse]
	}
	function RunCombatMission(int agentId)
	{
		switch ${This.CurrentState}
		{
			case IDLE
				This:NextCommand
				break
			case ERROR
				This:InvalidateMission
				break
			case TEST
				wait 50
				break
			default
				UI:UpdateConsole["Calling missioncommands with ${This.MissionCommands.StateStack.Top}"]
				;stealthy suck my balls
				call This.${This.CurrentState}
				break
		}
	}
		
	method NextCommand()
	{
		if ${MissionCache.Commands:Next(exists)}
		{
			switch ${MissionCache.Commands.Value}
			{
				case "ClearRoom"
					This.CurrentState:Set["CLEARROOM"]
					break
				case "ActivateGate"
					if ${Entity["Acceleration Gate"](exists)}
					{
						TargetEntity:Set[${Entity["Acceleration Gate"].ID}]
						This.MissionCommands.StateStack:Push["APPROACH"]					
						This.MissionCommands.StateStack:Push["WARP_PREPARE"]
						This.MissionCommands.StateStack:Push["ACTIVATE_GATE"]
						This.MissionCommands.StateStack:Push["WARP"]
						This.MissionCommands.StateStack:Push["END_WARP"]
						This.CurrentState:Set["ActivateGate"]
					}
					else
					{
						UI:UpdateConsole["Could not find acceleration gate, you twat"]
					}
					break
				case "Kill"
					This.CurrentState:Set["KILL"]
					break
				}
			}		
	}
	
	function ActivateGate()
	{
		if ${This.MissionCommands.StateStack.Top(exists)}
		{
				switch ${This.MissionCommands.StateStack.Top}
				{
					case APPROACH
						UI:UpdateConsole["Trying to approach dis gate"]
						call This.MissionCommands.Approach ${TargetEntity} JUMP_RANGE
						break
					case WARP_PREPARE
						UI:UpdateConsole["Getting ready for warpings boss"]
						call This.MissionCommands.WarpPrepare
						break
					case ACTIVATEGATE
						UI:UpdateConsole["WAAAAAAAAAAAAAAAAUUUGH"]
						call This.MissionCommands.ActivateGate ${TargetEntity}
						break
					case WARP
						UI:UpdateConsole["WATING FOR WARP BOSS"]
						call This.MissionCommands.WaitWarp
						break
					case END_WARP
						UI:UpdateConsole["OOOOOOOOOOOPS"]
						call This.MissionCommands.EndWarp
						break
					case ERROR
						UI:UpdateConsole["Shit broke"]
						This.CurrentState:Set["ERROR"]
						break
					default
						UI:UpdateConsole["Unknown MissionCommands State : ${This.MissionCommands.StateStack.Top}"]
						break
				}
		}
		else
		{
			UI:UpdateConsole["Stack exhausted, let it rest"]
			This.CurrentState:Set["TEST"]
			;This:NextCommand
		}
	}
	function ClearRoom()
	{
		if ${Targeting.CurrentEntityCount} > 0
		{
			if ${Targeting.AgressionCount} == 0
			{
				if ${This.MissionCommands.StateStack.Used} == 0
				{
					UI:UpdateConsole["CombatMissions.ClearRoom : Nothing in the stack and no aggression, queuing Pull"]
					TargetEntity:Set[${Targeting.ClosestEntity}]
					This.MissionCommands.StateStack:Push["PULL"]
				}				
			}
			else
			{
				if ${This.MissionCommands.StateStack.Used} == 0
				{
					UI:UpdateConsole["CombatMissions.ClearRoom : Nothing in the stack and aggression, queuing Kill"]
					TargetEntity:Set[${Targeting.ClosestEntity}]
					This.MissionCommands.StateStack:Push["KILL"]
				}				
			}
			
			switch ${This.MissionCommands.StateStack.Top}
			{
				case PULL
					call This.MissionCommands.Pull ${This.TargetEntity}
					break
				case KILL
					call This.MissionCommands.Kill ${This.TargetEntity}
					break
				case APPROACH
					call This.MissionCommands.Approach ${This.TargetEntity} 5000
					break
				case APPROACH_BREAK_COMBAT
					call This.MissionCommands.ApproachBreakOnCombat ${This.TargetEntity} 5000
					break
				case ERROR
					This.CurrentState:Set["ERROR"]
					break
				default
					UI:UpdateConsole["ERROR: CombatMissions.ClearRoom : Unregonized state ${This.MissionCommands.StateStack"]
					break
			}
		}
		else
		{
			UI:UpdateConsole["CombatMissions.ClearRoom : CurrentEntityCount is 0 , NEXTCOMMAND"]
			;This:NextCommand
		}
	}
	function Kill(string TargetName,int GroupID)
	{
		
		
		
	}
	
	function SearchLoot(string ItemName , int SearchCategory)
	{
		
	}
	
	
	
	
	
	/* 
	
			TESTING FUNCTIONS AND STUFF BELOW IGNORE , NOT USED FOR THINGS UNLESS YOU ARE A SMARTYMAN
	
	*/
	method TestActivateGate()
	{	
		This.MissionCommands.StateStack:Push["END_WARP"]				
		This.MissionCommands.StateStack:Push["WARP"]
		This.MissionCommands.StateStack:Push["ACTIVATEGATE"]
		This.MissionCommands.StateStack:Push["WARP_PREPARE"]
		This.MissionCommands.StateStack:Push["APPROACH"]
		This.CurrentState:Set["ActivateGate"]
		TargetEntity:Set[${Entity["Acceleration Gate"].ID}]
		UI:UpdateConsole["TESTIFIED"]
	}
	method TestClearRooom()
	{
		This.CurrentState:Set["ClearRoom"]
		UI:UpdateConsole["CombatMissions.TestClearRoom : State Set"]		
	}
	method TestReadVariables()
	{
		This.CurrentState:Set["ReadVariables"]
		UI:UpdateConsole["CombatMissions.TestReadVariables : State Set"]		
	}
	
	function ReadVariables()
	{
		UI:UpdateConsole["CombatMissions.ReadVariable : CurrentAggressionCount : ${Targeting.AgressionCount}"]
		UI:UpdateConsole["CombatMissions.ReadVariable : CurrentEntityCount : ${Targeting.CurrentEntityCount}"]
	}
	
}