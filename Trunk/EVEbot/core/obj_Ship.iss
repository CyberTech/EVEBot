/*
	Ship class

	Main object for interacting with the ship and its functions

	-- CyberTech

*/

objectdef obj_Ship
{
	variable int MODE_WARPING = 3

	variable time NextPulse
	variable int PulseIntervalInSeconds = 8

	variable int Calculated_MaxLockedTargets
	variable float BaselineUsedCargo
	variable bool CargoIsOpen
	variable index:module ModuleList
	variable index:module ModuleList_MiningLaser
	variable index:module ModuleList_Weapon
	variable index:module ModuleList_ActiveResists
	variable index:module ModuleList_Regen_Shield
	variable index:module ModuleList_Repair_Armor
	variable index:module ModuleList_Repair_Hull
	variable index:module ModuleList_AB_MWD
	variable index:module ModuleList_Passive
	variable index:module ModuleList_Salvagers
	variable index:module ModuleList_TractorBeams
	variable index:module ModuleList_Cloaks
	variable index:module ModuleList_StasisWeb
	variable bool Repairing_Armor = FALSE
	variable bool Repairing_Hull = FALSE
	variable float m_MaxTargetRange
	variable bool  m_WaitForCapRecharge = FALSE
	variable int   m_CargoSanityCounter = 0
	variable bool InteruptWarpWait = FALSE
	
	variable iterator ModulesIterator

	variable obj_Drones Drones

	method Initialize()
	{
		This:StopShip[]
		This:UpdateModuleList[]

		Event[OnFrame]:AttachAtom[This:Pulse]
		This:CalculateMaxLockedTargets
		UI:UpdateConsole["obj_Ship: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
    		if (${Me.InStation(exists)} && !${Me.InStation})
    		{
    			This:ValidateModuleTargets

				if (${Me.ToEntity.Mode} == 3 || !${Config.Common.BotModeName.Equal[Ratter]})
				{	/* ratter was converted to use obj_Combat already */

	    			/* Ship Armor Repair
	    				We rep to a fairly high level here because it's done while we're in warp.
	    			*/
	    			if ${This.Total_Armor_Reps} > 0
	    			{
	    				if ${Me.Ship.ArmorPct} < 100
	    				{
	    					This:ActivateRepairing_Armor
	    				}

	    				if ${This.Repairing_Armor}
	    				{
	    					if ${Me.Ship.ArmorPct} >= 98
	    					{
	    						This:DeactivateRepairing_Armor
	    						This.Repairing_Armor:Set[FALSE]
	    					}
	    				}
	    			}

	    			/* Shield Boosters
	    				We boost to a higher % in here, as it's done during warp, so cap has time to regen.
	    			*/
					if ${Me.Ship.ShieldPct} < 85 || ${Config.Combat.AlwaysShieldBoost}
					{	/* Turn on the shield booster */
						This:Activate_Shield_Booster[]
					}

					if ${Me.Ship.ShieldPct} > 95 && !${Config.Combat.AlwaysShieldBoost}
					{	/* Turn off the shield booster */
						This:Deactivate_Shield_Booster[]
					}
				}
    		}
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.IntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

	/* The IsSafe function should check the tank, ammo availability, etc.. */
	/* and determine if it is safe to put the ship back into harms way.    */
	/* TODO - Rename to SystemsReady (${Ship.SystemsReady}) or similar for clarity - CyberTech */
	member:bool IsSafe()
	{
		if ${m_WaitForCapRecharge} && ${Me.Ship.CapacitorPct} < 90
		{
			return FALSE
		}
		else
		{
			m_WaitForCapRecharge:Set[FALSE]
		}

		/* TODO - These functions are not reliable. Redo per Looped armor/shield test in obj_Miner.Mine() (then consolidate code) -- CyberTech */
		if ${Me.Ship.CapacitorPct} < 10
		{
			UI:UpdateConsole["Capacitor low!  Run for cover!", LOG_CRITICAL]
			m_WaitForCapRecharge:Set[TRUE]
			return FALSE
		}

		if ${Me.Ship.ArmorPct} < 25
		{
			UI:UpdateConsole["Armor low!  Run for cover!", LOG_CRITICAL]
			return FALSE
		}

		return TRUE
	}

	member:bool IsAmmoAvailable()
	{
		variable iterator aWeaponIterator
		variable index:item anItemIndex
		variable iterator anItemIterator
		variable bool bAmmoAvailable = TRUE

		This.ModuleList_Weapon:GetIterator[aWeaponIterator]
		if ${aWeaponIterator:First(exists)}
		do
		{
			if ${aWeaponIterator.Value.Charge(exists)}
			{
				;UI:UpdateConsole["DEBUG: obj_Ship.IsAmmoAvailable:"]
				;UI:UpdateConsole["Slot: ${aWeaponIterator.Value.ToItem.Slot}  ${aWeaponIterator.Value.ToItem.Name}"]

				aWeaponIterator.Value:DoGetAvailableAmmo[anItemIndex]
				;UI:UpdateConsole["Ammo: Used = ${anItemIndex.Used}"]

				anItemIndex:GetIterator[anItemIterator]
				if ${anItemIterator:First(exists)}
				{
					do
					{
						;UI:UpdateConsole["Ammo: Type = ${anItemIterator.Value.Type}"]
						if ${anItemIterator.Value.TypeID} == ${aWeaponIterator.Value.Charge.TypeID}
						{
							;UI:UpdateConsole["Ammo: Match!"]
							;UI:UpdateConsole["Ammo: Qty = ${anItemIterator.Value.Quantity}"]
							;UI:UpdateConsole["Ammo: Max = ${aWeaponIterator.Value.MaxCharges}"]
							if ${anItemIterator.Value.Quantity} < ${Math.Calc[${aWeaponIterator.Value.MaxCharges}*6]}
							{
								UI:UpdateConsole["DEBUG: obj_Ship.IsAmmoAvailable: FALSE!", LOG_CRITICAL]
								bAmmoAvailable:Set[FALSE]
							}
						}
					}
					while ${anItemIterator:Next(exists)}
				}
				else
				{
					UI:UpdateConsole["DEBUG: obj_Ship.IsAmmoAvailable: FALSE!", LOG_CRITICAL]
					bAmmoAvailable:Set[FALSE]
				}
			}
		}
		while ${aWeaponIterator:Next(exists)}

		return ${bAmmoAvailable}
	}

	member:bool HasCovOpsCloak()
	{
		variable bool rVal = FALSE

		variable iterator aModuleIterator
		This.ModuleList_Cloaks:GetIterator[aModuleIterator]
		if ${aModuleIterator:First(exists)}
		do
		{
			if ${aModuleIterator.Value.MaxVelocityPenalty} == 0
			{
				rVal:Set[TRUE]
				break
			}
		}
		while ${aModuleIterator:Next(exists)}

		return ${rVal}
	}

	member:float CargoMinimumFreeSpace()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		return ${Math.Calc[${Me.Ship.CargoCapacity}*0.02]}
	}

	member:float CargoFreeSpace()
	{
		if !${Me.Ship(exists)}
		{
			return 0
		}

		if ${Me.Ship.UsedCargoCapacity} < 0
		{
			return ${Me.Ship.CargoCapacity}
		}
		return ${Math.Calc[${Me.Ship.CargoCapacity}-${Me.Ship.UsedCargoCapacity}]}
	}

	member:bool CargoFull()
	{
		if !${Me.Ship(exists)}
		{
			return FALSE
		}

		if ${This.CargoFreeSpace} <= ${This.CargoMinimumFreeSpace}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool CargoHalfFull()
	{
		if !${Me.Ship(exists)}
		{
			return FALSE
		}

		if ${This.CargoFreeSpace} <= ${Math.Calc[${Me.Ship.CargoCapacity}*0.50]}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool IsDamped()
	{
		return ${Me.Ship.MaxTargetRange} < ${This.m_MaxTargetRange}
	}

	member:float MaxTargetRange()
	{
		return ${m_MaxTargetRange}
	}

	method UpdateModuleList()
	{
		if ${Me.InStation}
		{
			; GetModules cannot be used in station as of 07/15/2007
			UI:UpdateConsole["DEBUG: obj_Ship:UpdateModuleList called while in station", LOG_DEBUG]
			return
		}

		/* save ship values that may change in combat */
		This.m_MaxTargetRange:Set[${Me.Ship.MaxTargetRange}]

		/* build module lists */
		This.ModuleList:Clear
		This.ModuleList_MiningLaser:Clear
		This.ModuleList_Weapon:Clear
		This.ModuleList_ActiveResists:Clear
		This.ModuleList_Regen_Shield:Clear
		This.ModuleList_Repair_Armor:Clear
		This.ModuleList_AB_MWD:Clear
		This.ModuleList_Passive:Clear
		This.ModuleList_Repair_Armor:Clear
		This.ModuleList_Repair_Hull:Clear
		This.ModuleList_Salvagers:Clear
		This.ModuleList_TractorBeams:Clear
		This.ModuleList_Cloaks:Clear
		This.ModuleList_StasisWeb:Clear
		
		Me.Ship:DoGetModules[This.ModuleList]

		if !${This.ModuleList.Used} && ${Me.Ship.HighSlots} > 0
		{
			UI:UpdateConsole["ERROR: obj_Ship:UpdateModuleList - No modules found. Pausing - If this ship has slots, you must have at least one module equipped, of any type.", LOG_CRITICAL]
			EVEBot:Pause
			return
		}

		variable iterator Module

		UI:UpdateConsole["Module Inventory:", LOG_MINOR]
		This.ModuleList:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${Module.Value.ToItem.GroupID}]
			variable int TypeID
			TypeID:Set[${Module.Value.ToItem.TypeID}]

			if !${Module.Value.IsActivatable}
			{
				This.ModuleList_Passive:Insert[${Module.Value}]
				continue
			}

			;echo "DEBUG: Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
			;echo " DEBUG: Group: ${Module.Value.ToItem.Group}  ${GroupID}"
			;echo " DEBUG: Type: ${Module.Value.ToItem.Type}  ${TypeID}"

			if ${Module.Value.MiningAmount(exists)}
			{
				This.ModuleList_MiningLaser:Insert[${Module.Value}]
				continue
			}

			switch ${GroupID}
			{
				case GROUPID_DAMAGE_CONTROL
				case GROUPID_SHIELD_HARDENER
				case GROUPID_ARMOR_HARDENERS
					This.ModuleList_ActiveResists:Insert[${Module.Value}]
					break
				case GROUP_PROJECTILEWEAPON
				case GROUP_HYBRIDWEAPON
				case GROUP_MISSILELAUNCHER
				case GROUP_MISSILELAUNCHERASSAULT
				case GROUP_MISSILELAUNCHERBOMB
				case GROUP_MISSILELAUNCHERCITADEL
				case GROUP_MISSILELAUNCHERCRUISE
				case GROUP_MISSILELAUNCHERDEFENDER
				case GROUP_MISSILELAUNCHERHEAVY
				case GROUP_MISSILELAUNCHERHEAVYASSAULT
				case GROUP_MISSILELAUNCHERROCKET
				case GROUP_MISSILELAUNCHERSIEGE
				case GROUP_MISSILELAUNCHERSNOWBALL
				case GROUP_MISSILELAUNCHERSTANDARD				
					This.ModuleList_Weapon:Insert[${Module.Value}]
					break
				case GROUPID_FREQUENCY_MINING_LASER
					break
				case GROUPID_SHIELD_BOOSTER
					This.ModuleList_Regen_Shield:Insert[${Module.Value}]
					continue
				case GROUPID_AFTERBURNER
					This.ModuleList_AB_MWD:Insert[${Module.Value}]
					continue
				case GROUPID_ARMOR_REPAIRERS
					This.ModuleList_Repair_Armor:Insert[${Module.Value}]
					continue
				case 538
					/* data miners */
					; DEBUG: Group: Data Miners  538
					; DEBUG: Type: Salvager I  25861
					if ${TypeID} == 25861
				   	{	/* Salvager I */
						This.ModuleList_Salvagers:Insert[${Module.Value}]
				   	}
					continue
				case 650
					/* tractor beams */
					; DEBUG: Group: Tractor Beam  650
					; DEBUG: Type: Small Tractor Beam I  24348
					This.ModuleList_TractorBeams:Insert[${Module.Value}]
					continue
				case NONE
					This.ModuleList_Repair_Hull:Insert[${Module.Value}]
				  continue
				case GROUPID_CLOAKING_DEVICE
					This.ModuleList_Cloaks:Insert[${Module.Value}]
					continue
				case GROUPID_STASIS_WEB
					This.ModuleList_StasisWeb:Insert[${Module.Value}]
				default
					continue
			}

		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Weapons:", LOG_MINOR]
		This.ModuleList_Weapon:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Active Resistance Modules:", LOG_MINOR]
		This.ModuleList_ActiveResists:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Passive Modules:", LOG_MINOR]
		This.ModuleList_Passive:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Mining Modules:", LOG_MINOR]
		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Armor Repair Modules:", LOG_MINOR]
		This.ModuleList_Repair_Armor:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Shield Regen Modules:", LOG_MINOR]
		This.ModuleList_Regen_Shield:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["AfterBurner Modules:", LOG_MINOR]
		This.ModuleList_AB_MWD:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		if ${This.ModuleList_AB_MWD.Used} > 1
		{
			UI:UpdateConsole["Warning: More than 1 Afterburner or MWD was detected, I will only use the first one.", LOG_MINOR]
		}

		UI:UpdateConsole["Salvaging Modules:", LOG_MINOR]
		This.ModuleList_Salvagers:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Tractor Beam Modules:", LOG_MINOR]
		This.ModuleList_TractorBeams:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Cloaking Device Modules:", LOG_MINOR]
		This.ModuleList_Cloaks:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}
		UI:UpdateConsole["Stasis Web Modules:", LOG_MINOR]
		This.ModuleList_StasisWeb:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["    Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR]
		}
		while ${Module:Next(exists)}
	}

	function ArmorPct()
	{
		/* TODO - clean up this code when ArmorPct/ShieldPct wierdness is gone */
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable int counter
		variable float Percent

		Percent:Set[${Me.Ship.ArmorPct}]
        Counter:Set[0]
        while (${Percent} == NULL || ${Percent} <= 0)
        {
            if ${Counter} > 30
            {
               Percent:Set[-1]
               UI:UpdateConsole["ob_Ship: ArmorPct was invalid for longer than 30 seconds", LOG_CRITICAL]
               break
            }
            Counter:Inc[1]
            wait 10
            Percent:Set[${Me.Ship.ArmorPct}]
        }
        
        return ${Percent}
	}

	function ShieldPct()
	{
		/* TODO - clean up this code when ArmorPct/ShieldPct wierdness is gone */
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable int counter
		variable float Percent

		Percent:Set[${Me.Ship.ShieldPct}]
        Counter:Set[0]
        while (${Percent} == NULL || ${Percent} <= 0)
        {
                if ${Counter} > 30
                {
                	Percent:Set[-1]
                    UI:UpdateConsole["ob_Ship: ShieldPct was invalid for longer than 30 seconds", LOG_CRITICAL]
                    break
                }
                Counter:Inc[1]
                wait 10
	            Percent:Set[${Me.Ship.ShieldPct}]
        }
        
        return ${Percent}
	}

	function CapacitorPct()
	{
		/* TODO - clean up this code when ArmorPct/ShieldPct wierdness is gone */
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable int counter
		variable float Percent

		Percent:Set[${Me.Ship.CapacitorPct}]
        Counter:Set[0]
        while (${Percent} == NULL || ${Percent} <= 0)
        {
                if ${Counter} > 30
                {
                	Percent:Set[-1]
                    UI:UpdateConsole["ob_Ship: CapacitorPct was invalid for longer than 30 seconds", LOG_CRITICAL]
                    break
                }
                Counter:Inc[1]
                wait 10
	            Percent:Set[${Me.Ship.CapacitorPct}]
        }

        return ${Percent}
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

	; "Safe" max locked targets is defined as max locked targets - 1
	; for a buffer of targets so that hostiles may be targeted.
	; Always return at least 1

	member:int SafeMaxLockedTargets()
	{
		variable int result
		result:Set[${This.Calculated_MaxLockedTargets}]
		if ${result} > 3
		{
			result:Dec
		}
		return ${result}
	}

	member:int TotalMiningLasers()
	{
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
	member:string LoadedMiningLaserCrystal(string SlotName, bool fullName = FALSE)
	{
		if !${Me.Ship(exists)}
		{
			return "NOCHARGE"
		}


		if ${Me.Ship.Module[${SlotName}].Charge(exists)}
		{
			if ${fullName}
                        {
                                return ${Me.Ship.Module[${SlotName}].Charge.Name}
                        }
                        else
                        {
                                return ${Me.Ship.Module[${SlotName}].Charge.Name.Token[1, " "]}

                        }
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
				;UI:UpdateConsole["DEBUG: obj_Ship:LoadedMiningLaserCrystal Returning ${Module.Value.Charge.Name.Token[1, " "]}]
				return ${Module.Value.Charge.Name.Token[1, " "]}
			}
		}
		while ${Module:Next(exists)}

		return "NOCHARGE"
	}

	; Returns TRUE if we've got a laser mining this entity already
	member:bool IsMiningAsteroidID(int EntityID)
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
		{
			UI:ConsoleUpdate["Unlocking all targets", LOG_MINOR]
			do
			{
				Target.Value:UnlockTarget
			}
			while ${Target:Next(exists)}
		}
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
			UI:UpdateConsole["Current crystal in ${SlotName} is ${LoadedAmmo}, looking for ${OreType}"]
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
					UI:UpdateConsole["Switching Crystal in ${SlotName} from ${LoadedAmmo} to ${CrystalIterator.Value.Name}"]
					Me.Ship.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID},1]
					; This takes 2 seconds ingame, let's give it 50% more
					wait 30
					return
				}
			}
			while ${CrystalIterator:Next(exists)}
			UI:UpdateConsole["Warning: No crystal found for ore type ${OreType}, efficiency reduced"]
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
				UI:UpdateConsole["${Module.Value.ToItem.Slot}:${Module.Value.ToItem.Name} has no target: Deactivating"]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}


