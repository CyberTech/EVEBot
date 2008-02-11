#include defines.iss

#define ChainSpawns TRUE
#define SafespotBookmark "[safespotname]"

function main()
{
	variable cls_Belts Belts
	variable cls_Targets Targets
	variable cls_Modules Modules
	variable cls_Local LocalInformation
	variable cls_Safespot Safespot
	
	while TRUE
	{
		while ${LocalInformation.IsSafe}
		{
			; Make sure we're not cloaked
			Modules:ActivateCloak[FALSE]

			; Warp to the next belt
			Belts:NextBelt

			echo "Warping to belt ${Belts.Belt.Value.Name}"
			Belts.Belt.Value:WarpTo[0]

			; Wait till warp starts
			wait 50
			
			; Wait till warp ends
			while ${Me.ToEntity.Mode} == 3 && ${LocalInformation.IsSafe}
			{
				wait 20
			}

			; Reload just before targeting everything, the ship
			; has been through warp so we're sure that no weapons are still
			; active
			Modules:ReloadWeapons[TRUE]

			; Make sure we dropped out of warp
			wait 30
			
			; This will reset target information about the belt 
			; (its needed for chaining)
			Targets:ResetTargets

			; Before opening fire, lets see if there are any friendlies here
			if !${Targets.PC}
			while ${Targets.TargetNPCs} && ${LocalInformation.IsSafe}
			{
				; Make sure our hardeners are running
				Modules:ActivateHardeners
				
				; Reload the weapons -if- ammo is below 30% and they arent firing
				Modules:ReloadWeapons[FALSE]

				; Activate the weapons, the modules class checks if there's a target
				Modules:ActivateWeapons
				
				if ${Me.Ship.ShieldPct} < 80
				{
					; Turn on the shield booster
					Modules:ActivateShieldBooster[TRUE]
				}
				
				if ${Me.Ship.ShieldPct} > 98
				{
					; Turn off the shield booster
					Modules:ActivateShieldBooster[FALSE]
				}

				; Wait 2 seconds
				wait 20
			}
		}
	
		if !${LocalInformation.IsSafe}
		{
			; Are we at the safespot and not warping?
			if !${Safespot.IsAtSafespot} && ${Me.ToEntity.Mode} != 3
			{
				echo "Enemy in local and not at safespot! Warping to safety!"
				Safespot:WarpTo
				
				; Wait 3 seconds
				wait 30
			}
			
			if ${Safespot.IsAtSafespot}
			{
				Modules:ActivateCloak[TRUE]
				
				; Wait 1 minute, there was hostiles so who cares how long we wait
				wait 600
			}
		}
		
		; Wait 2 seconds
		wait 20
	}
}

objectdef cls_Safespot
{

	method Initialize()
	{
		if ${EVE.Bookmark[SafespotBookmark](exists)}
		{
			echo "Safespot found: ${EVE.Bookmark[SafespotBookmark]}" 
		}
		else
		{
			echo "Safespot not found!"
		}
	}

	member:bool IsAtSafespot()
	{
		; Are we within 150km off th bookmark?
		if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${EVE.Bookmark[SafespotBookmark].X}, ${EVE.Bookmark[SafespotBookmark].Y}, ${EVE.Bookmark[SafespotBookmark].Z}]} < 150000
		{
			return TRUE
		}
		
		return FALSE
	}
	
	method WarpTo()
	{
		EVE.Bookmark[SafespotBookmark]:WarpTo[0]
	}
}

objectdef cls_Local
{
	variable index:int SafeAllianceIDs
	variable index:int SafeCorporationIDs

	method Initialize()
	{
		; Aliance ID
		SafeAllianceIDs:Insert[0]
		; Corp ID
		SafeCorporationIDs:Insert[0]
	}
	
	member:bool IsSafe()
	{
		variable index:pilot Pilots
		variable iterator Pilot
	
		EVE:DoGetPilots[Pilots]
		Pilots:GetIterator[Pilot]

		if ${Pilot:First(exists)}
		do
		{
			variable bool Safe
			Safe:Set[FALSE]
			
			variable iterator SafeAllianceID
			SafeAllianceIDs:GetIterator[SafeAllianceID]
			
			if ${SafeAllianceID:First(exists)}
			do
			{
				if ${SafeAllianceID.Value} == ${Pilot.Value.AllianceID}
				{
					Safe:Set[TRUE]
				}
			}
			while ${SafeAllianceID:Next(exists)}
			
			variable iterator SafeCorporationID
			SafeCorporationIDs:GetIterator[SafeCorporationID]
			
			if ${SafeCorporationID:First(exists)}
			do
			{
				if ${SafeCorporationID.Value} == ${Pilot.Value.CorporationID}
				{
					Safe:Set[TRUE]
				}
			}
			while ${SafeCorporationID:Next(exists)}
			
			if !${Safe}
			{
				echo "Enemy in local: ${Pilot.Value.Name} [${Pilot.Value.Corporation}|${Pilot.Value.CorporationID}][${Pilot.Value.Alliance}|${Pilot.Value.AllianceID}]"
				return FALSE
			}
		}
		while ${Pilot:Next(exists)}
		
		return TRUE
	}
}

