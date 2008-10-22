/*
	Missions class
	
	Object to contain members related to missions.
	
	-- GliderPro
	
*/

objectdef obj_MissionCache
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${_Me.Name} Mission Cache.xml"
	variable string SET_NAME = "Missions"

	variable index:entity entityIndex
	variable iterator     entityIterator
	
	method Initialize()
	{
		LavishSettings[MissionCache]:Clear
		LavishSettings:AddSet[MissionCache]
		LavishSettings[MissionCache]:AddSet[${This.SET_NAME}]
		LavishSettings[MissionCache]:Import[${This.CONFIG_FILE}]
		UI:UpdateConsole["obj_MissionCache: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[MissionCache]:Export[${This.CONFIG_FILE}]
		LavishSettings[MissionCache]:Clear
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

;objectdef obj_MissionDatabase
;{
;	variable string SVN_REVISION = "$Rev$"
;	variable int Version
;
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
;	UI:UpdateConsole["obj_MissionDatabase: Initialized", LOG_MINOR]
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
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	variable obj_MissionCache MissionCache
;   variable obj_MissionDatabase MissionDatabase
	variable obj_Combat Combat

	method Initialize()
	{
		UI:UpdateConsole["obj_Missions: Initialized", LOG_MINOR]
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
		
		UI:UpdateConsole["obj_Missions: DEBUG: amIndex.Used = ${amIndex.Used}"]	
		if ${amIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]	
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]	
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]	
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
						UI:UpdateConsole["obj_Missions: ERROR!  Unknown mission type!"]
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
		itemVolume:Set[${EVEDB_Items.Volume[${itemName}]}]
		if ${itemVolume} > 0
		{
			UI:UpdateConsole["DEBUG: RunCourierMission: ${This.MissionCache.TypeID[${agentID}]}:${itemName} has volume ${itemVolume}."]
			QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}]
		}
		else
		{
			UI:UpdateConsole["DEBUG: RunCourierMission: ${This.MissionCache.TypeID[${agentID}]}: Item not found!  Assuming one unit to move."]
			QuantityRequired:Set[1]
		}
		
		do
		{
			Cargo:FindShipCargoByType[${This.MissionCache.TypeID[${agentID}]}]
			if ${Cargo.CargoToTransferCount} == 0
			{
				UI:UpdateConsole["obj_Missions: MoveToPickup"]
				call Agents.MoveToPickup
				UI:UpdateConsole["obj_Missions: TransferCargoToShip"]
				wait 50
				call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
				allDone:Set[${Cargo.LastTransferComplete}]
			}

			UI:UpdateConsole["obj_Missions: MoveToDropOff"]
			call Agents.MoveToDropOff
			wait 50
			
			call Cargo.CloseHolds
			call Cargo.OpenHolds

			UI:UpdateConsole["DEBUG: RunCourierMission: Checking ship's cargohold for ${QuantityRequired} units of ${itemName}."]
			Me.Ship:DoGetCargo[CargoIndex]
			CargoIndex:GetIterator[CargoIterator]
			if ${CargoIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${CargoIterator.Value.TypeID}]
					ItemQuantity:Set[${CargoIterator.Value.Quantity}]
					UI:UpdateConsole["DEBUG: RunCourierMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]
					
					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						UI:UpdateConsole["DEBUG: RunCourierMission: Found required items in ship's cargohold."]
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
				UI:UpdateConsole["DEBUG: RunCourierMission: Checking station hangar for ${QuantityRequired} units of ${itemName}."]
				Me:DoGetHangarItems[CargoIndex]
				CargoIndex:GetIterator[CargoIterator]						
				
				if ${CargoIterator:First(exists)}
				{
					do
					{
						TypeID:Set[${CargoIterator.Value.TypeID}]
						ItemQuantity:Set[${CargoIterator.Value.Quantity}]
						UI:UpdateConsole["DEBUG: RunCourierMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]
						
						if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
						   (${ItemQuantity} >= ${QuantityRequired})
						{
							UI:UpdateConsole["DEBUG: RunCourierMission: Found required items in station hangar."]
							allDone:Set[TRUE]
							break
						}
					}
					while ${CargoIterator:Next(exists)}
				}			
			}
		}
		while !${allDone}
		
		UI:UpdateConsole["obj_Missions: TurnInMission"]
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
		
		Agents:SetActiveAgent[${Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${EVEDB_Items.Volume[${itemName}]}]}]

		call Cargo.CloseHolds
		call Cargo.OpenHolds
		
		;;; Check the cargohold of your ship
		Me.Ship:DoGetCargo[CargoIndex]
		CargoIndex:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				TypeID:Set[${CargoIterator.Value.TypeID}]
				ItemQuantity:Set[${CargoIterator.Value.Quantity}]
				UI:UpdateConsole["DEBUG: RunTradeMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]
				
				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				   (${ItemQuantity} >= ${QuantityRequired})
				{
					UI:UpdateConsole["DEBUG: RunTradeMission: Found required items in ship's cargohold."]
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
					UI:UpdateConsole["DEBUG: RunTradeMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]
					
					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						UI:UpdateConsole["DEBUG: RunTradeMission: Found required items in station hangar."]
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
				UI:UpdateConsole["obj_Missions: ERROR: Couldn't carry all the trade goods!  Pasuing script!!"]
				Script:Pause
			}
		}
				
		;;;UI:UpdateConsole["obj_Missions: MoveTo Agent"]
		call Agents.MoveTo
		wait 50
		;;;call Cargo.TransferItemTypeToHangar ${This.MissionCache.TypeID[${agentID}]}
		;;;wait 50
		
		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

	function RunMiningMission(int agentID)
	{
		UI:UpdateConsole["obj_Missions: ERROR!  Mining missions are not supported!"]
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
;            EVE:DoGetEntities[entityIndex,TypeID,TYPE_ACCELERATION_GATE]
;            call Ship.Approach ${entityIndex.Get[1].ID} JUMP_RANGE
;            entityIndex.Get[1]:Activate
;        }
;        while ${entityIndex.Used} == 1

		UI:UpdateConsole["obj_Missions: DEBUG: ${Ship.Type} (${Ship.TypeID})"]		
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
				UI:UpdateConsole["obj_Missions: WARNING!  Unknown Ship Type."]
				call This.DefaultCombat ${agentID}
				break
		}

		call This.WarpToHomeBase ${agentID}
		wait 50
		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}	
	
	function DefaultCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}
	
	function PunisherCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}
	
	function RavenCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
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

			waitframe
		 }

		 if ${This.HostileCount} > 0
		 {
			; wait up to 15 seconds for agro
			breakTime:Set[${Time.Timestamp}]
			breakTime.Second:Inc[15]
			breakTime:Update
   
			while TRUE
			{
			   if ${_Me.GetTargetedBy} > 0
			   {
				  break
			   }
   
			   if ${Time.Timestamp} >= ${breakTime.Timestamp}
			   {
				  break
			   }
   
			   waitframe
			}

			while ${This.HostileCount} > 0
			{
			   if ${_Me.GetTargetedBy} > 0 || ${Math.Calc[${_Me.GetTargeting}+${_Me.GetTargets}]} > 0
			   {
				  call This.TargetAgressors
			   }
			   else
			   {
				  call This.PullTarget
			   }

			   This.Combat:SetState
			   call This.Combat.ProcessState

			   waitframe
			}
		}
		elseif ${This.MissionCache.TypeID[${agentID}]} && ${This.ContainerCount} > 0
		{
			/* loot containers */
		}
		elseif ${This.GatePresent}
		{
			/* activate gate and go to next room */
			call Ship.Approach ${Entity[TypeID,TYPE_ACCELERATION_GATE].ID} DOCKING_RANGE
			wait 10
			UI:UpdateConsole["Activating Acceleration Gate..."]
			while !${This.WarpEntered}
			{
			   Entity[TypeID,TYPE_ACCELERATION_GATE]:Activate
			   wait 10
			}
			call This.WarpWait
			if ${Return} == 2
			{
			   return
			}
		}
		else
		{
			missionComplete:Set[TRUE]
		}

		waitframe
		}
	}

   function TargetAgressors()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator

	  EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
	  targetIndex:GetIterator[targetIterator]

	  UI:UpdateConsole["GetTargeting = ${_Me.GetTargeting}, GetTargets = ${_Me.GetTargets}"]
	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			if ${targetIterator.Value.IsTargetingMe} && \
			   !${targetIterator.Value.BeingTargeted} && \
			   !${targetIterator.Value.IsLockedTarget} && \
			   ${Ship.MaxLockedTargets} > ${Math.Calc[${_Me.GetTargeting}+${_Me.GetTargets}]}
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

	  EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
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

	  EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
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
	  return ${Entity[TypeID,TYPE_ACCELERATION_GATE](exists)}
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
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]	
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
	
	member:bool TargetStructures(int agentID)
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

	  UI:UpdateConsole["DEBUG: TargetStructures"]
	  
		if ${_Me.Ship.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
		}
		
		EVE:DoGetEntities[Targets, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
		   do
		   {
			if ${_Me.GetTargetedBy} > 0 && ${Target.Value.IsLockedTarget}
			{
				   Target.Value:UnlockTarget
			}
			   elseif ${This.SpecialStructure[${agentID},${Target.Value.Name}]} && \
				 !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			   {
				  variable int OrbitDistance
				  OrbitDistance:Set[${Math.Calc[${_Me.Ship.MaxTargetRange}*0.40/1000].Round}]
				  OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
				  Target.Value:Orbit[${OrbitDistance}]

				   if ${_Me.GetTargets} < ${Ship.MaxLockedTargets}
				   {
					   UI:UpdateConsole["Locking ${Target.Value.Name}"]
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

		if ${_Me.Ship.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
		}
		
		EVE:DoGetEntities[Targets, CategoryID, CATEGORYID_ENTITY]
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
				   if ${_Me.GetTargets} < ${Ship.MaxLockedTargets}
				   {
					   UI:UpdateConsole["Locking ${Target.Value.Name}"]
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
			OrbitDistance:Set[${Math.Calc[${_Me.Ship.MaxTargetRange}*0.40/1000].Round}]
			OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
			Me.ActiveTarget:Orbit[${OrbitDistance}]
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
