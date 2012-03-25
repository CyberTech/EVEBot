	
objectdef obj_EVEDB_Spawns
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/EVEDB_Spawns.xml"
	variable string SET_NAME = "EVEDB_Spawns"

	method Initialize()
	{
		LavishSettings:Import[${CONFIG_FILE}]

		UI:UpdateConsole["obj_EVEDB_Spawns: Initialized", LOG_MINOR]
	}

	member:int SpawnBounty(string spawnName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${spawnName}].FindSetting[bounty, NOTSET]}
	}
}

objectdef obj_Targets
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string query2 = "CategoryID = 11 && GroupID != 226 && GroupID != 784 && GroupID != 319 && GroupID != 99 && GroupID != 301 && GroupID != 446 && GroupID != 182 && GroupID != 298 && GroupID != 297 && GroupID != 288 && GroupID != 323 && GroupID != 306 && GroupID != 494"

	variable int Counter = 0
	variable time TIMER
	variable index:int64 ToTarget
	variable uint WINNING
	method Initialize()
	{
		;WINNING:Set[${LavishScript.CreateQuery[]}]
		;UI:UpdateConsole["Query set to ${WINNING}"]
	}


	member:bool TargetNPCs()
	{
		variable index:entity Targets
		variable iterator Target
		variable iterator Target2
		variable iterator Target3
		variable index:entity LockedAssholes
		variable index:jammer Jammers
		variable iterator Jammer
	  	variable time breakTime
	 	 variable index:entity InRange
	 	 variable index:entity NotInRange
		  variable bool HasTargets = FALSE
		  variable int ToLock
		if ${Time.Timestamp} > ${TIMER.Timestamp}
		{
			Counter:Set[0]
			TIMER:Set[${Time.Timestamp}]
			TIMER.Second:Inc[1]
			TIMER:Update	
		}
		/* Me.Ship.MaxTargetRange contains the (possibly) damped value */
		EVE:QueryEntities[InRange, ${query2}]
		Targets:GetIterator[Target]
		ToLock:Set[${Math.Calc[${MyShip.MaxLockedTargets} - ${Me.TargetCount} - ${Me.TargetingCount}]}]
		InRange:GetIterator[Target2]
		if ${Entity[${query2}](exists)} && (${Entity["TypeID = TYPE_ACCELERATION_GATE"].Distance} > 110000 || (${Entity[Name =- "Beacon"].Distance} > 110000 && !${Entity["TypeID = TYPE_ACCELERATION_GATE"](exists)}) && ${Me.ToEntity.Mode} != 1
		{
			if ${Entity["TypeID = TYPE_ACCELERATION_GATE"](exists)}
			{
				Entity["TypeID = TYPE_ACCELERATION_GATE"]:Approach[10000]
				UI:UpdateConsole["Approaching gate."]
			}
			else
			{
				Entity[Name =- "Beacon"]:Approach[10000]
				UI:UpdateConsole["Approaching beacon."]
			}
		}
		if ${Target2:First(exists)}
		{
			HasTargets:Set[TRUE]
			do
			{
				if ${ToTarget.Used} > 0 
				{
					if  !${Entity[${ToTarget[1]}].IsActiveTarget} && ${Entity[${ToTarget[1]}].IsLockedTarget}
					{
						Entity["ID = ${ToTarget[1]}"]:MakeActiveTarget
						UI:UpdateConsole["Making ${ToTarget[1]} active target."]
					}
					else
					{
						if ${Entity[${ToTarget[1]}].Distance} > ${MyShip.MaxTargetRange} && ${Me.ToEntity.Mode} != 1
						{
							Entity[${ToTarget[1]}]:Approach[${MyShip.MaxTargetRange}]
							Ship:Activate_AfterBurner
						}

					}						
					if ${Math.Calc[${Me.TargetCount}+${Me.TargetingCount}]} < ${Ship.MaxLockedTargets}
					{
						if !${Entity[${ToTarget[1]}].IsLockedTarget} && !${Entity[${ToTarget[1]}].BeingTargeted}
						{
							Entity["ID = ${ToTarget[1]}"]:LockTarget
							UI:UpdateConsole["Locking ${ToTarget[1]} && ${ToTarget.Used} to target."]
						}
					}
					else
					{
						if !${Entity[${ToTarget[1]}].IsLockedTarget} && ${MyShip.MaxLockedTargets} > 0
						{
							Me:GetTargets[LockedAssholes]
							LockedAssholes[1]:UnlockTarget
							UI:UpdateConsole["Unlocking ${LockedAssholes[1].Name}"]
						}
					}
				}
				if ${Target2.Value.Distance} <= ${MyShip.MaxTargetRange}
				{
					if ${ToTarget.Used} == 0 && !${Target2.Value.IsLockedTarget} && !${Target2.Value.BeingTargeted} && ${ToLock} > ${Counter} && ${Counter}  < 2
					{
						Target2.Value:LockTarget
						UI:UpdateConsole["Locking ${Target2.Value.Name}"]
						UI:UpdateConsole["${Counter} is current amount of locking targets."]
						Counter:Inc		
					}
					else
					{
						;UI:UpdateConsole["ToLock = ${ToLock} Counter = ${Counter} ToTarget = ${ToTarget.Used} Target = ${Target2.Value.Name}"]
					}
				}
				else
				{
					if ${Me.TargetCount} == 0 && ${MyShip.MaxLockedTargets} > 0
					{
						if ${Me.ToEntity.Mode} != 1 && ${Entity["TypeID = TYPE_ACCELERATION_GATE"].Distance} < 110000 
						{
							Target2.Value:Approach[${MyShip.MaxTargetRange}]
							UI:UpdateConsole["Approaching rat out of range. Name = ${Target2.Value.Name} and distance < ${Target2.Value.Distance}."]
							Ship:Activate_AfterBurner
						}
					}
				}





			}
			while ${Target2:Next(exists)}
		}
		if ${Me.TargetedByCount} > 0 && ${InRange.Used} > 0
		{
			HasTargets:Set[TRUE] 
		}
		Me:GetJammers[Jammers]
		Jammers:GetIterator[Jammer]
		if ${Jammer:First(exists)} && (!${Entity[${ToTarget[1]}](exists)} || ${Me.ToEntity.IsWarpScrambled})
		{
			ToTarget:Clear
			if ${Me.Ship.MaxLockedTargets} == 0
			{
				UI:UpdateConsole["Jammed, cant target..."]
			}
			HasTargets:Set[TRUE]
				do
				{
					ToTarget:Insert[${Jammer.Value.ID}]
					UI:UpdateConsole["Jammer found with name ${Jammer.Value.Name}"]
				}
				while ${Jammer:Next(exists)}
		}
		if !${Entity[${ToTarget[1]}]} && ${ToTarget.Used} > 0
		{
			UI:UpdateConsole["Unprioritising target that no longer exists"]
			;if ${ToTarget.Used} > 1
			;{
			ToTarget:Remove[1]
			ToTarget:Collapse
			;}
			;else
			;{
			;	ToTarget:Clear
			;	UI:UpdateConsole["ToTarget.Used is ${ToTarget.Used} after :Clear"]
			;}
		}


		;if ${HasTargets} && ${Me.ActiveTarget(exists)}
		;{
		;	variable int OrbitDistance
		;	OrbitDistance:Set[${Math.Calc[${Me.Ship.MaxTargetRange}*0.40/1000].Round}]
		;	OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
		;	Me.ActiveTarget:Orbit[${OrbitDistance}]
		;}
		variable index:string Targetser
		variable iterator Targetse
		Targetser:Insert["Kruul's Pleasure Garden"]
		Targetser:Insert["Drone Bunker"]
		Targetser:Insert["Roden Shipyard Factory Station"]
		Targetser:Insert["Smuggler Stargate"]
		Targetser:Insert["Outpost Headquarters"]
		Targetser:GetIterator[Targetse]
		if ${Targetse:First(exists)}
		do
		{
			if ${Entity[Name =-"${Targetse.Value}"](exists)} && !${Entity["TypeID = TYPE_ACCELERATION_GATE"](exists)}
			{
				if ${Entity[Name =-"${Targetse.Value}"].Distance} < ${MyShip.MaxTargetRange}
				{
					if !${Entity[Name =- "${Targetse.Value}"].IsLockedTarget} && !${Entity[Name =- "${Targetse.Value}"].BeingTargeted} && !${HasTargets}
					{
						Entity[Name =- "${Targetse.Value}"]:LockTarget
					}
					elseif ${Entity[Name =- "${Targetse.Value}"].IsLockedTarget} && ${HasTargets}
					{
						Entity[Name =- "${Targetse.Value}"]:UnlockTarget
					}
					HasTargets:Set[TRUE]
				}
				else
				{
					if ${Me.ToEntity.Mode} > 1
					{
						;Check here for sentrydrones
						if ${Ship.Drones.IsDroneBoat}
						{
							Entity[Name =-"${Targetse.Value}"]:Approach[${Me.DroneControlDistance}]
						}
						else 
						{
							Entity[Name =-"${Targetse.Value}"]:Approach[${MyShip.MaxTargetRange}]
						}
						HasTargets:Set[TRUE]
					}
				}
			}
		}
		while ${Targetse:Next(exists)}

		return ${HasTargets}
	}

	member:bool PC()
	{
		variable index:entity tgtIndex
		variable iterator tgtIterator

		EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_SHIP"]
		tgtIndex:GetIterator[tgtIterator]
		if ${tgtIterator:First(exists)}
		do
		{
			; todo - make ignoring whitelisted chars in your belt an optional action.
			if ${tgtIterator.Value.Owner.CharID} != ${Me.CharID} && !${Social.PilotWhiteList.Contains[${tgtIterator.Value.Owner.CharID}]}
			{	/* A player is already present here ! */
				UI:UpdateConsole["Player found ${tgtIterator.Value.Owner} ${tgtIterator.Value.Owner.CharID} ${tgtIterator.Value.ID}"]
				return TRUE
			}
		}
		while ${tgtIterator:Next(exists)}

		; No other players around
		return FALSE
	}

	member:int DroneAggTargets()
	{
		variable index:ent sarp
		variable iterator itter
		EVE:QueryEntities[sarp, ${Query2}]
		; ents > 60 km && not agging me approach add code to not orbit if we approaching make sure approach to 10 km below targeting and to toTargets
	}
	member:bool NPC()
	{
		variable index:entity tgtIndex
		variable iterator tgtIterator

		EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_ENTITY"]
		UI:UpdateConsole["DEBUG: Found ${tgtIndex.Used} entities."]

		tgtIndex:GetIterator[tgtIterator]
		if ${tgtIterator:First(exists)}
		do
		{
			switch ${tgtIterator.Value.GroupID}
			{
				case GROUP_CONCORDDRONE
				case GROUP_CONVOYDRONE
				case GROUP_CONVOY
				case GROUP_LARGECOLLIDABLEOBJECT
				case GROUP_LARGECOLLIDABLESHIP
				case GROUP_LARGECOLLIDABLESTRUCTURE
					;UI:UpdateConsole["DEBUG: Ignoring entity ${tgtIterator.Value.Group} (${tgtIterator.Value.GroupID})"]
					continue
					break
				default
					UI:UpdateConsole["DEBUG: NPC found: ${tgtIterator.Value.Group} (${tgtIterator.Value.GroupID})"]
					return TRUE
					break
			}
		}
		while ${tgtIterator:Next(exists)}

		; No NPCs around
		return FALSE
	}
}