/*
CycleMiningLaser: HiSlot1 Activate: FALSE
Error: Math sequence not available
Dumping script stack
--------------------
-->C:/Program Files/InnerSpace/Scripts/evebot/core/obj_Ship.iss:516 Atom000000B1() if !${Activate} &&(!${Me.Ship.Module[${Slot}].IsActive} ||${Me.Ship.Module[${Slot}].IsGoingOnline}
||${Me.Ship.Module[${Slot}].IsDeactivating} ||${Me.Ship.Module[${Slot}].IsChangingAmmo} ||${Me.Ship.Module[${Slot}].IsReloadingAmmo}
C:/Program Files/InnerSpace/Scripts/evebot/core/obj_Ship.iss:584 ActivateFreeMiningLaser() wait 10
C:/Program Files/InnerSpace/Scripts/evebot/core/obj_Miner.iss:190 Mine() call Ship.ActivateFreeMiningLaser
C:/Program Files/InnerSpace/Scripts/evebot/core/obj_Miner.iss:59 ProcessState() call Miner.Mine
C:/Program Files/InnerSpace/Scripts/evebot/evebot.iss:90 main() call ${BotType}.ProcessState
	*/

	method CycleMiningLaser(string Activate, string Slot)
	{
		echo CycleMiningLaser: ${Slot} Activate: ${Activate}
		if ${Activate.Equal[ON]} && \
			( ${Me.Ship.Module[${Slot}].IsActive} || \
			  ${Me.Ship.Module[${Slot}].IsGoingOnline} || \
			  ${Me.Ship.Module[${Slot}].IsDeactivating} || \
			  ${Me.Ship.Module[${Slot}].IsChangingAmmo} || \
			  ${Me.Ship.Module[${Slot}].IsReloadingAmmo} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Activate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[OFF]} && \
			(!${Me.Ship.Module[${Slot}].IsActive} || \
			  ${Me.Ship.Module[${Slot}].IsGoingOnline} || \
			  ${Me.Ship.Module[${Slot}].IsDeactivating} || \
			  ${Me.Ship.Module[${Slot}].IsChangingAmmo} || \
			  ${Me.Ship.Module[${Slot}].IsReloadingAmmo} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Deactivate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[ON]} && \
			(	!${Me.Ship.Module[${Slot}].LastTarget(exists)} || \
				!${Entity[id,${Me.Ship.Module[${Slot}].LastTarget.ID}](exists)} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Target doesn't exist"
			return
		}

		Me.Ship.Module[${Slot}]:Click
		if ${Activate.Equal[ON]}
		{
			; Delay from 18 to 45 seconds before deactivating
			TimedCommand ${Math.Rand[65]:Inc[30]} Script[EVEBot].ExecuteAtom[Ship:CycleMiningLaser, OFF, ${Slot}]
			echo "next: off"
			return
		}
		else
		{
			; Delay for the time it takes the laser to deactivate and be ready for reactivation
			TimedCommand 20 Script[EVEBot].ExecuteAtom[Ship:CycleMiningLaser, ON, "${Slot}"]
			echo "next: on"
			return
		}
	}

	method DeactivateAllMiningLasers()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		{
			if ${Module.Value.IsActive} && \
				!${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating all mining lasers..."]
			}
		}
		do
		{
			if ${Module.Value.IsActive} && \
				!${Module.Value.IsDeactivating}
			{
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
			UI:UpdateConsole["Error: Mining Lasers may only be used on Asteroids"]
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
				variable string Slot
				Slot:Set[${Module.Value.ToItem.Slot}]
				if ${Module.Value.SpecialtyCrystalMiningAmount(exists)}
				{
					variable string OreType
					OreType:Set[${Me.ActiveTarget.Name.Token[2,"("]}]
					OreType:Set[${OreType.Token[1,")"]}]
					;OreType:Set[${OreType.Replace["(",]}]
					;OreType:Set[${OreType.Replace[")",]}]
					call This.ChangeMiningLaserCrystal "${OreType}" ${Slot}
				}

				UI:UpdateConsole["Activating: ${Module.Value.ToItem.Slot}: ${Module.Value.ToItem.Name}"]
				Module.Value:Click
				wait 25
				;TimedCommand ${Math.Rand[35]:Inc[18]} Script[EVEBot].ExecuteAtom[Ship:CycleMiningLaser, OFF, ${Slot}]
				return
			}
			wait 10
		}
		while ${Module:Next(exists)}
	}

	method StopShip()
	{
		EVE:Execute[CmdStopShip]
	}

	; Approaches EntityID to within 5% of Distance, then stops ship.  Momentum will handle the rest.
	function Approach(int EntityID, int64 Distance)
	{
		if ${Entity[${EntityID}](exists)}
		{
			variable float64 OriginalDistance = ${Entity[${EntityID}].Distance}
			variable float64 CurrentDistance

			If ${OriginalDistance} < ${Distance}
			{
				return
			}
			OriginalDistance:Inc[10]

			CurrentDistance:Set[${Entity[${EntityID}].Distance}]
			UI:UpdateConsole["Approaching: ${Entity[${EntityID}].Name} - ${Math.Calc[(${CurrentDistance} - ${Distance}) / ${Me.Ship.MaxVelocity}].Ceil} Seconds away"]

			This:Activate_AfterBurner[]
			do
			{
				Entity[${EntityID}]:Approach
				wait 50
				CurrentDistance:Set[${Entity[${EntityID}].Distance}]

				if ${Entity[${EntityID}](exists)} && \
					${OriginalDistance} < ${CurrentDistance}
				{
					UI:UpdateConsole["DEBUG: obj_Ship:Approach: ${Entity[${EntityID}].Name} is getting further away!  Is it moving? Are we stuck, or colliding?", LOG_MINOR]
				}
			}
			while ${CurrentDistance} > ${Math.Calc64[${Distance} * 1.05]}
			EVE:Execute[CmdStopShip]
			This:Deactivate_AfterBurner[]
		}
	}

	member IsCargoOpen()
	{
		if ${EVEWindow[MyShipCargo](exists)}
		{
			if ${EVEWindow[MyShipCargo].Caption(exists)}
			{
				return TRUE
			}
			else
			{
				UI:UpdateConsole["\${EVEWindow[MyShipCargo](exists)} == ${EVEWindow[MyShipCargo](exists)}", LOG_DEBUG]
				UI:UpdateConsole["\${EVEWindow[MyShipCargo].Caption(exists)} == ${EVEWindow[MyShipCargo].Caption(exists)}", LOG_DEBUG]
			}
		}
		return FALSE
	}

	function OpenCargo()
	{
		if !${This.IsCargoOpen}
		{
			UI:UpdateConsole["Opening Ship Cargohold"]
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait WAIT_CARGO_WINDOW

			; Note that this has a race condition. If the window populates fully before we check the CaptionCount
			; OR if the cargo hold is empty, then we will sit forever.  Hence the LoopCheck test
			; -- CyberTech
			variable int CaptionCount
			variable int LoopCheck

			LoopCheck:Set[0]
			CaptionCount:Set[${EVEWindow[MyShipCargo].Caption.Token[2,"["].Token[1,"]"]}]
			;UI:UpdateConsole["obj_Ship: Waiting for cargo to load: CaptionCount: ${CaptionCount}", LOG_DEBUG]
			while (${CaptionCount} > ${Me.Ship.GetCargo} && \
					${LoopCheck} < 10)
			{
				UI:UpdateConsole["obj_Ship: Waiting for cargo to load...(${Loopcheck})", LOG_MINOR]
				while !${This.IsCargoOpen}
				{
					wait 0.5
				}
				wait 10
				LoopCheck:Inc
			}
		}
	}

	function CloseCargo()
	{
		if ${This.IsCargoOpen}
		{
			UI:UpdateConsole["Closing Ship Cargohold"]
			EVEWindow[MyShipCargo]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}


	function WarpToID(int Id)
	{
		if (${Id} <= 0)
		{
			UI:UpdateConsole["Error: obj_Ship:WarpToID: Id is <= 0 (${Id})"]
			return
		}

		if !${Entity[${Id}](exists)}
		{
			UI:UpdateConsole["Error: obj_Ship:WarpToID: No entity matched the ID given."]
			return
		}

		call This.WarpPrepare
		while ${Entity[${Id}].Distance} >= WARP_RANGE
		{
			UI:UpdateConsole["Warping to ${Entity[${Id}].Name}"]
			while !${This.WarpEntered}
			{
				Entity[${Id}]:WarpTo
				wait 10
			}
			call This.WarpWait
			if ${Return} == 2
			{
				return
			}
		}
	}

	function WarpToBookMarkName(string DestinationBookmarkLabel)
	{
		if (!${EVE.Bookmark[${DestinationBookmarkLabel}](exists)})
		{
			UI:UpdateConsole["ERROR: Bookmark: '${DestinationBookmarkLabel}' does not exist!", LOG_CRITICAL]
			return
		}

		call This.WarpToBookMark ${EVE.Bookmark[${DestinationBookmarkLabel}].ID}
	}

	function TravelToSystem(int systemID)
	{
		while ${systemID} != ${Me.SolarSystemID}
		{
			UI:UpdateConsole["Setting autopilot to ${Universe[${systemID}].Name} (${systemID})"]
			Universe[${systemID}]:SetDestination
			wait 5
			UI:UpdateConsole["Activating autopilot and waiting until arrival..."]
			EVE:Execute[CmdToggleAutopilot]
			do
			{
				wait 50
				if !${Me.AutoPilotOn(exists)}
				{
					do
					{
						wait 5
					}
					while !${Me.AutoPilotOn(exists)}
				}
			}
			while ${Me.AutoPilotOn}
			wait 20
			do
			{
			   wait 10
			}
			while !${Me.ToEntity.IsCloaked}
			wait 20
		}
	}

	function WarpToBookMark(bookmark DestinationBookmark)
	{
		variable int Counter

		if (${Me.InStation})
		{
			call Station.Undock
		}

		call This.WarpPrepare
		call This.TravelToSystem ${DestinationBookmark.SolarSystemID}

		;echo \${DestinationBookmark.Type} = ${DestinationBookmark.Type}
		;echo \${DestinationBookmark.TypeID} = ${DestinationBookmark.TypeID}
		;echo \${DestinationBookmark.ToEntity(exists)} = ${DestinationBookmark.ToEntity(exists)}
		;echo \${DestinationBookmark.ToEntity.Category} = ${DestinationBookmark.ToEntity.Category}
		;echo \${DestinationBookmark.ToEntity.CategoryID} = ${DestinationBookmark.ToEntity.CategoryID}
		;echo \${DestinationBookmark.ToEntity.Distance} = ${DestinationBookmark.ToEntity.Distance}
		;echo \${DestinationBookmark.ItemID} = ${DestinationBookmark.ItemID}
		;echo DestinationBookmark Location: ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}

		declarevariable TypeID int ${DestinationBookmark.ToEntity.TypeID}
		declarevariable GroupID int ${DestinationBookmark.ToEntity.GroupID}
		declarevariable CategoryID int ${DestinationBookmark.ToEntity.CategoryID}
		declarevariable EntityID int ${DestinationBookmark.ToEntity.ID}
		declarevariable Label string ${DestinationBookmark.Label}
		declarevariable WarpCounter int 0
		variable int MinWarpRange
		
		if ${DestinationBookmark.ToEntity(exists)}
		{
			/* This is a station bookmark, we can use .Distance properly */
			switch ${CategoryID}
			{				
				case CATEGORYID_STATION
					MinWarpRange:Set[WARP_RANGE]
					break
				case CATEGORYID_CELESTIAL
					switch ${GroupID}
					{
						case GROUP_SUN
							UI:UpdateConsole["obj_Ship:WarpToBookMark - Sun/Star Entity Bookmarks are not supported", LOG_CRITICAL]
							return
							break
						case GROUP_STARGATE
							MinWarpRange:Set[WARP_RANGE]
							break
						case GROUP_MOON
							MinWarpRange:Set[WARP_RANGE_MOON]
							break
						case GROUP_PLANET
							MinWarpRange:Set[WARP_RANGE_PLANET]
							break
						default
							MinWarpRange:Set[WARP_RANGE]
							break
					}
					break
				default
					MinWarpRange:Set[WARP_RANGE]
					break
			}


			WarpCounter:Set[1]
			while ${DestinationBookmark.ToEntity.Distance} > ${MinWarpRange}
			{
				if ${WarpCounter} > 10
				{
					/* 	We return here, instead of breaking. We're either in a HUGE-ass system, which takes more
						than 10 jumps to cross, or some putz with no Warp Drive Op skill is trying to cross a large system,
						or, more likely, we're not actually warping anywhere.  So we'll return and let the bot do something
						useful with itself -- CyberTech
					*/
					UI:UpdateConsole["obj_Ship:WarpToBookMark - Failed to arrive at bookmark after ${WarpCounter} warps", LOG_CRITICAL]
					return
				}
				UI:UpdateConsole["Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
				while !${This.WarpEntered}
				{
					DestinationBookmark:WarpTo
					wait 10
				}
				call This.WarpWait
				if ${Return} == 2
				{
					return
				}
				WarpCounter:Inc
			}
		}
		elseif ${DestinationBookmark.ItemID} > -1
		{
			/* This is an entity bookmark, but that entity is not on the overhead yet. */

			WarpCounter:Set[1]
			while !${DestinationBookmark.ToEntity(exists)}
			{
				if ${WarpCounter} > 10
				{
					UI:UpdateConsole["obj_Ship:WarpToBookMark - Failed to arrive at bookmark after ${WarpCounter} warps", LOG_CRITICAL]
					return
				}
				UI:UpdateConsole["Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
				while !${This.WarpEntered}
				{
					DestinationBookmark:WarpTo
					wait 10
				}
				call This.WarpWait
				if ${Return} == 2
				{
					return
				}
				WarpCounter:Inc
			}
		}
		else
		{
			/* This is an in-space bookmark, just warp to it. */

			WarpCounter:Set[1]
			while ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}]} > WARP_RANGE
			{
				;echo Bookmark Distance: ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}]} > WARP_RANGE
				if ${WarpCounter} > 10
				{
					UI:UpdateConsole["obj_Ship:WarpToBookMark - Failed to arrive at bookmark after ${WarpCounter} warps", LOG_CRITICAL]
					return
				}
				UI:UpdateConsole["Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
				while !${This.WarpEntered}
				{
					DestinationBookmark:WarpTo
					wait 10
				}
				call This.WarpWait
				if ${Return} == 2
				{
					return
				}
				WarpCounter:Inc
			}
		}

		/* Special-Case Code for docking or getting in proper range for known objects we'll warp to */
		if ${DestinationBookmark.ToEntity(exists)}
		{
			switch ${CategoryID}
			{
				case 2
					; stargate
					break
				case CATEGORYID_STATION
					call This.Approach ${EntityID} DOCKING_RANGE
					UI:UpdateConsole["Docking with destination station..."]
					DestinationBookmark.ToEntity:Dock
					Counter:Set[0]
					do
					{
					   wait 20
					   Counter:Inc[1]
					   UI:UpdateConsole["Tick ${Counter}", LOG_MINOR]
					   if ${Counter} > 5
					   {
					      UI:UpdateConsole["Retrying dock with destination station"]
					      ;DestinationBookmark.ToEntity:Dock
					      Entity[CategoryID,3]:Dock
					      Counter:Set[0]
					   }
					}
					while !${Station.DockedAtStation[${EntityID}]}
					break
			}

			switch ${TypeID}
			{
				case TYPEID_CORPORATE_HANGAR_ARRAY
					call This.Approach ${EntityID} CORP_HANGAR_LOOT_RANGE
					break
			}
		}
		wait 20
		;UI:UpdateConsole["obj_Ship:WarpToBookMark: Exiting", LOG_DEBUG]
	}

	function WarpPrepare()
	{
		UI:UpdateConsole["Preparing for warp"]
		This:Deactivate_Cloak
		if ${This.Drones.WaitingForDrones}
		{
			UI:UpdateConsole["Drone deployment already in process, delaying warp", LOG_CRITICAL]
			do
			{
				waitframe
			}
			while ${This.Drones.WaitingForDrones}
		}
		if !${This.HasCovOpsCloak}
		{
        	This:Deactivate_Cloak[]
        }
		This:DeactivateAllMiningLasers[]
		This:UnlockAllTargets[]
		call This.Drones.ReturnAllToDroneBay
	}

	member:bool InWarp()
	{
		if ${Me.ToEntity.Mode} == 3
		{
			return TRUE
		}
		return FALSE
	}

	member:bool WarpEntered()
	{
		variable bool Warped = FALSE

		if ${This.InWarp}
		{
			Warped:Set[TRUE]
			UI:UpdateConsole["Warping..."]
		}
		return ${Warped}		
	}
	
	function WarpWait()
	{
		variable bool Warped = FALSE
		
		; We reload weapons here, because we know we're in warp, so they're deactivated.
		This:Reload_Weapons[TRUE]
		while ${This.InWarp}
		{
			Warped:Set[TRUE]
			wait 10
			if ${This.InteruptWarpWait}
			{
				UI:UpdateConsole["Leaving WarpWait due to emergency condition", LOG_CRITICAL]
				This.InteruptWarpWait:Set[False]
				return 2
			}
		}
		UI:UpdateConsole["Dropped out of warp"]
		return ${Warped}
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
			if !${Module.Value.IsActive} && ${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				Module.Value:Click
			}
		}
	}

	member:int Total_Armor_Reps()
	{
		return ${This.ModuleList_Repair_Armor.Used}
	}

	method Activate_Armor_Reps()
	{
		if !${Me.Ship(exists) || }
		{
			return
		}

		variable iterator Module

		This.ModuleList_Repair_Armor:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && ${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				Module.Value:Click
				This.Repairing_Armor:Set[TRUE]
			}
		}
		while ${Module:Next(exists)}
	}

	method Deactivate_Armor_Reps()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Repair_Armor:GetIterator[Module]
		if ${Module:First(exists)}
		{
			if ${Module.Value.IsActive} && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
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
			if ${Module.Value.IsActive} && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
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
			if !${Module.Value.IsActive} && ${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Deactivate_Shield_Booster()
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
			if ${Module.Value.IsActive} && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Activate_Hardeners()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_ActiveResists:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && ${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Deactivate_Hardeners()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_ActiveResists:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Activate_StasisWebs()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		
		variable iterator Module

		This.ModuleList_StasisWeb:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Me.ActiveTarget.Distance} < ${Module.Value.OptimalRange}
			{
				if !${Module.Value.IsActive} && ${Module.Value.IsOnline}
				{
					UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
					Module.Value:Click
				}
			}
		}
		while ${Module:Next(exists)}
	}

	method Deactivate_StasisWebs()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_StasisWeb:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Activate_Cloak()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module
		variable iterator Salvagers

		This.ModuleList_Salvagers:GetIterator[Salvagers]
		This.ModuleList_Cloaks:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && ${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				Module.Value:Click
			}
