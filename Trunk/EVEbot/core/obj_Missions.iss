/*
	Missions class

	Object to contain members related to missions.

	-- GliderPro

*/

objectdef obj_MissionCache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${Me.Name} Mission Cache.xml"
	variable string SET_NAME = "Missions"

	variable index:entity entityIndex
	variable iterator     entityIterator

	method Initialize()
	{
		LavishSettings[MissionCache]:Remove
		LavishSettings:AddSet[MissionCache]
		LavishSettings[MissionCache]:AddSet[${This.SET_NAME}]
		LavishSettings[MissionCache]:Import[${This.CONFIG_FILE}]
		Logger:Log["obj_MissionCache: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[MissionCache]:Export[${This.CONFIG_FILE}]
		LavishSettings[MissionCache]:Remove
	}

	member:settingsetref MissionsRef()
	{
		return ${LavishSettings[MissionCache].FindSet[${This.SET_NAME}]}
	}

	member:settingsetref MissionRef(int agentID)
	{
		return ${This.MissionsRef.FindSet[${agentID}]}
	}

	method AddMission(int agentID, string name)
	{
		This.MissionsRef:AddSet[${agentID}]
		This.MissionRef[${agentID}]:AddSetting[Name,"${name}"]
	}
	member:string Name(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[Name,FALSE]}
	}

	member:int FactionID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[FactionID,0]}
	}

	method SetFactionID(int agentID, int factionID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[FactionID,${factionID}]
	}

	member:int TypeID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[TypeID,0]}
	}

	method SetTypeID(int agentID, int typeID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[TypeID,${typeID}]
	}

	member:float Volume(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[Volume,0]}
	}

	method SetVolume(int agentID, float volume)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[Volume,${volume}]
	}

	member:bool LowSec(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[LowSec,FALSE]}
	}

	method SetLowSec(int agentID, bool isLowSec)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[LowSec,${isLowSec}]
	}
}

objectdef obj_MissionDatabase
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/Mission Database.xml"
	variable string SET_NAME = "Mission Database"

	method Initialize()
	{
		LavishSettings[${This.SET_NAME}]:Remove
		LavishSettings:Import[${CONFIG_FILE}]
		Logger:Log["obj_MissionDatabase: Initialized", LOG_MINOR]

		;Logger:Log["obj_MissionDatabase: Dumping database...",LOG_MINOR]
		;This:DumpSet[${LavishSettings[${This.SET_NAME}]},1]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
	}
	member:settingsetref MissionCommands(string missionName,int missionLevel)
	{
		return ${LavishSettings["${This.SET_NAME}"].FindSet["${missionName}"].FindSet["${missionLevel}"].FindSet["Commands"]}
	}
	method DumpSet(settingsetref Set, uint Indent=1)
	{
		Logger:Log["${Set.Name} - ${Set.GUID}",LOG_MINOR,Indent]

		variable iterator Iterator
		Set:GetSetIterator[Iterator]

		Indent:Inc
		if ${Iterator:First(exists)}
		{
			do
			{
				This:DumpSet[${Iterator.Value.GUID},${Indent}]
			}
			while ${Iterator:Next(exists)}
		}
		else
		{
			This:DumpSettings[${Set.GUID},${Indent}]
			return
		}
	}

	method DumpSettings(settingsetref Set, uint Indent=1)
	{
		variable iterator Iterator
		Set:GetSettingIterator[Iterator]

		if ${Iterator:First(exists)}
		{
			do
			{
				Logger:Log["${sIndent}${Iterator.Key} - ${Iterator.Value}",LOG_MINOR,Indent]
			}
			while ${Iterator:Next(exists)}
		}
	}
}

