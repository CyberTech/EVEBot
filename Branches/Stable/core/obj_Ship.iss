/*
	Ship class

	Main object for interacting with the ship and its functions

	-- CyberTech

*/

objectdef obj_Ship
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable int MODE_WARPING = 3

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable int Calculated_MaxLockedTargets
	variable float BaselineUsedCargo
	variable bool CargoIsOpen
	variable int RetryUpdateModuleList
	variable index:module ModuleList
	variable index:module ModuleList_ShieldTransporters
	variable index:module ModuleList_MiningLaser
	variable index:module ModuleList_Weapon
	variable index:module ModuleList_ECM_Burst
	variable index:module ModuleList_ECCM
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
	variable index:module ModuleList_SensorBoost
	variable index:module ModuleList_TargetPainter
	variable index:module ModuleList_TrackingComputer
	variable index:module ModuleList_GangLinks
	variable index:module ModuleList_SurveyScanners
	
	variable time SurveyScanWaitTime
	variable bool Repairing_Armor = FALSE
	variable bool Repairing_Hull = FALSE
	variable float m_MaxTargetRange
	variable bool  m_WaitForCapRecharge = FALSE
	variable int	m_CargoSanityCounter = 0
	variable bool InteruptWarpWait = FALSE
	variable bool AlertedInPod
	variable uint ReloadingWeapons = 0

	variable iterator ModulesIterator

	variable obj_Drones Drones

	method Initialize()
	{
		This:StopShip[]
		This:UpdateModuleList[]

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Ship: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${Me.InStation} && ${Me.InSpace}
			{
				This:ValidateModuleTargets

				if ${RetryUpdateModuleList} == 10
				{
					UI:UpdateConsole["ERROR: obj_Ship:UpdateModuleList - No modules found. Pausing.", LOG_CRITICAL]
					UI:UpdateConsole["ERROR: obj_Ship:UpdateModuleList - If this ship has slots, you must have at least one module equipped, of any type.", LOG_CRITICAL]
					RetryUpdateModuleList:Set[0]
					EVEBot:Pause
				}

				if ${RetryUpdateModuleList} > 0
				{
					This:UpdateModuleList
				}

				if (${Me.ToEntity.Mode} == 3 || !${Config.Common.BotModeName.Equal[Ratter]})
				{	/* ratter was converted to use obj_Combat already */

					/* Ship Armor Repair
						We rep to a fairly high level here because it's done while we're in warp.
					*/
					if ${This.Total_Armor_Reps} > 0
					{
						if ${MyShip.ArmorPct} < 100
						{
							This:Activate_Armor_Reps
						}

						if ${This.Repairing_Armor}
						{
							if ${MyShip.ArmorPct} >= 98
							{
								This:Deactivate_Armor_Reps
								This.Repairing_Armor:Set[FALSE]
							}
						}
					}

					/* Shield Boosters
						We boost to a higher % in here, as it's done during warp, so cap has time to regen.
					*/
					if (!${MyShip.ToEntity.IsCloaked} && (${MyShip.ShieldPct} < 95 || ${Config.Combat.AlwaysShieldBoost})) && !${Miner.AtPanicBookmark}
					{	/* Turn on the shield booster */
							This:Activate_Hardeners[]
							This:Activate_Shield_Booster[]
					}

					if !${MyShip.ToEntity.IsCloaked} && (${MyShip.ShieldPct} > 99 && (!${Config.Combat.AlwaysShieldBoost}) || ${Miner.AtPanicBookmark})
					{	/* Turn off the shield booster */
						This:Deactivate_Hardeners[]
						This:Deactivate_Shield_Booster[]
					}
				}
			}
			if ${This.ReloadingWeapons} && ${Math.Calc[${Time.Timestamp} - ${This.ReloadingWeapons}]} > 12
			{
				This.ReloadingWeapons:Set[0]
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	/* The IsSafe function should check the tank, ammo availability, etc.. */
	/* and determine if it is safe to put the ship back into harms way. */
	/* TODO - Rename to SystemsReady (${Ship.SystemsReady}) or similar for clarity - CyberTech */
	member:bool IsSafe()
	{
		if ${m_WaitForCapRecharge} && ${MyShip.CapacitorPct} < 90
		{
			return FALSE
		}
		else
		{
			m_WaitForCapRecharge:Set[FALSE]
		}

		/* TODO - These functions are not reliable. Redo per Looped armor/shield test in obj_Miner.Mine() (then consolidate code) -- CyberTech */
		if ${MyShip.CapacitorPct} < 10
		{
			UI:UpdateConsole["Capacitor low!  Run for cover!", LOG_CRITICAL]
			m_WaitForCapRecharge:Set[TRUE]
			return FALSE
		}

		if ${MyShip.ArmorPct} < 25
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
				;UI:UpdateConsole["DEBUG: obj_Ship.IsAmmoAvailable:", LOG_DEBUG]
				;UI:UpdateConsole["Slot: ${aWeaponIterator.Value.ToItem.Slot}  ${aWeaponIterator.Value.ToItem.Name}", LOG_DEBUG]

				aWeaponIterator.Value:GetAvailableAmmo[anItemIndex]
				;UI:UpdateConsole["Ammo: Used = ${anItemIndex.Used}", LOG_DEBUG]

				anItemIndex:GetIterator[anItemIterator]
				if ${anItemIterator:First(exists)}
				{
					do
					{
						;UI:UpdateConsole["Ammo: Type = ${anItemIterator.Value.Type}", LOG_DEBUG]
						if ${anItemIterator.Value.TypeID} == ${aWeaponIterator.Value.Charge.TypeID}
						{
							;UI:UpdateConsole["Ammo: Match!", LOG_DEBUG]
							;UI:UpdateConsole["Ammo: Qty = ${anItemIterator.Value.Quantity}", LOG_DEBUG]
							;UI:UpdateConsole["Ammo: Max = ${aWeaponIterator.Value.MaxCharges}", LOG_DEBUG]
							if ${anItemIterator.Value.Quantity} < ${Math.Calc[${aWeaponIterator.Value.MaxCharges}*12]}
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
		if !${MyShip(exists)}
		{
			return
		}

		return ${Math.Calc[${MyShip.CargoCapacity}*0.02]}
	}

	member:float CargoFreeSpace()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		if ${MyShip.UsedCargoCapacity} < 0
		{
			return ${MyShip.CargoCapacity}
		}
		return ${Math.Calc[${MyShip.CargoCapacity}-${MyShip.UsedCargoCapacity}]}
	}

	member:float CargoUsedSpace()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		if ${MyShip.UsedCargoCapacity} < 0
		{
			return ${MyShip.CargoCapacity}
		}
		return ${MyShip.UsedCargoCapacity}
	}

	method StackCargoHold()
	{
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo](exists)}
		{
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
			EVEWindow["Inventory"]:StackAll
		}
	}

	method StackOreHold()
	{
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold](exists)}
		{
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold]:MakeActive
			EVEWindow["Inventory"]:StackAll
		}
	}

	member:float OreHoldMinimumFreeSpace()
	{
		if !${MyShip(exists)}
		{
			return
		}
		return ${Math.Calc[${This.OreHoldCapacity} * 0.02]}
	}

	member:float OreHoldFreeSpace()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		return ${Math.Calc[${This.OreHoldCapacity} - ${This.OreHoldUsedCapacity}]}
	}

	member:float OreHoldCapacity()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		return ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].Capacity}
	}

	member:float OreHoldUsedCapacity()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		return ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].UsedCapacity}
	}

	member:bool OreHoldFull()
	{
		if !${MyShip(exists)}
		{
			return FALSE
		}

		if ${This.OreHoldFreeSpace} <= ${This.OreHoldMinimumFreeSpace}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool OreHoldHalfFull()
	{
		if !${MyShip(exists)}
		{
			return FALSE
		}

		if ${This.OreHoldFreeSpace} <= ${Math.Calc[${This.OreHoldCapacity}*0.50]}
		{
			return TRUE
		}
		return FALSE
	}

	method OpenOreHold()
	{
		if !${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold](exists)}
		{
			MyShip:Open
		}
	}

	member:bool OreHoldEmpty()
	{
		if !${MyShip(exists)}
		{
			return FALSE
		}
		if ${This.OreHoldUsedCapacity.Int} == 0
		{
			return TRUE
		}
		return FALSE
	}


	method StackCorpHangar()
	{
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar](exists)}
		{
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar]:MakeActive
			EVEWindow["Inventory"]:StackAll
		}
	}

	member:float CorpHangarMinimumFreeSpace()
	{
		if !${MyShip(exists)}
		{
			return
		}

		return ${Math.Calc[${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].Capacity} * 0.02]}
	}

	member:float CorpHangarFreeSpace()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		return ${Math.Calc[${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].Capacity} - ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].UsedCapacity}]}
	}

	member:float CorpHangarUsedSpace(bool IgnoreCrystals=FALSE)
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable index:item HangarCargo
		variable iterator CargoIterator
		variable float Volume=0
		MyShip:GetCorpHangarsCargo[HangarCargo]
		if ${IgnoreCrystals}
			HangarCargo:RemoveByQuery[${LavishScript.CreateQuery[Name =- "Mining Crystal"]}]
		HangarCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
			do
			{
					Volume:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
			}
			while ${CargoIterator:Next(exists)}
		return ${Volume}
	}

	member:bool CorpHangarFull()
	{
		if !${MyShip(exists)}
		{
			return FALSE
		}

		if ${This.CorpHangarFreeSpace} <= ${This.CorpHangarMinimumFreeSpace}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool CorpHangarEmpty()
	{
		if !${MyShip(exists)}
		{
			return FALSE
		}

		This:OpenCorpHangars

		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].UsedCapacity} == 0
		{
			return TRUE
		}
		return FALSE
	}

	method OpenCorpHangars()
	{
		if !${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar](exists)}
		{
			MyShip:Open
		}
	}

	member:bool CargoFull()
	{
		if !${MyShip(exists)}
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
		if !${MyShip(exists)}
		{
			return FALSE
		}

		if ${This.CargoFreeSpace} <= ${Math.Calc[${MyShip.CargoCapacity}*0.50]}
		{
			return TRUE
		}
		return FALSE
	}

	member:float CargoNoCrystals()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable index:item HangarCargo
		variable iterator CargoIterator
		variable float Volume=0
		MyShip:GetCargo[HangarCargo]
		HangarCargo:RemoveByQuery[${LavishScript.CreateQuery[Name =- "Mining Crystal"]}]
		HangarCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
			do
			{
					Volume:Inc[${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]}]
			}
			while ${CargoIterator:Next(exists)}
		return ${Volume}
	}

	member:bool CargoTenthFull()
	{
		if !${MyShip(exists)}
		{
			return FALSE
		}

		if ${This.CargoNoCrystals} >= ${Math.Calc[${MyShip.CargoCapacity}*0.10]}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool IsDamped()
	{
		return ${MyShip.MaxTargetRange.Centi} < ${This.m_MaxTargetRange.Centi}
	}

	member:float MaxTargetRange()
	{
		variable float CurrentTargetRange = ${MyShip.MaxTargetRange}

		if ${This.m_MaxTargetRange.Centi} < ${CurrentTargetRange.Centi}
		{
			This.m_MaxTargetRange:Set[${CurrentTargetRange}]
	}

		return ${CurrentTargetRange}
	}

	method UpdateModuleList()
	{
		if ${Me.InStation}
		{
			; GetModules cannot be used in station as of 07/15/2007
			UI:UpdateConsole["DEBUG: obj_Ship:UpdateModuleList called while in station", LOG_DEBUG]
			RetryUpdateModuleList:Set[1]
			return
		}

		/* build module lists */
		This.ModuleList:Clear
		This.ModuleList_MiningLaser:Clear
		This.ModuleList_ModuleList_ECM_Burst:Clear
		This.ModuleList_ECCM:Clear
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
		This.ModuleList_SensorBoost:Clear
		This.ModuleList_TargetPainter:Clear
		This.ModuleList_TrackingComputer:Clear
		This.ModuleList_GangLinks:Clear
		This.ModuleList_ShieldTransporters:Clear
		This.ModuleList_SurveyScanners:Clear

		if !${MyShip:GetModules[This.ModuleList]}
		{
			UI:UpdateConsole["ERROR: obj_Ship:UpdateModuleList - GetModules failed. Retrying in a few seconds.", LOG_CRITICAL]
			RetryUpdateModuleList:Inc
			return
		}
		RetryUpdateModuleList:Set[0]

		/* save ship values that may change in combat */
		This.m_MaxTargetRange:Set[${MyShip.MaxTargetRange}]

		variable iterator ModuleIter

		UI:UpdateConsole["Module Inventory:", LOG_MINOR, 1]
		This.ModuleList:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${ModuleIter.Value.ToItem.GroupID}]
			variable int TypeID
			TypeID:Set[${ModuleIter.Value.ToItem.TypeID}]

			if !${ModuleIter.Value(exists)}
			{
				UI:UpdateConsole["ERROR: obj_Ship:UpdateModuleList - Null module found. Retrying in a few seconds.", LOG_CRITICAL]
				RetryUpdateModuleList:Inc
				return
			}

			UI:UpdateConsole["DEBUG: ID: ${ModuleIter.Value.ID} Activatable: ${ModuleIter.Value.IsActivatable} Name: ${ModuleIter.Value.ToItem.Name} Slot: ${ModuleIter.Value.ToItem.Slot} Group: ${ModuleIter.Value.ToItem.Group} ${GroupID} Type: ${ModuleIter.Value.ToItem.Type} ${TypeID}", LOG_DEBUG]

			;if !${ModuleIter.Value.IsActivatable}
			;{
			;	This.ModuleList_Passive:Insert[${ModuleIter.Value.ID}]
			;	continue
			;}

			if ${ModuleIter.Value.MiningAmount(exists)}
			{
				This.ModuleList_MiningLaser:Insert[${ModuleIter.Value.ID}]
				continue
			}

			switch ${GroupID}
			{
				case GROUPID_SHIELD_HARDENER
				case GROUPID_ARMOR_HARDENERS
					This.ModuleList_ActiveResists:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_ENERGYWEAPON
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
					This.ModuleList_Weapon:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_ECM_BURST
					This.ModuleList_ECM_Burst:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_ECCM
					This.ModuleList_ECCM:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_MININGLASER
				case GROUP_STRIPMINER
				case GROUPID_FREQUENCY_MINING_LASER
					This.ModuleList_MiningLaser:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_SHIELD_BOOSTER
					This.ModuleList_Regen_Shield:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_AFTERBURNER
					This.ModuleList_AB_MWD:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_ARMOR_REPAIRERS
					This.ModuleList_Repair_Armor:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_DATA_MINER
					if ${TypeID} == TYPEID_SALVAGER
					{
						This.ModuleList_Salvagers:Insert[${ModuleIter.Value.ID}]
					}
					break
				case GROUPID_SALVAGER
						This.ModuleList_Salvagers:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_TRACTOR_BEAM
					This.ModuleList_TractorBeams:Insert[${ModuleIter.Value.ID}]
					break
				case NONE
					This.ModuleList_Repair_Hull:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_CLOAKING_DEVICE
					This.ModuleList_Cloaks:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_STASIS_WEB
					This.ModuleList_StasisWeb:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_SENSORBOOSTER
					This.ModuleList_SensorBoost:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_TARGETPAINTER
					This.ModuleList_TargetPainter:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_TRACKINGCOMPUTER
					This.ModuleList_TrackingComputer:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_GANGLINK
				case GROUP_COMMAND_BURST
					This.ModuleList_GangLinks:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_SHIELD_TRANSPORTER
					This.ModuleList_ShieldTransporters:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_SURVEYSCANNER
					This.ModuleList_SurveyScanners:Insert[${ModuleIter.Value.ID}]
				default
					break
			}
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Weapons:", LOG_MINOR, 2]
		This.ModuleList_Weapon:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["Slot: ${ModuleIter.Value.ToItem.Slot} ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["ECM Burst Modules:", LOG_MINOR, 2]
		This.ModuleList_ECM_Burst:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["ECCM Modules:", LOG_MINOR, 2]
		This.ModuleList_ECCM:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Active Resistance Modules:", LOG_MINOR, 2]
		This.ModuleList_ActiveResists:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Passive Modules:", LOG_MINOR, 2]
		This.ModuleList_Passive:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Mining Modules:", LOG_MINOR, 2]
		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Armor Repair Modules:", LOG_MINOR, 2]
		This.ModuleList_Repair_Armor:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Shield Regen Modules:", LOG_MINOR, 2]
		This.ModuleList_Regen_Shield:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["AfterBurner Modules:", LOG_MINOR, 2]
		This.ModuleList_AB_MWD:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		if ${This.ModuleList_AB_MWD.Used} > 1
		{
			UI:UpdateConsole["Warning: More than 1 Afterburner or MWD was detected, I will only use the first one.", LOG_MINOR, 4]
		}

		UI:UpdateConsole["Salvaging Modules:", LOG_MINOR, 2]
		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Tractor Beam Modules:", LOG_MINOR, 2]
		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Cloaking Device Modules:", LOG_MINOR, 2]
		This.ModuleList_Cloaks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Stasis Web Modules:", LOG_MINOR, 2]
		This.ModuleList_StasisWeb:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Sensor Boost Modules:", LOG_MINOR, 2]
		This.ModuleList_SensorBoost:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Target Painter Modules:", LOG_MINOR, 2]
		This.ModuleList_TargetPainter:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Tracking Computer Modules:", LOG_MINOR, 2]
		This.ModuleList_TrackingComputer:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Gang Link Modules:", LOG_MINOR, 2]
		This.ModuleList_GangLinks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Shield Transporter Modules:", LOG_MINOR, 2]
		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		UI:UpdateConsole["Survey Scanners:", LOG_MINOR, 2]
		This.ModuleList_SurveyScanners:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${ModuleIter:Next(exists)}

		if ${This.ModuleList_SurveyScanners.Used} > 1
		{
			UI:UpdateConsole["Warning: More than 1 survey scanners detected, I will only use the first one.", LOG_MINOR, 4]
		}

	}

	method UpdateBaselineUsedCargo()
	{
		; Store the used cargo space as the cargo hold exists NOW, with whatever is leftover in it.
		This.BaselineUsedCargo:Set[${MyShip.UsedCargoCapacity.Ceil}]
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
		This:CalculateMaxLockedTargets[]
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

	member:int TotalTractorBeams()
	{
		return ${This.ModuleList_TractorBeams.Used}
	}
	member:int TotalSalvagers()
	{
		return ${This.ModuleList_Salvagers.Used}
	}

	member:int TotalActivatedMiningLasers()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable int count
		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} || \
				${ModuleIter.Value.IsDeactivating} || \
				${ModuleIter.Value.IsReloading}
			{
				count:Inc
			}
		}
		while ${ModuleIter:Next(exists)}

		return ${count}
	}
	member:int TotalActivatedTractorBeams()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable int count
		variable iterator ModuleIter

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if (${ModuleIter.Value.IsActive} || \
				${ModuleIter.Value.IsDeactivating})
			{
				count:Inc
			}
		}
		while ${ModuleIter:Next(exists)}

		return ${count}
	}
	member:int TotalActivatedShieldTransporters()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable int count
		variable iterator ModuleIter

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if (${ModuleIter.Value.IsActive} || \
				${ModuleIter.Value.IsDeactivating})
			{
				count:Inc
			}
		}
		while ${ModuleIter:Next(exists)}

		return ${count}
	}
	member:int TotalActivatedSalvagers()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable int count
		variable iterator ModuleIter

		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} || \
				${ModuleIter.Value.IsDeactivating}
			{
				count:Inc
			}
		}
		while ${ModuleIter:Next(exists)}

		return ${count}
	}

	; Note: This doesn't return ALL the mining amounts, just one.
	; It should perhaps be changed to return the largest, or the smallest, or an average.
	member:float MiningAmountPerLaser()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			if ${ModuleIter.Value.SpecialtyCrystalMiningAmount(exists)}
			{
				return ${ModuleIter.Value.SpecialtyCrystalMiningAmount}
			}
			else
			{
				return ${ModuleIter.Value.MiningAmount}
			}
		}
		return 0
	}

	; Note: This doesn't return ALL the mining amounts, just one.
	; Returns the laser mining range minus 10%
	member:int OptimalMiningRange(float Padding=0.90)
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			return ${Math.Calc[${ModuleIter.Value.OptimalRange} * ${Padding}]}
		}

		return 0
	}

	; Returns the shield transporter range minus 10%
	member:int OptimalShieldTransporterRange(float Padding=0.90)
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable iterator ModuleIter

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			return ${Math.Calc[${ModuleIter.Value.OptimalRange} * ${Padding}]}
		}

		return 0
	}

	; Returns the loaded crystal in a mining laser, given the slot name ("HiSlot0"...)
	member:string LoadedMiningLaserCrystal(string SlotName, bool fullName = FALSE)
	{
		if !${MyShip(exists)}
		{
			return "NOCHARGE"
		}

		if ${MyShip.Module[${SlotName}].Charge(exists)}
		{
			if ${fullName}
			{
				return ${MyShip.Module[${SlotName}].Charge.Type}
			}
			else
			{
				return ${MyShip.Module[${SlotName}].Charge.Type.Token[1, " "]}
			}
		}
		return "NOCHARGE"

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIteratorModule]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.SpecialtyCrystalMiningAmount(exists)}
			{
				continue
			}
			if ${ModuleIter.Value.ToItem.Slot.Equal[${SlotName}]} && \
				${ModuleIter.Value.Charge(exists)}
			{
				;UI:UpdateConsole["DEBUG: obj_Ship:LoadedMiningLaserCrystal Returning ${ModuleIter.Value.Charge.Type.Token[1, " "]}]
				return ${ModuleIter.Value.Charge.Type.Token[1, " "]}
			}
		}
		while ${ModuleIter:Next(exists)}

		return "NOCHARGE"
	}

	; Returns TRUE if we've got a laser mining this entity already
	member:bool IsMiningAsteroidID(int64 EntityID)
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.LastTarget(exists)} && \
				${ModuleIter.Value.LastTarget.ID.Equal[${EntityID}]} && \
				${ModuleIter.Value.IsActive}
			{
				return TRUE
			}
		}
		while ${ModuleIter:Next(exists)}

		return FALSE
	}

	; Returns TRUE if we've got a shield transporter healing this entity already
	member:bool IsShieldTransportingID(int64 EntityID)
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if	${ModuleIter.Value.TargetID} == ${EntityID} && \
				${ModuleIter.Value.IsActive}
			{
				return TRUE
			}
		}
		while ${ModuleIter:Next(exists)}

		return FALSE
	}

	; Returns how many shield transporters healing this entity already
	member:int ShieldTransportersOnID(int64 EntityID)
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter
		variable int val=0

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if	${ModuleIter.Value.TargetID} == ${EntityID} && \
				${ModuleIter.Value.IsActive}
			{
				val:Inc[1]
			}
		}
		while ${ModuleIter:Next(exists)}

		return ${val}
	}


	member:bool IsTractoringWreckID(int64 EntityID)
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.LastTarget(exists)} && \
				${ModuleIter.Value.LastTarget.ID.Equal[${EntityID}]} && \
				${ModuleIter.Value.IsActive}
			{
				return TRUE
			}
		}
		while ${ModuleIter:Next(exists)}

		return FALSE
	}

	member:bool IsSalvagingWreckID(int64 EntityID)
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.LastTarget(exists)} && \
				${ModuleIter.Value.LastTarget.ID.Equal[${EntityID}]} && \
				${ModuleIter.Value.IsActive}
			{
				return TRUE
			}
		}
		while ${ModuleIter:Next(exists)}

		return FALSE
	}



	method UnlockAllTargets()
	{
		variable index:entity LockedTargets
		variable iterator Target

		Me:GetTargets[LockedTargets]
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
		if !${MyShip(exists)}
		{
			return
		}

		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			Calculated_MaxLockedTargets:Set[${Me.MaxLockedTargets}]
		}
		else
		{
			Calculated_MaxLockedTargets:Set[${MyShip.MaxLockedTargets}]
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

			Me.Ship.Module[${SlotName}]:GetAvailableAmmo[CrystalList]

			if ${CrystalList.Used} == 0
			{
				UI:UpdateConsole["Unable to find ammo for ${SlotName} - lag?"]
			}
			CrystalList:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				variable string CrystalType
				CrystalType:Set[${CrystalIterator.Value.Name.Token[1, " "]}]
				if ${CystalType.Equal["Ochre"]}
				{
					CrystalType:Set["Dark Ochre"]
				}
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
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating} && \
				!${ModuleIter.Value.LastTarget(exists)}
			{
				UI:UpdateConsole["${ModuleIter.Value.ToItem.Slot}:${ModuleIter.Value.ToItem.Name} has no target: Deactivating"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method CycleMiningLaser(string Activate, string Slot)
	{
		;echo CycleMiningLaser: ${Slot} Activate: ${Activate}
		if ${Activate.Equal[ON]} && \
			( ${MyShip.Module[${Slot}].IsActive} || \
			  ${MyShip.Module[${Slot}].IsDeactivating} || \
			  ${MyShip.Module[${Slot}].IsReloading} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Activate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[OFF]} && \
			(!${MyShip.Module[${Slot}].IsActive} || \
			  ${MyShip.Module[${Slot}].IsDeactivating} || \
			  ${MyShip.Module[${Slot}].IsReloading} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Deactivate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[ON]} && \
			(	!${MyShip.Module[${Slot}].LastTarget(exists)} || \
				!${Entity[${MyShip.Module[${Slot}].LastTarget.ID}](exists)} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Last Target doesn't exist"
			return
		}

		if ${Activate.Equal[ON]}
		{
			Me.Ship.Module[${Slot}]:Activate[${MyShip.Module[${Slot}].LastTarget.ID}]
			; Delay from 30 to 60 seconds before deactivating
			TimedCommand ${Math.Rand[600]:Inc[300]} "Script[EVEBot].VariableScope.Ship:CycleMiningLaser[OFF, ${Slot}]"
			return
		}
		else
		{
			Me.Ship.Module[${Slot}]:Deactivate
			; Delay for the time it takes the laser to deactivate and be ready for reactivation
			TimedCommand 20 "Script[EVEBot].VariableScope.Ship:CycleMiningLaser[ON, ${Slot}]"
			return
		}
	}

	method DeactivateAllMiningLasers()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			if ${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating all mining lasers..."]
			}
		}
		do
		{
			if ${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating}
			{
				ModuleIter.Value:Deactivate
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	function ActivateFreeMiningLaser(int64 id=-1)
	{
		variable string Slot

		if !${MyShip(exists)}
		{
			return
		}

		if ${id.Equal[-1]}
		{
			id:Set[${Me.ActiveTarget.ID}]
		}
		if !${Entity[${id}](exists)}
		{
			UI:UpdateConsole["ActivateFreeMiningLaser: Target ${id} not found", LOG_DEBUG]
			return
		}
		if ${Entity[${id}].CategoryID} != ${Asteroids.AsteroidCategoryID}
		{
			UI:UpdateConsole["Error: Mining Lasers may only be used on Asteroids"]
			return
		}

		variable iterator ModuleIter

		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating} && \
				!${ModuleIter.Value.IsReloading}
			{
				Slot:Set[${ModuleIter.Value.ToItem.Slot}]
				if ${ModuleIter.Value.SpecialtyCrystalMiningAmount(exists)}
				{
					variable string OreType
					OreType:Set[${Entity[${id}].Name.Token[2,"("]}]
					OreType:Set[${OreType.Token[1,")"]}]
					;OreType:Set[${OreType.Replace["(",]}]
					;OreType:Set[${OreType.Replace[")",]}]
					call This.ChangeMiningLaserCrystal "${OreType}" ${Slot}
				}

				UI:UpdateConsole["Activating: ${Slot}: ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Activate[${id}]

				variable int OreAvailable = ${Entity[${id}].SurveyScannerOreQuantity}
				if (${OreAvailable} > 0 && ${ModuleIter.Value.MiningAmountPerSecond(exists)})
				{
					variable float64 OrePerSec = ${ModuleIter.Value.MiningAmountPerSecond}
					if (${OrePerSec < 0.5})
					{
						UI:UpdateConsole["ActivateFreeMiningLaser: MiningAmountPerSecond for ${ModuleIter.Value.Slot} is invalid", LOG_DEBUG]
						return
					}
					variable float64 OrePerCycle = ${Math.Calc[${OrePerSec} * ${ModuleIter.Value.Duration}]}
					if (${OreAvailable} < ${OrePerCycle})
					{
						variable int SecondsToRun = ${Math.Calc[(${OreAvailable} / ${OrePerSec}) + 1]}
						UI:UpdateConsole["ActivateFreeMiningLaser: OreAvailable ${OreAvailable} < OrePerCycle ${OrePerCycle}, shortening runtime from ${ModuleIter.Value.Duration} to ${SecondsToRun}", LOG_DEBUG]
						TimedCommand ${SecondsToRun} "MyShip.Module[${ModuleIter.Value.Slot}]:Deactivate"
					}
				}
				;TimedCommand ${Math.Rand[600]:Inc[300]} "Script[EVEBot].VariableScope.Ship:CycleMiningLaser[OFF, ${Slot}]"
				return
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	function ActivateFreeTractorBeam(int64 id=-1)
	{
		variable string Slot

		if !${MyShip(exists)}
		{
			return
		}
		if ${id.Equal[-1]}
		{
			id:Set[${Me.ActiveTarget.ID}]
		}
		if !${Entity[${id}](exists)}
		{
			UI:UpdateConsole["ActivateFreeTractorBeam: Target ${id} not found", LOG_DEBUG]
			return
		}

		variable iterator ModuleIter

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating} && \
				!${ModuleIter.Value.IsReloading}
			{
				Slot:Set[${ModuleIter.Value.ToItem.Slot}]

				UI:UpdateConsole["Activating: ${Slot}: ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Activate[${id}]
				return
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	function ActivateFreeShieldTransporter(int64 id=-1)
	{
		variable string Slot

		if !${MyShip(exists)}
		{
			return
		}
		if ${id.Equal[-1]}
		{
			id:Set[${Me.ActiveTarget.ID}]
		}
		if !${Entity[${id}](exists)}
		{
			UI:UpdateConsole["ActivateFreeShieldTransporter: Target ${id} not found", LOG_DEBUG]
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating} && \
				!${ModuleIter.Value.IsReloading}
			{
				Slot:Set[${ModuleIter.Value.ToItem.Slot}]

				UI:UpdateConsole["Activating: ${Slot}: ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Activate[${id}]
				return
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	function ActivateFreeSalvager()
	{
		variable string Slot

		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && \
				!${ModuleIter.Value.IsDeactivating} && \
				!${ModuleIter.Value.IsReloading}
			{
				Slot:Set[${ModuleIter.Value.ToItem.Slot}]

				UI:UpdateConsole["Activating: ${Slot}: ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
				return
			}
			wait 10
		}
		while ${ModuleIter:Next(exists)}
	}


	method StopShip()
	{
		EVE:Execute[CmdStopShip]
	}

	; Approaches EntityID to within 5% of Distance, then stops ship.  Momentum will handle the rest.
	function Approach(int64 EntityID, int64 Distance)
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
			UI:UpdateConsole["Approaching: ${Entity[${EntityID}].Name} - ${Math.Calc[(${CurrentDistance} - ${Distance}) / ${MyShip.MaxVelocity}].Ceil} Seconds away"]

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

	member:bool IsCargoOpen()
	{
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo](exists)}
		{
			return TRUE
		}
		return FALSE
	}

	function OpenCargo()
	{
		if !${This.IsCargoOpen}
		{
			UI:UpdateConsole["Opening Ship Cargohold"]
			MyShip:Open
			wait WAIT_CARGO_WINDOW
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
		}
		EVEWindow[ByItemID, ${MyShip.ID}]:StackAll
		wait 5
	}

	function CloseCargo()
	{
		if ${This.IsCargoOpen}
		{
			UI:UpdateConsole["Closing Ship Cargohold"]
			EVEWindow["Inventory"]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen}
			{
				wait 1
			}
			wait 10
		}
	}


	function WarpToID(int64 Id, int WarpInDistance=0, bool WarpFleet=FALSE)
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

		Entity[${Id}]:AlignTo
		call This.WarpPrepare
		while ${Entity[${Id}].Distance} >= WARP_RANGE
		{
			UI:UpdateConsole["Warping to ${Entity[${Id}].Name} @ ${EVEBot.MetersToKM_Str[${WarpInDistance}]}"]
			while !${This.WarpEntered}
			{
				if ${WarpFleet}
				{
					Entity[${Id}]:WarpFleetTo[${WarpInDistance}]
				}
				else
				{
					Entity[${Id}]:WarpTo[${WarpInDistance}]
				}
				wait 10
			}

			call This.WarpWait
			if ${Return} == 2
			{
				return
			}
		}
	}

	; This takes CHARID, not Entity id
	function WarpToFleetMember(int64 charID, int distance=0, bool WarpFleet=FALSE)
	{
		variable index:fleetmember FleetMembers
		variable iterator FleetMember

		FleetMembers:Clear
		Me.Fleet:GetMembers[FleetMembers]
		FleetMembers:GetIterator[FleetMember]

		if ${FleetMember:First(exists)}
		{
			do
			{
				if ${charID.Equal[${FleetMember.Value.CharID}]} && ${Local[${FleetMember.Value.Name}](exists)}
				{
					call This.WarpPrepare
					while !${Entity["OwnerID = ${charID} && CategoryID = 6"](exists)}
					{
						UI:UpdateConsole["Warping to Fleet Member: ${FleetMember.Value.Name}"]
						while !${This.WarpEntered}
						{
							if ${WarpFleet}
							{
								FleetMember.Value:WarpFleetTo[${distance}]
							}
							else
							{
								FleetMember.Value:WarpTo[${distance}]
							}
							wait 10
						}
						call This.WarpWait
						if ${Return} == 2
						{
							UI:UpdateConsole["ERROR: Ship.WarpToFleetMember never reached fleet member!"]
							return
						}
					}
					return
				}
			}
			while ${FleetMember:Next(exists)}
		}
		UI:UpdateConsole["ERROR: Ship.WarpToFleetMember could not find fleet member!"]
	}

	function WarpToBookMarkName(string DestinationBookmarkLabel, bool WarpFleet=FALSE)
	{
		if (!${EVE.Bookmark[${DestinationBookmarkLabel}](exists)})
		{
			UI:UpdateConsole["ERROR: Bookmark: '${DestinationBookmarkLabel}' does not exist!", LOG_CRITICAL]
			return
		}

		call This.WarpToBookMark ${EVE.Bookmark[${DestinationBookmarkLabel}].ID} ${WarpFleet}
	}

	; TODO - Move this to obj_AutoPilot when it is ready - CyberTech
	function ActivateAutoPilot()
	{
		variable int Counter
		UI:UpdateConsole["Activating autopilot and waiting until arrival..."]
		if !${Me.AutoPilotOn}
		{
			EVE:Execute[CmdToggleAutopilot]
		}
		do
		{
			do
			{
				Counter:Inc
				wait 10
			}
			while !${Me.AutoPilotOn} && (${Counter} < 10)
			wait 10
		}
		while ${Me.AutoPilotOn}
		wait 30
	}

	function TravelToSystem(int64 DestinationSystemID)
	{
		while !${DestinationSystemID.Equal[${Me.SolarSystemID}]}
		{
			UI:UpdateConsole["DEBUG: To: ${DestinationSystemID} At: ${Me.SolarSystemID}", LOG_DEBUG]
			UI:UpdateConsole["Setting autopilot from ${Universe[${Me.SolarSystemID}].Name} to ${Universe[${DestinationSystemID}].Name}"]
			Universe[${DestinationSystemID}]:SetDestination

			call This.ActivateAutoPilot
		}
		wait 20
		while ${EVE.EntitiesCount} == 2
		{
			wait 5
		}
	}

	function WarpToBookMark(bookmark DestinationBookmark, bool WarpFleet=FALSE)
	{
		variable int Counter
		if ${Me.Station} == ${DestinationBookmark.ItemID}
		{
			return
		}

		if ${Me.InStation}
		{
			call Station.Undock
		}

		call This.WarpPrepare
		; Note -- this does not handle WarpFleet=true (the fleet wont' change systems)
		call This.TravelToSystem ${DestinationBookmark.SolarSystemID}

#if EVEBOT_DEBUG
		echo \${DestinationBookmark.Type} = ${DestinationBookmark.Type}
		echo \${DestinationBookmark.TypeID} = ${DestinationBookmark.TypeID}
		echo \${DestinationBookmark.ToEntity(exists)} = ${DestinationBookmark.ToEntity(exists)}
		echo \${DestinationBookmark.ToEntity.Category} = ${DestinationBookmark.ToEntity.Category}
		echo \${DestinationBookmark.ToEntity.CategoryID} = ${DestinationBookmark.ToEntity.CategoryID}
		echo \${DestinationBookmark.ToEntity.Distance} = ${DestinationBookmark.ToEntity.Distance}
		echo \${DestinationBookmark.AgentID} = ${DestinationBookmark.AgentID}
		echo \${DestinationBookmark.ItemID} = ${DestinationBookmark.ItemID}
		echo \${DestinationBookmark.LocationType} = ${DestinationBookmark.LocationType}
		echo \${DestinationBookmark.LocationID} = ${DestinationBookmark.LocationID}
		echo DestinationBookmark Location: ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}
		echo \${Entity["CategoryID = 6"].X} = ${Entity["CategoryID = 6"].X}
		echo \${Entity["CategoryID = 6"].Y} = ${Entity["CategoryID = 6"].Y}
		echo \${Entity["CategoryID = 6"].Z} = ${Entity["CategoryID = 6"].Z}
		echo \${Me.ToEntity.X} = ${Me.ToEntity.X}
		echo \${Me.ToEntity.Y} = ${Me.ToEntity.Y}
		echo \${Me.ToEntity.Z} = ${Me.ToEntity.Z}
#endif


		variable int MinWarpRange
		declarevariable WarpCounter int 0
		declarevariable Label string ${DestinationBookmark.Label}

		declarevariable TypeID int ${DestinationBookmark.ToEntity.TypeID}
		declarevariable GroupID int ${DestinationBookmark.ToEntity.GroupID}
		declarevariable CategoryID int ${DestinationBookmark.ToEntity.CategoryID}
		declarevariable EntityID int64 ${DestinationBookmark.ToEntity.ID}

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
				UI:UpdateConsole["1: Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
				while !${This.WarpEntered}
				{
					if ${WarpFleet}
					{
						DestinationBookmark:WarpFleetTo
					}
					else
					{
						DestinationBookmark:WarpTo
					}
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
		elseif ${DestinationBookmark.ItemID} == -1 || \
				(${DestinationBookmark.AgentID(exists)} && ${DestinationBookmark.LocationID(exists)})
		{
			/* This is an in-space bookmark, or a dungeon bookmark, just warp to it. */

			WarpCounter:Set[1]
			while ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}]} > WARP_RANGE
			{
				;echo Bookmark Distance: ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}]} > WARP_RANGE
				if ${WarpCounter} > 10
				{
					UI:UpdateConsole["obj_Ship:WarpToBookMark - Failed to arrive at bookmark after ${WarpCounter} warps", LOG_CRITICAL]
					return
				}

				if ${DestinationBookmark.AgentID(exists)} && ${DestinationBookmark.LocationID(exists)} && \
					${Entity["TypeID = TYPE_ACCELERATION_GATE"](exists)}
				{
					call This.Approach ${Entity["TypeID = TYPE_ACCELERATION_GATE"].ID} DOCKING_RANGE
					wait 10
					UI:UpdateConsole["Activating Acceleration Gate..."]
					while !${This.WarpEntered}
					{
						Entity["TypeID = TYPE_ACCELERATION_GATE"]:Activate
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
					UI:UpdateConsole["2: Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
					while !${This.WarpEntered} && ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}]} > WARP_RANGE
					{
						if ${WarpFleet}
						{
							DestinationBookmark:WarpFleetTo
						}
						else
						{
							DestinationBookmark:WarpTo
						}
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
		}
		else
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
				UI:UpdateConsole["3: Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
				while !${This.WarpEntered}
				{
					if ${WarpFleet}
					{
						DestinationBookmark:WarpFleetTo
					}
					else
					{
						DestinationBookmark:WarpTo
					}
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
				case CATEGORYID_STATION
					call Station.DockAtStation ${EntityID}
					break
				Default
					break
			}
		}
		wait 20
		;UI:UpdateConsole["obj_Ship:WarpToBookMark: Exiting", LOG_DEBUG]
	}

	function WarpPrepare()
	{
		UI:UpdateConsole["Preparing for warp"]
		if !${This.HasCovOpsCloak}
		{
			This:Deactivate_Cloak[]
		}
		This.Drones:ReturnAllToDroneBay
		This:Deactivate_SensorBoost

		if ${This.Drones.WaitingForDrones}
		{
			UI:UpdateConsole["Drone deployment already in process, delaying warp (${This.Drones.WaitingForDrones})", LOG_CRITICAL]
			do
			{
				wait 1
			}
			while ${This.Drones.WaitingForDrones}
		}
		variable int Counter = 0

		; *2 because we're only waiting half a second.
		while (${This.Drones.DronesInSpace[FALSE]} > 1 && ${Counter:Inc} < (${Config.Combat.MaxDroneReturnWaitTime}*2))
		{
			wait 5
		}

		This:DeactivateAllMiningLasers[]
		This:UnlockAllTargets[]
	}

	member:bool InWarp()
	{
		if ${Me.InSpace} && ${Me.ToEntity.Mode} == 3
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

		if (!${Me.ToEntity.IsCloaked} && ${This.HasCovOpsCloak})
		{
			This:Activate_Cloak[]
		}
		while !${This.InWarp}
		{
			wait 1
		}
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

	member:bool HasSurveyScanner()
	{
		variable iterator aModuleIterator
		This.ModuleList_SurveyScanners:GetIterator[aModuleIterator]
		return ${aModuleIterator:First(exists)}
	}

	method Activate_SurveyScanner()
	{
		if !${MyShip(exists)}
		{
			return
		}

		if ${Time.Timestamp} < ${SurveyScanWaitTime.Timestamp}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_SurveyScanners:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				; Only allow scans at most every 30 seconds
				SurveyScanWaitTime:Set[${Time.Timestamp}]
				SurveyScanWaitTime.Second:Inc[30]
				SurveyScanWaitTime:Update
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				MyShip.Scanners.Survey[${ModuleIter.Value.ID}]:StartScan
			}
		}
	}

	method Activate_AfterBurner()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_AB_MWD:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
	}

	member:int Total_Armor_Reps()
	{
		return ${This.ModuleList_Repair_Armor.Used}
	}

	method Activate_Armor_Reps()
	{
		if !${MyShip(exists) || }
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Repair_Armor:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
				This.Repairing_Armor:Set[TRUE]
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Armor_Reps()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Repair_Armor:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
	}

	function Deactivate_Shield_Transporter(int64 id)
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
		if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating} && ${ModuleIter.Value.TargetID} == ${id}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Deactivate
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_AfterBurner()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_AB_MWD:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
	}

	method Activate_Shield_Booster()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Regen_Shield:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Shield_Booster()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Regen_Shield:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_Gang_Links()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_GangLinks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Gang_Links()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_GangLinks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_ECM_Burst()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ECM_Burst:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_ECM_Burst()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ECM_Burst:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
		if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_ECCM()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ECCM:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_ECCM()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ECCM:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
		if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_Tracking_Computer()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_TrackingComputer:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Tracking_Computer()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Tracking_Computer:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_Hardeners()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ActiveResists:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Hardeners()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_ActiveResists:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_SensorBoost()
	{
		if !${MyShip(exists)}
		{
			return
		}


		variable iterator ModuleIter

		This.ModuleList_SensorBoost:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_SensorBoost()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_SensorBoost:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_StasisWebs()
	{
		if !${MyShip(exists)}
		{
			return
		}


		variable iterator ModuleIter

		This.ModuleList_StasisWeb:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${Me.ActiveTarget.Distance} < ${ModuleIter.Value.OptimalRange}
			{
				if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
				{
					UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
					ModuleIter.Value:Click
				}
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_StasisWebs()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_StasisWeb:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_TargetPainters()
	{
		if !${MyShip(exists)}
		{
			return
		}


		variable iterator ModuleIter

		This.ModuleList_TargetPainter:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
/*
    * from 0m to optimal range, there's a 100% chance the paint will hit;
    * at optimal + falloff, there's roughly a 50% chance the paint will hit;
    * at optimal + 2 * falloff, there's roughly a 2% chance the paint will hit.
    http://eve.grismar.net/wikka.php?wakka=TargetPainter
*/
				if ${Me.ActiveTarget.Distance} < ${Math.Calc[${ModuleIter.Value.OptimalRange} + ${ModuleIter.Value.AccuracyFalloff}]}
				{
					UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
					ModuleIter.Value:Click
					;TODO We don't break here, we activate all painters on the current target. Future versions will want to user-select distribution
				}
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_TargetPainters()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_TargetPainter:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Activate_Cloak()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter
		variable iterator Salvagers

		This.ModuleList_Salvagers:GetIterator[Salvagers]
		This.ModuleList_Cloaks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
/*
			elseif !${ModuleIter.Value.IsOnline} && ${MyShip.CapacitorPct} > 97
			{
				if ${Math.Calc[${MyShip.CPUOutput}-${MyShip.CPULoad}]} <  ${ModuleIter.Value.CPUUsage} || \
					${Math.Calc[${MyShip.PowerOutput}-${MyShip.PowerLoad}]} <  ${ModuleIter.Value.PowergridUsage}
				{
					if ${Salvagers:First(exists)} && ${Salvagers.Value.IsOnline}
					{
						UI:UpdateConsole["Putting ${Salvagers.Value.ToItem.Name} offline."]
						Salvagers.Value:PutOffline
					}
				}
				else
				{
					UI:UpdateConsole["Putting ${ModuleIter.Value.ToItem.Name} online."]
					ModuleIter.Value:PutOnline
				}
			}
*/
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Cloak()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Cloaks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Offline_Cloak()
	{
		;TODO
		return
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Cloaks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Putting ${ModuleIter.Value.ToItem.Name} offline."]
				ModuleIter.Value:PutOffline
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Online_Salvager()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Putting ${ModuleIter.Value.ToItem.Name} online."]
				ModuleIter.Value:PutOnline
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	member:bool IsCloaked()
	{
		if ${Me.InSpace} && ${Me.ToEntity(exists)} && ${Me.ToEntity.IsCloaked}
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
			wait 1
		}
	}

	function StackAll()
	{
		if ${This.IsCargoOpen}
		{
			EVEWindow[ByItemID, ${MyShip.ID}]:StackAll
		}
	}

	; Returns the salvager range minus 10%
	member:int OptimalSalvageRange()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable iterator ModuleIter

		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			return ${ModuleIter.Value.OptimalRange}
		}

		return 0
	}

	; Returns the tractor range minus 10%
	member:int OptimalTractorRange()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable iterator ModuleIter

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			return ${ModuleIter.Value.OptimalRange}
		}

		return 0
	}

	; Returns the targeting range minus 10%
	member:int OptimalTargetingRange()
	{
		return ${Math.Calc[${MyShip.MaxTargetRange}*0.90]}
	}

	member:bool IsPod()
	{
		variable int GroupID = 0

		if (!${MyShip(exists)})
		{
			return FALSE
		}

		if ${Me.InSpace} && !${Me.InStation}
		{
			GroupID:Set[${MyShip.ToEntity.GroupID}]
		}
		elseif !${Me.InSpace} && ${Me.InStation}
		{
			GroupID:Set[${MyShip.ToItem.GroupID}]
		}
		else
		{
			return FALSE
		}

		if ${GroupID} == GROUP_CAPSULE || ${MyShip.Name.Right[10].Equal["'s Capsule"]}
		{
			if !${This.AlertedInPod}
			{
				Sound:Speak["Critical Information: ${Me.Name} is in a pod"]
				Sound:Speak["How we deal with death is at least as important as how we deal with life\\, wouldn't you say??", 1.1]
				UI:UpdateConsole["Critical Information: ${Me.Name} is in a pod", LOG_CRITICAL]
				This.AlertedInPod:Set[TRUE]
			}
			return TRUE
		}
		This.AlertedInPod:Set[FALSE]
		return FALSE
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

	method Activate_Tractor()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline}
			{
				UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]

				ModuleIter.Value:Activate
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Tractor()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
		if ${ModuleIter.Value.IsActive} && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method OrbitAtOptimal()
	{
		variable int OrbitDistance = 5000

		if !${MyShip(exists)}
		{
			return
		}
		if ${This.ReloadingWeapons}
		{
			return
		}
		if ${Me.ToEntity.Mode} == 4 || ${Me.ToEntity.Mode} == 1
		{
			; already orbiting something
			This:Activate_AfterBurner
			return
		}

		variable iterator ModuleIter
		This.ModuleList_Weapon:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			OrbitDistance:Set[${Math.Calc[${ModuleIter.Value.Charge.MaxFlightTime}*${ModuleIter.Value.Charge.MaxVelocity}*.85]}]
			if ${ModuleIter.Value.OptimalRange} > ${OrbitDistance}
			{
				OrbitDistance:Set[${ModuleIter.Value.OptimalRange}]
			}
			if ${OrbitDistance} == 0
			{
				return
			}
			UI:UpdateConsole["Orbiting active target at ${Math.Calc[${OrbitDistance}/1000]} KM."]
			Me.ActiveTarget:Orbit[${OrbitDistance}]
		}
	}

	method KeepAtRangeAtOptimal()
	{
		variable int KeepAtRangeDistance = 5000

		if !${MyShip(exists)}
		{
			return
		}
		if ${This.ReloadingWeapons}
		{
			return
		}
		if ${Me.ToEntity.Mode} == 4 || ${Me.ToEntity.Mode} == 1
		{
			; already Keeping something AtRange
			This:Activate_AfterBurner
			return
		}

		variable iterator ModuleIter
		This.ModuleList_Weapon:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			KeepAtRangeDistance:Set[${Math.Calc[${ModuleIter.Value.Charge.MaxFlightTime}*${ModuleIter.Value.Charge.MaxVelocity}*.85]}]
			if ${ModuleIter.Value.OptimalRange} > ${KeepAtRangeDistance}
			{
				KeepAtRangeDistance:Set[${ModuleIter.Value.OptimalRange}]
			}
			if ${KeepAtRangeDistance} == 0
			{
				return
			}
			UI:UpdateConsole["KeepingAtRange active target at ${Math.Calc[${KeepAtRangeDistance}/1000]} KM."]
			Me.ActiveTarget:KeepAtRange[${KeepAtRangeDistance}]
		}
	}

	method Activate_Weapons()
	{
		if !${MyShip(exists)}
		{
			return
		}
		if ${This.ReloadingWeapons}
			return

		variable iterator ModuleIter

		This.ModuleList_Weapon:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			;UI:UpdateConsole["ModuleIter.Value.IsActive = ${ModuleIter.Value.IsActive}"]
			;UI:UpdateConsole["ModuleIter.Value.IsReloading = ${ModuleIter.Value.IsReloading}"]
			;UI:UpdateConsole["ModuleIter.Value.IsOnline = ${ModuleIter.Value.IsOnline}"]
			if !${ModuleIter.Value.IsActive} && !${ModuleIter.Value.IsReloading} && ${ModuleIter.Value.IsOnline}
			{
				;;UI:UpdateConsole["Activating ${ModuleIter.Value.ToItem.Name}"]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Deactivate_Weapons()
	{
		if !${MyShip(exists)}
		{
			return
		}

		variable iterator ModuleIter

		This.ModuleList_Weapon:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if (${ModuleIter.Value.IsActive} || ${ModuleIter.Value.IsWaitingForActiveTarget}) && ${ModuleIter.Value.IsOnline} && !${ModuleIter.Value.IsDeactivating}
			{
				;;UI:UpdateConsole["Deactivating ${ModuleIter.Value.ToItem.Name}", LOG_MINOR]
				ModuleIter.Value:Click
			}
		}
		while ${ModuleIter:Next(exists)}
	}

	method Reload_Weapons(bool ForceReload)
	{
		variable bool NeedReload = FALSE
		variable int CurrentCharges = 0

		if !${MyShip(exists) || ${This.ReloadingWeapons}}
		{
			return
		}

		if !${ForceReload}
		{
			variable iterator ModuleIter
			This.ModuleList_Weapon:GetIterator[ModuleIter]
			if ${ModuleIter:First(exists)}
			do
			{
				if !${ModuleIter.Value.IsActive} && !${ModuleIter.Value.IsReloading}
				{
					; Sometimes this value can be NULL
					if !${ModuleIter.Value.MaxCharges(exists)}
					{
						UI:UpdateConsole["Sanity check failed... weapon has no MaxCharges!"]
						NeedReload:Set[TRUE]
						break
					}

					; Has ammo been used?
					if ${ModuleIter.Value.CurrentCharges} > 0
					{
						CurrentCharges:Set[${ModuleIter.Value.CurrentCharges}]
					}
					else
					{
						CurrentCharges:Set[${ModuleIter.Value.Charge.Quantity}]
					}

					if ${CurrentCharges} != ${ModuleIter.Value.MaxCharges}
					{
						;UI:UpdateConsole["ModuleIter.Value.CurrentCharges = ${ModuleIter.Value.CurrentCharges}"]
						;UI:UpdateConsole["ModuleIter.Value.MaxCharges = ${ModuleIter.Value.MaxCharges}"]
						;UI:UpdateConsole["ModuleIter.Value.Charge.Quantity = ${ModuleIter.Value.Charge.Quantity}"]
						; Is there still more then 30% ammo available?
						if ${Math.Calc[${ModuleIter.Value.CurrentCharges}/${ModuleIter.Value.MaxCharges}]} < 0.3
						{
							; No, reload
							NeedReload:Set[TRUE]
						}
					}
				}
			}
			while ${ModuleIter:Next(exists)}
		}

		; ignore forced reload if we can only have one charge
		; Can't use an iterator that hasn't been initialized OR has no value. Reverting this change. - Valerian
		; ReloadingWeapons is reset in Ship.Pulse every 12 seconds.
		if !${This.ReloadingWeapons} && (${ForceReload} || ${NeedReload})
		{
			UI:UpdateConsole["Reloading Weapons..."]
			EVE:Execute[CmdReloadAmmo]
			This.ReloadingWeapons:Set[${Time.Timestamp}]
		}
	}

	member:string Type()
	{
		if ${Station.Docked}
		{
			return ${MyShip.ToItem.Type}
		}
		elseif ${Me.InSpace} && !${Me.InStation}
		{
			return ${Me.ToEntity.Type}
		}
	}

	member:int TypeID()
	{
		if ${Station.Docked}
		{
			return ${MyShip.ToItem.TypeID}
		}
		elseif ${Me.InSpace} && !${Me.InStation}
		{
			return ${Me.ToEntity.TypeID}
		}
	}

	function ActivateShip(string name)
	{
		variable index:item hsIndex
		variable iterator hsIterator
		variable string shipName

		if ${Station.Docked}
		{
			Me:GetHangarShips[hsIndex]
			hsIndex:GetIterator[hsIterator]

			shipName:Set[${MyShip}]
			if ${shipName.NotEqual[${name}]}
			{
				if ${hsIterator:First(exists)}
				{
					do
					{
						if ${hsIterator.Value.Name.Equal[${name}]}
						{
							UI:UpdateConsole["obj_Ship: Switching to ship named ${hsIterator.Value.Name}."]
							hsIterator.Value:MakeActive
							break
						}
					}
					while ${hsIterator:Next(exists)}
				}
			}
		}
	}
}
