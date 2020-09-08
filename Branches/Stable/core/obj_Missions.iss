/*
	Missions class

	Object to contain members related to missions.

	-- GliderPro

*/

objectdef obj_MissionCache
{
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

	member:int FactionID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[FactionID,-1]}
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
		return ${This.MissionRef[${agentID}].FindSetting[TypeID,-1]}
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

;objectdef obj_MissionDatabase
;{
;	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/Mission Database.xml"
;	variable string SET_NAME = "Mission Database"
;
;	method Initialize()
;	{
;		if ${LavishSettings[${This.SET_NAME}](exists)}
;		{
;			LavishSettings[${This.SET_NAME}]:Clear
;		}
;		LavishSettings:Import[${CONFIG_FILE}]
;		LavishSettings[${This.SET_NAME}]:GetSettingIterator[This.agentIterator]
;     This:DumpDatabase
;	Logger:Log["obj_MissionDatabase: Initialized", LOG_MINOR]
;	}
;
;   method DumpDatabase()
;   {
;
;   }
;
;}

objectdef obj_Missions
{
	variable obj_MissionCache MissionCache
;   variable obj_MissionDatabase MissionDatabase
	variable obj_Combat Combat

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

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		Logger:Log["obj_Missions: DEBUG: amIndex.Used = ${amIndex.Used}", LOG_DEBUG]
		if ${amIterator:First(exists)}
		{
			do
			{
				Logger:Log["obj_Missions: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]
				Logger:Log["obj_Missions: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]
				Logger:Log["obj_Missions: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]
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


		Agents:SetActiveAgent[${EVE.Agent[id, ${agentID}].Name}]

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

		TypeID:Set[${This.MissionCache.TypeID[${agentID}]}]
		if ${TypeID} == -1
		{
			Logger:Log["ERROR: RunCourierMission: Unable to retrieve item type from mission cache for ${agentID}. Stopping."]
			Script:Pause
		}
		itemName:Set[${EVEDB_Items.Name[${TypeID}]}]
		itemVolume:Set[${EVEDB_Items.Volume[${TypeID}]}]
		if ${itemVolume} > 0
		{
			Logger:Log[DEBUG: RunCourierMission: ${TypeID}:${itemName} has volume ${itemVolume}.]
			QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}]
		}
		else
		{
			Logger:Log["DEBUG: RunCourierMission: ${This.MissionCache.TypeID[${agentID}]}: Item not found!  Assuming one unit to move."]
			QuantityRequired:Set[1]
		}

		do
		{
			call Inventory.ShipCargo.Activate
			if !${Inventory.ShipCargo.IsCurrent}
			{
				Logger:Log["RunCourierMission: Failed to activate ${Inventory.ShipCargo.EVEWindowParams}"]
				return
			}
			Inventory.Current:GetItems[CargoIndex, "TypeID == ${This.MissionCache.TypeID[${agentID}]}"]

			if ${CargoIndex.Used} == 0
			{
				Logger:Log["obj_Missions: MoveToPickup"]
				call Agents.MoveToPickup
				wait 50
				call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
				allDone:Set[${Cargo.LastTransferComplete}]
			}

			Logger:Log["obj_Missions: MoveToDropOff"]
			call Agents.MoveToDropOff
			wait 50

			Logger:Log["DEBUG: RunCourierMission: Checking ship's cargohold for ${QuantityRequired} units of ${itemName}."]
			MyShip:GetCargo[CargoIndex]
			CargoIndex:GetIterator[CargoIterator]
			if ${CargoIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${CargoIterator.Value.TypeID}]
					ItemQuantity:Set[${CargoIterator.Value.Quantity}]
					Logger:Log["DEBUG: RunCourierMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						Logger:Log["DEBUG: RunCourierMission: Found required items in ship's cargohold."]
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
				Logger:Log["DEBUG: RunCourierMission: Checking station hangar for ${QuantityRequired} units of ${itemName}."]
				Me:GetHangarItems[CargoIndex]
				CargoIndex:GetIterator[CargoIterator]

				if ${CargoIterator:First(exists)}
				{
					do
					{
						TypeID:Set[${CargoIterator.Value.TypeID}]
						ItemQuantity:Set[${CargoIterator.Value.Quantity}]
						Logger:Log["DEBUG: RunCourierMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

						if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
						   (${ItemQuantity} >= ${QuantityRequired})
						{
							Logger:Log["DEBUG: RunCourierMission: Found required items in station hangar."]
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
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		Agents:SetActiveAgent[${EVE.Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${EVEDB_Items.Volume[${This.MissionCache.TypeID[${agentID}]}]}]}]}]

		; Check the cargohold of your ship
		MyShip:GetCargo[CargoIndex]
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
			Me:GetHangarItems[CargoIndex]
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
		call Ship.ActivateShip "${Config.Missioneer.CombatShip}"
		wait 10
		call This.WarpToEncounter ${agentID}
		wait 50

;       do
;       {
;            EVE:QueryEntities[entityIndex, "TypeID = TYPE_ACCELERATION_GATE"]
;            call Ship.Approach ${entityIndex.Get[1].ID} JUMP_RANGE
;            entityIndex.Get[1]:Activate
;        }
;        while ${entityIndex.Used} == 1

		Logger:Log["obj_Missions: DEBUG: ${Ship.Type} (${Ship.TypeID})"]
		switch ${Ship.TypeID}
		{
			case TYPE_PUNISHER
				call This.PunisherCombat ${agentID}
				break
			case TYPE_HAWK
				call This.HawkCombat ${agentID}
				break
			case TYPE_KESTREL
				call This.KestrelCombat ${agentID}
				break
			case TYPE_RAVEN
				call This.RavenCombat ${agentID}
				break
			default
				Logger:Log["obj_Missions: WARNING!  Unknown Ship Type."]
				call This.DefaultCombat ${agentID}
				break
		}

		call This.WarpToHomeBase ${agentID}
		wait 50
		Logger:Log["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

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

	function RavenCombat(int agentID)
	{
		Logger:Log["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}
	function HawkCombat(int agentID)
	{
		wait 100
		while ${This.TargetNPCs} && ${Social.IsSafe}
		{
			This.Combat:SetState
			call This.Combat.ProcessState
			wait 10
		}
	}

	function KestrelCombat(int agentID)
	{
	  variable bool missionComplete = FALSE
	  variable time breakTime

	  while !${missionComplete}
	  {
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

			wait 1
		 }

		 if ${This.HostileCount} > 0
		 {
			; wait up to 15 seconds for agro
			breakTime:Set[${Time.Timestamp}]
			breakTime.Second:Inc[15]
			breakTime:Update

			while TRUE
			{
			   if ${Me.TargetedByCount} > 0
			   {
				  break
			   }

			   if ${Time.Timestamp} >= ${breakTime.Timestamp}
			   {
				  break
			   }

			   wait 1
			}

			while ${This.HostileCount} > 0
			{
			   if ${Me.TargetedByCount} > 0 || ${Ship.TotalTargeting} > 0
			   {
				  call This.TargetAgressors
			   }
			   else
			   {
				  call This.PullTarget
			   }

			   This.Combat:SetState
			   call This.Combat.ProcessState

			   wait 1
			}
		}
		elseif ${This.MissionCache.TypeID[${agentID}]} && ${This.ContainerCount} > 0
		{
			/* loot containers */
		}
		elseif ${This.GatePresent}
		{
			/* activate gate and go to next room */
			call Ship.Approach ${Entity["TypeID = TYPE_ACCELERATION_GATE"].ID} DOCKING_RANGE
			wait 10
			Logger:Log["Activating Acceleration Gate..."]
			while !${This.WarpEntered}
			{
			   Entity["TypeID = TYPE_ACCELERATION_GATE"]:Activate
			   wait 10
			}
			call Ship.WarpWait
			if ${Return} == 2
			{
			   return
			}
		}
		else
		{
			missionComplete:Set[TRUE]
		}

		wait 1
		}
	}

   function TargetAgressors()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator

	  EVE:QueryEntities[targetIndex, "CategoryID = CATEGORYID_ENTITY"]
	  targetIndex:GetIterator[targetIterator]

	  Logger:Log["TargetingCount = ${Me.TargetingCount}, TargetCount = ${Me.TargetCount}", LOG_DEBUG]
	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			if ${targetIterator.Value.IsTargetingMe} && \
			   !${targetIterator.Value.BeingTargeted} && \
			   !${targetIterator.Value.IsLockedTarget} && \
			   ${Ship.SafeMaxLockedTargets} > ${Ship.TotalTargeting}
			{
			   if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
			   {
				  Ship:Activate_AfterBurner
				  targetIterator.Value:Approach
				  wait 10
			   }
			   else
			   {
				  EVE:Execute[CmdStopShip]
				  Ship:Deactivate_AfterBurner
				  targetIterator.Value:LockTarget
				  wait 10
			   }
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }
   }

   function PullTarget()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator

	  EVE:QueryEntities[targetIndex, "CategoryID = CATEGORYID_ENTITY"]
	  targetIndex:GetIterator[targetIterator]

	  /* FOR NOW just pull the closest target */
	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			switch ${targetIterator.Value.GroupID}
			{
			   case GROUP_LARGECOLLIDABLEOBJECT
			   case GROUP_LARGECOLLIDABLESHIP
			   case GROUP_LARGECOLLIDABLESTRUCTURE
				  continue

			   default
				  if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
				  {
					 Ship:Activate_AfterBurner
					 targetIterator.Value:Approach
				  }
				  else
				  {
					 EVE:Execute[CmdStopShip]
					 Ship:Deactivate_AfterBurner
					 targetIterator.Value:LockTarget
					 wait 10
					 return
				  }
				  break
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }
   }

   member:int HostileCount()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator
	  variable int          targetCount = 0

	  EVE:QueryEntities[targetIndex, "CategoryID = CATEGORYID_ENTITY"]
	  targetIndex:GetIterator[targetIterator]

	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			switch ${targetIterator.Value.GroupID}
			{
			   case GROUP_LARGECOLLIDABLEOBJECT
			   case GROUP_LARGECOLLIDABLESHIP
			   case GROUP_LARGECOLLIDABLESTRUCTURE
				  continue

			   default
				  targetCount:Inc
				  break
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
	  return ${Entity["TypeID = TYPE_ACCELERATION_GATE"](exists)}
   }

	function WarpToEncounter(int agentID)
	{
		variable index:agentmission amIndex
		variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["dungeon"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value.ID}
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

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							Logger:Log["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["agenthomebase"]} || \
							   ${mbIterator.Value.LocationType.Equal["objective"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value.ID}
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

	member:bool TargetStructures(int agentID)
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

	  Logger:Log["DEBUG: TargetStructures"]

		if ${MyShip.MaxLockedTargets} == 0
		{
			Logger:Log["Jammed, cant target..."]
			return TRUE
		}

		EVE:QueryEntities[Targets, "GroupID = GROUP_LARGECOLLIDABLESTRUCTURE"]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
		   do
		   {
			if ${Me.TargetedByCount} > 0 && ${Target.Value.IsLockedTarget}
			{
				   Target.Value:UnlockTarget
			}
			   elseif ${This.SpecialStructure[${agentID},${Target.Value.Name}]} && \
				 !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			   {
				  ;variable int OrbitDistance
				  ;OrbitDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
				  ;OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
				  ;Target.Value:Orbit[${OrbitDistance}]
				  variable int KeepAtRangeDistance
				  KeepAtRangeDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
				  KeepAtRangeDistance:Set[${Math.Calc[${KeepAtRangeDistance}*1000]}]
				  Target.Value:KeepAtRange[${KeepAtRangeDistance}]

				   if ${Ship.TotalTargeting} < ${Ship.MaxLockedTargets}
				   {
					   Logger:Log["Locking ${Target.Value.Name}"]
					   Target.Value:LockTarget
				   }
			   }

			   ; Set the return value so we know we have targets
			   HasTargets:Set[TRUE]
		   }
		   while ${Target:Next(exists)}
	  }

		return ${HasTargets}
	}

	member:bool TargetNPCs()
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

		if ${MyShip.MaxLockedTargets} == 0
		{
			Logger:Log["Jammed, cant target..."]
			return TRUE
		}

		EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY"]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
			do
			{
				switch ${Target.Value.GroupID}
				{
					case GROUP_LARGECOLLIDABLEOBJECT
					case GROUP_LARGECOLLIDABLESHIP
					case GROUP_LARGECOLLIDABLESTRUCTURE
						continue

					default
						break
				}

				if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
				{
					if ${Ship.TotalTargeting} < ${Ship.MaxLockedTargets}
					{
						Logger:Log["CombatMission: Locking ${Target.Value.Name}"]
						Target.Value:LockTarget
					}
				}

				; Set the return value so we know we have targets
				HasTargets:Set[TRUE]
			}
			while ${Target:Next(exists)}
		}

		if ${HasTargets} && ${Me.ActiveTarget(exists)}
		{
			variable int OrbitDistance
			OrbitDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
			OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
			Me.ActiveTarget:Orbit[${OrbitDistance}]
		}

		if ${HasTargets} && ${Me.ActiveTarget(exists)}
		{
			variable int KeepAtRangeDistance
			KeepAtRangeDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
			KeepAtRangeDistance:Set[${Math.Calc[${KeepAtRangeDistance}*1000]}]
			Me.ActiveTarget:KeepAtRange[${KeepAtRangeDistance}]
		}

		return ${HasTargets}
	}

   member:bool SpecialStructure(int agentID, string name)
   {
	  if ${This.MissionCache.Name[${agentID}](exists)}
	  {
		 if ${This.MissionCache.Name.Equal["avenge a fallen comrade"]} && \
			${name.Equal["habitat"]}
		 {
			return TRUE
		 }
		 ; elseif {...}
		 ; etc...
	  }

	  return FALSE
   }
}
