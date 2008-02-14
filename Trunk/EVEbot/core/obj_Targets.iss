/*
Officer spawns appear in their home region, or in any region where their 
faction normally appears, but *only* in systems with -0.8 or below true 
sec rating.

Faction: Guristas/Pithi/Dread Guristas
Home Region: Venal
Officers:
Estamel
Vepas
Thon
Kaikka


Faction: Angels/Gisi/Domination
Home Region: Curse
Officers:
Tobias
Gotan
Hakim
Mizuro

Faction: Serpentis/Coreli/Shadow:
Home Region: Fountain
Officers:
Cormack
Setele
Tuvan
Brynn

Faction: Sanshas/Centi/True Sansha:
Home Region: Stain
Officers:
Chelm
Vizan
Selynne
Brokara

Faction: Blood/Corpi/Dark Blood:
Home Region: Not sure actually... Delve?
Officers:
Draclira
Ahremen
Raysere
Tairei
*/
objectdef obj_Targets
{
	variable index:string PriorityTargets
	variable iterator PriorityTarget
	
	variable index:string ChainTargets
	variable iterator ChainTarget
	
	variable index:string SpecialTargets
	variable iterator SpecialTarget
	
	variable bool CheckChain
	variable bool Chaining
	variable int TrueMaxTargetRange
	
	method Initialize()
	{
		TrueMaxTargetRange:Set[${Me.Ship.MaxTargetRange}]
		
		; TODO - load this all from XML files
	
		; Priority targets will be targeted (and killed) 
		; before other targets, they often do special things
		; which we cant use (scramble / web / damp / etc)
		; You can specify the entire rat name, for example 
		; leave rats that dont scramble which would help
		; later when chaining gets added
		PriorityTargets:Insert["Dire Guristas"]
		PriorityTargets:Insert["Arch Angel"]
		PriorityTargets:Insert["Sansha's Loyal"]

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
		;ChainTargets:Insert["Serpentis Flotilla Admiral"]
		;ChainTargets:Insert["Serpentis Vice Admiral"]
		;ChainTargets:Insert["Serpentis Admiral"]
		ChainTargets:Insert["Serpentis Grand Admiral"]
		ChainTargets:Insert["Serpentis High Admiral"]
		ChainTargets:Insert["Serpentis Lord Admiral"]
				
		; Special targets will (eventually) trigger an alert
		; This should include haulers / faction / officers
		SpecialTargets:Insert["Dread Guristas"]
		SpecialTargets:Insert["Estamel Tharchon"]
		SpecialTargets:Insert["Kaikka Peunato"]
		SpecialTargets:Insert["Thon Eney"]
		SpecialTargets:Insert["Vepas Minimala"]
		SpecialTargets:Insert["Courier"]
		SpecialTargets:Insert["Ferrier"]
		SpecialTargets:Insert["Gatherer"]
		SpecialTargets:Insert["Harvester"]
		SpecialTargets:Insert["Loader"]
		SpecialTargets:Insert["Bulker"]
		SpecialTargets:Insert["Carrier"]
		SpecialTargets:Insert["Convoy"]
		SpecialTargets:Insert["Trailer"]
		SpecialTargets:Insert["Transporter"]
		SpecialTargets:Insert["Trucker"]
		SpecialTargets:Insert["Cormack"]
		SpecialTargets:Insert["Setele"]
		SpecialTargets:Insert["Tuvan"]
		SpecialTargets:Insert["Brynn"]
		SpecialTargets:Insert["Shadow"]

		; Get the iterators
		PriorityTargets:GetIterator[PriorityTarget]
		ChainTargets:GetIterator[ChainTarget]
		SpecialTargets:GetIterator[SpecialTarget]
	}
	
	method ResetTargets()
	{
		CheckChain:Set[TRUE]
		Chaining:Set[FALSE]
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

	member:bool IsChainTarget(string name)
	{
			; Loop through the chainable targets
			if ${ChainTarget:First(exists)}
			do
			{
				if ${name.Find[${ChainTarget.Value}]} > 0
				{
					return TRUE
				}
			}
			while ${ChainTarget:Next(exists)}
			
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

	member:bool TargetNPCs()
	{
		variable index:entity Targets
		variable iterator Target

		EVE:DoGetEntities[Targets, CategoryID, CATEGORYID_ENTITY, radius, ${Me.Ship.MaxTargetRange}]
		Targets:GetIterator[Target]

		if !${Target:First(exists)}
		{
			if ${Me.Ship.MaxTargetRange} < ${TrueMaxTargetRange}
			{
				EVE:DoGetEntities[Targets, CategoryID, CATEGORYID_ENTITY, radius, ${TrueMaxTargetRange}]
				Targets:GetIterator[Target]

				if !${Target:First(exists)}
				{
					echo "No targets found..."
					return FALSE
				}
				else
				{
					echo "Damped, cant target..."
					return TRUE
				}
			}
			else
			{
				echo "No targets found..."
				return FALSE
			}
		}

		if ${Me.Ship.MaxLockedTargets} == 0
		{
			echo "Jammed, cant target..."
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

		SpecialTargetFlag:Set[FALSE]
		
		variable int TypeID
		TypeID:Set[${Target.Value.TypeID}]
		do
		{
			; If the Type ID is different then there's more then 1 type in the belt
			if ${TypeID} != ${Target.Value.TypeID}
			{
				HasMultipleTypes:Set[TRUE]
			}
			
			; Check for a chainable target
			if ${This.IsChainTarget[${Target.Value.Name}]}
			{
				HasChainableTarget:Set[TRUE]
			}
			
			; Check for a special target
			if ${This.IsSpecialTarget[${Target.Value.Name}]}
			{
				HasSpecialTarget:Set[TRUE]
				SpecialTargetFlag:Set[TRUE]
			}
		
			; Loop through the priority targets
			if ${This.IsPriorityTarget[${Target.Value.Name}]}
			{
				; Yes, is it locked?
				if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
				{
					; No, report it and lock it.
					echo "Locking priority target ${Target.Value.Name}"
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
		
		; Do we need to determin if we need to chain ?
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

			CheckChain:Set[FALSE]
		}

		; If there was a priority target, dont worry about targeting the rest
		if !${HasPriorityTarget} && ${Target:First(exists)}
		do
		{
			variable bool DoTarget = FALSE
			if ${Chaining}
			{
				; We're chaining, only kill chainable spawns
				DoTarget:Set[${This.IsChainTarget[${Target.Value.Name}]}]
			}
			else
			{
				; Target everything
				DoTarget:Set[TRUE]
			}
			
			; Do we have to target this target?
			if ${DoTarget}
			{
				if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
				{
					echo "Locking ${Target.Value.Name}"
					Target.Value:LockTarget
				}
				
				; Set the return value so we know we have targets
				HasTargets:Set[TRUE]
			}
			else
			{
				; Make sure (due to auto-targeting) that its not targeted
				if ${Target.Value.IsLockedTarget}
				{
					Target.Value:UnlockTarget
				}
			}
		}
		while ${Target:Next(exists)}
		
		if ${HasTargets} && ${Me.ActiveTarget(exists)}
		{
			variable int OrbitDistance
			OrbitDistance:Set[${Math.Calc[${Me.Ship.MaxTargetRange}*0.40/1000].Round}]
			OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
			Me.ActiveTarget:Orbit[${OrbitDistance}]
		}
		
		return ${HasTargets}
	}
	
	member:bool PC()
	{
		variable index:entity Targets
		variable iterator Target

		EVE:DoGetEntities[Targets, CategoryID, CATEGORYID_SHIP]
		Targets:GetIterator[Target]
		
		if ${Target:First(exists)}
		do
		{
			if ${Target.Value.OwnerID} != ${Me.CharID}
			{
				; A player is already present here !
				echo "Player found ${Target.Value.Owner}"
				return TRUE
			}
		}
		while ${Target:Next(exists)}
		
		; No other players around 
		return FALSE
	}
}
