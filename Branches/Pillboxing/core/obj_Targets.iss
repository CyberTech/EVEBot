	
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
	
	variable index:string SpecialTargets
	variable iterator SpecialTarget

	variable index:string SpecialTargetsToLoot
	variable iterator SpecialTargetToLoot
	variable uint WarpScramQuery = ${LavishScript.CreateQuery[IsWarpScramblingMe = "0"]}
	method Initialize()
	{
		;WINNING:Set[${LavishScript.CreateQuery[]}]
		;UI:UpdateConsole["Query set to ${WINNING}"]
			SpecialTargets:Insert["Gotan Kreiss"]
		SpecialTargets:Insert["Hakim Stormare"]
		SpecialTargets:Insert["Mizuro Cybon"]
		SpecialTargets:Insert["Tobias Kruzhoryy"]

		; Asteroid Angel Cartel Battleship
		SpecialTargets:Insert["Domination Cherubim"]
		SpecialTargets:Insert["Domination Commander"]
		SpecialTargets:Insert["Domination General"]
		SpecialTargets:Insert["Domination Malakim"]
		SpecialTargets:Insert["Domination Nephilim"]
		SpecialTargets:Insert["Domination Saint"]
		SpecialTargets:Insert["Domination Seraphim"]
		SpecialTargets:Insert["Domination Throne"]
		SpecialTargets:Insert["Domination War General"]
		SpecialTargets:Insert["Domination Warlord"]

		; Asteroid Angel Cartel Battlecruiser
		SpecialTargets:Insert["Domination Legatus"]
		SpecialTargets:Insert["Domination Legionnaire"]
		SpecialTargets:Insert["Domination Praefectus"]
		SpecialTargets:Insert["Domination Primus"]
		SpecialTargets:Insert["Domination Tribuni"]
		SpecialTargets:Insert["Domination Tribunus"]

		; Asteroid Angel Cartel Cruiser
		SpecialTargets:Insert["Domination Breaker"]
		SpecialTargets:Insert["Domination Centurion"]
		SpecialTargets:Insert["Domination Crusher"]
		SpecialTargets:Insert["Domination Defeater"]
		SpecialTargets:Insert["Domination Depredator"]
		SpecialTargets:Insert["Domination Liquidator"]
		SpecialTargets:Insert["Domination Marauder"]
		SpecialTargets:Insert["Domination Phalanx"]
		SpecialTargets:Insert["Domination Predator"]
		SpecialTargets:Insert["Domination Smasher"]

		; Asteroid Angel Cartel Destroyer
		SpecialTargets:Insert["Domination Defacer"]
		SpecialTargets:Insert["Domination Defiler"]
		SpecialTargets:Insert["Domination Haunter"]
		SpecialTargets:Insert["Domination Seizer"]
		SpecialTargets:Insert["Domination Shatterer"]
		SpecialTargets:Insert["Domination Trasher"]

		; Asteroid Angel Cartel Frigate
		SpecialTargets:Insert["Domination Ambusher"]
		SpecialTargets:Insert["Domination Hijacker"]
		SpecialTargets:Insert["Domination Hunter"]
		SpecialTargets:Insert["Domination Impaler"]
		SpecialTargets:Insert["Domination Nomad"]
		SpecialTargets:Insert["Domination Outlaw"]
		SpecialTargets:Insert["Domination Raider"]
		SpecialTargets:Insert["Domination Rogue"]
		SpecialTargets:Insert["Domination Ruffian"]
		SpecialTargets:Insert["Domination Thug"]
		SpecialTargets:Insert["Psycho Ambusher"]
		SpecialTargets:Insert["Psycho Hijacker"]
		SpecialTargets:Insert["Psycho Hunter"]
		SpecialTargets:Insert["Psycho Impaler"]
		SpecialTargets:Insert["Psycho Nomad"]
		SpecialTargets:Insert["Psycho Outlaw"]
		SpecialTargets:Insert["Psycho Raider"]
		SpecialTargets:Insert["Psycho Rogue"]
		SpecialTargets:Insert["Psycho Ruffian"]
		SpecialTargets:Insert["Psycho Thug"]

		; Asteroid Blood Raiders Officers
		SpecialTargets:Insert["Ahremen Arkah"]
		SpecialTargets:Insert["Draclira Merlonne"]
		SpecialTargets:Insert["Raysere Giant"]
		SpecialTargets:Insert["Tairei Namazoth"]

		; Asteroid Guristas Officers
		SpecialTargets:Insert["Estamel Tharchon"]
		SpecialTargets:Insert["Kaikka Peunato"]
		SpecialTargets:Insert["Thon Eney"]
		SpecialTargets:Insert["Vepas Minimala"]

		; Asteroid Sansha's Nation Officers
		SpecialTargets:Insert["Brokara Ryver"]
		SpecialTargets:Insert["Chelm Soran"]
		SpecialTargets:Insert["Selynne Mardakar"]
		SpecialTargets:Insert["Vizan Ankonin"]

		; Asteroid Serpentis Officers
		SpecialTargets:Insert["Brynn Jerdola"]
		SpecialTargets:Insert["Cormack Vaaja"]
		SpecialTargets:Insert["Setele Schellan"]
		SpecialTargets:Insert["Tuvan Orth"]


		SpecialTargets:Insert["Dread Guristas"]
		SpecialTargets:Insert["Shadow Serpentis"]
		SpecialTargets:Insert["True Sansha"]
		SpecialTargets:Insert["Dark Blood"]

		SpecialTargets:Insert["Courier"]
		SpecialTargets:Insert["Ferrier"]
		SpecialTargets:Insert["Gatherer"]
		SpecialTargets:Insert["Harvester"]
		SpecialTargets:Insert["Loader"]
		SpecialTargets:Insert["Bulker"]
		SpecialTargets:Insert["Carrier"]
		SpecialTargets:Insert["Convoy"]
		SpecialTargets:Insert["Hauler"]
		SpecialTargets:Insert["Trailer"]
		SpecialTargets:Insert["Transporter"]
		SpecialTargets:Insert["Trucker"]

		SpecialTargetsToLoot:Insert["Dread Guristas"]
		SpecialTargetsToLoot:Insert["Shadow Serpentis"]
		SpecialTargetsToLoot:Insert["True Sansha"]
		SpecialTargetsToLoot:Insert["Dark Blood"]
		SpecialTargetsToLoot:Insert["Domination"]

		; Asteroid Serpentis Officers
		SpecialTargetsToLoot:Insert["Brynn Jerdola"]
		SpecialTargetsToLoot:Insert["Cormack Vaaja"]
		SpecialTargetsToLoot:Insert["Setele Schellan"]
		SpecialTargetsToLoot:Insert["Tuvan Orth"]

		; Asteroid Guristas Officers
		SpecialTargetsToLoot:Insert["Estamel Tharchon"]
		SpecialTargetsToLoot:Insert["Kaikka Peunato"]
		SpecialTargetsToLoot:Insert["Thon Eney"]
		SpecialTargetsToLoot:Insert["Vepas Minimala"]

		; Asteroid Angel Cartel Battleship
		SpecialTargetsToLoot:Insert["Domination Cherubim"]
		SpecialTargetsToLoot:Insert["Domination Commander"]
		SpecialTargetsToLoot:Insert["Domination General"]
		SpecialTargetsToLoot:Insert["Domination Malakim"]
		SpecialTargetsToLoot:Insert["Domination Nephilim"]
		SpecialTargetsToLoot:Insert["Domination Saint"]
		SpecialTargetsToLoot:Insert["Domination Seraphim"]
		SpecialTargetsToLoot:Insert["Domination Throne"]
		SpecialTargetsToLoot:Insert["Domination War General"]
		SpecialTargetsToLoot:Insert["Domination Warlord"]

		; Asteroid Angel Cartel Battlecruiser
		SpecialTargetsToLoot:Insert["Domination Legatus"]
		SpecialTargetsToLoot:Insert["Domination Legionnaire"]
		SpecialTargetsToLoot:Insert["Domination Praefectus"]
		SpecialTargetsToLoot:Insert["Domination Primus"]
		SpecialTargetsToLoot:Insert["Domination Tribuni"]
		SpecialTargetsToLoot:Insert["Domination Tribunus"]

		; Asteroid Angel Cartel Cruiser
		SpecialTargetsToLoot:Insert["Domination Breaker"]
		SpecialTargetsToLoot:Insert["Domination Centurion"]
		SpecialTargetsToLoot:Insert["Domination Crusher"]
		SpecialTargetsToLoot:Insert["Domination Defeater"]
		SpecialTargetsToLoot:Insert["Domination Depredator"]
		SpecialTargetsToLoot:Insert["Domination Liquidator"]
		SpecialTargetsToLoot:Insert["Domination Marauder"]
		SpecialTargetsToLoot:Insert["Domination Phalanx"]
		SpecialTargetsToLoot:Insert["Domination Predator"]
		SpecialTargetsToLoot:Insert["Domination Smasher"]

		; Asteroid Angel Cartel Destroyer
		SpecialTargetsToLoot:Insert["Domination Defacer"]
		SpecialTargetsToLoot:Insert["Domination Defiler"]
		SpecialTargetsToLoot:Insert["Domination Haunter"]
		SpecialTargetsToLoot:Insert["Domination Seizer"]
		SpecialTargetsToLoot:Insert["Domination Shatterer"]
		SpecialTargetsToLoot:Insert["Domination Trasher"]

		; Asteroid Angel Cartel Frigate
		SpecialTargetsToLoot:Insert["Domination Ambusher"]
		SpecialTargetsToLoot:Insert["Domination Hijacker"]
		SpecialTargetsToLoot:Insert["Domination Hunter"]
		SpecialTargetsToLoot:Insert["Domination Impaler"]
		SpecialTargetsToLoot:Insert["Domination Nomad"]
		SpecialTargetsToLoot:Insert["Domination Outlaw"]
		SpecialTargetsToLoot:Insert["Domination Raider"]
		SpecialTargetsToLoot:Insert["Domination Rogue"]
		SpecialTargetsToLoot:Insert["Domination Ruffian"]
		SpecialTargetsToLoot:Insert["Domination Thug"]
		SpecialTargetsToLoot:Insert["Psycho Ambusher"]
		SpecialTargetsToLoot:Insert["Psycho Hijacker"]
		SpecialTargetsToLoot:Insert["Psycho Hunter"]
		SpecialTargetsToLoot:Insert["Psycho Impaler"]
		SpecialTargetsToLoot:Insert["Psycho Nomad"]
		SpecialTargetsToLoot:Insert["Psycho Outlaw"]
		SpecialTargetsToLoot:Insert["Psycho Raider"]
		SpecialTargetsToLoot:Insert["Psycho Rogue"]
		SpecialTargetsToLoot:Insert["Psycho Ruffian"]
		SpecialTargetsToLoot:Insert["Psycho Thug"]

		; Asteroid Angel Cartel Officers
		SpecialTargetsToLoot:Insert["Gotan Kreiss"]
		SpecialTargetsToLoot:Insert["Hakim Stormare"]
		SpecialTargetsToLoot:Insert["Mizuro Cybon"]
		SpecialTargetsToLoot:Insert["Tobias Kruzhoryy"]

		; Asteroid Blood Raiders Officers
		SpecialTargetsToLoot:Insert["Ahremen Arkah"]
		SpecialTargetsToLoot:Insert["Draclira Merlonne"]
		SpecialTargetsToLoot:Insert["Raysere Giant"]
		SpecialTargetsToLoot:Insert["Tairei Namazoth"]

		; Asteroid Sansha's Nation Officers
		SpecialTargetsToLoot:Insert["Brokara Ryver"]
		SpecialTargetsToLoot:Insert["Chelm Soran"]
		SpecialTargetsToLoot:Insert["Selynne Mardakar"]
		SpecialTargetsToLoot:Insert["Vizan Ankonin"]

		; Asteroid Angel Cartel Officers
		SpecialTargetsToLoot:Insert["Gotan Kreiss"]
		SpecialTargetsToLoot:Insert["Hakim Stormare"]
		SpecialTargetsToLoot:Insert["Mizuro Cybon"]
		SpecialTargetsToLoot:Insert["Tobias Kruzhoryy"]

		; Asteroid Blood Raiders Officers
		SpecialTargetsToLoot:Insert["Ahremen Arkah"]
		SpecialTargetsToLoot:Insert["Draclira Merlonne"]
		SpecialTargetsToLoot:Insert["Raysere Giant"]
		SpecialTargetsToLoot:Insert["Tairei Namazoth"]

		; Asteroid Sansha's Nation Officers
		SpecialTargetsToLoot:Insert["Brokara Ryver"]
		SpecialTargetsToLoot:Insert["Chelm Soran"]
		SpecialTargetsToLoot:Insert["Selynne Mardakar"]
		SpecialTargetsToLoot:Insert["Vizan Ankonin"]

		; Get the iterators
		PriorityTargets:GetIterator[PriorityTarget]
		SpecialTargets:GetIterator[SpecialTarget]
		SpecialTargetsToLoot:GetIterator[SpecialTargetToLoot]

	}

	method ResetTargets()
	{
		This.CheckChain:Set[TRUE]
		This.Chaining:Set[FALSE]
		This.CheckedSpawnValues:Set[FALSE]
		This.TotalSpawnValue:Set[0]
	}

	member:bool SpecialTargetPresent()
	{
		return ${m_SpecialTargetPresent}
	}

	member:bool IsPriorityTarget(int ID)
	{
		; Loop through the priority targets
		variable iterator itty
		ToTarget:GetIterator[itty]
		if ${itty:First(exists)}
		{
			do
			{
				if ${itty.Value.Equal[${ID}]}
				{
					return TRUE
				}
			}
			while ${itty:Next(exists)}
		}
		return FALSE
	}

	member:bool IsSpecialTarget(string name)
	{
			; Loop through the special targets
			if ${SpecialTarget:First(exists)}
			do
			{
				if ${name.Find[${SpecialTarget.Value}]} > 0
				{
					return TRUE
				}
			}
			while ${SpecialTarget:Next(exists)}

			return FALSE
	}

	member:bool IsSpecialTargetToLoot(string name)
	{
			; Loop through the special targets
			if ${SpecialTargetToLoot:First(exists)}
			do
			{
				if ${name.Find[${SpecialTargetToLoot.Value}]} > 0
				{
					return TRUE
				}
			}
			while ${SpecialTargetToLoot:Next(exists)}

			return FALSE
	}



	member:bool TargetNPCs()
	{
		if !${Me.InSpace}
		{
			echo "TargetNPCs called from in a station, wtf you tard."
			return
		}
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
		variable int64 GATEID = ${Entity["TypeID = TYPE_ACCELERATION_GATE"].ID}
		variable int64 BEACONID = ${Entity[Name =- "Beacon"].ID}
		if ${Time.Timestamp} > ${TIMER.Timestamp}
		{
			Counter:Set[0]
			TIMER:Set[${Time.Timestamp}]
			TIMER.Second:Inc[1]
			TIMER:Update	
		}
		if ${Config.Common.BotModeName.Equal[Ratter]}
		{
			Me:GetTargets[Targets]	
			Targets:GetIterator[Target]
			if ${Target:First(exists)}
			{
				do
				{
					if ${This.IsSpecialTarget[${Target.Value.Name}]}
					{
						HasSpecialTarget:Set[TRUE]
						m_SpecialTargetPresent:Set[TRUE]
						m_SpecialTargetName:Set[${Target.Value.Name}]
					}
				}
				while ${Target:Next(exists)}
			}
		}
		/* MyShip.MaxTargetRange contains the (possibly) damped value */
		EVE:QueryEntities[InRange, ${query2}]
		ToLock:Set[${Math.Calc[${Ship.MaxLockedTargets} - ${Me.TargetCount} - ${Me.TargetingCount}]}]
		InRange:GetIterator[Target2]
		if (!${Ship.Approaching.Equal[${Entity[${query2}]}]}  && \
			${Entity[${query2}](exists)} && \
			 (${Entity[${GATEID}].Distance} > 110000 || (${Entity[${BEACONID}].Distance} > 110000 && !${Entity[${GATEID}](exists)})) 
		{
			if ${Entity[${GATEID}](exists)}
			{
				Entity[${GATEID}]:Approach[10000]
				UI:UpdateConsole["Approaching gate."]
			}
			else
			{
				Entity[${BEACONID}]:Approach[10000]
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
					if !${Entity[${ToTarget[1]}].IsActiveTarget} && \
					${Entity[${ToTarget[1]}].IsLockedTarget}
					{	
						;Adding some drone checks here
						;The checks need to be as follows: PSEUDOCODE POWER
						/* 
						if Drones target is not equal to our prioritised target and the button is checked in cmbat settings, change the target to teh priority target
						or if the dontkillfrigate options is on
						So in effect this code shouldn't fire if dont kill frigates is on and the frigates are already attacking our target
						*/
						if (!${Ship.Drones.DroneTarget.Equal[${ToTarget[1]}]} && ${Config.Combat.DontKillFrigs}) || \
						!${Config.Combat.DontKillFrigs}
						{
							Entity["ID = ${ToTarget[1]}"]:MakeActiveTarget
							UI:UpdateConsole["Making ${ToTarget[1]} active target."]
						}
						else
						{
							;echo "if (${Entity[${Ship.Drones.DroneTarget}](exists)} && !${Ship.Drones.DroneTarget.Equal[${ToTarget[1]}]} && ${Config.Combat.DontKillFrigs})"
						}
					}					
					if ${Math.Calc[${Me.TargetCount}+${Me.TargetingCount}]} < ${Ship.MaxLockedTargets}
					{
						if !${Entity[${ToTarget[1]}].IsLockedTarget} && !${Entity[${ToTarget[1]}].BeingTargeted}
						{
							if ${Entity[${ToTarget[1]}].Distance} <= ${MyShip.MaxTargetRange}
							{
								Entity["ID = ${ToTarget[1]}"]:LockTarget
								UI:UpdateConsole["Locking ${ToTarget[1]} && ${ToTarget.Used} to target."]							
							}
							else
							{
								if !${Ship.Approaching.Equal[${Entity[${ToTarget[1]}]}]}
								{
									Ship:Approach[${Entity[${ToTarget[1]}]},${MyShip.MaxTargetRange}]
									UI:UpdateConsole["Approaching rat out of range. Name = ${Target2.Value.Name} and distance < ${Target2.Value.Distance}."]
								}
							}	
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
				if ${Target2.Value.Distance} <= ${MyShip.MaxTargetRange} && ${Me.TargetCount} < ${Ship.MaxLockedTargets}
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
						if !${Entity[${Ship.Approaching}](exists)} && !${Entity[${query2} && Distance <= "${MyShip.MaxTargetRange}"](exists)} && (${Entity[${GATEID}].Distance} < 110000 || ${Entity[${BEACONID}].Distance} < 110000)
						{
							Ship:Approach[${Target2.Value.ID},${MyShip.MaxTargetRange}]
							;I'm going to have to update this into a check that checks for sentry drones in space before approaching.
							UI:UpdateConsole["Approaching rat out of range. Name = ${Target2.Value.Name} and distance < ${Target2.Value.Distance}."]
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
		if ${Jammer:First(exists)} && !${Entity[${ToTarget[1]}](exists)} || ${Me.ToEntity.IsWarpScrambled}
		{
			ToTarget:Clear
			if ${MyShip.MaxLockedTargets} == 0
			{
				UI:UpdateConsole["Jammed, cant target..."]
			}
			HasTargets:Set[TRUE]
				do
				{
					ToTarget:Insert[${Jammer.Value.ID}]
				}
				while ${Jammer:Next(exists)}
			if ${Me.ToEntity.IsWarpScrambled}
			{
				UI:UpdateConsole["We are being warp scrambled, all priority targets or jammers are ignored until we're not."]
				ToTarget:RemoveByQuery[${WarpScramQuery}]
			}
		}
		if !${Entity[${ToTarget[1]}]} && ${ToTarget.Used} > 0
		{
			UI:UpdateConsole["Unprioritising target that no longer exists"]
			ToTarget:Remove[1]
			ToTarget:Collapse
		}


		variable index:string Targetser
		variable iterator Targetse
		Targetser:Insert["Kruul's Pleasure Garden"]
		Targetser:Insert["Drone Bunker"]
		Targetser:Insert["Roden Shipyard Factory Station"]
		Targetser:Insert["Smuggler Stargate"]
		Targetser:Insert["Outpost Headquarters"]
		Targetser:Insert["Docked bestower"]
		Targetser:Insert["Slave Pen"]
		Targetser:Insert["Lesser Drone Hive"]
		Targetser:Insert["Repair Station"]
		Targetser:Insert["Drone Silo"]
		Targetser:Insert["Powerful EM Forcefield"]
		Targetser:Insert["Broadcasting Array"]
		Targetser:Insert["Infested Station"]
		Targetser:Insert["Imperial Stargate"]
		Targetser:Insert["Caldari Manufacturing Plant"]
		Targetser:Insert["Caldari Supply Depot"]
		Targetser:Insert["Patient Zero"]
		Targetser:Insert["Amarr Shipyard Control Tower"]
		Targetser:Insert["Blood Raider Cathedral"]
		Targetser:GetIterator[Targetse]
		Targetse:First
		if ${InRange.Used.Equal[0]} 
		do
		{
			if ${Entity[Name =-"${Targetse.Value}"](exists)} && !${Entity[${GATEID}](exists)}
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
					if !${Ship.Approaching.Equal[${Entity[Name =- "Targetse.Value"].ID}]}
					{
						;Check here for sentrydrones
						if ${Ship.Drones.IsDroneBoat}
						{
							Ship:Approach[${Entity[Name =-"${Targetse.Value}"]},${Me.DroneControlDistance}]
						}
						else 
						{
							Ship:Approach[${Entity[Name =-"${Targetse.Value}"]},${MyShip.MaxTargetRange}]
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
	method NextTarget()
	{
		variable index:entity ListOfTargets
		variable iterator itty
		Me:GetTargets[ListOfTargets]
		if ${ListOfTargets.Used} > 0
		{
			ListOfTargets:GetIterator[itty]
			itty:First
			do
			{
				if ${itty.Value.ID.Equal[${Me.ActiveTarget}]}
				{
					itty:Next
					itty.Value:MakeActiveTarget
				}
			}
			while ${itty:Next(exists)}
		}
		else
		{
			UI:UpdateConsole[obj_Targets - NextTarget: No targets locked. ]
		}
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
