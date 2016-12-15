
/*
Officer spawns appear in their home region, or in any region where their
faction normally appears, but *only* in systems with -0.8 or below true
sec rating.

Faction: Guristas/Pithi/Dread Guristas
Home Region: Venal
Officers:
Estamel Tharchon
Vepas Minimala
Thon Eney
Kaikka Peunato


Faction: Angels/Gisi/Domination
Home Region: Curse
Officers:
Tobias Kruzhor
Gotan Kreiss
Hakim Stormare
Mizuro Cybon

Faction: Serpentis/Coreli/Shadow:
Home Region: Fountain
Officers:
Cormack Vaaja
Setele Schellan
Tuvan Orth
Brynn Jerdola

Faction: Sanshas/Centi/True Sansha:
Home Region: Stain
Officers:
Chelm Soran
Vizan Ankonin
Selynne Mardakar
Brokara Ryver

Faction: Blood/Corpi/Dark Blood:
Home Region: Delve
Officers:
Draclira Merlonne
Ahremen Arkah
Raysere Giant
Tairei Namazoth
*/

objectdef obj_Targets inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"

	variable index:int64 TargetQueue
	variable index:int64 TargetQueueOverride

	variable index:int64 DefensiveQueue
	variable index:int64 DefensiveQueueOverride

	variable int ReservedDefensiveSlots = 2

	variable index:string PriorityTargets
	variable iterator PriorityTarget

	variable index:string ChainTargets
	variable iterator ChainTarget

	variable index:string SpecialTargets
	variable iterator SpecialTarget

	variable index:string SpecialTargetsToLoot
	variable iterator SpecialTargetToLoot

	variable bool CheckChain
	variable bool Chaining

	variable bool m_SpecialTargetPresent
	variable set DoNotKillList
	variable bool CheckedSpawnValues = FALSE

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		m_SpecialTargetPresent:Set[FALSE]

		ReservedDefensiveSlots:Set[${Ship.MaxLockedTargets}]
		while ${ReservedDefensiveSlots} > 2
		{
			ReservedDefensiveSlots:Dec
		}

		; TODO - load this all from XML files

		; Priority targets will be targeted (and killed)
		; before other targets, they often do special things
		; which we cant use (scramble / web / damp / etc)
		; You can specify the entire rat name, for example
		; leave rats that dont scramble which would help
		; later when chaining gets added
		PriorityTargets:Insert["Factory Defense Battery"] 		/* web/scram */
		PriorityTargets:Insert["Dire Pithi Arrogator"] 		/* web/scram */
		PriorityTargets:Insert["Dire Pithi Despoiler"] 		/* Jamming */
		PriorityTargets:Insert["Dire Pithi Imputor"] 		/* web/scram */
		PriorityTargets:Insert["Dire Pithi Infiltrator"] 	/* web/scram */
		PriorityTargets:Insert["Dire Pithi Invader"] 		/* web/scram */
		PriorityTargets:Insert["Dire Pithi Saboteur"] 		/* Jamming */
		PriorityTargets:Insert["Dire Pithi Annihilator"] 	/* Jamming */
		PriorityTargets:Insert["Dire Pithi Killer"] 			/* Jamming */
		PriorityTargets:Insert["Dire Pithi Murderer"] 		/* Jamming */
		PriorityTargets:Insert["Dire Pithi Nullifier"] 		/* Jamming */
		PriorityTargets:Insert["Dire Guristas Arrogator"] 		/* web/scram */
		PriorityTargets:Insert["Dire Guristas Despoiler"] 		/* Jamming */
		PriorityTargets:Insert["Dire Guristas Imputor"] 		/* web/scram */
		PriorityTargets:Insert["Dire Guristas Infiltrator"] 	/* web/scram */
		PriorityTargets:Insert["Dire Guristas Invader"] 		/* web/scram */
		PriorityTargets:Insert["Dire Guristas Saboteur"] 		/* Jamming */
		PriorityTargets:Insert["Dire Guristas Annihilator"] 	/* Jamming */
		PriorityTargets:Insert["Dire Guristas Killer"] 			/* Jamming */
		PriorityTargets:Insert["Dire Guristas Murderer"] 		/* Jamming */
		PriorityTargets:Insert["Dire Guristas Nullifier"] 		/* Jamming */

		PriorityTargets:Insert["Guristas Nullifier"]

		PriorityTargets:Insert["Arch Angel Hijacker"]
		PriorityTargets:Insert["Arch Angel Outlaw"]
		PriorityTargets:Insert["Arch Angel Rogue"]
		PriorityTargets:Insert["Arch Angel Thug"]
		PriorityTargets:Insert["Sansha's Loyal"]

		PriorityTargets:Insert["Guardian Agent"]			/* web/scram */
		PriorityTargets:Insert["Guardian Initiate"]			/* web/scram */
		PriorityTargets:Insert["Guardian Scout"]			/* web/scram */
		PriorityTargets:Insert["Guardian Spy"]				/* web/scram */
		PriorityTargets:Insert["Crook Watchman"]			/* damp */
		PriorityTargets:Insert["Guardian Watchman"]			/* damp */
		PriorityTargets:Insert["Serpentis Watchman"]		/* damp */
		PriorityTargets:Insert["Crook Patroller"]			/* damp */
		PriorityTargets:Insert["Guardian Patroller"]		/* damp */
		PriorityTargets:Insert["Serpentis Patroller"]		/* damp */

		PriorityTargets:Insert["Elder Blood Upholder"]		/* web/scram */
		PriorityTargets:Insert["Elder Blood Worshipper"]	/* web/scram */
		PriorityTargets:Insert["Elder Blood Follower"]		/* web/scram */
		PriorityTargets:Insert["Elder Blood Herald"]		/* web/scram */
		PriorityTargets:Insert["Blood Wraith"]				/* web/scram */
		PriorityTargets:Insert["Blood Disciple"]			/* web/scram */

		PriorityTargets:Insert["Strain Decimator Drone"]    /* web/scram */
		PriorityTargets:Insert["Strain Infester Drone"]     /* web/scram */
		PriorityTargets:Insert["Strain Render Drone"]       /* web/scram */
		PriorityTargets:Insert["Strain Splinter Drone"]     /* web/scram */

		; Chain targets will be scanned for the first time
		; and then the script will determin if its safe / alright
		; to chain the belt.
		ChainTargets:Insert["Guristas Destroyer"]
		ChainTargets:Insert["Guristas Conquistador"]
		ChainTargets:Insert["Guristas Eliminator"]
		ChainTargets:Insert["Guristas Exterminator"]
		ChainTargets:Insert["Guristas Massacrer"]
		ChainTargets:Insert["Guristas Usurper"]
		ChainTargets:Insert["Angel Throne"]
		ChainTargets:Insert["Angel Saint"]
		ChainTargets:Insert["Angel Malakim"]
		ChainTargets:Insert["Angel Nephilim"]
		;ChainTargets:Insert["Serpentis Commodore"]	/* 650k */
		ChainTargets:Insert["Serpentis Port Admiral"]	/* 800k */
		ChainTargets:Insert["Serpentis Rear Admiral"]	/* 950k */
		ChainTargets:Insert["Serpentis Flotilla Admiral"]
		ChainTargets:Insert["Serpentis Vice Admiral"]
		ChainTargets:Insert["Serpentis Admiral"]
		ChainTargets:Insert["Serpentis Admiral"]
		ChainTargets:Insert["Serpentis Grand Admiral"]
		ChainTargets:Insert["Serpentis High Admiral"]
		ChainTargets:Insert["Serpentis Lord Admiral"]
		ChainTargets:Insert["Sansha's Lord"]
		ChainTargets:Insert["Sansha's Slave Lord"]
		ChainTargets:Insert["Sansha's Savage Lord"]
		ChainTargets:Insert["Sansha's Mutant Lord"]

		; Special targets will (eventually) trigger an alert
		; This should include haulers / faction / officers
		;
		; Asteroid Angel Cartel Officers
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
		ChainTargets:GetIterator[ChainTarget]
		SpecialTargets:GetIterator[SpecialTarget]
		SpecialTargetsToLoot:GetIterator[SpecialTargetToLoot]

		DoNotKillList:Clear

		;PulseTimer:SetIntervals[0.5,1.0]
		;Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
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

	member:bool IsPriorityTarget(string name)
	{
		; Loop through the priority targets
		if ${PriorityTarget:First(exists)}
		do
		{
			if ${name.Find[${PriorityTarget.Value}]} > 0
			{
				return TRUE
			}
		}
		while ${PriorityTarget:Next(exists)}

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
	member:bool PC()
	{
		variable iterator tgtIterator
		EntityCache.EntityFilters.Get[${EntityCache.CacheID_Ships}].Entities:GetIterator[tgtIterator]

		if ${tgtIterator:First(exists)}
		do
		{
			if ${tgtIterator.Value.OwnerID} != ${Me.CharID}
			{	/* A player is already present here ! */
				/* TODO - Add optional check for ignoring group members */
				Logger:Log["Player found ${tgtIterator.Value.Owner}"]
				return TRUE
			}
		}
		while ${tgtIterator:Next(exists)}

		; No other players around
		return FALSE
	}

	member:bool NPC()
	{
		variable iterator tgtIterator
		EntityCache.EntityFilters.Get[${EntityCache.CacheID_Entities}].Entities:GetIterator[tgtIterator]

		Logger:Log["Targets.NPC() Found ${EntityCache.Used[${EntityCache.CacheID_Entities}]} entities.", LOG_DEBUG]

		tgtIndex:GetIterator[tgtIterator]
		if ${tgtIterator:First(exists)}
		do
		{
			switch ${tgtIterator.Value.GroupID}
			{
				case GROUP_LARGECOLLIDABLEOBJECT
				case GROUP_LARGECOLLIDABLESHIP
				case GROUP_SENTRYGUN
				case GROUP_CONCORDDRONE
				case GROUP_CUSTOMSOFFICIAL
				case GROUP_POLICEDRONE
				case GROUP_CONVOYDRONE
				case GROUP_CONVOY
				case GROUP_FACTIONDRONE
				case GROUP_BILLBOARD
				case GROUP_DEADSPACEOVERSEERSSTRUCTURE
				case GROUP_LARGECOLLIDABLESTRUCTURE
					Logger:Log["DEBUG: Ignoring entity ${tgtIterator.Value.Group} (${tgtIterator.Value.GroupID})"]
					break
				default
					Logger:Log["DEBUG: NPC found: ${tgtIterator.Value.Group} (${tgtIterator.Value.GroupID})"]
					return TRUE
					break
			}
		}
		while ${tgtIterator:Next(exists)}

		; No NPCs around
		return FALSE
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
			case GROUP_CONVOY
			case GROUP_FACTIONDRONE
			case GROUP_BILLBOARD
			case GROUPID_SPAWN_CONTAINER
			case GROUP_DEADSPACEOVERSEERSSTRUCTURE
				return FALSE
				break
		}

		return TRUE
	}
}

