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

objectdef obj_Targets
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

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
	variable int  TotalSpawnValue

	variable bool m_SpecialTargetPresent
	variable bool m_SpecialTargettoLootPresent
	variable string m_SpecialTargetName
	variable string m_SpecialTargetToLootName
	variable set DoNotKillList
	variable bool CheckedSpawnValues = FALSE
	
	;	Used to track entities that are locked or being locked
	variable index:entity LockedOrLocking


	method Initialize()
	{
		m_SpecialTargetPresent:Set[FALSE]
		m_SpecialTargetToLootPresent:Set[FALSE]

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

		PriorityTargets:Insert["Guardian Agent"]		    /* web/scram */
		PriorityTargets:Insert["Guardian Initiate"]		    /* web/scram */
		PriorityTargets:Insert["Guardian Scout"]		    /* web/scram */
		PriorityTargets:Insert["Guardian Spy"]			    /* web/scram */
		PriorityTargets:Insert["Crook Watchman"]		    /* damp */
		PriorityTargets:Insert["Guardian Watchman"]		    /* damp */
		PriorityTargets:Insert["Serpentis Watchman"]	    /* damp */
		PriorityTargets:Insert["Crook Patroller"]		    /* damp */
		PriorityTargets:Insert["Guardian Patroller"]	    /* damp */
		PriorityTargets:Insert["Serpentis Patroller"]	    /* damp */

		PriorityTargets:Insert["Elder Blood Upholder"]	    /* web/scram */
		PriorityTargets:Insert["Elder Blood Worshipper"]    /* web/scram */
		PriorityTargets:Insert["Elder Blood Follower"]	    /* web/scram */
		PriorityTargets:Insert["Elder Blood Herald"]	    /* web/scram */
		PriorityTargets:Insert["Blood Wraith"]	            /* web/scram */
		PriorityTargets:Insert["Blood Disciple"]	        /* web/scram */

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
		;ChainTargets:Insert["Serpentis Port Admiral"]	/* 800k */
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

	member:bool SpecialTargetToLootPresent()
	{
		return ${m_SpecialTargetToLootPresent}
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

	member:bool TargetNPCs()
	{
		variable index:entity Targets
		variable iterator Target

		/* MyShip.MaxTargetRange contains the (possibly) damped value */
		if ${Ship.TypeID} == TYPE_RIFTER
		{
			EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= 100000"]
		}
		else
		{
			EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= ${MyShip.MaxTargetRange}"]
		}
		Targets:GetIterator[Target]

		if !${Target:First(exists)}
		{
			if ${Ship.IsDamped}
			{	/* Ship.MaxTargetRange contains the maximum undamped value */
				EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY && Distance <= ${Ship.MaxTargetRange}"]
				Targets:GetIterator[Target]

				if !${Target:First(exists)}
				{
					UI:UpdateConsole["No targets found..."]
					return FALSE
				}
				else
				{
					UI:UpdateConsole["Damped, cant target..."]
					return TRUE
				}
			}
			else
			{
				UI:UpdateConsole["No targets found..."]
				return FALSE
			}
		}

		if ${MyShip.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
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
		m_SpecialTargetToLootPresent:Set[FALSE]

      ; Determine the total spawn value
      if ${Target:First(exists)} && !${This.CheckedSpawnValues}
      {
		This.CheckedSpawnValues:Set[TRUE]
         do
         {
         	variable int pos
         	variable string NPCName
         	variable string NPCGroup
         	variable string NPCShipType

         	NPCName:Set[${Target.Value.Name}]
			NPCGroup:Set[${Target.Value.Group}]
			pos:Set[1]
        	while ${NPCGroup.Token[${pos}, " "](exists)}
        	{
				;echo ${NPCGroup.Token[${pos}, " "]}
        		NPCShipType:Set[${NPCGroup.Token[${pos}, " "]}]
        		pos:Inc
        	}
            UI:UpdateConsole["NPC: ${NPCName}(${NPCShipType}) ${EVEBot.ISK_To_Str[${Target.Value.Bounty}]}"]

            ;UI:UpdateConsole["DEBUG: Type: ${Target.Value.Type}(${Target.Value.TypeID})"]
            ;UI:UpdateConsole["DEBUG: Category: ${Target.Value.Category}(${Target.Value.CategoryID})"]

            switch ${Target.Value.GroupID}
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

               default
                  break
            }
			if ${NPCGroup.Find["Battleship"](exists)}
			{
            	This.TotalSpawnValue:Inc[${Target.Value.Bounty}]
            }
         }
         while ${Target:Next(exists)}
         UI:UpdateConsole["NPC: Battleship Value is ${EVEBot.ISK_To_Str[${This.TotalSpawnValue}]}"]
      }

      if ${This.TotalSpawnValue} >= ${Config.Combat.MinChainBounty}
      {
         ;UI:UpdateConsole["NPC: Spawn value exceeds minimum.  Should chain this spawn."]
         HasChainableTarget:Set[TRUE]
      }

		if ${Target:First(exists)}
		{
			variable int TypeID
			TypeID:Set[${Target.Value.TypeID}]
			do
			{
	            switch ${Target.Value.GroupID}
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

	               default
	                  break
	            }

				; If the Type ID is different then there's more then 1 type in the belt
				if ${TypeID} != ${Target.Value.TypeID}
				{
					HasMultipleTypes:Set[TRUE]
				}

				; Check for a special target
				if ${This.IsSpecialTarget[${Target.Value.Name}]}
				{
					HasSpecialTarget:Set[TRUE]
					m_SpecialTargetPresent:Set[TRUE]
					m_SpecialTargetName:Set[${Target.Value.Name}]
					if ${This.IsSpecialTargetToLoot[${Target.Value.Name}]}
					{
						m_SpecialTargetToLootPresent:Set[TRUE]
						m_SpecialTargetToLootName:Set[${Target.Value.Name}]
					}
				}

				; Loop through the priority targets
				if ${This.IsPriorityTarget[${Target.Value.Name}]}
				{
					; Yes, is it locked?
					if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
					{
						; No, report it and lock it.
						UI:UpdateConsole["Locking priority target ${Target.Value.Name}"]
						Target.Value:LockTarget
					}

					; By only saying there's priority targets when they arent
					; locked yet, the npc bot will target non-priority targets
					; after it has locked all the priority targets
					; (saves time once the priority targets are dead)
					if !${Target.Value.IsLockedTarget}
					{
						HasPriorityTarget:Set[TRUE]
					}

					; We have targets
					HasTargets:Set[TRUE]
				}
			}
			while ${Target:Next(exists)}
		}

		; Determine if we need to chain
		if ${Config.Combat.ChainSpawns} && ${CheckChain}
		{
			; Is there a chainable target? Is there a special or priority target?
			if ${HasChainableTarget} && !${HasSpecialTarget} && !${HasPriorityTarget}
			{
	        	UI:UpdateConsole["NPC: Chaining Spawn"]
				Chaining:Set[TRUE]
			}

			; Special exception, if there is only 1 type its most likely a chain in progress
			if !${HasMultipleTypes} && !${HasPriorityTarget}
			{
	        	UI:UpdateConsole["NPC: Chaining Spawn"]
				Chaining:Set[TRUE]
			}

			if ${HasSpecialTarget}
			{
				UI:UpdateConsole["NPC: Not Chaining: Special targets present"]
				Chaining:Set[FALSE]
			}

			if ${HasPriorityTarget}
			{
				UI:UpdateConsole["NPC: Not Chaining: EWar Rats present"]
				Chaining:Set[FALSE]
			}

			;skip chaining if chain solo == false and we are alone
			if !${Config.Combat.ChainSolo} && ${EVE.LocalsCount} == 1
			{
				UI:UpdateConsole["NPC: Not Chaining: ChainSolo disabled"]
				Chaining:Set[FALSE]
			}

			CheckChain:Set[FALSE]
		}

		; If there was a priority target, dont worry about targeting the rest
		if !${HasPriorityTarget} && ${Target:First(exists)}
		do
		{
			switch ${Target.Value.GroupID}
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

				default
					break
			}

			variable bool DoTarget = FALSE
			if ${Chaining}
			{
				; We're chaining, only kill chainable spawns'
                if ${Target.Value.Group.Find["Battleship"](exists)}
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
            if ${DoNotKillList.Contains[${Target.Value.ID}]}
            {
				DoTarget:Set[FALSE]
            }

			; Do we have to target this target?
			if ${DoTarget}
			{
				if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
				{
					if ${Me.TargetCount} < ${Ship.MaxLockedTargets}
					{
						if ${Ship.TypeID} == TYPE_RIFTER
						{
							if ${Target.Value.Distance} > ${MyShip.MaxTargetRange}
							{
								if ${Me.ToEntity.Approaching.NotEqual[NULL]}
								{
									Target.Value:Approach
								}
							}
						}
						else
						{
							UI:UpdateConsole["Locking ${Target.Value.Name}"]
							Target.Value:LockTarget
						}
					}
				}

				; Set the return value so we know we have targets
				HasTargets:Set[TRUE]
			}
			else
			{
				if !${DoNotKillList.Contains[${Target.Value.ID}]}
				{
					UI:UpdateConsole["NPC: Adding ${Target.Value.Name} (${Target.Value.Group})(${Target.Value.ID}) to the \"do not kill list\"!"]
					DoNotKillList:Add[${Target.Value.ID}]
				}
				; Make sure (due to auto-targeting) that its not targeted
				if ${Target.Value.IsLockedTarget}
				{
					Target.Value:UnlockTarget
				}
			}
		}
		while ${Target:Next(exists)}

		;if ${HasTargets} && ${Me.ActiveTarget(exists)}
		;{
		;	variable int OrbitDistance
		;	OrbitDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
		;	OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
		;	Me.ActiveTarget:Orbit[${OrbitDistance}]
		;}
		
		;if ${HasTargets} && ${Me.ActiveTarget(exists)}
		;{
		;	variable int KeepAtRangeDistance
		;	KeepAtRangeDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
		;	KeepAtRangeDistance:Set[${Math.Calc[${KeepAtRangeDistance}*1000]}]
		;	Me.ActiveTarget:KeepAtRange[${KeepAtRangeDistance}]
		;}

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

	member:int64 Rat()
	{
		variable index:entity tgtIndex
		variable iterator tgtIterator

		EVE:QueryEntities[tgtIndex, "CategoryID = CATEGORYID_ENTITY"]

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
					UI:UpdateConsole["ALERT: Targeting: ${tgtIterator.Value.Group}"]
					return ${tgtIterator.Value.ID}
					break
			}
		}
		while ${tgtIterator:Next(exists)}

		; No NPCs around
		return -1
	}
	
	method UpdateLockedAndLockingTargets()
	{
		variable index:entity Targets
		variable iterator Target

		LockedOrLocking:Clear
		EVE:QueryEntities[Targets]
		Targets:GetIterator[Target]
		if ${Target:First(exists)}
			do
			{
				if ${Target.Value.IsLockedTarget} || ${Target.Value.BeingTargeted}
					LockedOrLocking:Insert[${Target.Value}]
			}
			while ${Target:Next(exists)}
	}
	member:int LockedAndLockingTargets()
	{
		variable index:entity Targets
		variable iterator Target

		LockedOrLocking:Clear
		EVE:QueryEntities[Targets]
		Targets:GetIterator[Target]
		if ${Target:First(exists)}
			do
			{
				if ${Target.Value.IsLockedTarget} || ${Target.Value.BeingTargeted}
					LockedOrLocking:Insert[${Target.Value}]
			}
			while ${Target:Next(exists)}
		return ${LockedOrLocking.Used}
	}
}