objectdef obj_Missions
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable obj_MissionCache MissionCache
	variable obj_MissionDatabase MissionDatabase
	variable obj_MissionCombat missionCombat

	method Initialize()
	{
		Logger:Log["obj_Missions: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

	function RunMission()
	{
		variable index:agentmission amIndex
		variable iterator amIterator

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		Logger:Log["obj_Missions: DEBUG: amIndex.Used = ${amIndex.Used}",LOG_DEBUG]
		if ${amIterator:First(exists)}
		{
			do
			{
				;Logger:Log["obj_Missions: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]
				;Logger:Log["obj_Missions: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]
				;Logger:Log["obj_Missions: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]
				if ${amIterator.Value.State} == 2
				{
					if ${amIterator.Value.Type.Find[Courier](exists)}
					{
						call This.RunCourierMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Trade](exists)}
					{
						call This.RunTradeMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Mining](exists)}
					{
						call This.RunMiningMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Encounter](exists)}
					{
						Logger:Log["obj_Missions: DEBUG: Run Combat Mission being called",LOG_DEBUG]
						call This.RunCombatMission ${amIterator.Value.AgentID}
					}
					else
					{
						Logger:Log["obj_Missions: ERROR!  Unknown mission type!"]
						Script:Pause
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}

	function RunCourierMission(int agentID)
	{
		variable int        QuantityRequired
		variable string     itemName
		variable float      itemVolume
		variable bool       haveCargo = FALSE
		variable bool       allDone = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		call Cargo.CloseHolds
		call Cargo.OpenHolds

	    Agents:SetActiveAgent[${Agent[id, ${agentID}].Name}]

		if ${This.MissionCache.Volume[${agentID}]} == 0
		{
			call Agents.MissionDetails
		}

		if ${This.MissionCache.Volume[${agentID}]} > ${Config.Missioneer.SmallHaulerLimit}
		{
			call Ship.ActivateShip "${Config.Missioneer.LargeHauler}"
		}
		else
		{
			call Ship.ActivateShip "${Config.Missioneer.SmallHauler}"
		}

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		itemVolume:Set[${EVEDB_Items.Volume[${This.MissionCache.TypeID[${agentID}]}]}]
		if ${itemVolume} > 0
		{
			Logger:Log["DEBUG: RunCourierMission: ${This.MissionCache.TypeID[${agentID}]}:${itemName} has volume ${itemVolume}."]
			QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}]
		}
		else
		{
			Logger:Log["DEBUG: RunCourierMission: ${This.MissionCache.TypeID[${agentID}]}: Item not found!  Assuming one unit to move."]
			QuantityRequired:Set[1]
		}

		do
		{
			Cargo:FindShipCargoByType[${This.MissionCache.TypeID[${agentID}]}]
			if ${Cargo.CargoToTransferCount} == 0
			{
				Logger:Log["obj_Missions: MoveToPickup"]
				call Agents.MoveToPickup
				Logger:Log["obj_Missions: TransferCargoToShip"]
				wait 50
				call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
				allDone:Set[${Cargo.LastTransferComplete}]
			}

			Logger:Log["obj_Missions: MoveToDropOff"]
			call Agents.MoveToDropOff
			wait 50

			call Cargo.CloseHolds
			call Cargo.OpenHolds

			Logger:Log["DEBUG: RunCourierMission: Checking ship's cargohold for ${QuantityRequired} units of ${itemName}.", LOG_DEBUG]
			MyShip:DoGetCargo[CargoIndex]
			CargoIndex:GetIterator[CargoIterator]
			if ${CargoIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${CargoIterator.Value.TypeID}]
					ItemQuantity:Set[${CargoIterator.Value.Quantity}]
					Logger:Log["DEBUG: RunCourierMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID}).", LOG_DEBUG]

					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						Logger:Log["DEBUG: RunCourierMission: Found required items in ship's cargohold.", LOG_DEBUG]
						haveCargo:Set[TRUE]
						break
					}
				}
				while ${CargoIterator:Next(exists)}
			}

			if ${haveCargo} == TRUE
			{
				break
			}

			call Cargo.TransferItemTypeToHangar ${This.MissionCache.TypeID[${agentID}]}
			wait 50

			if ${Station.Docked}
			{
				Logger:Log["DEBUG: RunCourierMission: Checking station hangar for ${QuantityRequired} units of ${itemName}.", LOG_DEBUG]
				Me:DoGetHangarItems[CargoIndex]
				CargoIndex:GetIterator[CargoIterator]

				if ${CargoIterator:First(exists)}
				{
					do
					{
						TypeID:Set[${CargoIterator.Value.TypeID}]
						ItemQuantity:Set[${CargoIterator.Value.Quantity}]
						Logger:Log["DEBUG: RunCourierMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID}).", LOG_DEBUG]

						if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
						   (${ItemQuantity} >= ${QuantityRequired})
						{
							Logger:Log["DEBUG: RunCourierMission: Found required items in station hangar.", LOG_DEBUG]
							allDone:Set[TRUE]
							break
						}
					}
					while ${CargoIterator:Next(exists)}
				}
			}
		}
		while !${allDone}

		Logger:Log["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

	function RunTradeMission(int agentID)
	{
		variable int        QuantityRequired
		variable float      itemVolume
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		Agents:SetActiveAgent[${Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		itemVolume:Set[${EVEDB_Items.Volume[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}]

		Logger:Log["RunTradeMission: Looking for ${QuantityRequired} units of ${itemName}"]
		call Cargo.CloseHolds
		call Cargo.OpenHolds

		;;; Check the cargohold of your ship
		MyShip:DoGetCargo[CargoIndex]
		CargoIndex:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				TypeID:Set[${CargoIterator.Value.TypeID}]
				ItemQuantity:Set[${CargoIterator.Value.Quantity}]
				Logger:Log["DEBUG: RunTradeMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				   (${ItemQuantity} >= ${QuantityRequired})
				{
					Logger:Log["DEBUG: RunTradeMission: Found required items in ship's cargohold."]
					haveCargo:Set[TRUE]
				}
			}
			while ${CargoIterator:Next(exists)}
		}

		if ${This.MissionCache.Volume[${agentID}]} > ${Config.Missioneer.SmallHaulerLimit}
		{
			call Ship.ActivateShip "${Config.Missioneer.LargeHauler}"
		}
		else
		{
			call Ship.ActivateShip "${Config.Missioneer.SmallHauler}"
		}

		;;; Check the hangar of the current station
		if ${haveCargo} == FALSE && ${Station.Docked}
		{
			Me:DoGetHangarItems[CargoIndex]
			CargoIndex:GetIterator[CargoIterator]

			if ${CargoIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${CargoIterator.Value.TypeID}]
					ItemQuantity:Set[${CargoIterator.Value.Quantity}]
					Logger:Log["DEBUG: RunTradeMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						Logger:Log["DEBUG: RunTradeMission: Found required items in station hangar."]
						if ${Agents.InAgentStation} == FALSE
						{
							call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
						}
						haveCargo:Set[TRUE]
					}
				}
				while ${CargoIterator:Next(exists)}
			}
		}

		;;;  Try to buy the item
		if ${haveCargo} == FALSE
		{
		  	if ${Station.Docked}
		  	{
			 	call Station.Undock
		  	}

			call Market.GetMarketOrders ${This.MissionCache.TypeID[${agentID}]}
			call Market.FindBestWeightedSellOrder ${Config.Missioneer.AvoidLowSec} ${quantity}
			call Ship.TravelToSystem ${Market.BestSellOrderSystem}
			call Station.DockAtStation ${Market.BestSellOrderStation}
			call Market.PurchaseItem ${This.MissionCache.TypeID[${agentID}]} ${quantity}

			call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}

			if ${Cargo.LastTransferComplete} == FALSE
			{
				Logger:Log["obj_Missions: ERROR: Couldn't carry all the trade goods!  Pasuing script!!"]
				Script:Pause
			}
		}

		;;;Logger:Log["obj_Missions: MoveTo Agent"]
		call Agents.MoveTo
		wait 50
		;;;call Cargo.TransferItemTypeToHangar ${This.MissionCache.TypeID[${agentID}]}
		;;;wait 50

		Logger:Log["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

	function RunMiningMission(int agentID)
	{
		Logger:Log["obj_Missions: ERROR!  Mining missions are not supported!"]
		Script:Pause
	}

	function RunCombatMission(int agentID)
	{
		missionCombat.MissionID:Set[${agentID}]
		call missionCombat.ProcessState
		;if ${missionCombat.CurrentState.Equals["Idle"]}
		;{
		;	missionCombat.MissionID:Set[${agentID}]
		;}
	;	call missionCombat.ProcessState
	}



;
;		Logger:Log["obj_Missions: DEBUG: Shiptype ${Ship.Type} (${Ship.TypeID}) Mission agent (${MissionCache.Name[${agentID}]}) (${Agents.AgentName})"]
;
;		variable string missLevel = ${Agent[id,${agentID}].Level}
;		variable string missionName = ${MissionCache.Name[${agentID}]}
;
;
;		;echo ${MissionDatabase.MissionCommands[${missionName},${missLevel}]}
;		if ${MissionDatabase.MissionCommands[${missionName},${missLevel}].Children(exists)}
;		{
;			Logger:Log["obj_Missions: DEBUG: Mission Name : __${missionName}__ , level ${missLevel}"]
;
;			call This.WarpToEncounter ${agentID}
;
;			call missionCombat.RunMission ${MissionDatabase.MissionCommands[${missionName},${missLevel}]}
;			wait 10
;			; missionCombat.RunMission will return true if it exhausts all commands without being interrupted
;			if ${Return}
;			{
;				;we go home and hand the mission in
;				call This.WarpToHomeBase ${agentID}
;				wait 50
;				Logger:Log["obj_Missions: TurnInMission"]
;				call Agents.TurnInMission
;			}
;		}
;		else
;		{
;			Logger:Log["obj_Missions: Paused Script. No commands available for mission, complete mission manually then run the script."]
;			Script:Pause
;		}
;	}

	function DefaultCombat(int agentID)
	{
		Logger:Log["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

	function PunisherCombat(int agentID)
	{
		Logger:Log["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

	function RifterCombat(int agentID)
	{
		call This.DrakeCombat ${agentID}
	}

	function RavenCombat(int agentID)
	{
		Logger:Log["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

	function HawkCombat(int agentID)
	{
		Logger:Log["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

	function DrakeCombat(int agentID)
	{
		variable bool missionComplete = FALSE
		variable time breakTime
		variable int  gateCounter = 0
		variable int  doneCounter = 0

			; wait up to 15 seconds for spawns to appear
			breakTime:Set[${Time.Timestamp}]
			breakTime.Second:Inc[15]
			breakTime:Update

		while TRUE
		{
			if ${This.HostileCount} > 0
			{
			   break
			}

			if ${Time.Timestamp} >= ${breakTime.Timestamp}
			{
			   break
			}

			This.Combat:SetState
			call This.Combat.ProcessState
			waitframe
		}

		call Cargo.OpenHolds

		while !${missionComplete}
		{
			Logger:Log["obj_Missions: DEBUG: TypeID = ${This.MissionCache.TypeID[${agentID}]}."]

			Logger:Log["obj_Missions: DEBUG: Targeting.QueueSize = ${Targeting.QueueSize}."]

			if ${This.HostileCount} > 0
			{
				gateCounter:Set[0]
				doneCounter:Set[0]

				; wait up to 15 seconds for agro
				breakTime:Set[${Time.Timestamp}]
				breakTime.Second:Inc[15]
				breakTime:Update

				Logger:Log["obj_Missions: ${This.HostileCount} hostiles present."]

				while TRUE
				{
				   if ${Me.GetTargetedBy} > 0
				   {
					  break
				   }

				   if ${Time.Timestamp} >= ${breakTime.Timestamp}
				   {
					  break
				   }

					This.Combat:SetState
					call This.Combat.ProcessState
				   waitframe
				}

				while ${This.HostileCount} > 0
				{
				   if ${Me.GetTargetedBy} > 0 || ${Targeting.QueueSize} > 0
				   {
					  call This.TargetAgressors
				   }
				   else
				   {
					  call This.PullTarget
				   }

					if ${Me.ActiveTarget.Distance} > ${Ship.OptimalWeaponRange}
					{
						call This.CombatApproach ${Me.ActiveTarget.ID} ${Ship.OptimalWeaponRange}
					}

				   This.Combat:SetState
				   call This.Combat.ProcessState

				   wait 50
				}
			}
			elseif ${This.SpecialStructurePresent[${agentID}]} == TRUE
			{
				variable int structureID

				structureID:Set[${This.SpecialStructureID[${agentID}]}]
				Logger:Log["obj_Missions: Special structure present."]
				if !${Targeting.IsQueued[${structureID}]}
				{
					Targeting:Queue[${structureID},1,1,FALSE]
				}
				call This.CombatApproach ${structureID} LOOT_RANGE
			}
			elseif ${This.MissionCache.TypeID[${agentID}]} > 0 && !${This.HaveLoot[${agentID}]}
			{
				/* loot containers */
				variable index:entity containerIndex
				variable iterator     containerIterator

				EVE:DoGetEntities[containerIndex, GroupID, GROUP_SPAWNCONTAINER]
				containerIndex:GetIterator[containerIterator]

				if ${containerIterator:First(exists)}
				{
					Logger:Log["obj_Missions: There are ${containerIndex.Used} cargo containers nearby."]
					do
					{
						call This.CombatApproach ${containerIterator.Value.ID} LOOT_RANGE
						call This.LootEntity ${containerIterator.Value.ID} ${This.MissionCache.TypeID[${agentID}]}
					}
					while ${containerIterator:Next(exists)}
				}

				EVE:DoGetEntities[containerIndex, GroupID, GROUP_CARGOCONTAINER]
				containerIndex:GetIterator[containerIterator]

				if ${containerIterator:First(exists)}
				{
					Logger:Log["obj_Missions: There are ${containerIndex.Used} spawn containers nearby."]
					do
					{
						call This.CombatApproach ${containerIterator.Value.ID} LOOT_RANGE
						call This.LootEntity ${containerIterator.Value.ID}
					}
					while ${containerIterator:Next(exists)}
				}

				/* loot wrecks */
				if ${This.SpecialWreckPresent[${agentID}]} == TRUE
				{
					variable int wreckID

					wreckID:Set[${This.SpecialWreckID[${agentID}]}]
					Logger:Log["obj_Missions: Special wreck present."]
					call This.CombatApproach ${wreckID} LOOT_RANGE
					call This.LootEntity ${wreckID}
				}
			}

			;;;  This will not work for missions that have bonus rooms which require a key
			if ${This.HostileCount} == 0 && ${This.GatePresent}
			{
				gateCounter:Inc

				Logger:Log["DEBUG: obj_Missions: gateCounter = ${gateCounter}.",LOG_MINOR]

				if ${gateCounter} > 45
				{
					/* activate gate and go to next room */
					call Ship.Approach ${Entity[TypeID = TYPE_ACCELERATION_GATE].ID} DOCKING_RANGE
					wait 10
					call Ship.WarpPrepare
					Logger:Log["Activating Acceleration Gate..."]
					while !${Ship.WarpEntered}
					{
						Entity[TypeID = TYPE_ACCELERATION_GATE]:Activate
						wait 50
					}
					call Ship.WarpWait
					if ${Return} == 2
					{
						return
					}
				}
			}
			elseif ${This.HostileCount} == 0
			{
				doneCounter:Inc

				Logger:Log["DEBUG: obj_Missions: doneCounter = ${doneCounter}.",LOG_MINOR]

				if ${doneCounter} > 45
				{
					missionComplete:Set[TRUE]
				}
			}
			wait 10
		}
	}

	function KestrelCombat(int agentID)
	{
		Logger:Log["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

   function TargetAgressors()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator

	  EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
	  targetIndex:GetIterator[targetIterator]

	  ;;Logger:Log["GetTargeting = ${Me.GetTargeting}, GetTargets = ${Me.GetTargets}"]
	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			if ${targetIterator.Value.IsTargetingMe} && !${Targeting.IsQueued[${targetIterator.Value.ID}]}
			{
				Targeting:Queue[${targetIterator.Value.ID},1,1,FALSE]
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }
   }

   function PullTarget()
   {
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
				Logger:Log["obj_Missions: DEBUG: Pulling ${targetIterator.Value} (${targetIterator.Value.ID})..."]

				if !${Targeting.IsQueued[${targetIterator.Value.ID}]}
				{
					Targeting:Queue[${targetIterator.Value.ID},1,1,FALSE]
				}

				if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
				{
					call This.CombatApproach ${targetIterator.Value.ID} ${Ship.OptimalTargetingRange}
				}
				return
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }
   }

	; Approach the target while in combat
	function CombatApproach(int64 EntityID, int64 Distance)
	{
		if ${Entity[${EntityID}](exists)}
		{
			variable float64 OriginalDistance = ${Entity[${EntityID}].Distance}
			variable float64 CurrentDistance

			If ${OriginalDistance} < ${Distance}
			{
				return
			}
			OriginalDistance:Inc[10]

			CurrentDistance:Set[${Entity[${EntityID}].Distance}]
			Logger:Log["Approaching: ${Entity[${EntityID}].Name} - ${Math.Calc[(${CurrentDistance} - ${Distance}) / ${MyShip.MaxVelocity}].Ceil} Seconds away"]

			Ship:Activate_AfterBurner[]
			do
			{
				Entity[${EntityID}]:Approach
				wait 50
				CurrentDistance:Set[${Entity[${EntityID}].Distance}]

				if ${Entity[${EntityID}](exists)} && \
					${OriginalDistance} < ${CurrentDistance}
				{
					Logger:Log["DEBUG: obj_Ship:Approach: ${Entity[${EntityID}].Name} is getting further away!  Is it moving? Are we stuck, or colliding?", LOG_MINOR]
				}

				This.Combat:SetState
				call This.Combat.ProcessState
			}
			while ${CurrentDistance} > ${Math.Calc64[${Distance} * 1.05]}
			EVE:Execute[CmdStopShip]
			Ship:Deactivate_AfterBurner[]
		}
	}

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

   member:int HostileCount()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator
	  variable int          targetCount = 0

	  EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
	  targetIndex:GetIterator[targetIterator]

	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
		 	if ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}
			{
				  targetCount:Inc
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }

	  return ${targetCount}
   }

   member:int ContainerCount()
   {
	  return 0
   }

   member:bool GatePresent()
   {
		variable index:entity gateIndex

		EVE:DoGetEntities[gateIndex, TypeID, TYPE_ACCELERATION_GATE]

		Logger:Log["obj_Missions: DEBUG There are ${gateIndex.Used} gates nearby."]

		return ${gateIndex.Used} > 0
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
							Logger:Log["obj_Missions: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["agenthomebase"]} || \
							   ${mbIterator.Value.LocationType.Equal["objective"]}
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

	member:bool IsSpecialStructure(int agentID,string structureName)
	{
		variable string missionName

		;;;Logger:Log["obj_Agents: DEBUG: IsSpecialStructure(${agentID},${structureName}) >>> ${This.MissionCache.Name[${agentID}]}"]

		missionName:Set[${This.MissionCache.Name[${agentID}]}]
		if ${missionName.NotEqual[NULL]}
		{
			Logger:Log["obj_Missions: DEBUG: missionName = ${missionName}"]
			if ${missionName.Equal["avenge a fallen comrade"]} && \
				${structureName.Equal["habitat"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["break their will"]} && \
				${structureName.Equal["repair outpost"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["the hidden stash"]} && \
				${structureName.Equal["warehouse"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["secret pickup"]} && \
				${structureName.Equal["recon outpost"]}
			{
				return TRUE
			}
			; elseif {...}
			; etc...
		}

		return FALSE
	}

	member:bool SpecialStructurePresent(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		Logger:Log["obj_Missions: DEBUG: SpecialStructurePresent found ${targetIndex.Used} structures"]

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

		;;;Logger:Log["obj_Missions: DEBUG: IsSpecialWreck(${agentID},${wreckName}) >>> ${This.MissionCache.Name[${agentID}]}"]

		missionName:Set[${This.MissionCache.Name[${agentID}]}]
		if ${missionName.NotEqual[NULL]}
		{
			Logger:Log["obj_Missions: DEBUG: missionName = ${missionName}"]
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

		Logger:Log["obj_Missions: DEBUG: SpecialWreckPresent found ${targetIndex.Used} wrecks",LOG_MINOR]

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

	function LootEntity(int64 entityID, int typeID)
	{
		variable index:item ContainerCargo
		variable iterator Cargo
		variable int QuantityToMove

		Logger:Log["DEBUG: obj_Missions.LootEntity ${entityID} ${typeID}"]

		Entity[${entityID}]:OpenCargo
		wait 50
		Entity[${entityID}]:DoGetCargo[ContainerCargo]
		ContainerCargo:GetIterator[Cargo]
		if ${Cargo:First(exists)}
		{
			do
			{
				Logger:Log["DEBUG: obj_Missions.LootEntity: Found ${Cargo.Value.Quantity} x ${Cargo.Value.Name} - ${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}m3"]

				if ${typeID} != ${Cargo.Value.TypeID}
				{
					Logger:Log["DEBUG: obj_Missions.LootEntity: Skipping ${Cargo.Value.Name}..."]
					continue
				}

				if ${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]} > ${Ship.CargoFreeSpace}
				{
					/* Move only what will fit, minus 1 to account for CCP rounding errors. */
					QuantityToMove:Set[${Ship.CargoFreeSpace} / ${Cargo.Value.Volume} - 1]
				}
				else
				{
					QuantityToMove:Set[${Cargo.Value.Quantity}]
				}

				Logger:Log["DEBUG: obj_Missions.LootEntity: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
				if ${QuantityToMove} > 0
				{
					Cargo.Value:MoveTo[MyShip,${QuantityToMove}]
					wait 30
				}

				if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
				{
					Logger:Log["DEBUG: obj_Missions.LootEntity: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"]
					break
				}
			}
			while ${Cargo:Next(exists)}
		}

		MyShip:StackAllCargo
		wait 10
	}

	member:bool HaveLoot(int agentID)
	{
		variable int        QuantityRequired
		variable float		itemVolume
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		;;Agents:SetActiveAgent[${Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		itemVolume:Set[${EVEDB_Items.Volume[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}]

		;;; Check the cargohold of your ship
		MyShip:DoGetCargo[CargoIndex]
		CargoIndex:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				TypeID:Set[${CargoIterator.Value.TypeID}]
				ItemQuantity:Set[${CargoIterator.Value.Quantity}]
				;;Logger:Log["DEBUG: HaveLoot: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				   (${ItemQuantity} >= ${QuantityRequired})
				{
					Logger:Log["DEBUG: HaveLoot: Found required items in ship's cargohold."]
					haveCargo:Set[TRUE]
				}
			}
			while ${CargoIterator:Next(exists)}
		}

		return ${haveCargo}
	}
}
