objectdef obj_MissionCommands
{
	variable stack:string StateStack
	variable string CurrentState = "IDLE"
	variable string LastState = "FFFFFF"
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	method Pulse()
	{
		if !${CurrentState.Equal[${LastState}]}
		{
			UI:UpdateConsole["MissionCommands : Changed State, now is ${CurrentState}"]
			LastState:Set[${CurrentState}]
		}		
	}
	function Idle()
	{
		if ${StateStack.Top(exists)}
		{
			CurrentState:Set[${StateStack.Top}]
		}
		else
		{
			return
		}
	}
	function WaitWarp()
	{
		if ${Me.ToEntity.Mode} == 3
		{
			This.StateStack:Pop
		}
		else
		{
			UI:UpdateConsole["MissionCommands.WaitWarp - Not in warp yet boss"]
		}
	}
	function EndWarp()
	{
		if ${Me.ToEntity.Mode} != 3
		{
			This.StateStack:Pop
		}
		else
		{
			UI:UpdateConsole["MissionCommands.WaitWarp - not left warp yet boss"]
		}
	}
	function Approach(int EntityID, int64 Distance = DOCKING_RANGE)
	{
		UI:UpdateConsole["MissionCommands.Approach : Arguments - EntityID ${EntityID} Distance ${Distance}"]
		if !${Entity[${EntityID}](exists)}
		{
			UI:UpdateConsole["MissionCommands.Approach : ENTITY DOES NOT EXIST FUCKHEAD"]
			This.StateStack:Pop
		}
		elseif ${Entity[${EntityID}].Distance} < ${Distance}
		{
			UI:UpdateConsole["MissionCommands.Approach : IM CLOSE ENOUGH"]
			This.StateStack:Pop
		}
		elseif ${Navigator.TargetEntityID} == ${EntityID}
		{
			;already approaching , do nothing
			UI:UpdateConsole["MissionCommands.Approach : NAVIGATOR IS APPROACHING - FUCK YEAH"]
		}
		else
		{
			UI:UpdateConsole["MissionCommands.Approach : NOT CLOSE ENOUGH - NAVIGATOR APROACH!"]
			Navigator:Approach[${EntityID},${Distance}]
		}
	}
	
	function ApproachBreakOnCombat(int EntityID,int Distance = DOCKING_RANGE)
	{
		UI:UpdateConsole["MissionCommands.ApproachBreakOnCombat : Arguments - EntityID ${EntityID} Distance ${Distance}"]
		if !${Entity[${EntityID}](exists)}
		{
			UI:UpdateConsole["MissionCommands.ApproachBreakOnCombat : ENTITY DOES NOT EXIST FUCKHEAD"]
			This.StateStack:Pop
		}
		elseif ${Targeting.AgressionCount} > 0
		{
			UI:UpdateConsole["MissionCommands.ApproachBreakOnCombat : GOT HOSTILES"]
			This.StateStack:Pop
		}
		elseif ${Entity[${EntityID}].Distance} < ${Distance}
		{
			UI:UpdateConsole["MissionCommands.ApproachBreakOnCombat : IM CLOSE ENOUGH"]
			This.StateStack:Pop
		}
		elseif ${Navigator.TargetEntityID} == ${EntityID}
		{
			;already approaching , do nothing
			UI:UpdateConsole["MissionCommands.ApproachBreakOnCombat : NAVIGATOR IS APPROACHING - FUCK YEAH"]
		}
		else
		{
			UI:UpdateConsole["MissionCommands.ApproachBreakOnCombat : NOT CLOSE ENOUGH - NAVIGATOR APROACH!"]
			Navigator:Approach[${EntityID},${Distance}]
		}
	}
	
	function ActivateGate(int EntityID)
	{
		UI:UpdateConsole["MissionCommands.ActivateGate : Arguments - EntityID ${EntityID}"]
		if ${Entity[${EntityID}].Distance} < JUMP_RANGE
		{			
			Entity[${EntityID}]:Activate
			wait 20
			This.StateStack:Pop
		}
		else
		{
			UI:UpdateConsole["MissionCommands.ActivateGate : Jumpgate was not close enough blurrr"]
		}
	}
	function Kill(int EntityID)
	{
		if ${Entity[${EntityID}](exists)} && !${Entity[${EntityID}].IsMoribund} && ${Entity[${EntityID}].GroupID} != GROUPID_WRECK
		{
			if ${Entity[${EntityID}].Distance} > 9000
			{
				This.StateStack:Push["APPROACH"]
			}
			else
			{
				if ${Targeting.IsQueued[${EntityID}]}
				{
					UI:UpdateConsole["MissionCommands.Kill : Target is queued for destruction, chillaxing"]
				}
				else
				{
					Targeting:Queue[${EntityID},0,${Entity[${EntityID}].TypeID},TRUE,FALSE]
				}
			}
		}
		else
		{
			UI:UpdateConsole["MissionCommands.Kill : Entity with ID ${EntityID} , no longer exists , we killed it woot"]
			This.StateStack:Pop
		}
	}
	
	function Pull(int EntityID)
	{
		if ${Targeting.AgressionCount} == 0
		{
			if ${Entity[${EntityID}](exists)}
			{
				if ${Entity[${EntityID}].Distance} > ${Ship.OptimalWeaponRange}
				{
					UI:UpdateConsole["MissionCommands.Pull : Too far away to shoot, moving a bit closer"]
					This.StateStack:Push["APPROACH_BREAK_COMBAT"]
				}
				else
				{
					if ${Targeting.IsQueued[${EntityID}]}
					{
						UI:UpdateConsole["MissionCommands.Kill : Target is queued for destruction, chillaxing"]
					}
					else
					{
						Targeting:Queue[${EntityID},0,${Entity[${EntityID}].TypeID},TRUE,FALSE]
					}
				}
			}
			else
			{
				UI:UpdateConsole["MissionCommands.Kill : Entity with ID ${EntityID} , no longer exists , we killed it woot"]
				This.StateStack:Pop
			}
		}
		else
		{
			UI:UpdateConsole["MissionCommands.Pull : Aggression Detected beep beep"]
			This.StateStack:Pop
		}
	}
	
	function IgnoreEntity(string entityName)
	{
	}
	
	function PrioritzeEntity(string entityName)
	{
		
	}
	
	function WaitAggro(int aggroCount = 1)
	{
		if ${This.AggroCount} >= ${aggroCount}
		{
			This.CurrentState:Set['IDLE']
		}
	}
	
	function KillAggressors()
	{
		
	}
	
	function ClearRoom()
	{
		;import clear_room
	}
	
	function KillID(int entityID)
	{
		if ${Entity[${entityID}].Distance} < ${Ship.OptimalWeaponRange}
		{
			if ${Targeting.IsQueued[${entityID}]}
			{
				Targeting:Queue[${entityID},5,65]
			}
		}
	}
	
	function Waves(int timeoutMinutes)
	{

		
	}
	
	function WaitTargetQueueZero()
	{
		
	}
	
	function CheckContainers(int groupID = GROUPID_CARGO_CONTAINER,string lootItem,string containerName)
	{
	
	}
	function WarpPrepare()
	{
		call Ship.WarpPrepare
		UI:UpdateConsole["MissionComamnds.WarpPrepare : Prepared for warp captain"]
		This.StateStack:Pop
	}


	; ------------------ END OF USER FUNCTIONS


	; ------------------ HELPER FUNCTIONS
	member:int AggroCount()
	{
		return ${Me.GetTargetedBy}
	}

	member:int HostileCount()
	{
		return ${This.EntityCache.CachedEntities.Used}
	}
	
	member:bool GatePresent()
	{
		variable index:entity gateIndex

		EVE:DoGetEntities[gateIndex, TypeID, TYPE_ACCELERATION_GATE]

		UI:UpdateConsole["obj_Missions: DEBUG There are ${gateIndex.Used} gates nearby."]

		return ${gateIndex.Used} > 0
	}

	member:int LootEntity(int entID,string lootItem)
	{
		
	}	
	
	member:bool HaveLoot(int agentID)
	{
		
	}
	
	member:bool ReturnAllToDroneBay()
	{
		
	}

	member:bool WarpPrepare()
	{

	}
	
	member:bool WarpWait()
	{
		
	}
}

