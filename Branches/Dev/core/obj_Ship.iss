/*
	Ship class

	Main object for interacting with the ship and its functions

	-- CyberTech

*/

#macro Validate_Ship()
		if !${MyShip(exists)} || !${EVEBot.SessionValid}
		{
			return
		}
#endmac

#macro Define_ModuleMethod(_Activate_FunctionName, _Deactivate_FunctionName, _ModuleIndex, _LOG)
	method _Activate_FunctionName(bool LOG=_LOG)
	{
		if !${EVEBot.SessionValid}
		{
			return
		}

		variable iterator Module

		_ModuleIndex:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{

			/* Validation:
					Module is:
						Online
						Not Active
						Has no optimal range OR active target is within it
						Has no charges OR is not reloading ammo
			*/
			if !${Module.Value.IsActive} && ${Module.Value.IsOnline} && \
				(!${Module.Value.OptimalRange(exists)} || ${Me.ActiveTarget.Distance} < ${Module.Value.OptimalRange}) && \
				(!${Module.Value.Charge(exists)} || (!${Module.Value.IsReloading}))
			{
				if ${LOG}
				{
					Logger:Log["Activating ${Module.Value.ToItem.Name}"]
				}
				Module.Value:Activate
			}

			if !${EVEBot.SessionValid}
			{
				return
			}
		}
		while ${Module:Next(exists)}
	}

	method _Deactivate_FunctionName(bool LOG=_LOG)
	{
		Validate_Ship()

		variable iterator Module

		_ModuleIndex:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if (${Module.Value.IsActive} || ${Module.Value.IsWaitingForActiveTarget}) && \
				${Module.Value.IsOnline} && !${Module.Value.IsDeactivating}
			{
				if ${LOG}
				{
					Logger:Log["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				}
				Module.Value:Deactivate
			}
		}
		while ${Module:Next(exists)}
	}
#endmac

objectdef obj_Ship inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"

	variable int MODE_WARPING = 3

	variable float BaselineUsedCargo
	variable bool CargoIsOpen
	variable int RetryUpdateModuleList
	variable index:module ModuleList
	variable index:module ModuleList_ShieldTransporters
	variable index:module ModuleList_MiningLaser
	variable index:module ModuleList_Weapon
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
	variable bool Repairing_Armor = FALSE
	variable bool Repairing_Hull = FALSE
	variable float m_MaxTargetRange
	variable bool m_WaitForCapRecharge = FALSE
	variable int m_CargoSanityCounter = 0
	variable bool InteruptWarpWait = FALSE
	variable bool AlertedInPod

	variable collection:float HybridNameModPairs
	variable collection:float AmmoNameModPairs
	variable collection:float FrequencyNameModPairs
	variable collection:float TurretBaseOptimals
	variable collection:string HybridLookupTable
	variable collection:string AmmoLookupTable
	variable collection:string FrequencyLookupTable
	variable collection:collection:float TurretMinimumRanges
	variable collection:collection:float TurretMaximumRanges
	variable bool LookupTableBuilt = FALSE
	variable collection:string TurretSlots
	variable bool HaveTrackingEnhancer = FALSE

	;Change these to change min/maxrange mod.
	variable float TurretMinRangeMod = 0.4
	variable float TurretMaxRangeMod = 1.2

	variable obj_Drones Drones

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This:StopShip[]
		This:UpdateModuleList[]
		This:PopulateNameModPairs[]

		PulseTimer:SetIntervals[2.0,3.0]
		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if !${EVEBot.Loaded} || ${EVEBot.Disabled}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			if ${EVEBot.SessionValid}
			{
				if ${Me.InSpace}
				{
					This:ValidateModuleTargets

					if ${RetryUpdateModuleList} == 10
					{
						Logger:Log["ERROR: obj_Ship:UpdateModuleList - No modules found. Pausing.", LOG_CRITICAL]
						Logger:Loge["ERROR: obj_Ship:UpdateModuleList - If this ship has slots, you must have at least one module equipped, of any type.", LOG_CRITICAL]
						RetryUpdateModuleList:Set[0]
						Defense:RunAway["ERROR: obj_Ship - No modules found"]
					}

					if ${RetryUpdateModuleList} > 0
					{
						This:UpdateModuleList
					}

					if !${This.LookupTableBuilt}
					{
						;if we have Weapon Enhance modules, slightly lower min range and raise max range
						if ${This.HaveTrackingEnhancer}
						{
							;Track 9.5% faster; 1/1.095=~0.91
							This.TurretMinRangeMod:Set[${Math.Calc[${This.TurretMinRangeMod} * 0.91]}]
							;+15% optimal range
							This.TurretMaxRangeMod:Set[${Math.Calc[${This.TurretMaxRangeMod} * 1.15]}]
						}
						This:BuildLookupTables
					}
				}
			}

			This.PulseTimer:Update
		}
	}

	method PopulateNameModPairs()
	{
		HybridNameModPairs:Set["Spike",1.8]
		HybridNameModPairs:Set["Iron",1.6]
		HybridNameModPairs:Set["Tungsten",1.4]
		HybridNameModPairs:Set["Null",1.25]
		HybridNameModPairs:Set["Iridium",1.2]
		HybridNameModPairs:Set["Lead",1]
		HybridNameModPairs:Set["Thorium",0.875]
		HybridNameModPairs:Set["Uranium",0.75]
		HybridNameModPairs:Set["Void",0.75]
		HybridNameModPairs:Set["Plutonium",0.625]
		HybridNameModPairs:Set["Antimatter",0.5]
		HybridNameModPairs:Set["Javelin",0.25]

		AmmoNameModPairs:Set["Tremor",1.8]
		AmmoNameModPairs:Set["Carbonized Lead",1.6]
		AmmoNameModPairs:Set["Nuclear",1.4]
		AmmoNameModPairs:Set["Proton",1.2]
		AmmoNameModPairs:Set["Depleted Uranium",1]
		AmmoNameModPairs:Set["Barrage",1]
		AmmoNameModPairs:Set["Titanium Sabot",0.875]
		AmmoNameModPairs:Set["Fusion",0.75]
		AmmoNameModPairs:Set["Phased Plasma",0.625]
		AmmoNameModPairs:Set["EMP",0.5]
		AmmoNameModPairs:Set["Hail",0.5]
		AmmoNameModPairs:Set["Quake",0.25]

		FrequencyNameModPairs:Set["Aurora",1.8]
		FrequencyNameModPairs:Set["Radio",1.6]
		FrequencyNameModPairs:Set["Scorch",1.5]
		FrequencyNameModPairs:Set["Microwave",1.4]
		FrequencyNameModPairs:Set["Infrared",1.2]
		FrequencyNameModPairs:Set["Standard",1]
		FrequencyNameModPairs:Set["Ultraviolet",0.875]
		FrequencyNameModPairs:Set["Xray",0.75]
		FrequencyNameModPairs:Set["Gamma",0.625]
		FrequencyNameModPairs:Set["Multifrequency",0.5]
		FrequencyNameModPairs:Set["Conflagration",0.5]
		FrequencyNameModPairs:Set["Gleam",0.25]
	}

	/* float HitChance(int64 EntityID, int turret):
	Calculate the chance to hit to the best of our ability. */
	member:float HitChance(int64 EntityID, int turret, float falloff, float tracking)
	{
		variable float Blob
		variable int AvgSigRadius
		variable float TurretOptimal
		variable float Max = 0

		if ${TurretBaseOptimals.Element[${turret}](exists)}
		{
			TurretOptimal:Set[${TurretBaseOptimals.Element[${turret}]}]
		}
		else
		{
			TurretBaseOptimals:Set[${turret},${This.TurretBaseOptimal[${turret}]}]
			TurretOptimal:Set[${TurretBaseOptimals.Element[${turret}]}]
		}

		if ${Math.Calc[${Entity[${EntityID}].Distance} - ${TurretOptimal}]} > 0
		{
			Max:Set[${Math.Calc[${Entity[${EntityID}].Distance} - ${TurretOptimal}]}]
		}

		if ${Entity[${EntityID}].Name.Find[Battleship](exists)} || ${Entity[${EntityID}].Name.Find[Hauler]}
		{
			AvgSigRadius:Set[450]
		}
		elseif ${Entity[${EntityID}].Name.Find[Battlecruiser](exists)}
		{
			AvgSigRadius:Set[280]
		}
		elseif ${Entity[${EntityID}].Name.Find[Cruiser](exists)}
		{
			AvgSigRadius:Set[140]
		}
		elseif ${Entity[${EntityID}].Name.Find[Frigate](exists)}
		{
			AvgSigRadius:Set[35]
		}

		Blob:Set[${Math.Calc[((1/${tracking}) * (${Entity[${EntityID}].TransverseVelocity}/${Entity[${EntityID}].Distance}) * (${MyShip.ScanResolution} / ${AvgSigRadius})) ^^ 2 + \
			(${Max} / ${falloff}) ^^ 2]}]

			return 0.5 && ${Blob}
	}

	/* void BuildLookupTables():
	Build a lookup table for ranges at which we change ammo, and what ammo we change to.
	Warning: THIS IS A *VERY* EXPENSIVE CALL. */
	method BuildLookupTables()
	{
		Logger:Log["obj_Ship:BuildLookupTables[]: called."]
		variable index:item AvailableCharges
		variable iterator Weapon
		variable iterator AvailableCharge
		variable iterator LookupIterator
		variable string ChargeType

		This.ModuleList_Weapon:GetIterator[Weapon]
		variable float BaseOptimal

		variable int CurrentTurret = 0
		variable int idx
		for ( idx:Set[0]; ${idx} <= 7; idx:Inc )
		{
			CurrentTurret:Inc
			Logger:Log["obj_Ship:BuildLookupTables[]: HiSlot${idx}: ${MyShip.Module[HiSlot${idx}].ToItem.Name} ${MyShip.Module[HiSlot${idx}].ToItem.GroupID}"]
			switch ${MyShip.Module[HiSlot${idx}].ToItem.GroupID}
			{
				case GROUP_PROJECTILEWEAPON
				case GROUP_HYBRIDWEAPON
				case GROUP_ENERGYWEAPON
					This.TurretSlots:Set[${CurrentTurret},HiSlot${idx}]
					break
			}
		}

		if ${Weapon:First(exists)}
		{
			do
			{
				BaseOptimal:Set[${This.TurretBaseOptimal[${Weapon.Key}]}]
				Logger:Log["obj_Ship:BuildLookupTables[]: TurretBaseOptimals.Element[${Weapon.Key}]: ${TurretBaseOptimals.Element[${Weapon.Key}]}"]

				Weapon.Value:GetAvailableAmmo[AvailableCharges]
				AvailableCharges:GetIterator[AvailableCharge]

				Logger:Log["obj_Ship:BuildLookupTables[]: GroupID: ${Weapon.Value.ToItem.GroupID}"]
				switch ${Weapon.Value.ToItem.GroupID}
				{
					case GROUP_PROJECTILEWEAPON
						ChargeType:Set[Ammo]
						break
					case GROUP_HYBRIDWEAPON
						ChargeType:Set[Hybrid]
						break
					case GROUP_ENERGYWEAPON
						ChargeType:Set[Frequency]
						break
				}
				Logger:Log["obj_Ship:BuildLookupTables[]: ChargeType: ${ChargeType}"]
				${ChargeType}NameModPairs:GetIterator[LookupIterator]

				if ${AvailableCharge:First(exists)}
				{
					do
					{
						Logger:Log["obj_Ship.BuildLookupTables[]: Weapon: ${Weapon.Key}, Available Charge: ${AvailableCharge.Value.Name}"]
						if ${LookupIterator:First(exists)}
						{
							do
							{
								Logger:Log["obj_Ship.BuildLookupTables[]: Weapon: ${Weapon.Key}, Lookup Charge: ${LookupIterator.Key}"]
								if ${AvailableCharge.Value.Name.Find[${LookupIterator.Key}](exists)}
								{
									Logger:Log["obj_Ship:BuildLookupTables[]: ${ChargeType}, ${LookupIterator.Key}, ${LookupIterator.Value}, ${Math.Calc[${BaseOptimal} * ${LookupIterator.Value}]}"]
									${ChargeType}LookupTable:Set[${Math.Calc[${BaseOptimal} * ${LookupIterator.Value}]}, ${LookupIterator.Key}]
									if !${This.TurretMinimumRanges.Element[${Weapon.Key}](exists)}
									{
										This.TurretMinimumRanges:Set[${Weapon.Key}]
									}
									This.TurretMinimumRanges.Element[${Weapon.Key}]:Set[${LookupIterator.Key},${Math.Calc[${BaseOptimal} * ${LookupIterator.Value} * ${This.TurretMinRangeMod}]}]
									if !${This.TurretMaximumRanges.Element[${Weapon.Key}](exists)}
									{
										This.TurretMaximumRanges:Set[${Weapon.Key}]
									}
									This.TurretMaximumRanges.Element[${Weapon.Key}]:Set[${LookupIterator.Key},${Math.Calc[${BaseOptimal} * ${LookupIterator.Value} * ${This.TurretMaxRangeMod}]}]
									Logger:Log["obj_Ship:BuildLookupTables[]: ${Weapon.Key}, ${This.TurretMinimumRanges.Element[${Weapon.Key}](exists)}, ${LookupIterator.Key}, ${This.TurretMinimumRanges.Element[${Weapon.Key}].Element[${LookupIterator.Key}]} ${This.TurretMinimumRanges.Element[${Weapon.Key}].Used} ${BaseOptimal} ${LookupIterator.Value}"]
									Logger:Log["obj_Ship:BuildLookupTables[]: ${Weapon.Key}, ${This.TurretMaximumRanges.Element[${Weapon.Key}](exists)}, ${LookupIterator.Key}, ${This.TurretMaximumRanges.Element[${Weapon.Key}].Element[${LookupIterator.Key}]} ${This.TurretMaximumRanges.Element[${Weapon.Key}].Used} ${BaseOptimal} ${LookupIterator.Value}"]
									break
								}
							}
							while ${LookupIterator:Next(exists)}
						}
					}
					while ${AvailableCharge:Next(exists)}
				}
			}
			while ${Weapon:Next(exists)}
		}
		This.LookupTableBuilt:Set[TRUE]
	}

	/* bool NeedAmmoChange(float range, int turret):
	Return true if we are currently using a different ammo than is optimal in specified turret. Otherwise return false. */
	member:bool NeedAmmoChange(float range, int turret)
	{
		variable string BestAmmo = ${This.BestAmmoTypeByRange[${range},${turret}]}
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		Logger:Log["obj_Ship.NeedAmmoChange[${range},${turret}]: BestAmmo: ${BestAmmo}",LOG_DEBUG]
		variable bool FoundAmmo = FALSE

		if ${MyShip.Module[${slot}].Charge.Name.Find[${BestAmmo}](exists)}
		{
			FoundAmmo:Set[TRUE]
		}
		else
		{
			FoundAmmo:Set[FALSE]
		}
		/* If we DON'T find our optimal ammo, we DO need an ammo change */
		if !${FoundAmmo}
		{
			return TRUE
		}
		return FALSE
	}

	/* LoadOptimalAmmo(float range, int turret):
	Determine the best ammo type for passed turret at passed range and swap to it. */
	method LoadOptimalAmmo(float range, int turret)
	{
		variable string BestAmmo = ${This.BestAmmoTypeByRange[${range},${turret}]}
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		Logger:Log["obj_Ship:LoadOptimalAmmo(${range}): Best Ammo: ${BestAmmo}",LOG_DEBUG]

		variable index:item AmmoIndex
		variable iterator AmmoIterator

		MyShip.Module[${slot}]:GetAvailableAmmo[AmmoIndex]
		AmmoIndex:GetIterator[AmmoIterator]
		if ${AmmoIterator:First(exists)}
		{
			do
			{
				Logger:Log["obj_Ship:LoadOptimalAmmo(${range},${turret}): Found best ammo: ${AmmoIterator.Value.Name.Find[${BestAmmo}](exists)}",LOG_DEBUG]
				if ${AmmoIterator.Value.Name.Find[${BestAmmo}](exists)} && !${MyShip.Module[${slot}].Charge.Name.Find[${BestAmmo}](exists)}
				{
					Logger:Log["obj_Ship:LoadOptimalAmmo(${range},${turret}): Changing ammo to ${AmmoIterator.Value.ID}/${AmmoIterator.Value.Name}, ${MyShip.Module[${slot}].MaxCharges}. Turret Active? ${MyShip.Module[${slot}].IsActive}",LOG_DEBUG]
					MyShip.Module[${slot}]:ChangeAmmo[${AmmoIterator.Value.ID},${MyShip.Module[${slot}].MaxCharges}]
					return
				}
			}
			while ${AmmoIterator:Next(exists)}
		}
	}

	/* float GetMaximumTurretRange(int turret):
	Get the slot for the passed Turret, get its current ammo type, and check against the MaximumRanges dictionary for a match. */
	member:float GetMaximumTurretRange(int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}

		if !${MyShip.Module[${slot}].Charge(exists)}
		{
			return ${Math.Calc[${This.TurretBaseOptimal[${turret}]} * ${This.TurretMaxRangeMod}]}
		}

		variable string ChargeName = ${MyShip.Module[${slot}].Charge.Name}
		variable iterator RangeIterator
		Logger:Log["obj_Ship This.TurretMaximumRanges.Element[${turret}](exists) ${This.TurretMaximumRanges.Element[${turret}](exists)} ${This.TurretMaximumRanges.Element[${turret}].Used}",LOG_DEBUG]
		if ${This.TurretMaximumRanges.Element[${turret}](exists)}
		{
			This.TurretMaximumRanges.Element[${turret}]:GetIterator[RangeIterator]
			if ${RangeIterator:First(exists)}
			{
				do
				{
					Logger:Log["obj_Ship range ${RangeIterator.Key} ${RangeIterator.Value}",LOG_DEBUG]
					if ${ChargeName.Find[${RangeIterator.Key}](exists)}
					{
						return ${RangeIterator.Value}
					}
				}
				while ${RangeIterator:Next(exists)}
			}
		}
		;If something didn't return, something broke. Record it.
		Logger:Log["obj_Ship.GetMaximumTurretRange(${turret}): Could not find a match for ${ChargeName} in the TurretMaximumRanges dictionary!",LOG_CRITICAL]
		;This.BuildLookupTables[]
		return ${This.TurretMaximumRanges.Element[${turret}].Element[${MyShip.Module[${slot}].Charge.Name}]}
	}

	/* float GetMinimumTurretRange(int turret):
	Get the slot for the passed Turret, get its current ammo type, and check against the MinimumRanges dictionary for a match. */
	member:float GetMinimumTurretRange(int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}

		if !${MyShip.Module[${slot}].Charge(exists)}
		{
			return ${Math.Calc[${This.TurretBaseOptimal[${turret}]} * ${This.TurretMinRangeMod}]}
		}

		variable string ChargeName = ${MyShip.Module[${slot}].Charge.Name}
		variable iterator RangeIterator
		;echo "This.TurretMinimumRanges.Element[${turret}](exists) ${This.TurretMinimumRanges.Element[${turret}](exists)}"
		if ${This.TurretMinimumRanges.Element[${turret}](exists)}
		{
			This.TurretMinimumRanges.Element[${turret}]:GetIterator[RangeIterator]
			;echo "This.TurretMinimumRanges.Element[${turret}].Used ${This.TurretMinimumRanges.Element[${turret}].Used}"
			if ${RangeIterator:First(exists)}
			{
				do
				{
					Logger:Log["obj_Ship range ${RangeIterator.Key} ${RangeIterator.Value}",LOG_DEBUG]
					if ${ChargeName.Find[${RangeIterator.Key}]}
					{
						return ${RangeIterator.Value}
					}
				}
				while ${RangeIterator:Next(exists)}
			}
		}
		Logger:Log["obj_Ship.GetMinimumTurretRange(${turret},${ChargeType},${ChargeName}): Could not find charge ${ChargeName} in TurretMinimumRanges dictionary!",LOG_DEBUG]
		This.TurretMinimumRanges.Element[${turret}]:Set[${MyShip.Module[${slot}].Charge.Name},${Math.Calc[${This.TurretMinRangeMod} * ${This.TurretBaseOptimal[${turret}]}]}]
		return ${This.TurretMinimumRanges.Element[${turret}].Element[${MyShip.Module[${slot}].Charge.Name}]}
	}

	/* float TurretBaseOptimal(int turret):
	Calculate and return the base optimal range for passed turret. */
	member:float TurretBaseOptimal(int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		Logger:Log["obj_Ship.GetTurretBaseOptimal[${turret}]: Slot ${slot}, Module ${MyShip.Module[${slot}].ToItem.Name}, GroupID ${MyShip.Module[${slot}].ToItem.GroupID}"]
		variable float BaseOptimal = 0

		switch ${MyShip.Module[${slot}].ToItem.GroupID}
		{
			case GROUP_PROJECTILEWEAPON
				return ${This.GetTurretBaseOptimal[${turret},Ammo]}
			case GROUP_HYBRIDWEAPON
				return ${This.GetTurretBaseOptimal[${turret},Hybrid]}
			case GROUP_ENERGYWEAPON
				return ${This.GetTurretBaseOptimal[${turret},Frequency]}
			case GROUP_MOON
				;Figure out what the hell the correct one is since we've not yet cycled ammo
				;First check against normal ammo
				BaseOptimal:Set[${This.GetTurretBaseOptimal[${turret},Ammo]}]
				;If that didn't have a match, check against hybrid ammo
				if ${BaseOptimal} == 0
				{
					BaseOptimal:Set[${This.GetTurretBaseOptimal[${turret},Hybrid]}]
				}
				;If we couldn't match against ammo or hybrid ammo, check requency
				if ${BaseOptimal} == 0
				{
					BaseOptimal:Set[${This.GetTurretBaseOptimal[${turret},Frequency]}]
				}
				;If we had a match, return.
				if ${BaseOptimal} != 0
				{
					return ${BaseOptimal}
				}
				;If we didn't have a match... fallthrough to default
			default
				;Logger:Log["obj_Ship.TurretBaseOptimal: Unrecognized group for the weapon's charge, something is very broken. Group: ${WeaponIterator.Value.Charge.Group} ${WeaponIterator.Value.Charge.GroupID}",LOG_CRITICAL]
				return ${MyShip.Module[${slot}].OptimalRange}
		}
	}

	member:float GetTurretBaseOptimal(int turret, string ChargeType)
	{
		if ${This.TurretBaseOptimals.Element[${turret}](exists)}
		{
			return ${This.TurretBaseOptimals.Element[${turret}]}
		}

		variable string slot = ${This.TurretSlots[${turret}]}
		Logger:Log["obj_Ship.GetTurretBaseOptimal[${turret}]: Slot ${slot}"]
		variable index:item AmmoIndex
		variable iterator AmmoIterator

		variable float BaseOptimal
		variable float RangeMod = 0

		variable iterator FrequencyPairIterator
		variable iterator HybridPairIterator
		variable iterator AmmoPairIterator
		FrequencyNameModPairs:GetIterator[FrequencyPairIterator]
		HybridNameModPairs:GetIterator[HybridPairIterator]
		AmmoNameModPairs:GetIterator[AmmoPairIterator]

		if !${MyShip.Module[${slot}].Charge(exists)}
		{
			RangeMod:Set[${MyShip.Module[${slot}].OptimalRange}]
		}

		if ${${ChargeType}PairIterator:First(exists)}
		{
			do
			{
				if ${MyShip.Module[${slot}].Charge.Name.Find[${${ChargeType}PairIterator.Key}]}
				{
					Logger:Log["obj_Ship.GetTurretBaseOptimal[${turret},${ChargeType}]: Found ammo ${${ChargeType}PairIterator.Key}, mod ${${ChargeType}PairIterator.Value}",LOG_DEBUG]
					RangeMod:Set[${${ChargeType}PairIterator.Value}]
					break
				}
			}
			while ${${ChargeType}PairIterator:Next(exists)}
		}

		if ${RangeMod} != 0
		{
			BaseOptimal:Set[${Math.Calc[${MyShip.Module[${slot}].OptimalRange} / ${RangeMod}]}]
			Logger:Log["obj_Ship.GetTurretBaseOptimal(${turret}): Turret's base optimal: ${BaseOptimal}.",LOG_DEBUG]
		}
		Logger:Log["obj_Ship.GetTurretBaseOptimal(${turret}): Returning calculated base optimal: ${BaseOptimal}",LOG_DEBUG]
		This.TurretBaseOptimals:Set[${turret},${BaseOptimal}]
		return ${BaseOptimal}
	}

	/* string BestAmmoTypeByRange(float range, int turret):
	Return a string designating mest ammo type at a given range by determining what type of charge
	turret requires and calling GetBestAmmoTypeByRange using that charge type */
	member:string BestAmmoTypeByRange(float range, int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		variable string BestAmmoType

		switch ${MyShip.Module[${slot}].ToItem.GroupID}
		{
			case GROUP_PROJECTILEWEAPON
				return ${This.GetBestAmmoTypeByRange[${range},${turret},Ammo]}
			case GROUP_HYBRIDWEAPON
				return ${This.GetBestAmmoTypeByRange[${range},${turret},Hybrid]}
			case GROUP_ENERGYWEAPON
				return ${This.GetBestAmmoTypeByRange[${range},${turret},Frequency]}
			case GROUP_MOON
				;Figure out what the hell the correct one is since we've not yet cycled ammo
				;First check against normal ammo
				BestAmmoType:Set[${This.GetBestAmmoTypeByRange[${range},${turret},Ammo]}]
				;If that didn't have a match, check against hybrid ammo
				if ${BestAmmoType.Length} == 0
				{
					BestAmmoType:Set[${This.GetBestAmmoTypeByRange[${range},${turret},Hybrid]}]
				}
				;If we couldn't match against ammo or hybrid ammo, check requency
				if ${BestAmmoType.Length} == 0
				{
					BestAmmoType:Set[${This.GetBestAmmoTypeByRange[${range},${turret},Frequency]}]
				}
				;If we had a match, return.
				if ${BestAmmoType.Length} != 0
				{
					return ${BestAmmoType}
				}
				;If we didn't have a match... fallthrough to default
			default
				Logger:Log["obj_Ship.BestAmmoTypeByRange: Unrecognized group for the weapon's charge, something is very broken. Group: ${MyShip.Module[${slot}].Charge.Group} ${MyShip.Module[${slot}].Charge.GroupID} ${MyShip.Module[${slot}].IsReloading}",LOG_CRITICAL]
				return ${WeaponIterator.Value.Charge}
		}
	}

	/* string GetBestAmmoTypeByRange(float range, int turret, string ChargeType):
	Return a string designating the best ammo type at a given range for a given turret. */
	member:string GetBestAmmoTypeByRange(float range, int turret, string ChargeType)
	{
		variable string slot = ${This.TurretSlots[${turret}]}
		Logger:Log["obj_Ship.GetBestAmmoTypeByRange(${range},${turret},${ChargeType}): called, slot ${slot}",LOG_DEBUG]

		variable index:item AmmoIndex
		variable iterator AmmoIterator

		variable float RangeMod
		variable float TurretOptimal

		variable iterator FrequencyPairIterator
		variable iterator HybridPairIterator
		variable iterator AmmoPairIterator
		FrequencyLookupTable:GetIterator[FrequencyPairIterator]
		HybridLookupTable:GetIterator[HybridPairIterator]
		AmmoLookupTable:GetIterator[AmmoPairIterator]

		variable float OldDelta = 0
		variable float NewDelta = 0
		variable string BestSoFar
		variable string HighestSoFar
		variable float HighestRangeSoFar = 0
		variable bool BestFound = FALSE

		;Moved these down here = doesn't help at all to get available ammo for a freakin' nonexistent WeaponIterator value!
		; This must have worked previously out of pure luck
		MyShip.Module[${slot}]:GetAvailableAmmo[AmmoIndex]
		AmmoIndex:GetIterator[AmmoIterator]

		variable float BaseOptimal = ${TurretBaseOptimals.Element[${turret}]}
		Logger:Log["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): BaseOptimal: ${BaseOptimal}",LOG_DEBUG]

		; Do some math on our range to 'reduce' it a little, i.e. if our target is at 25km, math it down to 22.5 or 25
		; This will help reduce the number of ammo changes as we can certainly hit well at that little deviation, and
		; it will help account for rats moving towards us (common).
		range:Set[${Math.Calc[${range} * 0.85]}]
		; 0.85 is pretty random. I should see if there is a "better"

		/*figure out the best ammo for a given range. */
		if ${AmmoIterator:First(exists)}
		{
			do
			{
				if ${${ChargeType}PairIterator:First(exists)}
				{
					do
					{
						if ${AmmoIterator.Value.Name.Find[${${ChargeType}PairIterator.Value}]}
						{
							NewDelta:Set[${Math.Calc[${${ChargeType}PairIterator.Key} - ${range}]}]
							if ${NewDelta} > 0 && (${NewDelta} < ${OldDelta} || ${OldDelta} == 0)
							{
								BestSoFar:Set[${${ChargeType}PairIterator.Value}]
								BestFound:Set[TRUE]
								OldDelta:Set[${NewDelta}]
							}

							if ${HighestRangeSoFar} == 0 || ${NewDelta} > ${HighestRangeSoFar}
							{
								HighestRangeSoFar:Set[${NewDelta}]
								HighestSoFar:Set[${${ChargeType}PairIterator.Value}]
							}
							break
						}
					}
					while ${${ChargeType}PairIterator:Next(exists)}
				}
			}
			while ${AmmoIterator:Next(exists)}
		}
		if ${${ChargeType}PairIterator:First(exists)}
		{
			do
			{
				if ${MyShip.Module[${slot}].Charge.Name.Find[${${ChargeType}PairIterator.Value}]}
				{
					Logger:Log["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): including already loaded ammo in our check!",LOG_DEBUG]
					NewDelta:Set[${Math.Calc[${${ChargeType}PairIterator.Key} - ${range}]}]
					Logger:Log["NewDelta: ${NewDelta}, ${Math.Calc[${${ChargeType}PairIterator.Key} - ${range}]}, OldDelta: ${OldDelta}",LOG_DEBUG]
					if ${NewDelta} > 0 && (${NewDelta} < ${OldDelta} || ${OldDelta} == 0)
					{
						BestSoFar:Set[${${ChargeType}PairIterator.Value}]
						Logger:Log["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): BestSoFar: ${BestSoFar}, NewDelta ${NewDelta}, OldDelta ${OldDelta}",LOG_DEBUG]
						BestFound:Set[TRUE]
						OldDelta:Set[${NewDelta}]
					}

					if ${HighestRangeSoFar} == 0 || ${NewDelta} > ${HighestRangeSoFar}
					{
						HighestRangeSoFar:Set[${NewDelta}]
						HighestSoFar:Set[${${ChargeType}PairIterator.Value}]
					}
					break
				}
			}
			while ${${ChargeType}PairIterator:Next(exists)}
		}
		if !${BestFound}
		{
			BestSoFar:Set[${HighestSoFar}]
		}
		Logger:Log["obj_Ship.GetBestAmmoTypeByRange(${range}): BestSoFar: ${BestSoFar}, HighestSoFar: ${HighestSoFar}",LOG_DEBUG]
		Logger:Log["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): returning ${BestSoFar}",LOG_DEBUG]
		return ${BestSoFar}
	}

	member:bool IsAmmoAvailable()
	{
		Validate_Ship()

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
				;Logger:Log["DEBUG: obj_Ship.IsAmmoAvailable:", LOG_DEBUG]
				;Logger:Log["Slot: ${aWeaponIterator.Value.ToItem.Slot}  ${aWeaponIterator.Value.ToItem.Name}", LOG_DEBUG]

				aWeaponIterator.Value:GetAvailableAmmo[anItemIndex]
				;Logger:Log["Ammo: Used = ${anItemIndex.Used}", LOG_DEBUG]

				anItemIndex:GetIterator[anItemIterator]
				if ${anItemIterator:First(exists)}
				{
					do
					{
						;Logger:Log["Ammo: Type = ${anItemIterator.Value.Type}", LOG_DEBUG]
						if ${anItemIterator.Value.TypeID} == ${aWeaponIterator.Value.Charge.TypeID}
						{
							;Logger:Log["Ammo: Match!", LOG_DEBUG]
							;Logger:Log["Ammo: Qty = ${anItemIterator.Value.Quantity}", LOG_DEBUG]
							;Logger:Log["Ammo: Max = ${aWeaponIterator.Value.MaxCharges}", LOG_DEBUG]
							;TODO: This may need work in the future regarding different weapon types. -- stealthy
							if ${anItemIterator.Value.Quantity} < ${Math.Calc[${aWeaponIterator.Value.MaxCharges}*${This.ModuleList_Weapon.Used}]}
							{
								Logger:Log["DEBUG: obj_Ship.IsAmmoAvailable: FALSE!", LOG_CRITICAL]
								bAmmoAvailable:Set[FALSE]
								break
							}
						}
					}
					while ${anItemIterator:Next(exists)}
				}
				else
				{
					Logger:Log["DEBUG: obj_Ship.IsAmmoAvailable: FALSE!", LOG_CRITICAL]
					bAmmoAvailable:Set[FALSE]
				}
			}
		}
		while ${aWeaponIterator:Next(exists)}

		return ${bAmmoAvailable}
	}

	member:bool HasCovOpsCloak()
	{
		Validate_Ship()

		variable iterator aModuleIterator
		This.ModuleList_Cloaks:GetIterator[aModuleIterator]
		if ${aModuleIterator:First(exists)}
		do
		{
			if ${aModuleIterator.Value.MaxVelocityPenalty} == 0
			{
				return TRUE
			}
		}
		while ${aModuleIterator:Next(exists)}

		return FALSE
	}

	member:bool HasTractorBeams()
	{
		return ${This.ModuleList_TractorBeams.Used(bool)}
	}

	member:bool HasCloak()
	{
		return ${This.ModuleList_Cloaks.Used(bool)}
	}

	member:float CargoMinimumFreeSpace()
	{
		return ${Math.Calc[${MyShip.CargoCapacity}*0.02]}
	}

	member:float CargoFreeSpace()
	{
		if ${MyShip.UsedCargoCapacity} < 0
		{
			return ${MyShip.CargoCapacity}
		}
		return ${Math.Calc[${MyShip.CargoCapacity}-${MyShip.UsedCargoCapacity}]}
	}

	member:bool CargoFull()
	{
		if ${This.CargoFreeSpace} <= ${This.CargoMinimumFreeSpace}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool CargoHalfFull()
	{
		if ${This.CargoFreeSpace} <= ${Math.Calc[${MyShip.CargoCapacity}*0.50]}
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

	method Print_ModuleList(string Title, string List)
	{
		variable iterator Module
		Logger:Log[" ${Title}", LOG_MINOR, 2]
		${List}:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			Logger:Log["Slot: ${Module.Value.ToItem.Slot} ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}
	}

	method UpdateModuleList()
	{
		Validate_Ship()

		if !${Me.InSpace}
		{
			; GetModules cannot be used in station as of 07/15/2007
			Logger:Log["DEBUG: obj_Ship:UpdateModuleList called while not in space", LOG_DEBUG]
			return
		}

		/* build module lists */
		This.ModuleList:Clear
		This.ModuleList_MiningLaser:Clear
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
		This.ModuleList_ECCM:Clear

		MyShip:GetModules[This.ModuleList]

		if !${This.ModuleList.Used} && ${MyShip.HighSlots} > 0
		{
			Logger:Log["ERROR: obj_Ship:UpdateModuleList - No modules found. Retrying in a few seconds - If this ship has slots, you must have at least one module equipped, of any type.", LOG_CRITICAL]
			RetryUpdateModuleList:Inc
			return
		}
		RetryUpdateModuleList:Set[0]

		/* save ship values that may change in combat */
		This.m_MaxTargetRange:Set[${MyShip.MaxTargetRange}]
		variable iterator Module

		Logger:Log["Module Inventory:", LOG_MINOR, 1]
		This.ModuleList:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${Module.Value.ToItem.GroupID}]
			variable int TypeID
			TypeID:Set[${Module.Value.ToItem.TypeID}]

			if !${Module.Value(exists)}
			{
				Logger:Log["ERROR: obj_Ship:UpdateModuleList - Null module found. Retrying in a few seconds.", LOG_CRITICAL]
				RetryUpdateModuleList:Inc
				return
			}

			Logger:Log["DEBUG: ID: ${Module.Value.ID} Activatable: ${Module.Value.IsActivatable} Name: ${Module.Value.ToItem.Name} Slot: ${Module.Value.ToItem.Slot} Group: ${Module.Value.ToItem.Group} ${GroupID} Type: ${Module.Value.ToItem.Type} ${TypeID}", LOG_DEBUG]

			if !${Module.Value.IsActivatable}
			{
				if ${Module.Value.ToItem.GroupID} == GROUP_TRACKINGENHANCER
				{
					This.HaveTrackingEnhancer:Set[TRUE]
				}
				This.ModuleList_Passive:Insert[${Module.Value.ID}]
				continue
			}

			;echo "DEBUG: Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}"
			;echo " DEBUG: Group: ${Module.Value.ToItem.Group}  ${GroupID}"
			;echo " DEBUG: Type: ${Module.Value.ToItem.Type}  ${TypeID}"

			if ${Module.Value.MiningAmount(exists)}
			{
				This.ModuleList_MiningLaser:Insert[${Module.Value.ID}]
				continue
			}

			switch ${GroupID}
			{
				case GROUPID_SHIELD_TRANSPORTER
					This.ModuleList_ShieldTransporters:Insert[${ModuleIter.Value.ID}]
					break
				case GROUPID_DAMAGE_CONTROL
				case GROUPID_SHIELD_HARDENER
				case GROUPID_ARMOR_HARDENERS
					This.ModuleList_ActiveResists:Insert[${Module.Value.ID}]
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
					This.ModuleList_Weapon:Insert[${Module.Value.ID}]
					break
				case GROUP_ECCM
					This.ModuleList_ECCM:Insert[${Module.Value.ID}]
					continue
				case GROUPID_FREQUENCY_MINING_LASER
					continue
				case GROUPID_SHIELD_BOOSTER
					This.ModuleList_Regen_Shield:Insert[${Module.Value.ID}]
					continue
				case GROUPID_AFTERBURNER
					This.ModuleList_AB_MWD:Insert[${Module.Value.ID}]
					continue
				case GROUPID_ARMOR_REPAIRERS
					This.ModuleList_Repair_Armor:Insert[${Module.Value.ID}]
					continue
				case GROUPID_SALVAGER
					This.ModuleList_Salvagers:Insert[${Module.Value.ID}]
					continue
				case GROUPID_TRACTOR_BEAM
					This.ModuleList_TractorBeams:Insert[${Module.Value.ID}]
					continue
				case NONE
					This.ModuleList_Repair_Hull:Insert[${Module.Value.ID}]
					continue
				case GROUPID_CLOAKING_DEVICE
					This.ModuleList_Cloaks:Insert[${Module.Value.ID}]
					continue
				case GROUPID_STASIS_WEB
					This.ModuleList_StasisWeb:Insert[${Module.Value.ID}]
					continue
				case GROUP_SENSORBOOSTER
					This.ModuleList_SensorBoost:Insert[${Module.Value.ID}]
				case GROUP_TARGETPAINTER
					This.ModuleList_TargetPainter:Insert[${Module.Value.ID}]
					continue
				case GROUP_TRACKINGCOMPUTER
					This.ModuleList_TrackingComputer:Insert[${Module.Value.ID}]
					continue
				case GROUP_GANGLINK
				case GROUP_COMMAND_BURST
					This.ModuleList_GangLinks:Insert[${Module.Value.ID}]
					continue
				default
					continue
			}

		}
		while ${Module:Next(exists)}

		This:Print_ModuleList["Weapons:", 			"This.ModuleList_Weapon"]
		This:Print_ModuleList["ECCM:",				"This.ModuleList_ECCM"]
		This:Print_ModuleList["Active Resistance:",	"This.ModuleList_ActiveResists"]
		This:Print_ModuleList["Passive:",			"This.ModuleList_Passive"]
		This:Print_ModuleList["Mining:",			"This.ModuleList_MiningLaser"]
		This:Print_ModuleList["Armor Repair :",		"This.ModuleList_Repair_Armor"]
		This:Print_ModuleList["Shield Boost:",		"This.ModuleList_Regen_Shield"]
		This:Print_ModuleList["AfterBurner/MWD:",	"This.ModuleList_AB_MWD"]
		This:Print_ModuleList["Salvager:",			"This.ModuleList_Salvagers"]
		This:Print_ModuleList["Tractor Beam:",		"This.ModuleList_TractorBeams"]
		This:Print_ModuleList["Cloaking Device:",	"This.ModuleList_Cloaks"]
		This:Print_ModuleList["Stasis Webs:",		"This.ModuleList_StasisWeb"]
		This:Print_ModuleList["Sensor Boost:",		"This.ModuleList_SensorBoost"]
		This:Print_ModuleList["Target Painter:",	"This.ModuleList_TargetPainter"]
		This:Print_ModuleList["Shield Transporters:",	"This.ModuleList_ShieldTransporters"]

	}

	method UpdateBaselineUsedCargo()
	{
		Validate_Ship()

		; Store the used cargo space as the cargo hold exists NOW, with whatever is leftover in it.
		This.BaselineUsedCargo:Set[${MyShip.UsedCargoCapacity.Ceil}]
	}

	member:int MaxLockedTargets()
	{
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
			return ${Me.MaxLockedTargets}
		else
			return ${MyShip.MaxLockedTargets}
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
		Validate_Ship()

		variable int count
		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} || \
				${Module.Value.IsGoingOnline} || \
				${Module.Value.IsDeactivating} || \
				${Module.Value.IsReloading}
			{
				count:Inc
			}
		}
		while ${Module:Next(exists)}

		return ${count}
	}
	member:int TotalActivatedTractorBeams()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable int count
		variable iterator Module

		This.ModuleList_TractorBeams:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if (${Module.Value.IsActive} || \
				${Module.Value.IsGoingOnline} || \
				${Module.Value.IsDeactivating})
			{
				count:Inc
			}
		}
		while ${Module:Next(exists)}

		return ${count}
	}
	member:int TotalActivatedSalvagers()
	{
		if !${MyShip(exists)}
		{
			return 0
		}

		variable int count
		variable iterator Module

		This.ModuleList_Salvagers:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} || \
				${Module.Value.IsGoingOnline} || \
				${Module.Value.IsDeactivating}
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
		Validate_Ship()

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
		Validate_Ship()

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
		if !${MyShip(exists)}
		{
			return "NOCHARGE"
		}

		if ${MyShip.Module[${SlotName}].Charge(exists)}
		{
			if ${fullName}
			{
				return ${MyShip.Module[${SlotName}].Charge.Name}
			}
			else
			{
				return ${MyShip.Module[${SlotName}].Charge.Name.Token[1, " "]}
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
				;Logger:Log["DEBUG: obj_Ship:LoadedMiningLaserCrystal Returning ${Module.Value.Charge.Name.Token[1, " "]}]
				return ${Module.Value.Charge.Name.Token[1, " "]}
			}
		}
		while ${Module:Next(exists)}

		return "NOCHARGE"
	}

	; Returns TRUE if we've got a laser mining this entity already
	member:bool IsMiningAsteroidID(int64 EntityID)
	{
		Validate_Ship()

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.LastTarget(exists)} && \
				${Module.Value.LastTarget.ID.Equal[${EntityID}]} && \
				( ${Module.Value.IsActive} || ${Module.Value.IsGoingOnline} )
			{
				return TRUE
			}
		}
		while ${Module:Next(exists)}

		return FALSE
	}

	; TODO MOVE THIS TO TARGETING THREAD
	method UnlockAllTargets()
	{
		Validate_Ship()

		variable index:entity LockedTargets
		variable iterator Target

		Me:GetTargets[LockedTargets]
		LockedTargets:GetIterator[Target]

		if ${Target:First(exists)}
		{
			Logger:Log["Unlocking all targets", LOG_MINOR]
			do
			{
				Target.Value:UnlockTarget
			}
			while ${Target:Next(exists)}
		}
	}

	function ChangeMiningLaserCrystal(string OreType, string SlotName)
	{
		Validate_Ship()

		; We might need to change loaded crystal
		variable string LoadedAmmo

		LoadedAmmo:Set[${This.LoadedMiningLaserCrystal[${SlotName}]}]
		if !${OreType.Find[${LoadedAmmo}](exists)}
		{
			Logger:Log["Current crystal in ${SlotName} is ${LoadedAmmo}, looking for ${OreType}"]
			variable index:item CrystalList
			variable index:item CrystalListT1
			variable index:item CrystalListT2
			variable iterator CrystalIterator

			MyShip.Module[${SlotName}]:GetAvailableAmmo[CrystalList]

			CrystalList:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				if ${CrystalIterator.Value.Name.Right[3].Equal[" II"]}
				{
					CrystalListT2:Insert[${CrystalIterator.Value}]
				}
				else
				{
					CrystalListT1:Insert[${CrystalIterator.Value}]
				}
			}
			while ${CrystalIterator:Next(exists)}

			CrystalListT2:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				variable string CrystalType
				CrystalType:Set[${CrystalIterator.Value.Name.Token[1, " "]}]

				;echo "DEBUG: ChangeMiningLaserCrystal Testing ${OreType} contains ${CrystalType}"
				if ${OreType.Find[${CrystalType}](exists)}
				{
					Logger:Log["Switching Crystal in ${SlotName} from ${LoadedAmmo} to ${CrystalIterator.Value.Name}"]
					MyShip.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID},1]
					; This takes 2 seconds ingame, let's give it 50% more
					wait 30
					return
				}
			}
			while ${CrystalIterator:Next(exists)}
			Logger:Log["Warning: No T2 crystal found for ore type ${OreType}, checking for T1"]

			CrystalListT1:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				variable string CrystalType
				CrystalType:Set[${CrystalIterator.Value.Name.Token[1, " "]}]

				;echo "DEBUG: ChangeMiningLaserCrystal Testing ${OreType} contains ${CrystalType}"
				if ${OreType.Find[${CrystalType}](exists)}
				{
					Logger:Log["Switching Crystal in ${SlotName} from ${LoadedAmmo} to ${CrystalIterator.Value.Name}"]
					MyShip.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID},1]
					; This takes 2 seconds ingame, let's give it 50% more
					wait 30
					return
				}
			}
			while ${CrystalIterator:Next(exists)}
			Logger:Log["Warning: No crystal found for ore type ${OreType}, efficiency reduced"]
		}
	}

	; Validates that all targets of activated modules still exist
	; TODO - Add mid and low targetable modules, and high hostile modules, as well as just mining.
	method ValidateModuleTargets()
	{
		Validate_Ship()

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if ${Module.Value.IsActive} && \
				!${Module.Value.IsDeactivating} && \
				!${Module.Value.LastTarget(exists)}
			{
				Logger:Log["${Module.Value.ToItem.Slot}:${Module.Value.ToItem.Name} has no target: Deactivating"]
				Module.Value:Deactivate
			}
		}
		while ${Module:Next(exists)}
	}

	method CycleMiningLaser(string Activate, string Slot)
	{
		Validate_Ship()

		;echo CycleMiningLaser: ${Slot} Activate: ${Activate}
		if ${Activate.Equal[ON]} && \
			( ${MyShip.Module[${Slot}].IsActive} || \
			  ${MyShip.Module[${Slot}].IsGoingOnline} || \
			  ${MyShip.Module[${Slot}].IsDeactivating} || \
			  ${MyShip.Module[${Slot}].IsReloading} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Activate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[OFF]} && \
			(!${MyShip.Module[${Slot}].IsActive} || \
			  ${MyShip.Module[${Slot}].IsGoingOnline} || \
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
			echo "obj_Ship:CycleMiningLaser: Target doesn't exist"
			return
		}

		MyShip.Module[${Slot}].LastTarget:MakeActiveTarget
		if ${Activate.Equal[ON]}
		{
			MyShip.Module[${Slot}]:Activate
			; Delay from 30 to 60 seconds before deactivating
			TimedCommand ${Math.Rand[600]:Inc[300]} "Script[EVEBot].VariableScope.Ship:CycleMiningLaser[OFF, ${Slot}]"
			return
		}
		else
		{
			MyShip.Module[${Slot}]:Deactivate
			; Delay for the time it takes the laser to deactivate and be ready for reactivation
			TimedCommand 20 "Script[EVEBot].VariableScope.Ship:CycleMiningLaser[ON, ${Slot}]"
			return
		}
	}

	method DeactivateAllMiningLasers()
	{
		Validate_Ship()

		variable iterator Module

		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		{
			if ${Module.Value.IsActive} && \
				!${Module.Value.IsDeactivating}
			{
				Logger:Log["Deactivating all mining lasers..."]
			}
		}
		do
		{
			if ${Module.Value.IsActive} && \
				!${Module.Value.IsDeactivating}
			{
				Module.Value:Deactivate
			}
		}
		while ${Module:Next(exists)}
	}

	function ActivateFreeMiningLaser(int64 id=-1)
	{
		Validate_Ship()

		variable string Slot

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

		variable iterator Module
		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && \
				!${Module.Value.IsGoingOnline} && \
				!${Module.Value.IsDeactivating} && \
				!${Module.Value.IsReloading}
			{
				Slot:Set[${Module.Value.ToItem.Slot}]
				if ${Module.Value.SpecialtyCrystalMiningAmount(exists)}
				{
					variable string OreType
					OreType:Set[${Entity[${id}].Name.Token[2,"("]}]
					OreType:Set[${OreType.Token[1,")"]}]
					;OreType:Set[${OreType.Replace["(",]}]
					;OreType:Set[${OreType.Replace[")",]}]
					call This.ChangeMiningLaserCrystal "${OreType}" ${Slot}
				}

				Logger:Log["Activating: ${Slot}: ${Module.Value.ToItem.Name}"]
				Module.Value:Activate[${id}]
				wait 25
				;TimedCommand ${Math.Rand[600]:Inc[300]} "Script[EVEBot].VariableScope.Ship:CycleMiningLaser[OFF, ${Slot}]"
				return
			}
			wait 10
		}
		while ${Module:Next(exists)}
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

		variable iterator Module

		This.ModuleList_TractorBeams:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && \
				!${Module.Value.IsGoingOnline} && \
				!${Module.Value.IsDeactivating} && \
				!${Module.Value.IsReloading}
			{
				Slot:Set[${Module.Value.ToItem.Slot}]

				Logger:Log["Activating: ${Slot}: ${Module.Value.ToItem.Name}"]
				Module.Value:Activate[${id}]
				return
			}
		}
		while ${Module:Next(exists)}
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

		variable iterator Module

		This.ModuleList_ShieldTransporters:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && \
				!${Module.Value.IsGoingOnline} && \
				!${Module.Value.IsDeactivating} && \
				!${Module.Value.IsReloading}
			{
				Slot:Set[${Module.Value.ToItem.Slot}]

				Logger:Log["Activating: ${Slot}: ${Module.Value.ToItem.Name}"]
				Module.Value:Activate[${id}]
				return
			}
		}
		while ${Module:Next(exists)}
	}

	function ActivateFreeSalvager()
	{
		variable string Slot

		if !${MyShip(exists)}
		{
			return
		}

		variable iterator Module

		This.ModuleList_Salvagers:GetIterator[Module]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${Module.Value.IsActive} && \
				!${Module.Value.IsGoingOnline} && \
				!${Module.Value.IsDeactivating} && \
				!${Module.Value.IsReloading}
			{
				Slot:Set[${Module.Value.ToItem.Slot}]

				Logger:Log["Activating: ${Slot}: ${Module.Value.ToItem.Name}"]
				Module.Value:Activate
				return
			}
			wait 10
		}
		while ${Module:Next(exists)}
	}




	member IsCargoOpen()
	{
		if ${EVEWindow[ByCaption,"active ship"](exists)}
		{
			if ${EVEWindow[ByCaption,"active ship"].Caption(exists)}
			{
				return TRUE
			}
			else
			{
				Logger:Log["\${EVEWindow[ByCaption,"active ship"](exists)} == ${EVEWindow[ByCaption,"active ship"](exists)}", LOG_DEBUG]
				Logger:Log["\${EVEWindow[ByCaption,"active ship"].Caption(exists)} == ${EVEWindow[ByCaption,"active ship"].Caption(exists)}", LOG_DEBUG]
			}
		}
		return FALSE
	}

	function OpenCargo()
	{
		Validate_Ship()

		if !${This.IsCargoOpen}
		{
			Logger:Log["Opening Ship Cargohold"]
			MyShip:Open
			wait WAIT_CARGO_WINDOW
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
		}
		EVEWindow[ByItemID,${MyShip.ID}]:StackAll
		wait 5
	}

	function CloseCargo()
	{
		Validate_Ship()

		if ${This.IsCargoOpen}
		{
			Logger:Log["Closing Ship Cargohold"]
			EVEWindow["Inventory"]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen}
			{
				wait 1
			}
			wait 10
		}
	}

	Define_ModuleMethod(Activate_Armor_Reps, Deactivate_Armor_Reps, This.ModuleList_Repair_Armor, TRUE)
	Define_ModuleMethod(Activate_AfterBurner, Deactivate_AfterBurner, This.ModuleList_AB_MWD, TRUE)
	Define_ModuleMethod(Activate_Shield_Booster, Deactivate_Shield_Booster, This.ModuleList_Regen_Shield, TRUE)
	Define_ModuleMethod(Activate_Hardeners, Deactivate_Hardeners, This.ModuleList_ActiveResists, TRUE)
	Define_ModuleMethod(Activate_SensorBoost, Deactivate_SensorBoost, This.ModuleList_SensorBoost, TRUE)
	Define_ModuleMethod(Activate_StasisWebs, Deactivate_StasisWebs, This.ModuleList_StasisWeb, TRUE)
	Define_ModuleMethod(Activate_TargetPainters, Deactivate_TargetPainters, This.ModuleList_TargetPainter, TRUE)
	Define_ModuleMethod(Activate_Cloak, Deactivate_Cloak, This.ModuleList_Cloaks, TRUE)
	Define_ModuleMethod(Activate_Tractor, Deactivate_Tractor, This.ModuleList_TractorBeams, TRUE)
	Define_ModuleMethod(Activate_Weapons, Deactivate_Weapons, This.ModuleList_Weapon, FALSE)
	Define_ModuleMethod(Activate_ECCM, Deactivate_ECCM, This.ModuleList_ECCM, FALSE)

	member:bool IsCloaked()
	{
		Validate_Ship()

		if ${Me.ToEntity(exists)} && ${Me.ToEntity.IsCloaked}
		{
			return TRUE
		}

		return FALSE
	}

	function StackAll()
	{
		Validate_Ship()

		if ${This.IsCargoOpen}
		{
			EVEWindow[ByItemID,${MyShip.ID}]:StackAll
		}
	}

	; Returns the salvager range minus 10%
	member:float OptimalSalvageRange()
	{
		Validate_Ship()
		variable iterator Module

		This.ModuleList_Salvagers:GetIterator[Module]
		if ${Module:First(exists)}
		{
			return ${Math.Calc[${Module.Value.OptimalRange}*0.90]}
		}

		return 0
	}

	; Returns the tractor range minus 10%
	member:float OptimalTractorRange()
	{
		Validate_Ship()

		variable iterator Module

		This.ModuleList_TractorBeams:GetIterator[Module]
		if ${Module:First(exists)}
		{
			return ${Math.Calc[${Module.Value.OptimalRange}*0.90]}
		}

		return 0
	}

	; Returns the targeting range minus 10%
	member:float OptimalTargetingRange()
	{
		return ${Math.Calc[${MyShip.MaxTargetRange}*0.90]}
	}

	; Returns the highest weapon optimal range minus
	member:float OptimalWeaponRange()
	{
		variable float maxRange = ${Ship.GetMaximumTurretRange[1]}
		if ${maxRange} > 0
		{
			;echo "OptimalWeaponRange: Returning \${Ship.GetMaximumTurretRange[1]} ${Ship.GetMaximumTurretRange[1]}"
			return ${maxRange}
		}
		;echo "OptimalWeaponRange: Returning \${Math.Calc[${Config.Combat.MaxMissileRange} * 0.95]} ${Math.Calc[${Config.Combat.MaxMissileRange} * 0.95]}"
		return ${Math.Calc[${Config.Combat.MaxMissileRange} * 0.95]}
	}

	member:bool IsPod()
	{
		Validate_Ship()

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
		Validate_Ship()

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

	member:bool WeaponsActive()
	{
		variable iterator WeaponIterator
		This.ModuleList_Weapon:GetIterator[WeaponIterator]

		if ${WeaponIterator:First(exists)}
		{
			do
			{
				if ${WeaponIterator.Value.IsActive}
				{
					return TRUE
				}
			}
			while ${WeaponIterator:Next(exists)}
		}
		return FALSE
	}

	method Reload_Weapons(bool ForceReload)
	{
		variable bool NeedReload = FALSE
		variable int CurrentCharges = 0
		Validate_Ship()

		if !${This.ModuleList_Weapon.Used}
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
				if !${Module.Value.IsActive} && !${Module.Value.IsReloading}
				{
					; Sometimes this value can be NULL
					if !${Module.Value.MaxCharges(exists)}
					{
						;Logger:Log["Sanity check failed... weapon has no MaxCharges!"]
						NeedReload:Set[TRUE]
						break
					}

					; Has ammo been used?
					if ${Module.Value.CurrentCharges} > 0
					{
						CurrentCharges:Set[${Module.Value.CurrentCharges}]
					}
					else
					{
						CurrentCharges:Set[${Module.Value.Charge.Quantity}]
					}

					if ${CurrentCharges} != ${Module.Value.MaxCharges}
					{
						;UI:UpdateConsole["Module.Value.CurrentCharges = ${Module.Value.CurrentCharges}"]
						;UI:UpdateConsole["Module.Value.MaxCharges = ${Module.Value.MaxCharges}"]
						;UI:UpdateConsole["Module.Value.Charge.Quantity = ${Module.Value.Charge.Quantity}"]
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
			Logger:Log["Reloading Weapons..."]
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
		Validate_Ship()

		variable index:item hsIndex
		variable iterator hsIterator
		variable string shipName

		if ${Station.Docked}
		{
			Me:GetHangarShips[hsIndex]
			hsIndex:GetIterator[hsIterator]

			shipName:Set[${MyShip}]
			if ${shipName.NotEqual[${name}]} && \
				${hsIterator:First(exists)}
			{
				do
				{
					if ${hsIterator.Value.Name.Equal[${name}]}
					{
						Logger:Log["obj_Ship: Switching to ship named ${hsIterator.Value.Name}."]
						hsIterator.Value:MakeActive
						break
					}
				}
				while ${hsIterator:Next(exists)}
			}
		}
	}
}
