objectdef obj_MissionCommands
{
	variable string ApproachState = "IDLE"
	variable int ApproachIDCache
	member:bool Approach(int EntityID, int64 Distance = DOCKING_RANGE)
	{
		switch ${ApproachState}
		{
			case IDLE
			{
				if ${Entity[${EntityID}](exists)}
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - found entity with ID ${EntityID} , will approach",LOG_DEBUG]
					ApproachIDCache:Set[${EntityID}]
					ApproachState:Set["APPROACH"]
					return FALSE
					break
				}
				UI:UpdateConsole["DEBUG: obj_MissionCommands - Error , could not find entity with ID ${EntityID} to approach",LOG_DEBUG]
				return TRUE
				break
			}
			case APPROACH
			{
				if ${EntityID} == ${ApproachIDCache}
				{
					Entity[${ApproachIDCache}]:Approach
					Ship:Activate_AfterBurner[]
					ApproachState:Set["APPROACHING"]
					return FALSE
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - AprroachIDCache and EntityID do not match ,resetting to idle",LOG_DEBUG]
					ApproachState:Set["IDLE"]
					return FALSE
				}
				break
			}
			case APPROACHING
			{
				if ${EntityID} == ${ApproachIDCache}
				{
					if ${Entity[${ApproachIDCache}].Distance} < ${Math.Calc[${Distance} * 1.05]}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Reached ${EntityID} ",LOG_DEBUG]
						EVE:Execute[CmdStopShip]
						ApproachState:Set["IDLE"]
						return TRUE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - AprroachIDCache and EntityID do not match ,resetting to idle",LOG_DEBUG]
					EVE:Execute[CmdStopShip]
					ApproachState:Set["IDLE"]
					return FALSE
				}
				break
			}
		}
	}


	member:bool ApproachBreakOnCombat(int EntityID,int Distance = DOCKING_RANGE)
	{
		if ${This.AggroCount} > 0
		{
			This.ApproachState:Set["IDLE"]
			return TRUE
		}
		if ${This.Approach[${EntityID},${Distance}]}
		{
			return TRUE
		}
	}



	; TODO - move guts into Ship.Approach except for roonumer:inc
	member:bool NextRoom()
	{
		return ${This.ActivateGate[${Entity[TypeID,TYPE_ACCELERATION_GATE].ID}]}
	}

	variable string GateState = "IDLE"
	member:bool ActivateGate(int EntityID)
	{
		UI:UpdateConsole["DEBUG: obj_MissionCommands - attempting to activate ${Entity[${EntityID}].Name!",LOG_DEBUG]
		switch ${GateState}
		{
			case IDLE
			{
				if ${This.Approach[${EntityID}, DOCKING_RANGE]}
				{
					if ${This.WarpPrepare}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - attempting to activate ${Entity[${EntityID}].Name!",LOG_DEBUG]
						Entity[${EntityID}]:Activate
						GateState:Set["ACTIVATED_GATE"]
						return FALSE
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - not ready for warping will wait untill ready",LOG_DEBUG]
						return FALSE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands -  Not Close enough to acceleration gate, will get closer",LOG_DEBUG]
				}
				return FALSE
				break
			}
			case ACTIVATED_GATE
			{
				if ${Ship.WarpEntered}
				{
					GateState:Set["RELOAD"]
				}
				;TODO - put a timer here so we retry activating the gate
				return FALSE
				break
			}
			case RELOAD
			{
				Ship:Reload_Weapons[TRUE]
				GateState:Set["WARPWAIT"]
				return FALSE
				break
			}
			case WARPWAIT
			{
				if ${This.WarpWait}
				{
					GateState:Set["IDLE"]
					return TRUE
				}
				return FALSE
				break
			}
		}
	}

	; TODO - should be method
	member:bool IgnoreEntity(string entityName)
	{
		targetBlacklist:Insert[${entityName}]
		return TRUE
	}

	; TODO - should be method
	member:bool PrioritzeEntity(string entityName)
	{
		priorityTargets:Insert[${entityName}]
		return TRUE

	}


	member:bool WaitAggro(int aggroCount = 1)
	{
		if ${This.AggroCount} >= ${aggroCount}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool KillAggressors()
	{
		This:TargetAggros[]
		if ${This.AggroCount} < 1
		{
			return TRUE
		}
		return FALSE
	}

	variable string ClearRoomState = "KILLING"
	member:bool ClearRoom()
	{
		switch ${ClearRoomState}
		{
			case KILLING
			{
				if ${This.AggroCount} > 0
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Killing stuff",LOG_DEBUG]
					This:TargetAggros[]
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Switching to pulling stuff",LOG_DEBUG]
					ClearRoomState:Set["PULLING"]
				}
				return FALSE
				break
			}
			case PULLING
			{
				if ${This.HostileCount} > 0
				{
					if ${This.AggroCount} > 0
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - ClearRoom got some aggro, switching to killing",LOG_DEBUG]
						This.ClearRoomState:Set["KILLING"]
						return FALSE
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Clearroom trying to pull stuff",LOG_DEBUG]
						if ${This.Pull[]}
						{
							This.ClearRoomState:Set["KILLING"]
						}
						return FALSE
					}
				}
				else
				{
					return TRUE
				}
			}
		}
	}
	;these solutions for pulling and killing specific NPCs based on their names are not ideal, if you can come up with some better logic please tell
	variable int KillCache
	variable string KillState = "START"
	member:bool Kill(string targetName,int CatID)
	{
		switch ${KillState}
		{
			case START
			{
				variable index:entity targetIndex
				variable iterator     targetIterator
				EVE:DoGetEntities[targetIndex, CategoryID, ${CatID}]
				targetIndex:GetIterator[targetIterator]
				if ${targetIterator:First(exists)}
				{
					do
					{
						if ${targetIterator.Value.Name.Equal[${targetName}]}
						{
							KillState:Set["KILLING"]
							KillCache:Set[${targetIterator.Value.ID}]
							UI:UpdateConsole["DEBUG: obj_MissionCommands - found kill target will try and kill it",LOG_DEBUG]
							return FALSE
						}
					}
					while ${targetIterator:Next(exists)}
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find ${entityName}",LOG_DEBUG]
					return TRUE
				}
				UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find find any entities",LOG_DEBUG]
			}
			case KILLING
			{
				if ${Entity[${KillCache}](exists)}
				{
					if ${Entity[${KillCache}].Name.Equal[${targetName}]}
					{
						if ${This.KillID[${KillCache}]}
						{
							KillState:Set["START"]
							return TRUE
						}
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Cached name does not match ${targetName}, resetting",LOG_DEBUG]
						KillState:Set["START"]
						return FALSE
					}
				}
				UI:UpdateConsole["DEBUG: obj_MissionCommands - entity in cache dissapeared, resetting ",LOG_DEBUG]
				KillState:Set["START"]
				return FALSE
			}
		}
	}

	variable int KillIDCache
	variable string KillIDState = "START"
	member:bool KillID(int entityID)
	{

		switch ${KillIDState}
		{
			case START
			{
				KillIDCache:Set[${entityID}]
				KillIDState:Set["APPROACHING"]
				return FALSE
				break
			}
			case APPROACHING
			{
				if ${KillIDCache} == ${entityID}
				{
					if ${This.Approach[${entityID}, ${Math.Calc[${Ship.OptimalTargetingRange}*.9]}]}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - In weapons range, will target and fire",LOG_DEBUG]
						KillIDState:Set["TARGETING"]
						return FALSE
					}
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - Out of range of  ${KillIDCache} moving closer",LOG_DEBUG]
					return FALSE
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - EntityID does not match cached one, returning to start state",LOG_DEBUG]
					KillIDState:Set["START"]
					return FALSE
					break
				}
			}
			case TARGETING
			{
				if ${KillIDCache} == ${entityID}
				{
					if ${This.Approach[${entityID}, ${Math.Calc[${Ship.OptimalTargetingRange}*.9]}]}
					{
						if !${Targeting.IsMandatoryQueued[${KillIDCache}]}
						{
							UI:UpdateConsole["DEBUG: obj_MissionCommands - Targeting ${KillIDCache}",LOG_DEBUG]
							Targeting:Queue[${KillIDCache},1,1,TRUE]
							KillIDState:Set["KILLING"]
							return FALSE
						}
						else
						{
							KillIDState:Set["KILLING"]
							return FALSE
						}
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - EntityID does not match cached one, returning to start state",LOG_DEBUG]
					KillIDState:Set["START"]
					return FALSE
					break
				}
			}
			case KILLING
			{
				if ${KillIDCache} == ${entityID}
				{
					if ${Entity[${KillIDCache}](exists)}
					{
						if ${This.Approach[${entityID}, ${Math.Calc[${Ship.OptimalTargetingRange}*.9]}]}
						{
							return FALSE
						}
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill-  ${KillIDCache} is destroyed",LOG_DEBUG]
						KillIDState:Set["IDLE"]
						return TRUE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - EntityID does not match cached one, returning to start state",LOG_DEBUG]
					KillIDState:Set["START"]
					return FALSE
					break
				}
			}
		}
	}

	variable int PullCache
	variable string PullState = "START"
	member:bool Pull(string targetName = "NONE")
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		switch ${PullState}
		{
			case START
			{
				if ${targetName.Equal["NONE"]}
				{
					EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
					targetIndex:GetIterator[targetIterator]
					if ${targetIterator:First(exists)}
					{
						do
						{
							if ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}
							{
								PullState:Set["PULL"]
								PullCache:Set[${targetIterator.Value.ID}]
								UI:UpdateConsole["DEBUG: obj_MissionCommands - targeting closest npc",LOG_DEBUG]
								return FALSE
							}
						}
						while ${targetIterator:Next(exists)}
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find NPC target to shoot!",LOG_DEBUG]
						return TRUE
					}
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find find any entities",LOG_DEBUG]
					return FALSE

				}
				else
				{
					EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
					targetIndex:GetIterator[targetIterator]
					if ${targetIterator:First(exists)}
					{
						do
						{
							if ${targetIterator.Value.Name.Equal[${targetName}]}
							{
								PullState:Set["PULL"]
								PullCache:Set[${targetIterator.Value.ID}]
								UI:UpdateConsole["DEBUG: obj_MissionCommands - found ${targetName} will pull it",LOG_DEBUG]
								return FALSE
							}
						}
						while ${targetIterator:Next(exists)}
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find ${targetName}",LOG_DEBUG]
						return TRUE
					}
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find find any entities",LOG_DEBUG]
					return FALSE
				}
			}
			case PULL
			{
				if ${Entity[${PullCache}](exists)}
				{
					if ${Entity[${PullCache}].Name.Equal[${targetName}]} || ${targetName.Equal["NONE"]}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - attempting to kill ${targetName}",LOG_DEBUG]
						This:PullTarget[${PullCache}]
						if ${This.AggroCount} > 0
						{
							UI:UpdateConsole["DEBUG: obj_MissionCommands - we pulled something, success!",LOG_DEBUG]
							PullState:Set["START"]
							return TRUE
						}
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - name does not match cached name, resetting",LOG_DEBUG]
						PullState:Set["START"]
						return FALSE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - cached entity no longer exists, resetting",LOG_DEBUG]
					PullState:Set["START"]
					return FALSE
				}
			}
		}
	}





	variable time WaitTimeOut = 0
	member:bool Waves(int timeoutMinutes)
	{

		if ${This.WaitTimeOut.Timestamp} == 0
		{
			UI:UpdateConsole["DEBUG: obj_MissionCommands -  Waiting for waves , timeout ${timeoutMinutes} minutes",LOG_DEBUG]
			WaitTimeOut:Set[${Time.Timestamp}]
			WaitTimeOut.Minute:Inc[${timeoutMinutes}]
			WaitTimeOut:Update
			return FALSE
		}
		if ${This.HostileCount} < 1
		{
			if ${Time.Timestamp} >= ${This.WaitTimeOut.Timestamp}
			{
				UI:UpdateConsole["DEBUG: obj_MissionCommands - No hostiles present after timer expired, Waves finished",LOG_DEBUG]

				WaitTimeOut:Set[0]
				return TRUE
			}
		}
		if ${This.ClearRoom}
		{
			UI:UpdateConsole["DEBUG: obj_MissionCommands -  Waiting untill ${This.WaitTimeOut.Time24}",LOG_DEBUG]
			return FALSE
		}
		UI:UpdateConsole["DEBUG: obj_MissionCommands -  Waiting untill ${This.WaitTimeOut.Time24}",LOG_DEBUG]
		return FALSE
	}

	member:bool WaitTargetQueueZero()
	{
		if ${Math.Calc[${Targeting.QueueSize} + ${Targeting.TargetCount}]} > 0
		{
			return FALSE
		}
		else
		{
			return TRUE
		}
	}



	variable index:entity containerCache
	variable index:entity wreckList
	variable iterator wreckIterator
	variable iterator containerIterator
	variable int containerID
	variable string ContainerState = "START"
	member:bool CheckContainers(int groupID = GROUPID_CARGO_CONTAINER,string lootItem,string containerName)
	{
		variable int result
		switch ${ContainerState}
		{

			case START
			{
				EVE:DoGetEntities[containerCache, GroupID, ${groupID}]
				containerCache:GetIterator[containerIterator]
				UI:UpdateConsole["DEBUG: obj_MissionCommands - Looking for containers to loot",LOG_DEBUG]
				if ${containerName.Equal["NONE"]}
				{
					if ${containerIterator:First(exists)}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Searching all nearby cargo cans",LOG_DEBUG]
						ContainerState:Set["CHECKINGCANS"]
						return FALSE
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Error , Could not find any nearby cargo cans",LOG_DEBUG]
						return TRUE
					}
				}
				else
				{
					if ${containerIterator:First(exists)}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - looking for containers with name ${containerName}",LOG_DEBUG]
						do
						{
							if ${containerIterator.Value.Name.Find[${containerName}]} > 0
							{
								wreckList:Insert[${containerIterator.Value}]
							}
						}
						while ${containerIterator:Next(exists)}
						wreckList:GetIterator[wreckIterator]
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Error , could not find any nearby wrecks",LOG_DEBUG]
						return TRUE
					}
					if ${wreckIterator:First(exists)}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Searching all nearby wrecks",LOG_DEBUG]
						ContainerState:Set["CHECKINGWRECKS"]
						return FALSE
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Error - Found no wrecks with name ${containerName}",LOG_DEBUG]
						return TRUE
					}
				}
			}
			case CHECKINGCANS
			{
				if ${containerIterator.Value(exists)}
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Attempting to loot from ${containerIterator.Value.Name} ID ${containerIterator.Value.ID}",LOG_DEBUG]
					result:Set[${This.LootEntity[${containerIterator.Value.ID},${lootItem}]}]
					if ${result} == 3
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Found the item",LOG_DEBUG]
						return TRUE
					}
					if ${result} == 2
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Item was not in this container",LOG_DEBUG]
						if ${containerIterator:Next(exists)}
						{
							return FALSE
						}
						else
						{
							;error loot not found
							return TRUE
						}
					}
					if ${result} == 1
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Moving to container",LOG_DEBUG]
						return FALSE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands Entity no longer exists , resetting",LOG_DEBUG]
					ContainerState:Set["START"]
					return FALSE
				}
				break
			}
			case CHECKINGWRECKS
			{
				if ${wreckIterator.Value(exists)}
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Attempting to loot from ${wreckIterator.Value.Name} ID ${wreckIterator.Value.ID}",LOG_DEBUG]
					result:Set[${This.LootEntity[${wreckIterator.Value.ID}, ${lootItem}]}]
					if ${result} == 3
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Found the item",LOG_DEBUG]
						return TRUE
					}
					if ${result} == 2
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Did not find the item",LOG_DEBUG]
						if ${wreckIterator:Next(exists)}
						{
							return FALSE
						}
						else
						{
							;error loot not found
							return TRUE
						}
					}
					if ${result} == 1
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Moving to the container",LOG_DEBUG]
						return FALSE
					}
				}
				else
				{
					ContainerState:Set["START"]
					return FALSE
				}
				break
			}
		}
	}



	; ------------------ END OF USER FUNCTIONS


	; TODO - use of targetBlacklist appears to be more of a target ignore list; rename as appropriate
	member:int AggroCount()
	{
		return ${Me.GetTargetedBy}
	}

	; TODO - move to obj_Target
	member:bool IsNPCTarget(int groupID)
	{
		switch ${groupID}
		{
			case GROUP_LARGECOLLIDABLEOBJECT
			case GROUP_LARGECOLLIDABLESHIP
			case GROUP_LARGECOLLIDABLESTRUCTURE
			case GROUP_SENTRYGUN
			case GROUP_CONCORDDRONE
			case GROUP_CUSTOMSOFFICIAL
			case GROUP_POLICEDRONE
			case GROUP_CONVOYDRONE
			case GROUP_FACTIONDRONE
			case GROUP_BILLBOARD
			return FALSE
			break
			default
			return TRUE
			break
		}

		return TRUE
	}

	; TODO - move to Target.TargetSelect module
	; TODO move blacklist/ignorelist to same
	member:int HostileCount()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable int hostileCount = 0
		variable bool blackListed = FALSE

		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}
				{
					targetBlacklist:GetIterator[blackListIterator]
					if ${blackListIterator(exists)}
					{
						do
						{
							if ${blackListIterator.Value.Equal[${targetIterator.Value.Name}]}
							{
								blackListed:Set[TRUE]
								break
							}
						}
						while ${blackListIterator:Next(exists)}
						if !${blackListed}
						{
							hostileCount:Inc
						}
						else
						{
							blackListed:Set[FALSE]
						}
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
		return ${hostileCount}
	}

	member:int ContainerCount()
	{
		return 0
	}

	member:bool GatePresent()
	{
		variable index:entity gateIndex

		EVE:DoGetEntities[gateIndex, TypeID, TYPE_ACCELERATION_GATE]

		UI:UpdateConsole["obj_Missions: DEBUG There are ${gateIndex.Used} gates nearby."]

		return ${gateIndex.Used} > 0
	}

	member:bool IsSpecialStructure(int agentID,string structureName)
	{
		variable string missionName

		;;;UI:UpdateConsole["obj_Agents: DEBUG: IsSpecialStructure(${agentID},${structureName}) >>> ${This.MissionCache.Name[${agentID}]}"]

		missionName:Set[${This.MissionCache.Name[${agentID}]}]
		if ${missionName.NotEqual[NULL]}
		{
			UI:UpdateConsole["obj_Missions: DEBUG: missionName = ${missionName}"]
			if ${missionName.Equal["avenge a fallen comrade"]} && ${structureName.Equal["habitat"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["break their will"]} && ${structureName.Equal["repair outpost"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["the hidden stash"]} && ${structureName.Equal["warehouse"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["secret pickup"]} && ${structureName.Equal["recon outpost"]}
			{
				return TRUE
			}
		}

		return FALSE
	}

	member:bool SpecialStructurePresent(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		UI:UpdateConsole["obj_Missions: DEBUG: SpecialStructurePresent found ${targetIndex.Used} structures"]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialStructure[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return TRUE
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return FALSE
	}

	member:int SpecialStructureID(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialStructure[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return ${targetIterator.Value.ID}
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return -1
	}

	member:bool IsSpecialWreck(int agentID,string wreckName)
	{
		variable string missionName

		;;;UI:UpdateConsole["obj_Missions: DEBUG: IsSpecialWreck(${agentID},${wreckName}) >>> ${This.MissionCache.Name[${agentID}]}"]

		missionName:Set[${This.MissionCache.Name[${agentID}]}]
		if ${missionName.NotEqual[NULL]}
		{
			UI:UpdateConsole["obj_Missions: DEBUG: missionName = ${missionName}"]
			if ${missionName.Equal["smuggler interception"]} && \
			${wreckName.Find["transport"]} > 0
			{
				return TRUE
			}
			; elseif {...}
			; etc...
		}

		return FALSE
	}

	member:bool SpecialWreckPresent(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		UI:UpdateConsole["obj_Missions: DEBUG: SpecialWreckPresent found ${targetIndex.Used} wrecks",LOG_MINOR]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialWreck[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return TRUE
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return FALSE
	}

	member:int SpecialWreckID(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialWreck[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return ${targetIterator.Value.ID}
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return -1
	}

	; TODO - move to obj_Cargo
	variable int lootEntityID
	variable string LootEntityState = "APPROACHING"
	variable index:item ContainerCargo
	variable iterator Cargo
	member:int LootEntity(int entID,string lootItem)
	{
		switch ${LootEntityState}
		{
			case APPROACHING
			{
				UI:UpdateConsole["DEBUG: obj_MissionCommands - LootEntity moving closer to loot ${entID}",LOG_DEBUG]
				if ${This.Approach[${entID},DOCKING_RANGE]}
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - In range attempting to open cargo",LOG_DEBUG]
					lootEntityID:Set[${entID}]
					LootEntityState:Set["OPENCARGO"]
					Entity[${entID}]:OpenCargo
					return 1
				}
				return 1
			}
			case OPENCARGO
			{
				if ${entID} == ${lootEntityID}
				{
					if ${Entity[${entID}].LootWindow(exists)}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Found the loot window checking for itamz",LOG_DEBUG]

						LootEntityState:Set["LOOTING"]
						return 1
					}
				}
				LootEntityState:Set["APPROACHING"]
				return 1
			}
			case LOOTING
			{
				variable int QuantityToMove
				Entity[${entID}]:DoGetCargo[ContainerCargo]
				ContainerCargo:GetIterator[Cargo]
				if ${Cargo:First(exists)}
				{
					do
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Found item : ${Cargo.Value.Name}",LOG_DEBUG]
						if ${Cargo.Value.Name.Equal[${lootItem}]}
						{
							QuantityToMove:Set[${Cargo.Value.Quantity}]
							UI:UpdateConsole["DEBUG: obj_Missions.LootEntity: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
							if ${QuantityToMove} > 0
							{
								Cargo.Value:MoveTo[MyShip,${QuantityToMove}]
								Me.Ship:StackAllCargo
								return 3
							}
						}
					}
					while ${Cargo:Next(exists)}
				}
				UI:UpdateConsole["DEBUG: obj_MissionCommands - Did not find any items to loot!",LOG_DEBUG]
				LootEntityState:Set["APPROACHING"]
				return 2
			}
		}
	}

	;TODO - move to obj_Cargo
	;TODO - member will fail if called without cargo open
	member:bool HaveLoot(int agentID)
	{
		variable int        QuantityRequired
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		;;Agents:SetActiveAgent[${Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${EVEDB_Items.Volume[${itemName}]}]}]

		;;; Check the cargohold of your ship
		MyShip:DoGetCargo[CargoIndex]
		CargoIndex:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				TypeID:Set[${CargoIterator.Value.TypeID}]
				ItemQuantity:Set[${CargoIterator.Value.Quantity}]
				;;UI:UpdateConsole["DEBUG: HaveLoot: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				(${ItemQuantity} >= ${QuantityRequired})
				{
					UI:UpdateConsole["DEBUG: HaveLoot: Found required items in ship's cargohold."]
					haveCargo:Set[TRUE]
				}
			}
			while ${CargoIterator:Next(exists)}
		}

		return ${haveCargo}
	}
	member:bool ReturnAllToDroneBay()
	{
		if ${Ship.Drones.DronesInSpace} > 0
		{
			UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones",LOG_DEBUG]
			EVE:Execute[CmdDronesReturnToBay]
			if (${_MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
			${_MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct})
			{
				; We don't wait for drones if we're on emergency warp out

				UI:UpdateConsole["DEBUG: obj_MissionCommands - below safe minimums,sorry drones but im saving myself!",LOG_DEBUG]

				return TRUE
			}
			return FALSE
		}
		else
		{
			return TRUE
		}
	}
	method TargetAggros()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable bool blacklisted = FALSE
		Me:DoGetTargetedBy[targetIndex]
		targetIndex:GetIterator[targetIterator]

		;UI:UpdateConsole["GetTargeting = ${_Me.GetTargeting}, GetTargets = ${_Me.GetTargets}"]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if !${Targeting.IsQueued[${targetIterator.Value.ID}]}
				{
					targetBlacklist:GetIterator[blackListIterator]
					; Check the target blacklist and ignore anything on it
					if ${blackListIterator:First(exists)}
					{
						do
						{
							if ${blackListIterator.Value.Equal[${targetIterator.Value.Name}]}
							{
								blacklisted:Set[TRUE]
								break
							}
						}
						while ${blackListIterator:Next(exists)}
					}
					if !${blacklisted}
					{
						if !${Targeting.IsQueued[${targetIterator.Value.ID}]}
						{
							; target is not blacklisted so lock it up

							UI:UpdateConsole["DEBUG: obj_MissionCommands - targeting ${targetIterator.Value.Name}",LOG_DEBUG]

							Targeting:Queue[${targetIterator.Value.ID},1,1,FALSE]
						}
					}
					else
					{
						blacklisted:Set[FALSE]
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}
	member:bool WarpPrepare()
	{

		UI:UpdateConsole["DEBUG: obj_MissionCommands - preparing for warp",LOG_DEBUG]

		This:Deactivate_SensorBoost

		if ${Ship.Drones.WaitingForDrones}
		{

			UI:UpdateConsole["DEBUG: obj_MissionCommands - we were deploying drones, delaying warp untill drones are finished deploying",LOG_DEBUG]

			return FALSE
		}

		Targeting:Disable[]
		This:UnlockAllTargets[]
		if ${This.ReturnAllToDroneBay[]}
		{

			UI:UpdateConsole["DEBUG: obj_MissionCommands - drones returned we are ready for warp",LOG_DEBUG]

			return TRUE
		}
		else
		{

			UI:UpdateConsole["DEBUG: obj_MissionCommands - drones still returning to bay ,not ready for warp yet",LOG_DEBUG]

			return FALSE
		}
	}
	member:bool WarpWait()
	{
		; We reload weapons here, because we know we're in warp, so they're deactivated.

		if ${Ship.InWarp}
		{
			return FALSE
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_MissionCommands - Warpwait : we dropped out of warp!",LOG_DEBUG]

			return TRUE
		}
	}
	method PullTarget(int entityID)
	{
		if ${This.KillID[${entityID}]}
		{
			return
		}
	}

}

