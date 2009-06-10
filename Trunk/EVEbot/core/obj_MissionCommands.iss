objectdef obj_MissionCommands
{
	member:bool WarpWait()
	{
		variable bool Warped = FALSE

		; We reload weapons here, because we know we're in warp, so they're deactivated.
		#if EVEBOT_DEBUG
		UI:UpdateConsole["DEBUG: obj_MissionCommands - Warpwait reloading weapons"]
		#endif
		Ship:Reload_Weapons[TRUE]
		if ${Ship.InWarp}
		{
			return FALSE
		}
		else
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - Warpwait : we dropped out of warp!"]
			#endif
			return TRUE
		}
	}

	member:bool Approach(int EntityID,int64 Distance)
	{
		if ${Entity[${EntityID}](exists)}
		{
			if ${${Entity[${EntityID}].Distance} < ${Distance}}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - within desired ranged of entity ${Entity[${EntityID}].Name}"]
				#endif
				EVE:Execute[CmdStopShip]
				return TRUE
			}
			else
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - approaching entity ${Entity[${EntityID}].Name}"]
				#endif
				Ship:Activate_AfterBurner[]
				Entity[${EntityID}]:Approach
				return FALSE
			}
		}
		return TRUE
	}
	member:bool ApproachBreakOnCombat(int EntityID,int64 Distance)
	{
		if ${Entity[${EntityID}](exists)}
		{
			if ${This.AggroCount} > 0
			{
				return TRUE
			}
			if ${${Entity[${EntityID}].Distance} < ${Distance}}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - within desired ranged of entity ${Entity[${EntityID}].Name}"]
				#endif
				EVE:Execute[CmdStopShip]
				return TRUE
			}
			else
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - approaching entity ${Entity[${EntityID}].Name}"]
				#endif
				Ship:Activate_AfterBurner[]
				Entity[${EntityID}]:Approach
				return FALSE
			}
		}
		return TRUE
	}
	member:bool WarpPrepare()
	{
		#if EVEBOT_DEBUG
		UI:UpdateConsole["DEBUG: obj_MissionCommands - preparing for warp"]
		#endif
		This:Deactivate_SensorBoost

		if ${Ship.Drones.WaitingForDrones}
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - we were deploying drones, delaying warp untill drones are finished deploying"]
			#endif
			return FALSE
		}

		Targeting:Disable[]
		This:UnlockAllTargets[]
		if ${This.ReturnAllToDroneBay[]}
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - drones returned we are ready for warp"]
			#endif
			return TRUE
		}
		else
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - drones still returning to bay ,not ready for warp yet"]
			#endif
			return FALSE
		}
	}
	member:bool ReturnAllToDroneBay()
	{
		EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
		if ${This.DronesInSpace} > 0
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
			#endif

			EVE:Execute[CmdDronesReturnToBay]
			if (${_MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
			${_MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct})
			{
				; We don't wait for drones if we're on emergency warp out
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - below safe minimums,sorry drones but im saving myself!"]
				#endif
				return TRUE
			}
			return FALSE
		}
		else
		{
			return TRUE
		}
	}
	member:bool TargetAggros()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable bool blacklisted = FALSE
		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		;UI:UpdateConsole["GetTargeting = ${_Me.GetTargeting}, GetTargets = ${_Me.GetTargets}"]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.IsTargetingMe} && !${Targeting.IsQueued[${targetIterator.Value.ID}]}
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
							#if EVEBOT_DEBUG
							UI:UpdateConsole["DEBUG: obj_MissionCommands - targeting ${targetIterator.Value.Name}"]
							#endif
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
		return TRUE
	}

	; TODO - move guts into movement thread
	member:bool UseGateStructure(string gateName)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLEOBJECT]
		targetIndex:GetIterator[targetIterator]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.Name.Equal[${gateName}]}
				{
					if ${This.Approach[${targetIterator.Value.ID}, DOCKING_RANGE]}
					{
						if ${This.WarpPrepare[]}
						{
							#if EVEBOT_DEBUG
							UI:UpdateConsole["DEBUG: obj_MissionCommands - activating gate ${gateName}"]
							#endif
							if !${Ship.WarpEntered}
							{
								targetIterator.Value:Activate
							}
							if ${This.WarpWait[]}
							{
								return TRUE
							}
							else
							{
								return FALSE
							}
						}
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
		else
		{
			return TRUE
		}
	}


	; TODO - move guts into Ship.Approach except for roonumer:inc
	member:bool NextRoom()
	{
		if ${This.Approach[${Entity[TypeID,TYPE_ACCELERATION_GATE].ID}, DOCKING_RANGE]}
		{
			if ${This.WarpPrepare[]}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - activating acceleration gate!"]
				#endif
				Entity[TypeID,TYPE_ACCELERATION_GATE]:Activate
				if !${Ship.WarpEntered}
				{
					return FALSE
				}
				else
				{
					if ${This.WarpWait[]}
					{
						return FALSE
					}
					else
					{
						return TRUE
					}
				}
			}
			else
			{
				return FALSE
			}
		}
		else
		{
			return FALSE
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

	; TODO - infinite loop. should be part of FSM
	member:bool WaitAggro(int aggroCount = 1)
	{
		if ${This.AggroCount} >= ${aggroCount}
		{
			return TRUE
		}
		return FALSE
	}

	; TODO - should be part of FSM
	member:bool KillAggressors()
	{
		This.TargetAggros
		if ${This.AggroCount} < 1
		{
			return TRUE
		}
		return FALSE
	}

	; TODO - should be part of FSM
	member:bool ClearRoom()
	{
		This.TargetAggros
		if ${This.HostileCount} < 1
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - Hostile count is zero! Room cleared"]
			#endif
			UI:UpdateConsole["obj_MissionCombat.ClearRoom: DEBUG: "]
			return TRUE
		}
		if ${This.AggroCount} < 1
		{
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - Room not clear pulling nearest npc "]
			#endif
			This:PullNearest
		}
		return FALSE
	}

	;we have to cache things here to make sure we dont end up killing every entity with the same name, we only want to kill the first one we find
	variable int killCache
	variable string entityNameCache
	member:bool Kill(string entityName)
	{
		if ${killCache} != 0
		{
			if ${This.Approach[${killCache}, ${Ship.OptimalTargetingRange}]}
			{
				if ${!Targeting.IsMandatoryQueued[${killCache}]}
				{
					#if EVEBOT_DEBUG
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Killing ${entityName}"]
					#endif
					Targeting:Queue[${killCache},1,1,TRUE]
				}
			}
			return FALSE
		}
		else
		{
			if ${entityNameCache.Equal[${entityName}]}
			{
				;we only get here if the entity dissapeared and we are being asked to kill an entity with the same name, this should indicate we killed the entity!
				entityNameCache:Set[""]
				killCache:Set[0]
				return TRUE
			}
			else
			{
				;For the moment this will find the closest entity with a matching name
				variable index:entity targetIndex
				variable iterator     targetIterator
				EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
				targetIndex:GetIterator[targetIterator]
				if ${targetIterator:First(exists)}
				{
					do
					{
						if ${targetIterator.Value.Name.Equal[${entityName}]}
						{
							killCache:Set[${targetIterator.ID}]
							return FALSE
						}
					}
					while ${targetIterator:Next(exists)}
				}
			}
		}
	}

	variable time WaitTimeOut
	member:bool Waves(int timeoutMinutes)
	{
		#if EVEBOT_DEBUG
		UI:UpdateConsole["DEBUG: obj_MissionCommands -  Waiting for waves , timeout ${timeoutMinutes} minutes"]
		#endif


		if ${This:ClearRoom} && ${${This.WaitTimeOut.Timestamp} == 0}
		{
			WaitTimeOut:Set[${Time.Timestamp}]
			WaitTimeOut.Minute:Inc[${timeoutMinutes}]
			WaitTimeOut:Update
		}
		if ${This.HostileCount} < 1
		{
			if ${time.Timestamp} >= ${WaitTimeOut.Timestamp} && ${This.WaitTimeOut.Timestamp == 0}
			{
				#if EVEBOT_DEBUG
				UI:UpdateConsole["DEBUG: obj_MissionCommands - No hostiles present after timer expired, Waves finished"]
				#endif
				WaitTimeOut:[0]
				return TRUE
			}
		}
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

	variable int pullCache
	; TODO: Move to Targeting.SelectTarget module
	member:bool PullNearest()
	{
		if ${pullCache != 0}
		{
			if ${This.AggroCount} > 0
			{
				;we got sum aggro!
				pullCache:Set[0]
				return TRUE
			}
			else
			{
				if ${This.Approach[${pullCache}, ${Ship.OptimalTargetingRange}]}
				{
					if ${!Targeting.IsMandatoryQueued[${pullCache}]}
					{
						Targeting:Queue[${pullCache},1,1,TRUE]
					}
				}
				return FALSE
			}
		}
		else
		{
			;we dont have a target! lets find one!
			variable index:entity targetIndex
			variable iterator     targetIterator

			EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
			targetIndex:GetIterator[targetIterator]
			/* FOR NOW just pull the closest target */
			if ${targetIterator:First(exists)}
			{
				do
				{
					if ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}
					{
						UI:UpdateConsole["obj_Missions: DEBUG: Pulling ${targetIterator.Value} (${targetIterator.Value.ID})..."]
						UI:UpdateConsole["obj_Missions: DEBUG: Group = ${targetIterator.Value.Group} GroupID = ${targetIterator.Value.GroupID} IsNPCTarget : ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}"]
						pullCache:Set[${targetIterator.Value.ID}]
						return FALSE
					}
				}
				while ${targetIterator:Next(exists)}
			}
			;if we get here we found no targets!
			#if EVEBOT_DEBUG
			UI:UpdateConsole["DEBUG: obj_MissionCommands - No hostiles present , cannot pull nearest"]
			#endif
			return TRUE
		}
	}


	variable index:entity containerCache
	variable iterator containerIterator
	member:bool CheckContainers(int groupID,string lootItem,string containerName = "none")
	{
		if ${containerIterator.Value(exists)}
		{
			;if we have not specified a container name, loot all the ones matching a the groupID
			if !${containerName.Equal["none"]}
			{
				;otherwise we check the name
				if ${containerIterator.Value.Name.Find[${containerName}]} > 0
				{
					if ${This.Approach[${containerIterator.Value.ID}, LOOT_RANGE]}
					{
						#if EVEBOT_DEBUG
						UI:UpdateConsole["DEBUG: obj_MissionCommands - approached a container, looting now"]
						#endif
						if ${This.LootEntity[${containerIterator.Value.ID},lootItem]}
						{
							containerCache:Clear[]
							return TRUE
						}
					}
				}
			}
			else
			{
				if ${This.Approach[${containerIterator.Value.ID}, LOOT_RANGE]}
				{
					#if EVEBOT_DEBUG
					UI:UpdateConsole["DEBUG: obj_MissionCommands - approached a container, looting now"]
					#endif
					if ${This.LootEntity[${containerIterator.Value.ID},lootItem]}
					{
						containerCache:Clear[]
						return TRUE
					}
					else
					{
						;loot item not found must carry on
						if ${containerIterator:Next(exists)}
						{
							return FALSE
						}
						else
						{
							;we did not find the item but we ran out of containers to search
							;TODO 3 states for the method, failure,success,continue
							return TRUE
						}
					}
				}
				else
				{
					return FALSE
				}
			}
		}
		else
		{
			EVE:DoGetEntities[containerCache, GroupID, ${groupID}]
			containerCache:GetIterator[containerIterator]
			return FALSE
		}
	}


	; ------------------ END OF USER FUNCTIONS


	; TODO - use of targetBlacklist appears to be more of a target ignore list; rename as appropriate
	member:int AggroCount()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable int hostileCount = 0

		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.IsTargetingMe}
				{
					targetBlacklist:GetIterator[blackListIterator]
					if ${blackListIterator:First(exists)}
					{
						do
						{
							if ${blackListIterator.Value.Equal[${targetIterator.Value.Name}]}
							{
								continue
							}
							hostileCount:Inc
						}
						while ${blackListIterator:Next(exists)}
					}
					else
					{
						hostileCount:Inc
						echo ${hostileCount}
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
		return ${hostileCount}
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
	member:bool LootEntity(int entityID,string lootItem)
	{
		variable index:item ContainerCargo
		variable iterator Cargo
		variable int QuantityToMove
		variable int lootedamount = 0
		UI:UpdateConsole["DEBUG: obj_Missions.LootEntity  ${typeID}"]

		Entity[${entityID}]:OpenCargo

		Entity[${entityID}]:DoGetCargo[ContainerCargo]
		ContainerCargo:GetIterator[Cargo]
		if ${Cargo:First(exists)}
		{
			do
			{
				UI:UpdateConsole["DEBUG: obj_Missions.LootEntity: Found ${Cargo.Value.Quantity} x ${Cargo.Value.Name} - ${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}m3"]

				if ${Cargo.Value.Name.Equal[${lootItem}]}
				{
					QuantityToMove:Set[${Cargo.Value.Quantity}]

					UI:UpdateConsole["DEBUG: obj_Missions.LootEntity: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
					if ${QuantityToMove} > 0
					{
						Cargo.Value:MoveTo[MyShip,${QuantityToMove}]
						Me.Ship:StackAllCargo
						return true
					}
				}
			}
			while ${Cargo:Next(exists)}
		}
		else
		{
			return FALSE
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
}