objectdef cls_Modules
{
	variable index:module Modules

	variable index:module Weapons
	
	variable index:module ShieldBoosters
	variable index:module ArmorRepairers
	
	variable index:module Hardeners
	
	variable index:module Cloaks

	method Initialize()
	{
		Me.Ship:DoGetModules[Modules]
		
		variable iterator Module
		Modules:GetIterator[Module]
		
		if ${Module:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${Module.Value.ToItem.GroupID}]
		
			switch ${GroupID}
			{
				case GROUPID_SHIELD_BOOSTER
					echo "Shield booster ${Module.Value.ToItem.Name} found..."
					ShieldBoosters:Insert[${Module.Value}]
					continue

				case GROUPID_ARMOR_REPAIRERS
					echo "Armor repairer ${Module.Value.ToItem.Name} found..."
					ArmorRepairers:Insert[${Module.Value}]
					continue
					
				case GROUPID_SHIELD_HARDENERS
				case GROUPID_ARMOR_HARDENERS
					echo "Active hardener ${Module.Value.ToItem.Name} found..."
					Hardeners:Insert[${Module.Value}]
					continue
					
				case GROUPID_MISSILE_LAUNCHER_CRUISE
				case GROUPID_MISSILE_LAUNCHER_ROCKET 
				case GROUPID_MISSILE_LAUNCHER_SIEGE
				case GROUPID_MISSILE_LAUNCHER_STANDARD
				case GROUPID_MISSILE_LAUNCHER_HEAVY
					echo "Weapon ${Module.Value.ToItem.Name} found..."
					Weapons:Insert[${Module.Value}]
					continue
					
				case GROUPID_CLOAK
					echo "Cloak ${Module.Value.ToItem.Name} found..."
					Cloaks:Insert[${Module.Value}]
					continue
			}
		}
		while ${Module:Next(exists)}
	}
	
	method ReloadWeapons(bool force)
	{
		variable bool NeedReload = FALSE

		variable iterator Weapon
		Weapons:GetIterator[Weapon]

		if ${Weapon:First(exists)}
		do
		{
			if !${Weapon.Value.IsActive} && !${Weapon.Value.IsChangingAmmo} && !${Weapon.Value.IsReloadingAmmo}
			{
				; Sometimes this value can be NULL
				if !${Weapon.Value.MaxCharges(exists)}
				{
					echo "Sanity check failed, weapon has no MaxCharges!"
					return
				}
			
				; Has ammo been used?
				if ${Weapon.Value.CurrentCharges} != ${Weapon.Value.MaxCharges}
				{
					; Force reload ?
					if ${force}
					{
						; Yes, reload
						NeedReload:Set[TRUE]
					}
					else
					{
						; Is there still more then 30% ammo available?
						if ${Math.Calc[${Weapon.Value.CurrentCharges}/${Weapon.Value.MaxCharges}]} < 0.3
						{
							; No, reload
							NeedReload:Set[TRUE]
						}
					}
				}
			}
		}
		while ${Weapon:Next(exists)}
		
		if ${NeedReload}
		{
			echo "Reloading weapons..."
			EVE:Execute[CmdReloadAmmo]
		}
	}
		
	method ActivateWeapons()
	{
		if ${Me.GetTargets} == 0
		{
			;echo "No target locked, cant activate weapons"
			return
		}
	
		variable iterator Weapon
		Weapons:GetIterator[Weapon]

		if ${Weapon:First(exists)}
		do
		{
			if !${Weapon.Value.IsActive} && !${Weapon.Value.IsChangingAmmo} && !${Weapon.Value.IsReloadingAmmo}
			{
				Weapon.Value:Click
			}
		}
		while ${Weapon:Next(exists)}
	}
	
	method ActivateHardeners()
	{
		variable iterator Module
		Hardeners:GetIterator[Module]

		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive}
			{
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method ActivateCloak(bool activate)
	{
		variable iterator Module
		Cloaks:GetIterator[Module]

		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && ${activate}
			{
				echo "Cloaking..."
				Module.Value:Click
			}

			if ${Module.Value.IsActive} && !${activate}
			{
				echo "Uncloaking..."
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}
	
	method ActivateShieldBooster(bool activate)
	{
		variable iterator Module
		ShieldBoosters:GetIterator[Module]

		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && ${activate}
			{
				echo "Turning on shield booster..."
				Module.Value:Click
			}

			if ${Module.Value.IsActive} && !${activate}
			{
				echo "Turning off shield booster..."
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}
}

objectdef cls_Targets
{
	variable index:string PriorityTargets
	variable iterator PriorityTarget
	
	variable index:string ChainTargets
	variable iterator ChainTarget
	
	variable index:string SpecialTargets
	variable iterator SpecialTarget
	
	variable bool CheckChain
	variable bool Chaining
	
	method Initialize()
	{
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
			echo "No targets found..."
			return FALSE
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
		if ChainSpawns && ${CheckChain}
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

objectdef cls_Belts
{
	variable index:entity Belts
	variable iterator Belt

	method Initialize()
	{
		EVE:DoGetEntities[Belts, GroupID, GROUPID_ASTEROID_BELT]
		Belts:GetIterator[Belt]

		variable int Counter

		Counter:Set[0]
		if ${Belt:First(exists)}
		do
		{
			Counter:Inc[1]
		}
		while ${Belt:Next(exists)}

		echo "${Counter} belts found..."
	}

	method NextBelt()
	{
		if !${Belt:Next(exists)}
			Belt:First(exists)

		return
	}
}