/* Handles Targeting Rats:
	Prioritize jamming/scramming targets, keep chains in order.
*/
objectdef obj_Targets_Rats
{
	variable index:entity Targets
	variable iterator Target

	variable int TotalBattleShipValue
	variable bool UpdateSucceeded

	/* This will be called from obj_Ratter. Make use of the RatCache. */
	member:int CalcTotalBattleShipValue()
	{
		variable int iTotalBSValue = 0
		variable iterator EntityIterator
		EntityCache.EntityFilters.Get[${EntityCache.CacheID_Entities}].Entities:GetIterator[EntityIterator]

		; Determine the total spawn value
		if ${EntityIterator:First(exists)}
		{
			do
			{
				variable int pos
				variable string NPCName
				variable string NPCGroup
				variable string NPCShipType

				NPCName:Set[${EntityIterator.Value.Name}]
				NPCGroup:Set[${EntityIterator.Value.Group}]
				pos:Set[1]
				while ${NPCGroup.Token[${pos}, " "](exists)}
				{
					NPCShipType:Set[${NPCGroup.Token[${pos}, " "]}]
					pos:Inc
				}
				Logger:Log["NPC: ${NPCName}(${NPCShipType}) ${EVEBot.ISK_To_Str[${EVEDB_Spawns.SpawnBounty[${NPCName}]}]}",LOG_DEBUG]

				;Logger:Log["DEBUG: Type: ${EntityIterator.Value.Type}(${EntityIterator.Value.TypeID})"]
				;Logger:Log["DEBUG: Category: ${EntityIterator.Value.Category}(${EntityIterator.Value.CategoryID})"]

				switch ${EntityIterator.Value.GroupID}
				{
					case GROUP_LARGECOLLIDABLEOBJECT
					case GROUP_LARGECOLLIDABLESHIP
					case GROUP_LARGECOLLIDABLESTRUCTURE
						continue
						break
					default
						break
				}
				if ${NPCGroup.Find["Battleship"](exists)}
				{
					iTotalBSValue:Inc[${EVEDB_Spawns.SpawnBounty[${NPCName}]}]
				}
			 }
			 while ${EntityIterator:Next(exists)}
			 Logger:Log["NPC: Total Battleship Value is ${EVEBot.ISK_To_Str[${iTotalBSValue}]}",LOG_DEBUG]
		}
		return ${iTotalBSValue}
	}

	method UpdateTargetList()
	{
		if ${MyShip.MaxLockedTargets} == 0
		{
			Logger:Log["Jammed: Unable to Target"]
			return
		}

		/* MyShip.MaxTargetRange contains the (possibly) damped value */
		if ${Ship.TypeID} == TYPE_RIFTER
		{
			EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= 100000"]
		}
		else
		{
			EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= ${MyShip.MaxTargetRange}"]
		}
		This.Targets:GetIterator[This.Target]

		if !${This.Target:First(exists)}
		{
			if ${Ship.IsDamped}
			{
				/* Ship.MaxTargetRange contains the maximum undamped value */
				EVE:QueryEntities[This.Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= ${Ship.MaxTargetRange}"]
				This.Targets:GetIterator[This.Target]

				if !${This.Target:First(exists)}
				{
					Logger:Log["No targets found"]
					UpdateSucceeded:Set[FALSE]
					return
				}
				else
				{
					Logger:Log["Damped: Unable to Target"]
					UpdateSucceeded:Set[TRUE]
					return
				}
			}
			else
			{
				Logger:Log["No targets found..."]
				UpdateSucceeded:Set[FALSE]
				return
			}
		}

		; Chaining means there might be targets here which we shouldnt kill
		variable bool HasTargets = FALSE

		; Start looking for (and locking) priority targets
		; special targets and chainable targets, only priority
		; targets will be locked in this loop
		variable bool HasPriorityTarget = FALSE
		variable bool HasChainableTarget = FALSE
		variable bool HasSpecialTarget = FALSE
		variable bool HasMultipleTypes = FALSE

		m_SpecialTargetPresent:Set[FALSE]
		This:CalcTotalBattleShipValue[]
		if ${This.TotalBattleShipValue} >= ${Config.Combat.MinChainBounty}
		{
			 HasChainableTarget:Set[TRUE]
		}
		Logger:Log["obj_Targets: Total BS Value: ${This.TotalBattleShipValue}, Minimum: ${Config.Combat.MinChainBounty}, Chainable: ${HasChainableTarget}"]

		if ${This.Target:First(exists)}
		{
			variable int TypeID
			TypeID:Set[${This.Target.Value.TypeID}]
			do
			{
				switch ${This.Target.Value.GroupID}
				{
					case GROUP_LARGECOLLIDABLEOBJECT
					case GROUP_LARGECOLLIDABLESHIP
					case GROUP_LARGECOLLIDABLESTRUCTURE
					case GROUP_SENTRYGUN
					case GROUP_CONCORDDRONE
					case GROUP_CUSTOMSOFFICIAL
					case GROUP_POLICEDRONE
					case GROUP_CONVOYDRONE
					case GROUP_CONVOY
					case GROUP_FACTIONDRONE
					case GROUP_BILLBOARD
						continue
						break
					Default
						break
				}

				; If the Type ID is different then there's more then 1 type in the belt
				if ${TypeID} != ${This.Target.Value.TypeID}
				{
					HasMultipleTypes:Set[TRUE]
				}

				; Check for a special target
				if ${This.IsSpecialTarget[${This.Target.Value.Name}]}
				{
					HasSpecialTarget:Set[TRUE]
					m_SpecialTargetPresent:Set[TRUE]
				}

				; Loop through the priority targets
				Logger:Log["obj_Targets: IsPriorityTarget(${This.Target.Value.Name}): ${Targets.IsPriorityTarget[${This.Target.Value.Name}]}"]
				if ${Targets.IsPriorityTarget[${This.Target.Value.Name}]}
				{
					/* We have a priority target, set the flag true. */
					HasPriorityTarget:Set[TRUE]
					; Yes, is it locked?
					!${Targeting.IsQueued[${This.Target.Value.ID}]}
					{
						/* Queue[ID, Priority, TypeID, Mandatory] */
						; No, report it and lock it.
						Logger:Log["obj_Targets: Queueing priority target ${This.Target.Value.Name}"]
						Targeting:Queue[${This.Target.Value.ID},${Targeting.TYPE_HOSTILE},5,TRUE]
					}

					; By only saying there's priority targets when they arent
					; locked yet, the npc bot will target non-priority targets
					; after it has locked all the priority targets
					; (saves time once the priority targets are dead)
					if !${This.Target.Value.IsLockedTarget}
					{
						HasPriorityTarget:Set[TRUE]
					}

					; We have targets
					HasTargets:Set[TRUE]
				}
			}
			while ${This.Target:Next(exists)}
		}

		/* if we have priority targets just return until they're dead */
		if ${HasPriorityTarget}
		{
			Logger:Log["obj_Targets: Have priority target, returning 'til it's DEAD"]
			return
		}

		; Do we need to determine if we need to chain ?
		if ${Config.Combat.ChainSpawns} && ${CheckChain}
		{
			; Is there a chainable target? Is there a special or priority target?
			if ${HasChainableTarget} && !${HasSpecialTarget} && !${HasPriorityTarget}
			{
				Chaining:Set[TRUE]
			}

			; Special exception, if there is only 1 type its most likely
			; a chain in progress
			if !${HasMultipleTypes}
			{
				Chaining:Set[TRUE]
			}

			/* skip chaining if chain solo == false and we are alone */
			if !${Config.Combat.ChainSolo} && ${EVE.LocalsCount} == 1
			{
				;Logger:Log["NPC: We are alone.  Skip chaining!!"]
				Chaining:Set[FALSE]
			}

			if ${Chaining}
			{
				Logger:Log["NPC: Chaining Spawn"]
			}
			else
			{
				Logger:Log["NPC: Not Chaining Spawn"]
			}
			CheckChain:Set[FALSE]
		}

		; If there was a priority target, dont worry about targeting the rest
		if !${HasPriorityTarget} && ${This.Target:First(exists)}
		do
		{
		 switch ${This.Target.Value.GroupID}
		 {
			case GROUP_LARGECOLLIDABLEOBJECT
			case GROUP_LARGECOLLIDABLESHIP
			case GROUP_LARGECOLLIDABLESTRUCTURE
			case GROUP_SENTRYGUN
			case GROUP_CONCORDDRONE
			case GROUP_CUSTOMSOFFICIAL
			case GROUP_POLICEDRONE
			case GROUP_CONVOYDRONE
			case GROUP_CONVOY
			case GROUP_FACTIONDRONE
			case GROUP_BILLBOARD
			   continue
			   break
			Default
			   break
		 }

			variable bool DoTarget = FALSE
			if ${Chaining}
			{
				; We're chaining, only kill chainable spawns'
				if ${This.Target.Value.Group.Find["Battleship"](exists)}
				{
				   DoTarget:Set[TRUE]
				}
			}
			else
			{
				; Target everything
				DoTarget:Set[TRUE]
			}

			; override DoTarget to protect partially spawned chains
			if ${DoNotKillList.Contains[${This.Target.Value.ID}]}
			{
				DoTarget:Set[FALSE]
			}

			; Do we have to target this target?
			if ${DoTarget}
			{
				if !${Targeting.IsQueued[${This.Target.Value.ID}]}
				{
					Logger:Log["Queueing ${This.Target.Value.Name}"]
					Targeting:Queue[${This.Target.Value.ID},${Targeting.TYPE_HOSTILE}]
				}

				; Set the return value so we know we have targets
				HasTargets:Set[TRUE]
			}
			else
			{
				if !${DoNotKillList.Contains[${This.Target.Value.ID}]}
				{
					Logger:Log["NPC: Adding ${This.Target.Value.Name} (${This.Target.Value.ID}) to the \"do not kill list\"!"]
					DoNotKillList:Add[${This.Target.Value.ID}]
				}
				; Make sure (due to auto-targeting) that its not targeted
				if ${Targeting.IsQueued[${This.Target.Value.ID}]}
				{
					Targeting:Remove[${This.Target.Value.ID}]
				}
			}
		}
		while ${This.Target:Next(exists)}

		;if ${HasTargets} && ${Me.ActiveTarget(exists)}
		;{
		;	variable int OrbitDistance
		;	OrbitDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
		;	OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
		;	Me.ActiveTarget:Orbit[${OrbitDistance}]
		;}

		UpdateSucceeded:Set[${HasTargets}]
		return
	}
}
