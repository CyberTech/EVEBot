objectdef obj_MissionCommands
{
	method Initialize()
	{
		EntityCache:UpdateSearchParams["I like big butts can i cannot lie","CategoryID, CATEGORYID_ENTITY","IsNPC"]
		EntityCache:SetUpdateFrequency[2]
	}
	;TODO - Add checks to all members that involve movement to make sure we are actually moving!
	method MissionComplete()
	{
		;we reset all our states to their defaults and clear out all caches
		TargetPriorities:Clear
		ApproachState:Set["IDLE"]
		ApproachIDCache:Set[0]
		GateState:Set["IDLE"]
		ClearRoomState:Set["KILLING"]
		KillCache:Set[0]
		KillState:Set["START"]
		KillIDCache:Set[0]
		KillIDState:Set["START"]
		PullCache:Set[0]
		PullState:Set["START"]
		WaitTimeOut:Set[0]
		containerCache:Clear
		wreckList:Clear
		containerID:Set[0]
		ContainerState:Set["START"]
		lootEntityID:Set[0]
		LootEntityState:Set["APPROACHING"]
		ContainerCargo:Clear
		Recheck:Set[0]

	}
	variable obj_EntityCache EntityCache
	variable collection:int TargetPriorities
	variable string ApproachState = "IDLE"
	variable int ApproachIDCache
	variable string GateState = "IDLE"
	variable string ClearRoomState = "KILLING"
	variable int KillCache
	variable string KillState = "START"
	variable int KillIDCache
	variable string KillIDState = "START"
	variable int PullCache
	variable string PullState = "START"
	variable time WaitTimeOut = 0
	variable index:entity containerCache
	variable index:entity wreckList
	variable iterator wreckIterator
	variable iterator containerIterator
	variable int containerID
	variable string ContainerState = "START"
	variable int lootEntityID
	variable string LootEntityState = "APPROACHING"
	variable index:item ContainerCargo
	variable iterator Cargo
	variable int Recheck = 0
	member:bool Approach(int EntityID, int64 Distance = DOCKING_RANGE)
	{
		switch ${ApproachState}
		{
			case IDLE
			{
				if ${Entity[${EntityID}](exists)}
				{	
					UI:UpdateConsole["DEBUG: obj_MissionCommands - ENTITY EXISTS , GROUPID READS AS ${Entity[${EntityID}].GroupID} NAME IS ${Entity[${EntityID}].Name} NAME EXISTS IS  ${Entity[${EntityID}].GroupID(exists)}",LOG_DEBUG]
				}
				if ${Entity[${EntityID}].GroupID(exists)}
				{					
					if ${Entity[${EntityID}].Distance} > ${Math.Calc[${Distance} * 1.025]}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - found entity with Name ${Entity[${EntityID}].Name} ID ${EntityID} , will approach",LOG_DEBUG]
						ApproachIDCache:Set[${EntityID}]
						ApproachState:Set["APPROACH"]
						return FALSE
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Entity with name ${Entity[${EntityID}].Name} already in range",LOG_DEBUG]
						return TRUE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Error , could not find entity with ID ${EntityID} to approach",LOG_DEBUG]
					return TRUE
				}
			}
			case APPROACH
			{
				if ${Entity[${EntityID}].GroupID(exists)}
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
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Entity no longer exists cannot approach",LOG_DEBUG]
					ApproachState:Set["IDLE"]
					return TRUE
				}
			}
			case APPROACHING
			{
				if ${Entity[${EntityID}].GroupID(exists)}
				{
					if ${EntityID} == ${ApproachIDCache}
					{
						if ${Entity[${ApproachIDCache}].Distance} < ${Math.Calc[${Distance} * 1.025]}
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
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Entity no longer exists cannot approach",LOG_DEBUG]
					ApproachState:Set["IDLE"]
					return TRUE
				}
				
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


	member:bool ActivateGate(int EntityID)
	{
		UI:UpdateConsole["DEBUG: obj_MissionCommands - attempting to activate ${Entity[${EntityID}].Name!",LOG_DEBUG]
		switch ${GateState}
		{
			case IDLE
			{
				if ${Entity[${EntityID}].GroupID(exists)}
				{
					if ${This.Approach[${EntityID}, JUMP_RANGE]}
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
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find gate!",LOG_DEBUG]
					return TRUE
				}
			}
			case ACTIVATED_GATE
			{
				if ${Ship.WarpEntered}
				{
					GateState:Set["RELOAD"]
				}
				;TODO - put a timer here so we retry activating the gate
				return FALSE
			}
			case RELOAD
			{
				Ship:Reload_Weapons[TRUE]
				GateState:Set["WARPWAIT"]
				return FALSE
			}
			case WARPWAIT
			{
				if ${This.WarpWait}
				{
					GateState:Set["IDLE"]
					return TRUE
				}
				return FALSE
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
		This:NextTarget[]
		if ${This.AggroCount} < 1
		{
			return TRUE
		}
		return FALSE
	}


	member:bool ClearRoom()
	{
		switch ${ClearRoomState}
		{
			case KILLING
			{
				if ${This.AggroCount} > 0
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Killing stuff",LOG_DEBUG]
					This:NextTarget[]
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Switching to pulling stuff",LOG_DEBUG]
					ClearRoomState:Set["PULLING"]
				}
				return FALSE
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
				if ${Entity[${KillCache}].GroupID(exists)}
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


	member:bool KillID(int entityID)
	{

		switch ${KillIDState}
		{
			case START
			{
				if ${Entity[${entityID}].GroupID(exists)}
				{
					KillIDCache:Set[${entityID}]
					KillIDState:Set["APPROACHING"]
					return FALSE
				}
				else
				{
					KillIDState:Set["START"]
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - Entity does not exist ,it must be dead already!",LOG_DEBUG]
					return TRUE
				}

			}
			case APPROACHING
			{
				if ${KillIDCache} == ${entityID}
				{
					if ${Entity[${entityID}].GroupID(exists)}
					{
						if ${This.Approach[${entityID}, ${Math.Calc[${Ship.OptimalTargetingRange}*.8]}]}
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
						KillIDState:Set["START"]
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - Entity does not exist ,it must be dead already!",LOG_DEBUG]
						return TRUE
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - EntityID does not match cached one, returning to start state",LOG_DEBUG]
					KillIDState:Set["START"]
					return FALSE
				}
			}
			case TARGETING
			{
				if ${KillIDCache} == ${entityID}
				{
					if ${Entity[${KillIDCache}].GroupID(exists)}  && ${Entity[${KillIDCache}].GroupID} != GROUPID_WRECK && ${Entity[${KillIDCache}].GroupID} != GROUPID_CARGO_CONTAINER
						{
							if ${This.Approach[${KillIDCache}, ${Math.Calc[${Ship.OptimalTargetingRange}*.8]}]}
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
									UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - Target is in range and in the targeting queue,should be killing it now",LOG_DEBUG]
									KillIDState:Set["KILLING"]
									return FALSE
								}
							}
						}
						else
						{
							KillIDState:Set["START"]
							UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - Entity does not exist ,it must be dead already!",LOG_DEBUG]
							return TRUE
						}
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - EntityID does not match cached one, returning to start state",LOG_DEBUG]
						KillIDState:Set["START"]
						return FALSE
					}
				}
				case KILLING
				{
					if ${KillIDCache} == ${entityID}
					{
						if ${Entity[${KillIDCache}].GroupID(exists)}  && ${Entity[${KillIDCache}].GroupID} != GROUPID_WRECK && ${Entity[${KillIDCache}].GroupID} != GROUPID_CARGO_CONTAINER 
						{
							if ${This.Approach[${entityID}, ${Math.Calc[${Ship.OptimalTargetingRange}*.8]}]}
							{
								UI:UpdateConsole["DEBUG: obj_MissionCommands - Entity with ID ${KillIDCache} still exists, we have no killed it yet :<",LOG_DEBUG]
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
					}
				}
			}
		}


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
								if ${Targets.IsNPCTarget[${targetIterator.Value.GroupID}]}
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
					if ${Entity[${PullCache}].GroupID(exists)}
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






		member:bool Waves(int timeoutMinutes)
		{

			if ${This.WaitTimeOut.Timestamp} == 0 && ${This.HostileCount} < 1
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
							ContainerState:Set["START"]
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
								ContainerState:Set["START"]
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
							ContainerState:Set["START"]
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
								ContainerState:Set["START"]
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
				}
			}
		}



		; ------------------ END OF USER FUNCTIONS


		
		member:int AggroCount()
		{
			return ${Me.GetTargetedBy}
		}

		; TODO - move to Target.TargetSelect module
		; TODO move blacklist/ignorelist to same
		member:int HostileCount()
		{
			variable iterator     targetIterator
			variable iterator blackListIterator
			variable int hostileCount = 0
			variable bool blackListed = FALSE

			This.EntityCache.CachedEntities:GetIterator[targetIterator]

			if ${targetIterator:First(exists)}
			{
				do
				{
						hostileCount:Inc			
				}
				while ${targetIterator:Next(exists)}
			}
			return ${hostileCount}
		}



		member:bool GatePresent()
		{
			variable index:entity gateIndex

			EVE:DoGetEntities[gateIndex, TypeID, TYPE_ACCELERATION_GATE]

			UI:UpdateConsole["obj_Missions: DEBUG There are ${gateIndex.Used} gates nearby."]

			return ${gateIndex.Used} > 0
		}

	

		; TODO - move to obj_Cargo

		member:int LootEntity(int entID,string lootItem)
		{
			switch ${LootEntityState}
			{
				case APPROACHING
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - LootEntity moving closer to loot ${entID}",LOG_DEBUG]
					if ${This.Approach[${entID},LOOT_RANGE]}
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
									LootEntityState:Set["APPROACHING"]
									Cargo.Value:MoveTo[MyShip,${QuantityToMove}]
									Me.Ship:StackAllCargo
									return 3
								}
							}
						}
						while ${Cargo:Next(exists)}
					}
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Did not find any items to loot!, could be because we are going too fast",LOG_DEBUG]
					if ${Recheck} > 20
					{
						Recheck:Set[0]
						LootEntityState:Set["APPROACHING"]
						return 2
					}
					else
					{
						Recheck:Inc[1]
						return 1
					}
				}
				default
				{
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
		method NextTarget()
		{
			if !${Me.ActiveTarget(exists)}
			{
				variable int highestPriority = 0
				variable int highestID
				variable index:entity targetIndex
				variable iterator targetIterator
				Me:DoGetTargetedBy[targetIndex]
				targetIndex:GetIterator[targetIterator]
				;UI:UpdateConsole["GetTargeting = ${_Me.GetTargeting}, GetTargets = ${_Me.GetTargets}"]
				if ${targetIterator:First(exists)}
				{
					if ${TargetPriorities.Used} > 0
					{
						do
						{
							if ${TargetPriorities.Element[${targetIterator.Value.Name}](exists)}
							{
								if ${TargetPriorities.Element[${targetIterator.Value.Name}]} > ${highestPriority}
								{
									UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - Found new highest priority ${targetIterator.Value.Name}",LOG_DEBUG]
									highestPriority:Set[${TargetPriorities.Element[${targetIterator.Value.Name}]}]
									highestID:Set[${targetIterator.Value.ID}]
								}
							}
							elseif 5 > ${highestPriority}
							{
								highestPriority:Set[5]
								highestID:Set[${targetIterator.Value.ID}]
							}
						}
						while ${targetIterator:Next(exists)}
					}
					else
					{
						highestPriority:Set[5]
					}
					if ${highestPriority} == 5
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - All priority targets dead, will go hog wild killing non priority targets!",LOG_DEBUG]
						if ${targetIterator:First(exists)}
						do
						{
							if !${TargetPriorities.Element[${targetIterator.Value.Name}](exists)}
							{
								if !${Targeting.IsQueued[${targetIterator.Value.ID}]}
								{
									UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - Targeting ${targetIterator.Value.Name} ID ${targetIterator.Value.ID}",LOG_DEBUG]
									Targeting:Queue[${targetIterator.Value.ID},1,1,TRUE]
								}
							}
						}
						while ${targetIterator:Next(exists)}
					}
					else
					{
						if !${Targeting.IsQueued[${highestID}]}
						{
							UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - Targeting highest priority ${targetIterator.Value.Name}",LOG_DEBUG]
							Targeting:Queue[${highestID},1,1,TRUE]
						}
					}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - No hostiles!",LOG_DEBUG]
				}
			}
		}
	}