/*
			elseif !${Module.Value.IsOnline} && !${Module.Value.IsGoingOnline} && \
				${Me.Ship.CapacitorPct} > 97
			{

				if ${Math.Calc[${Me.Ship.CPUOutput}-${Me.Ship.CPULoad}]} <  ${Module.Value.CPUUsage} || \
				   ${Math.Calc[${Me.Ship.PowerOutput}-${Me.Ship.PowerLoad}]} <  ${Module.Value.PowergridUsage}
				{
					if ${Salvagers:First(exists)} && ${Salvagers.Value.IsOnline} && !${Salvagers.Value.IsGoingOnline}
					{
						UI:UpdateConsole["Putting ${Salvagers.Value.ToItem.Name} offline."]
						Salvagers.Value:PutOffline
					}
				}
				else
				{
					UI:UpdateConsole["Putting ${Module.Value.ToItem.Name} online."]
					Module.Value:PutOnline
				}
			}
*/				
		}
		while ${Module:Next(exists)}
	}

	method Deactivate_Cloak()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Cloaks:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Offline_Cloak()
	{
		;TODO
		return
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Cloaks:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Putting ${Module.Value.ToItem.Name} offline."]
				Module.Value:PutOffline
			}
		}
		while ${Module:Next(exists)}
	}

	method Online_Salvager()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Salvagers:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsOnline}
			{
				UI:UpdateConsole["Putting ${Module.Value.ToItem.Name} online."]
				Module.Value:PutOnline
			}
		}
		while ${Module:Next(exists)}
	}

	member:bool IsCloaked()
	{
		if ${Me.ToEntity(exists)} && ${Me.ToEntity.IsCloaked}
		{
			return TRUE
		}
		
		return FALSE
	}
	
	function LockTarget(int64 TargetID)
	{
		if ${Entity[${TargetID}](exists)}
		{
			UI:UpdateConsole["Locking ${Entity[${TargetID}].Name}: ${EVEBot.MetersToKM_Str[${Entity[${TargetID}].Distance}]}"]
			Entity[${TargetID}]:LockTarget
			waitframe
		}
	}

	function StackAll()
	{
		if ${This.IsCargoOpen}
		{
			Me.Ship:StackAllCargo
		}
	}

	; Returns the salvager range minus 10%
	member:int OptimalSalvageRange()
	{
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable iterator Module

		This.ModuleList_Salvagers:GetIterator[Module]
		if ${Module:First(exists)}
		{
			return ${Math.Calc[${Module.Value.OptimalRange}*0.90]}
		}

		return 0
	}

	; Returns the tractor range minus 10%
	member:int OptimalTractorRange()
	{
		if !${Me.Ship(exists)}
		{
			return 0
		}

		variable iterator Module

		This.ModuleList_TractorBeams:GetIterator[Module]
		if ${Module:First(exists)}
		{
			return ${Math.Calc[${Module.Value.OptimalRange}*0.90]}
		}

		return 0
	}
	function SetActiveCrystals()
    {
        variable iterator ModuleIterator

        This.ModuleList_MiningLaser:GetIterator[ModuleIterator]

        Cargo.ActiveMiningCrystals:Clear

        ;echo Found ${This.ModuleList_MiningLaser.Used} lasers

        if ${ModuleIterator:First(exists)}
        do
        {
            variable string crystal
            if ${ModuleIterator.Value.SpecialtyCrystalMiningAmount(exists)}
            {
                crystal:Set[${This.LoadedMiningLaserCrystal[${ModuleIterator.Value.ToItem.Slot},TRUE]}]
                ;echo ${crystal} found
                if !${crystal.Equal["NOCHARGE"]}
                {
                    Cargo.ActiveMiningCrystals:Insert[${crystal}]
                }
            }
        }
        while ${ModuleIterator:Next(exists)}
    }

	method Activate_Weapons()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Weapon:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && !${Module.Value.IsChangingAmmo} && !${Module.Value.IsReloadingAmmo} && ${Module.Value.IsOnline}
			{
				;;UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Deactivate_Weapons()
	{
		if !${Me.Ship(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Weapon:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if (${Module.Value.IsActive} || ${Module.Value.IsWaitingForActiveTarget}) && ${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				;;UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}

	method Reload_Weapons(bool ForceReload)
	{
		variable bool NeedReload = FALSE

		if !${Me.Ship(exists)}
		{
			return
		}

		if !${ForceReload}
		{
			variable iterator Module
			This.ModuleList_Weapon:GetIterator[Module]
			if ${Module:First(exists)}
			do
			{
				if !${Module.Value.IsActive} && !${Module.Value.IsChangingAmmo} && !${Module.Value.IsReloadingAmmo}
				{
					; Sometimes this value can be NULL
					if !${Module.Value.MaxCharges(exists)}
					{
						;UI:UpdateConsole["Sanity check failed... weapon has no MaxCharges!"]
						NeedReload:Set[TRUE]
						break
					}

					; Has ammo been used?
					if ${Module.Value.CurrentCharges} != ${Module.Value.MaxCharges}
					{
						; Is there still more then 30% ammo available?
						if ${Math.Calc[${Module.Value.CurrentCharges}/${Module.Value.MaxCharges}]} < 0.3
						{
							; No, reload
							NeedReload:Set[TRUE]
						}
					}
				}
			}
			while ${Module:Next(exists)}
		}

		if ${ForceReload} || ${NeedReload}
		{
			UI:UpdateConsole["Reloading Weapons..."]
			EVE:Execute[CmdReloadAmmo]
		}
	}
}
