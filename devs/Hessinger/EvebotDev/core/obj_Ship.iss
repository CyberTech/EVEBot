/*
	Ship class
	
	Main object for interacting with the ship and its functions
	
	-- CyberTech
	
*/

objectdef obj_Drones
{
	variable index:int ActiveDroneIDList
	variable int CategoryID_Drones = 18
	
	method Initialize()
	{
		call UpdateHudStatus "obj_Drones: Initialized"
	}

	method LaunchAll()
	{
		call UpdateHudStatus "Launching drones..."
		Me.Ship:LaunchAllDrones
	}
		
	member:int DronesInSpace()
	{
		return ${Me.GetActiveDroneIDs[This.ActiveDroneIDList]}
	}
   
	function ReturnAllToDroneBay()
	{
		while ${This.DronesInSpace} > 0
		{
			UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
			EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			wait 50
		}
	}
}

objectdef obj_Ship
{
	variable int MODE_WARPING = 3
	
	variable int FrameCounter
	variable int Calculated_MaxLockedTargets
	variable float BaselineUsedCargo
	variable bool CargoIsOpen
	variable index:module ModuleList
	variable index:module ModuleList_MiningLaser
	variable index:module ModuleList_CombatWeapon
	variable index:module ModuleList_ActiveResists
	variable index:module ModuleList_Regen_Shield
	variable index:module ModuleList_Regen_Armor
	variable index:module ModuleList_AB_MWD
	variable index:module ModuleList_Passive

	variable iterator ModulesIterator

	variable obj_Drones Drones

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		This:CalculateMaxLockedTargets
		call UpdateHudStatus "obj_Ship: Initialized"
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		FrameCounter:Inc

		variable int IntervalInSeconds = 8
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			if ${Combat.InCombat}== FALSE
		 	{		 		
				if (${Me.Ship.ShieldPct} < 100 && ${Me.GetTargetedBy} > 0)
				{
					Combat.InCombat:Set[TRUE]
					call UpdateHudStatus "Entered Combat"
					call Combat.Fight
				}
			}
			This:ValidateModuleTargets
			FrameCounter:Set[0]
		}

	}
	
	member:float CargoMinimumFreeSpace()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		return ${Math.Calc[${Me.Ship.CargoCapacity}*0.01]}
	}
	
	member:float CargoFreeSpace()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
		if ${Me.Ship.UsedCargoCapacity} < 0
		{
			return ${Me.Ship.CargoCapacity}
		}
		return ${Math.Calc[${Me.Ship.CargoCapacity}-${Me.Ship.UsedCargoCapacity}]}
	}

	method UpdateModuleList()
	{
		if ${Me.InStation}
		{
			; GetModules cannot be used in station as of 07/15/2007
			return
		}
		
		This.ModuleList:Clear
		This.ModuleList_MiningLaser:Clear
		This.ModuleList_CombatWeapon:Clear
		This.ModuleList_ActiveResists:Clear
		This.ModuleList_Regen_Shield:Clear
		This.ModuleList_Regen_Armor:Clear
		This.ModuleList_AB_MWD:Clear
		This.ModuleList_Passive:Clear

		Me.Ship:DoGetModules[This.ModuleList]
		
		if !${This.ModuleList.Used}
		{
			echo "DEBUG: obj_Ship:UpdateModuleList - No modules found"
			return
		}
	
		variable iterator Module

		echo "Module Inventory:"
		This.ModuleList:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${Module.Value.ToItem.GroupID}]
			variable int TypeID
			TypeID:Set[${Module.Value.ToItem.TypeID}]

			;echo "    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
			if !${Module.Value.IsActivatable}
			{
				This.ModuleList_Passive:Insert[${Module.Value}]
				continue
			}

			;echo "          Group: ${Module.Value.ToItem.Group}  ${GroupID}"
			;echo "          Type: ${Module.Value.ToItem.Type}  ${TypeID}"
			
			if ${Module.Value.MiningAmount(exists)}
			{
				This.ModuleList_MiningLaser:Insert[${Module.Value}]
				continue
			}
			
			; TODO - Populate these arrays
			;This.ModuleList_CombatWeapon
			;This.ModuleList_ActiveResists
			;This.ModuleList_AB_MWD

			switch ${GroupID}
			{
				case GROUPID_FREQUENCY_MINING_LASER
					break
				case GROUPID_SHIELD_BOOSTER
					This.ModuleList_Regen_Shield:Insert[${Module.Value}]
					continue
				case GROUPID_AFTERBURNER
					This.ModuleList_AB_MWD:Insert[${Module.Value}]
					continue
				default
					continue
			}

		}
		while ${Module:Next(exists)}

		echo "Passive Modules:"
		This.ModuleList_Passive:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			echo "    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
		}
		while ${Module:Next(exists)}

		echo "Mining Modules:"
		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			echo "    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
		}
		while ${Module:Next(exists)}

		echo "Shield Regen Modules:"
		This.ModuleList_Regen_Shield:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			echo "    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
		}
		while ${Module:Next(exists)}

		echo "AfterBurner Modules:"
		This.ModuleList_AB_MWD:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			echo "    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
		}
		while ${Module:Next(exists)}
		if ${This.ModuleList_AB_MWD.Used} > 1
		{
			call UpdateHudStatus "Warning: More than 1 Afterburner or MWD was detected, I will only use the first one."
		}
	}
	
	method UpdateBaselineUsedCargo()
	{
		; Store the used cargo space as the cargo hold exists NOW, with whatever is leftover in it.
		This.BaselineUsedCargo:Set[${Me.Ship.UsedCargoCapacity.Ceil}]
	}
		
	member:int MaxLockedTargets()
	{
		This:CalculateMaxLockedTargets[]
		return ${This.Calculated_MaxLockedTargets}
	}
	
	; "Safe" max locked targets is defined as max locked targets - 2
	; for a buffer of targets so that hostiles may be targeted.
	; Always return at least 1
	member:int SafeMaxLockedTargets()
	{
		variable int result
		result:Set[${This.Calculated_MaxLockedTargets}]
		if ${result} > 2
		{
			result:Dec
		}
		if ${result} > 2
		{
			result:Dec
		}		
		return ${result}
	}

	member:int TotalMiningLasers()
	{	
		if !${Me.Ship(exists)}
		{
			return 0
		}

		return ${This.ModuleList_MiningLaser.Used}
	}
	
	member:int TotalActivatedMiningLasers()
	{
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable int count
		variable iterator Module
		
		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} || \
				${Module.Value.IsGoingOnline} || \
				${Module.Value.IsDeactivating} || \
				${Module.Value.IsChangingAmmo} || \
				${Module.Value.IsReloadingAmmo}
			{
				count:Inc
			}
		}
		while ${Module:Next(exists)}

		return ${count}		
	}

	; Note: This doesn't return ALL the mining amounts, just one.
	; It should perhaps be changed to return the largest, or the smallest, or an average.
	member:float MiningAmountPerLaser()
	{
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		{
			if ${Module.Value.SpecialtyCrystalMiningAmount(exists)}
			{
				return ${Module.Value.SpecialtyCrystalMiningAmount}
			}
			else
			{
				return ${Module.Value.MiningAmount}
			}
		}
		return 0
	}

	; Note: This doesn't return ALL the mining amounts, just one.
	; Returns the laser mining range minus 10%
	member:int OptimalMiningRange()
	{
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		{
			return ${Math.Calc[${Module.Value.OptimalRange}*0.90]}
		}

		return 0
	}

	; Returns the loaded crystal in a mining laser, given the slot name ("HiSlot0"...)
	member:string LoadedMiningLaserCrystal(string SlotName)
	{
		if !${Me.Ship(exists)}
		{
			return "NOCHARGE"
		}

		
		if ${Me.Ship.Module[${SlotName}].Charge(exists)}
		{
			return ${Me.Ship.Module[${SlotName}].Charge.Name.Token[1, " "]}
		}
		return "NOCHARGE"
		
		variable iterator Module

		This.ModuleList_MiningLaser:GetIteratorModule]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.SpecialtyCrystalMiningAmount(exists)}
			{
				continue
			}
			if ${Module.Value.ToItem.Slot.Equal[${SlotName}]} && \
				${Module.Value.Charge(exists)}
			{
				echo "obj_Ship:LoadedMiningLaserCrystal Returning ${Module.Value.Charge.Name.Token[1, " "]}
				return ${Module.Value.Charge.Name.Token[1, " "]}
			}
		}
		while ${Module:Next(exists)}

		return "NOCHARGE"
	}
	
	; Returns TRUE if we've got a laser mining this entity already
	member:bool IsMiningAstroidID(int EntityID)
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.LastTarget(exists)} && \ 
				${Module.Value.LastTarget.ID} == ${EntityID} && \
				( ${Module.Value.IsActive} || ${Module.Value.IsGoingOnline} )
			{
				return TRUE
			}
		}
		while ${Module:Next(exists)}
		
		return FALSE
	}		
	
	method UnlockAllTargets()
	{
		variable index:entity LockedTargets
		variable iterator Target

		Me:DoGetTargets[LockedTargets]
		LockedTargets:GetIterator[Target]

		if ${Target:First(exists)}
		do
		{
			Target.Value:UnlockTarget
		}
		while ${Target:Next(exists)}
	}

	method CalculateMaxLockedTargets()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		if ${Me.MaxLockedTargets(exists)} && ${Me.MaxLockedTargets} < ${Me.Ship.MaxLockedTargets}
		{
			Calculated_MaxLockedTargets:Set[${Me.MaxLockedTargets}]
		}
		else
		{
			Calculated_MaxLockedTargets:Set[${Me.Ship.MaxLockedTargets}]
		}		
	}

	function ChangeMiningLaserCrystal(string OreType, string SlotName)
	{
		; We might need to change loaded crystal
		variable string LoadedAmmo
	
		LoadedAmmo:Set[${This.LoadedMiningLaserCrystal[${SlotName}]}]
		if !${OreType.Find[${LoadedAmmo}](exists)}
		{
			echo "DEBUG: Current crystal in ${SlotName} is ${LoadedAmmo}, looking for ${OreType}"
			variable index:item CrystalList
			variable iterator CrystalIterator
			
			Me.Ship.Module[${SlotName}]:DoGetAvailableAmmo[CrystalList]
			
			CrystalList:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				variable string CrystalType
				CrystalType:Set[${CrystalIterator.Value.Name.Token[1, " "]}]
				
				;echo "DEBUG: ChangeMiningLaserCrystal Testing ${OreType} contains ${CrystalType}"
				if ${OreType.Find[${CrystalType}](exists)}
				{
					call UpdateHudStatus "Switching Crystal in ${SlotName} from ${LoadedAmmo} to ${CrystalIterator.Value.Name}"
					Me.Ship.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID},1]
					; This takes 2 seconds ingame, let's give it 50% more
					wait 30
					return
				}
			}
			while ${CrystalIterator:Next(exists)}
			call UpdateHudStatus  "Warning: No crystal found for ore type ${OreType}, efficiency reduced"
		}
	}
	
	; Validates that all targets of activated modules still exist
	; TODO - Add mid and low targetable modules, and high hostile modules, as well as just mining.
	method ValidateModuleTargets()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
		
		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} && \
				!${Module.Value.IsDeactivating} && \
				( !${Module.Value.LastTarget(exists)} || !${Entity[id,${Module.Value.LastTarget.ID}](exists)} )
			{
				echo "${Module.Value.ToItem.Slot}:${Module.Value.ToItem.Name} has no target: Deactivating"
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}

	}
	
	function ActivateFreeMiningLaser()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		if ${Me.ActiveTarget.CategoryID} != ${Asteroids.AsteroidCategoryID}
		{
			call UpdateHudStatus "Error: Mining Lasers may only be used on Asteroids"
			return
		}

		variable iterator Module
		
		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && \
				!${Module.Value.IsGoingOnline} && \
				!${Module.Value.IsDeactivating} && \
				!${Module.Value.IsChangingAmmo} &&\
				!${Module.Value.IsReloadingAmmo}
			{
				if ${Module.Value.SpecialtyCrystalMiningAmount(exists)}
				{
					variable string OreType
					OreType:Set[${Me.ActiveTarget.Name.Token[2,"("]}]
					OreType:Set[${OreType.Replace[(,]}]
					call This.ChangeMiningLaserCrystal "${OreType}" ${Module.Value.ToItem.Slot}
				}

				call UpdateHudStatus "Activating: ${Module.Value.ToItem.Slot}: ${Module.Value.ToItem.Name}"
				Module.Value:Click
				wait 25
				return
			}
			wait 10
		}
		while ${Module:Next(exists)}
	}

	; Approaches EntityID to within 10% of Distance, then stops ship.  Momentum will handle the rest.
	function Approach(int EntityID, int64 Distance)
	{
		if ${Entity[${EntityID}](exists)}
		{
			variable float64 OriginalDistance = ${Entity[${EntityID}].Distance}
			If ${OriginalDistance} < ${Distance}
			{
				return
			}
			
			call UpdateHudStatus "Approaching: ${Entity[${EntityID}].Name} - ${Math.Calc[(${Entity[${EntityID}].Distance} - ${Distance}) / ${Me.Ship.MaxVelocity}].Ceil} Seconds away"
			This:Activate_AfterBurner[]
			do
			{
				Entity[${EntityID}]:Approach
				wait 20

				if ${Entity[${EntityID}](exists)} && \
					${OriginalDistance} < ${Entity[${EntityID}].Distance}
				{
					echo "DEBUG: obj_Ship:Approach: ${Entity[${EntityID}].Name} is getting further away!  Is it moving? Are we stuck, or colliding?"
				}
			
				if ${Entity[${EntityID}](exists)} && \
					${OriginalDistance} == ${Entity[${EntityID}].Distance}
				{
					echo "DEBUG: obj_Ship:Approach: We may be stuck or colliding"
					return
				}
			}
			while ${Entity[${EntityID}].Distance} > ${Math.Calc[${Distance} + (${Distance}*0.05)]}
			EVE:Execute[CmdStopShip]
			This:Deactivate_AfterBurner[]
		}
	}			

	member IsCargoOpen()
	{
		if ${EVEWindow[MyShipCargo](exists)}
		{
			return TRUE
		}
		else
		{
			return FALSE
		}
	}
	
	function OpenCargo()
	{
		if !${This.IsCargoOpen}
		{
			call UpdateHudStatus "Opening Ship Cargohold"
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait WAIT_CARGO_WINDOW
			while !${This.IsCargoOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}

	function CloseCargo()
	{
		if ${This.IsCargoOpen}
		{
			call UpdateHudStatus "Closing Ship Cargohold"
			EVEWindow[MyShipCargo]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}

	function Undock()
	{
		call UpdateHudStatus "Undock: Waiting while ship exits the station (13 sec)"

		EVE:Execute[CmdExitStation]	
		wait WAIT_UNDOCK
		do
		{
			wait 10
		}
		while (${Me.InStation} || !${EVEWindow[Local](exists)})
		
		Config.Common:SetHomeStation[${Entity[CategoryID,3].Name}]
		
		Me:SetVelocity[100]
		wait 100

		This:UpdateModuleList[]
	}
	
	function WarpToID(int Id)
	{ 
		if (${Id} <= 0)
		{
			echo "Error: obj_Ship:WarpToID: Id is <= 0 (${Id})"
			return
		}
		
		if !${Entity[${Id}](exists)}
		{
			echo "Error: obj_Ship:WarpToID: No entity matched the ID given."
			return
		}

		call This.WarpPrepare
		while ${Entity[${Id}].Distance} >= 10000
		{
			call UpdateHudStatus "Warping to ${Entity[${Id}].Name}"
			Entity[${Id}]:WarpTo
			call This.WarpWait
		}
	}	

	function WarpToBookMark(bookmark Dest)
	{ 
		; TODO - doesn't work, need TLO Bookmark[ID] so we can access bookmarks by passing IDs
		call This.WarpPrepare
		call UpdateHudStatus "Warping to ${Dest.Value.Label}"
		Dest.Value:WarpTo
		call This.WarpWait
	}	

	function WarpPrepare()
	{ 
		call UpdateHudStatus "Preparing for warp"
		call This.Drones.ReturnAllToDroneBay
	}
	
	member:bool InWarp()
	{
		return (${Me.ToEntity.Mode} == 3)
	}
	
	function WarpWait()
	{
		; TODO - add check for InWarp== true at least once, to validate we did actually warp.
		wait 120
		while ${Me.ToEntity.Mode} == 3
		{
			wait 20
		}
	
		call UpdateHudStatus "Finished warping (hopefully)"
	}	

	method Activate_AfterBurner()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
		
		variable iterator Module
		
		This.ModuleList_AB_MWD:GetIterator[Module]
		if ${Module:First(exists)}
		{
			if !${Module.Value.IsActive}
			{
				call UpdateHudStatus "Activating ${Module.Value.ToItem.Name}"
				Module.Value:Click
			}
		}
	}

	method Deactivate_AfterBurner()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
		
		variable iterator Module
		
		This.ModuleList_AB_MWD:GetIterator[Module]
		if ${Module:First(exists)}
		{
			if ${Module.Value.IsActive}
			{
				call UpdateHudStatus "Deactivating ${Module.Value.ToItem.Name}"
				Module.Value:Click
			}
		}
	}

	method Activate_Shield_Booster()
	{
		if !${Me.Ship(exists)}
		{
			return
		}
		
		variable iterator Module
		
		This.ModuleList_Regen_Shield:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive}
			{
				call UpdateHudStatus "Activating ${Module.Value.ToItem.Name}"
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	function LockTarget(int64 TargetID)
	{
		if ${Entity[${TargetID}](exists)}
		{
			call UpdateHudStatus "Locking ${Entity[${TargetID}].Name}: " ${Misc.MetersToKM_Str[${Entity[${TargetID}].Distance}]}"
			Entity[${TargetID}]:LockTarget
			wait 30
		}
	}
}
