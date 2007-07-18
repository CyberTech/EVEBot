/*
	Ship class
	
	Main object for interacting with the ship and its functions
	
	-- CyberTech
	
*/

objectdef obj_Ship
{
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

	variable index:int DroneList
	variable iterator ModulesIterator

	method Initialize()
	{
		This:CalculateMaxLockedTargets
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

		return ${Math.Calc[${Me.Ship.CargoCapacity}-${Me.Ship.UsedCargoCapacity}]}
	}

	member:float CargoFreeSpace()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		return ${Math.Calc[${Me.Ship.CargoCapacity}-${Me.Ship.UsedCargoCapacity}]}
	}

	method UpdateModuleList()
	{
		if ${Me.InStation}
		{
			; GetModules cannot be used in station as of 07/15/2007
			echo "DEBUG: obj_Ship:UpdateModulesList(): In Station, aborting"
			return
		}
		
		Me.Ship:DoGetModules[This.ModuleList]
		
		if !${This.ModuleList.Used}
		{
			echo "DEBUG: obj_Ship:UpdateModuleList - No modules found"
			return
		}

		echo "Module Inventory:"
		This.ModuleList:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${This.ModulesIterator.Value.ToItem.GroupID}]
			variable int TypeID
			TypeID:Set[${This.ModulesIterator.Value.ToItem.TypeID}]

			;echo "    Slot: ${This.ModulesIterator.Value.ToItem.Slot}  ${This.ModulesIterator.Value.ToItem.Name}"
			if !${This.ModulesIterator.Value.IsActivatable}
			{
				This.ModuleList_Passive:Insert[${This.ModulesIterator.Value}]
				continue
			}

			;echo "          Group: ${This.ModulesIterator.Value.ToItem.Group}  ${GroupID}"
			;echo "          Type: ${This.ModulesIterator.Value.ToItem.Type}  ${TypeID}"
			
			if ${This.ModulesIterator.Value.MiningAmount(exists)}
			{
				This.ModuleList_MiningLaser:Insert[${This.ModulesIterator.Value}]
				continue
			}
			
			; TODO - Populate these arrays
			;This.ModuleList_CombatWeapon
			;This.ModuleList_ActiveResists
			;This.ModuleList_AB_MWD

			switch ${GroupID}
			{
				; Frequency Mining Laser
				case 483
					break
				; Shield Booster
				case 40
					This.ModuleList_Regen_Shield:Insert[${This.ModulesIterator.Value}]
					continue
					break
				default
					continue
			}

		}
		while ${This.ModulesIterator:Next(exists)}

		echo "Passive Modules:"
		This.ModuleList_Passive:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			echo "    Slot: ${This.ModulesIterator.Value.ToItem.Slot}  ${This.ModulesIterator.Value.ToItem.Name}"
		}
		while ${This.ModulesIterator:Next(exists)}

		echo "Mining Modules:"
		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			echo "    Slot: ${This.ModulesIterator.Value.ToItem.Slot}  ${This.ModulesIterator.Value.ToItem.Name}"
		}
		while ${This.ModulesIterator:Next(exists)}

		echo "Shield Regen Modules:"
		This.ModuleList_Regen_Shield:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			echo "    Slot: ${This.ModulesIterator.Value.ToItem.Slot}  ${This.ModulesIterator.Value.ToItem.Name}"
		}
		while ${This.ModulesIterator:Next(exists)}
	}
	
	method UpdateBaselineUsedCargo()
	{
		; Store the used cargo space as the cargo hold exists NOW, with whatever is leftover in it.
		This.BaselineUsedCargo:Set[${Me.Ship.UsedCargoCapacity.Ceil}]
	}
		
	member:int MaxLockedTargets()
	{
		This:CalculateMaxLockedTargets
		return ${This.Calculated_MaxLockedTargets}
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
		
		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			if ${This.ModulesIterator.Value.IsActive} || \
				${This.ModulesIterator.Value.IsGoingOnline} || \
				${This.ModulesIterator.Value.IsDeactivating} || \
				${This.ModulesIterator.Value.IsChangingAmmo} || \
				${This.ModulesIterator.Value.IsReloadingAmmo}
			{
				count:Inc
			}
		}
		while ${This.ModulesIterator:Next(exists)}

		return ${count}		
	}

	; Note: This doesn't return ALL the mining amounts, just one.
	; It should perhaps be changed to return the largest, or the smallest, or an average.
	member:float MiningAmountPerLaser()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		{
			if ${This.ModulesIterator.Value.SpecialtyCrystalMiningAmount(exists)}
			{
				return ${This.ModulesIterator.Value.SpecialtyCrystalMiningAmount}
			}
			else
			{
				return ${This.ModulesIterator.Value.MiningAmount}
			}
		}
		return 0
	}

	; Note: This doesn't return ALL the mining amounts, just one.
	; It should perhaps be changed to return the smallest optimal range
	member:int OptimalMiningRange()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		{
			return ${This.ModulesIterator.Value.OptimalRange}
		}

		return 0
	}

	; Returns the loaded crystal in a mining laser, given the slot name ("HiSlot0"...)
	member:string LoadedMiningLaserCrystal(string SlotName)
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable index:item CrystalList

		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			if !${This.ModulesIterator.Value.SpecialtyCrystalMiningAmount(exists)}
			{
				continue
			}
			if ${This.ModulesIterator.Value.ToItem.Slot.Equal[${SlotName}]} && \
				${This.ModulesIterator.Value.Charge(exists)}
			{
				return ${This.ModulesIterator.Value.Charge.Name.Token[1, " "]}
			}
		}
		while ${This.ModulesIterator:Next(exists)}

		return
	}
	; Returns TRUE if we've got a laser mining this entity already
	member:bool IsMiningAstroidID(int EntityID)
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			if ${This.ModulesIterator.Value.LastTarget(exists)} && \ 
				${This.ModulesIterator.Value.LastTarget.ID} == ${EntityID}
			{
				return TRUE
			}
		}
		while ${This.ModulesIterator:Next(exists)}
		
		return FALSE
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
		LoadedAmmo:Set[${This.LoadedMiningLaserCrystal}]
		if !${AsteroidName.Find[${LoadedAmmo}]}
		{
			variable index:item CrystalList
			variable iterator CrystalIterator
			This.ModulesIterator.Value:DoGetAvailableAmmo[CrystalList]
						
			CrystalList:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				variable string CrystalType
				CrystalType:Set[${CrystalIterator.Value.Name.Token[1, " "]}]
						
				if !${OreType.Find[${CrystalType}]}
				{
					echo "Switching Crystal for slot ${SlotName} to ${OreType}"
					continue
					Me.Ship.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID}]
					; This takes 2 seconds ingame, let's give it 50% more
					wait 30
				}
			}
			while ${CrystalIterator:Next(exists)}
		}
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
		
		This.ModuleList_MiningLaser:GetIterator[This.ModulesIterator]
		if ${This.ModulesIterator:First(exists)}
		do
		{
			if !${This.ModulesIterator.Value.IsActive} && \
				!${This.ModulesIterator.Value.IsGoingOnline} && \
				!${This.ModulesIterator.Value.IsDeactivating} && \
				!${This.ModulesIterator.Value.IsChangingAmmo} &&\
				!${This.ModulesIterator.Value.IsReloadingAmmo}
			{
				if ${This.ModulesIterator.Value.SpecialtyCrystalMiningAmount(exists)}
				{
					variable string OreType
					OreType:Set[${Me.ActiveTarget.Name}]

					;TODO - Module.Charge is broken, so cant use this right now.
					;call ChangeMiningLaserCrystal ${OreType}
				}

				call UpdateHudStatus "Activating: ${This.ModulesIterator.Value.ToItem.Slot}: ${This.ModulesIterator.Value.ToItem.Name}"
				This.ModulesIterator.Value:Click
				wait 20
				return
			}
			wait 10
		}
		while ${This.ModulesIterator:Next(exists)}
	}

	function Approach(int EntityID)
	{
		if ${Entity[${EntityID}](exists)}
		{
			variable float OriginalDistance = ${Entity[${EntityID}].Distance}
			Entity[${EntityID}]:Approach
			wait 100
			call UpdateHudStatus "Approaching: ${Entity[${EntityID}].Name} - 10 Second wait"

			if ${Entity[${EntityID}](exists)} && \
				${OriginalDistance} < ${Entity[${EntityID}].Distance}
			{
				echo "DEBUG: obj_Ship:Approach: ${Entity[${EntityID}].Name} is getting further away!  Is it moving? Are we stuck, or colliding?"
			}
			
			if ${Entity[${EntityID}](exists)} && \
				${OriginalDistance} == ${Entity[${EntityID}].Distance}
			{
				echo "DEBUG: obj_Ship:Approach: We may be stuck or colliding"
			}
		}
	}			

	function OpenCargo()
	{
		if !${This.CargoIsOpen}
		{
			call UpdateHudStatus "Opening Ship Cargo Hold"
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 40
			This.CargoIsOpen:Set[TRUE]
		}
	}

	function CloseCargo()
	{
		if ${This.CargoIsOpen}
		{
			call UpdateHudStatus "Closing Ship Cargo Hold"
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 40
			This.CargoIsOpen:Set[FALSE]
		}
	}

	function Undock()
	{
		call UpdateHudStatus "Undocking"
		EVE:Execute[CmdExitStation]	
		call UpdateHudStatus "Waiting while ship exits the station"
		do
		{
			wait 50
		}
		while ${Me.InStation}
		wait 30

		This:UpdateModuleList[]
	}

	member DronesInSpace()
	{
		return ${EVE.GetEntityIDs[DroneList,OwnerID,${Me.CharID},CategoryID,18]}
	}

   
	function DronesReturnToDroneBay()
	{
		while ${This.DronesInSpace} > 0
		{
			EVE:DronesReturnToDroneBay[DroneList]
			wait 250
		}
	}

	method CheckAvailableMiningLaserCrystals()
	{
		;GetAvailableAmmo[<index:item>]
		
	}
}
