objectdef obj_MissionCommands
{
	variable int WaitTimeOut = 500
	variable obj_EntityCache EntityCache
	variable bool CommandComplete = FALSE
	variable bool Abort = FALSE
	method Initialize()
	{
		EntityCache:UpdateSearchParams["I like big butts can i cannot lie","CategoryID, CATEGORYID_ENTITY","IsNPC"]
		EntityCache:SetUpdateFrequency[1]
	}

	function Approach(int EntityID, int64 Distance)
	{
		if ${Entity[${EntityID}](exists)}
		{
			variable float64 OriginalDistance = ${Entity[${EntityID}].Distance}
			variable float64 CurrentDistance

			If ${OriginalDistance} < ${Distance}
			{
				EVE:Execute[CmdStopShip]
				return
			}
			OriginalDistance:Inc[10]

			CurrentDistance:Set[${Entity[${EntityID}].Distance}]
			UI:UpdateConsole["Approaching: ${Entity[${EntityID}].Name} - ${Math.Calc[(${CurrentDistance} - ${Distance}) / ${MyShip.MaxVelocity}].Ceil} Seconds away"]

			Ship:Activate_AfterBurner[]
			do
			{
				Entity[${EntityID}]:Approach
				wait 50
				CurrentDistance:Set[${Entity[${EntityID}].Distance}]

				if ${Entity[${EntityID}](exists)} && \
				${OriginalDistance} < ${CurrentDistance}

				{
					UI:UpdateConsole["DEBUG: obj_Ship:Approach: ${Entity[${EntityID}].Name} is getting further away!  Is it moving? Are we stuck, or colliding?", LOG_MINOR]
					return
				}
			}
			while ${CurrentDistance} > ${Math.Calc64[${Distance} * 1.05]} && \
			${This.AggroCount} > 0

			EVE:Execute[CmdStopShip]
			Ship:Deactivate_AfterBurner[]
		}
	}

	function ActivateGate(int EntityID)
	{
		variable int waitCounter = 0
		This.Approach[${EntityID}, JUMP_RANGE]
		Ship:WarpPrepare
		UI:UpdateConsole["DEBUG: obj_MissionCommands - attempting to activate ${Entity[${EntityID}].Name!",LOG_DEBUG]
		Entity[${EntityID}]:Activate
		while !${Ship.WarpEntered}
		{
			waitCounter:Inc[1]
			if ${waitCounter} > ${WaitTimeOut}
			{
				UI:UpdateConsole["DEBUG: obj_MissionCommands - timed out trying to enter warp",LOG_DEBUG]
				Abort:Set[TRUE]
				return
			}
			wait 20
			UI:UpdateConsole["DEBUG: obj_MissionCommands - waiting to enter warp",LOG_DEBUG]
		}
		call Ship.WarpWait
	}

	function WaitAggro(int aggroCount = 1)
	{
		if ${This.AggroCount} >= ${aggroCount}
		{
			CommandComplete:Set[TRUE]
		}
		CommandComplete:Set[FALSE]
	}

	function KillAggressors()
	{
		This:NextTarget[]
		if ${This.AggroCount} < 1
		{
			return TRUE
		}
		return FALSE
	}


	function ClearRoom()
	{

				if ${This.AggroCount} > 0
				{
				;Use "entity" more, please --stealthy
				;Seems like it doesn't check range until something is a
				EntityCache.Entities:GetIterator[EntityCache.EntityIterator]
				if ${EntityCache.EntityIterator:First(exists)}
				{
					do
					{
						if ${EntityCache.EntityIterator.Value.IsTargetingMe}
						{
							if ${EntityCache.EntityIterator.Value.Distance} < ${Ship.OptimalWeaponRange} || \
								${EntityCache.EntityIterator.Value.Distance} < ${Me.DroneControlDistance}
							{
								EntityInRange:Set[TRUE]
								break
							}
						}
					}
					while ${EntityCache.EntityIterator:Next(exists)}
				}
				;Why are we worried about aggro count in clearroom?
				 && ${EntityInRange}
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
			else if ${This.HostileCount} > 0
			{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Clearroom trying to pull stuff",LOG_DEBUG]
						if ${This.Pull[]}
						{
							This.ClearRoomState:Set["KILLING"]
						}				
			}
	}
	;these solutions for pulling and killing specific NPCs based on their names are not ideal, if you can come up with some better logic please tell

	

	function KillID(int entityID)
	{

				if ${Entity[${entityID}].GroupID(exists)}
				{
		
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - Approaching entity with Name ${Entity[${entityID}].Name} ID ${entityID} , we are ${Entity[${entityID}].Distance} away, we want to be ${dist} away will approach",LOG_DEBUG]

						didApproach:Set[${This.Approach[${KillIDCache},${dist}]}]
						if ${didApproach}
						{
							UI:UpdateConsole["DEBUG: obj_MissionCommands - Kill - In weapons range, will target and fire",LOG_DEBUG]
							KillIDState:Set["TARGETING"]
							return FALSE
						}
		
					if ${Entity[${KillIDCache}].GroupID(exists)}  && ${Entity[${KillIDCache}].GroupID} != GROUPID_WRECK && ${Entity[${KillIDCache}].GroupID} != GROUPID_CARGO_CONTAINER
					{
					
							if !${Targeting.IsMandatoryQueued[${KillIDCache}]}
							{
								UI:UpdateConsole["DEBUG: obj_MissionCommands - Targeting ${KillIDCache}"]
								Targeting:Queue[${KillIDCache},1,1,FALSE]
								KillIDState:Set["KILLING"]
								return FALSE
					
		}
		}
		}
	}


	function Pull(string targetName = "NONE")
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
								UI:UpdateConsole["DEBUG: obj_MissionCommands - targeting closest npc"]
								return FALSE
							}
						}
						while ${targetIterator:Next(exists)}
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find NPC target to shoot!",LOG_DEBUG]
						return TRUE
					}
					UI:UpdateConsole["DEBUG: obj_MissionCommands - Could not find find any entities",LOG_DEBUG]
					return FALSE

		
				if ${Entity[${PullCache}].GroupID(exists)}
				{
					if ${Entity[${PullCache}].Name.Equal[${targetName}]} || ${targetName.Equal["NONE"]}
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands.Pull.Pull - attempting to kill ${targetName}"]
						This:PullTarget[${PullCache}]
						if ${Entity[${PullCache}].Distance} <= ${dist} && ${This.AggroCount} > 0
						{
							Targeting:UnlockRandomTarget[]
							UI:UpdateConsole["DEBUG: obj_MissionCommands - we pulled something, success!"]
							PullState:Set["START"]
							return TRUE
						}
						;echo "Pull.Pull: Returning FALSE; entity not yet in range or no aggros."
						return FALSE
}
				
	}
}


	function Waves(int timeoutMinutes)
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
		else
		{
			WaitTimeOut:Set[0]
			if ${This.ClearRoom}
			{
				UI:UpdateConsole["DEBUG: obj_MissionCommands -  Waiting untill ${This.WaitTimeOut.Time24}",LOG_DEBUG]
				return FALSE
			}
		}
		UI:UpdateConsole["DEBUG: obj_MissionCommands -  Waiting untill ${This.WaitTimeOut.Time24}",LOG_DEBUG]
		return FALSE
	}

	function WaitTargetQueueZero()
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




	function CheckContainers(int groupID = GROUPID_CARGO_CONTAINER,string lootItem,string containerName)
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
		return ${This.EntityCache.CachedEntities.Used}
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
					break
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
			variable iterator droneIterator
			Ship.Drones.ActiveDrones:GetIterator[droneIterator]
			if ${droneIterator:First(exists)}
			{
				do
				{
					if ${droneIterator.Value.State} != DRONESTATE_RETURNING
					{
						UI:UpdateConsole["DEBUG: obj_MissionCommands - Attempting to recall drones!",LOG_DEBUG]

						EVE:Execute[CmdDronesReturnToBay]
						return FALSE
					}
				}
				while ${droneIterator:Next(exists)}

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
				UI:UpdateConsole["DEBUG: obj_MissionCommands - We dont have any drones!",LOG_DEBUG]
				return TRUE
			}
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

		;There is 0 reason to disable targeting. Don't.
		;Targeting:Disable[]
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
			UI:UpdateConsole["DEBUG: obj_MissionCommands - Warpwait : Ship.InWarp is ${Ship.InWarp}!",LOG_DEBUG]
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
			variable float dist
			if ${Ship.OptimalWeaponRange} > ${Me.DroneControlDistance}
			{
				dist:Set[${Ship.OptimalWeaponRange}]
			}
			else
			{
				dist:Set[${Me.DroneControlDistance}]
			}
			dist:Set[${Math.Calc[${dist} * 0.90]}]
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
									UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - Targeting ${targetIterator.Value.Name} ID ${targetIterator.Value.ID}"]
									Targeting:Queue[${targetIterator.Value.ID},1,1,FALSE]
							}
						}
					}
					while ${targetIterator:Next(exists)}
				}
				else
				{
					if !${Targeting.IsQueued[${highestID}]}
					{
							UI:UpdateConsole["DEBUG: obj_MissionCommands - NextTarget - Targeting highest priority ${targetIterator.Value.Name}"]
							
							Targeting:Queue[${highestID},1,1,FALSE]
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

