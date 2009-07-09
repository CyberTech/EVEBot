/*
	Ship class

	Main object for interacting with the ship and its functions

	-- CyberTech

*/

#macro Validate_Ship()
		if !${EVEBot.SessionValid}
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
				(!${Module.Value.Charge(exists)} || (!${Module.Value.IsChangingAmmo} && !${Module.Value.IsReloadingAmmo}))
			{
				if ${LOG}
				{
					UI:UpdateConsole["Activating ${Module.Value.ToItem.Name}"]
				}
				Module.Value:Click
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
					UI:UpdateConsole["Deactivating ${Module.Value.ToItem.Name}", LOG_MINOR]
				}
				Module.Value:Click
			}
		}
		while ${Module:Next(exists)}
	}
#endmac

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
	variable index:module ModuleList_SensorBoost
	variable index:module ModuleList_TargetPainter
	variable index:module ModuleList_WeaponEnhance
	variable index:module ModuleList_ECCM
	variable bool Repairing_Armor = FALSE
	variable bool Repairing_Hull = FALSE
	variable float m_MaxTargetRange
	variable bool m_WaitForCapRecharge = FALSE
	variable int m_CargoSanityCounter = 0
	variable bool InteruptWarpWait = FALSE
	variable string m_Type
	variable int m_TypeID
	
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
	variable float TurretMaxRangeMod = 1.3

	variable obj_Drones Drones

	method Initialize()
	{
		This:StopShip[]
		This:UpdateModuleList[]

		Event[OnFrame]:AttachAtom[This:Pulse]
		This:CalculateMaxLockedTargets
		This:PopulateNameModPairs[]
		UI:UpdateConsole["obj_Ship: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${EVEBot.SessionValid}
			{
				if ${Me.InSpace}
				{
					This:ValidateModuleTargets
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

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
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

	/* float HitChance(int EntityID, int turret):
	Calculate the chance to hit to the best of our ability. */
	member:float HitChance(int EntityID, int turret, float falloff, float tracking)
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
		UI:UpdateConsole["obj_Ship:BuildLookupTables[]: called.",LOG_DEBUG]
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
				UI:UpdateConsole["obj_Ship:BuildLookupTables[]: TurretBaseOptimals.Element[${Weapon.Key}]: ${TurretBaseOptimals.Element[${Weapon.Key}]}",LOG_DEBUG]
				
				Weapon.Value:DoGetAvailableAmmo[AvailableCharges]
				AvailableCharges:GetIterator[AvailableCharge]
				
				UI:UpdateConsole["obj_Ship:BuildLookupTables[]: GroupID: ${Weapon.Value.ToItem.GroupID}",LOG_DEBUG]
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
				UI:UpdateConsole["obj_Ship:BuildLookupTables[]: ChargeType: ${ChargeType}",LOG_DEBUG]
				${ChargeType}NameModPairs:GetIterator[LookupIterator]
				
				if ${AvailableCharge:First(exists)}
				{
					do
					{
						UI:UpdateConsole["obj_Ship.BuildLookupTables[]: Weapon: ${Weapon.Key}, Available Charge: ${AvailableCharge.Value.Name}",LOG_DEBUG]
						if ${LookupIterator:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.BuildLookupTables[]: Weapon: ${Weapon.Key}, Lookup Charge: ${LookupIterator.Key}",LOG_DEBUG]
								if ${AvailableCharge.Value.Name.Find[${LookupIterator.Key}](exists)}
								{
									UI:UpdateConsole["obj_Ship:BuildLookupTables[]: ${ChargeType}, ${LookupIterator.Key}, ${LookupIterator.Value}, ${Math.Calc[${BaseOptimal} * ${LookupIterator.Value}]}",LOG_DEBUG]
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
									This.TurretMaximumRanges.Element[${Weapon.Key}]:Set[${LookupIterator.Key},${Math.Calc[${BaseOptimal} * ${LookupIterator.Value} * 1.3]}]
									UI:UpdateConsole["obj_Ship:BuildLookupTables[]: ${Weapon.Key}, ${This.TurretMinimumRanges.Element[${Weapon.Key}](exists)}, ${LookupIterator.Key}, ${This.TurretMinimumRanges.Element[${Weapon.Key}].Element[${LookupIterator.Key}]} ${This.TurretMinimumRanges.Element[${Weapon.Key}].Used} ${BaseOptimal} ${LookupIterator.Value}",LOG_DEBUG]
									UI:UpdateConsole["obj_Ship:BuildLookupTables[]: ${Weapon.Key}, ${This.TurretMaximumRanges.Element[${Weapon.Key}](exists)}, ${LookupIterator.Key}, ${This.TurretMaximumRanges.Element[${Weapon.Key}].Element[${LookupIterator.Key}]} ${This.TurretMaximumRanges.Element[${Weapon.Key}].Used} ${BaseOptimal} ${LookupIterator.Value}",LOG_DEBUG]
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
		variable string sBestAmmo = ${This.BestAmmoTypeByRange[${range},${turret}]}
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		UI:UpdateConsole["obj_Ship.NeedAmmoChange[${range},${turret}]: sBestAmmo: ${sBestAmmo}",LOG_DEBUG]
		variable bool bFoundAmmo = FALSE
		
		if ${MyShip.Module[${slot}].Charge.Name.Find[${sBestAmmo}](exists)}
		{
			bFoundAmmo:Set[TRUE]
		}
		else
		{
			bFoundAmmo:Set[FALSE]
		}
		/* If we DON'T find our optimal ammo, we DO need an ammo change */
		if !${bFoundAmmo}
		{
			return TRUE
		}
		return FALSE
	}

	/* LoadOptimalAmmo(float range, int turret):
	Determine the best ammo type for passed turret at passed range and swap to it. */
	method LoadOptimalAmmo(float range, int turret)
	{ 
		variable string sBestAmmo = ${This.BestAmmoTypeByRange[${range},${turret}]}
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range}): Best Ammo: ${sBestAmmo}",LOG_DEBUG]
		
		variable index:item idxAmmo
		variable iterator itrAmmo
		
		MyShip.Module[${slot}]:DoGetAvailableAmmo[idxAmmo]
		idxAmmo:GetIterator[itrAmmo]			
		if ${itrAmmo:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range},${turret}): Found best ammo: ${itrAmmo.Value.Name.Find[${sBestAmmo}](exists)}",LOG_DEBUG]
				if ${itrAmmo.Value.Name.Find[${sBestAmmo}](exists)} && !${MyShip.Module[${slot}].Charge.Name.Find[${sBestAmmo}](exists)}
				{					
					UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range},${turret}): Changing ammo to ${itrAmmo.Value.Name}, ${MyShip.Module[${slot}].MaxCharges}",LOG_DEBUG]
					MyShip.Module[${slot}]:ChangeAmmo[${itrAmmo.Value.ID},${MyShip.Module[${slot}].MaxCharges}]							
					return
				}					
			}
			while ${itrAmmo:Next(exists)}
		}
	}

	/* float MaximumTurretRange(int turret):
	Make use of GetMaximumTurretRange to determine our Maximum turret range. */
	member:float MaximumTurretRange(int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		variable float MaximumRange = 0
		
		if !${MyShip.Module[${slot}].Charge(exists)}
		{
			return ${Math.Calc[${MyShip.Module[${slot}].OptimalRange} * ${This.TurretMaxRangeMod}]}
		}
		
		switch ${MyShip.Module[${slot}].Charge.GroupID}
		{
			case GROUP_AMMO
			case GROUP_ADVANCEDAUTOCANNONAMMO
			case GROUP_ADVANCEDARTILLERYAMMO
				return ${This.GetMaximumTurretRange[${turret},Ammo,${MyShip.Module[${slot}].Charge.Name}]}
			case GROUP_HYBRIDAMMO
			case GROUP_ADVANCEDBLASTERAMMO
			case GROUP_ADVANCEDRAILAMMO
				return ${This.GetMaximumTurretRange[${turret},Hybrid,${MyShip.Module[${slot}].Charge.Name}]}
			case GROUP_FREQUENCYCRYSTAL
			case GROUP_ADVANCEDBEAMLASERCRYSTAL
			case GROUP_ADVANCEDPULSELASERCRYSTAL
				return ${This.GetMaximumTurretRange[${turret},Frequency,${MyShip.Module[${slot}].Charge.Name}]}
			case GROUP_MOON
				;Figure out what the hell the correct one is since we've not yet cycled ammo
				;First check against normal ammo
				MaximumRange:Set[${This.GetMaximumTurretRange[${turret},Ammo,${MyShip.Module[${slot}].Charge.Name}]}]
				;If that didn't have a match, check against hybrid ammo
				if ${MaximumRange} == 0
				{
					MaximumRange:Set[${This.GetMaximumTurretRange[${turret},Hybrid,${MyShip.Module[${slot}].Charge.Name}]}]
				}
				;If we couldn't match against ammo or hybrid ammo, check requency
				if ${MaximumRange} == 0
				{
					MaximumRange:Set[${This.GetMaximumTurretRange[${turret},Frequency,${MyShip.Module[${slot}].Charge.Name}]}]
				}
				;If we had a match, return.
				if ${MaximumRange} != 0
				{
					return ${MaximumRange}
				}
				;If we didn't have a match... fallthrough to default
			default
				UI:UpdateConsole["obj_Ship.MaximumTurretRange: Unrecognized group for the weapon's charge, something is very broken. Group: ${MyShip.Module[${slot}].Charge(exists)} ${MyShip.Module[${slot}].Charge.Group} ${MyShip.Module[${slot}].Charge.GroupID} ${MyShip.Module[${slot}].IsReloadingAmmo} ${MyShip.Module[${slot}].IsChangingAmmo}",LOG_CRITICAL]
				return 0
		}

	}

	/* float GetMaximumTurretRange(int turret, string ChargeType):
	Calculate and return the Maximum range for passed turret, taking into account the ammo types available. */
	member:float GetMaximumTurretRange(int turret, string ChargeType, string ChargeName="")
	{
		variable iterator RangeIterator
		UI:UpdateConsole["obj_Ship This.TurretMaximumRanges.Element[${turret}](exists) ${This.TurretMaximumRanges.Element[${turret}](exists)} ${This.TurretMaximumRanges.Element[${turret}].Used}",LOG_DEBUG]
		if ${This.TurretMaximumRanges.Element[${turret}](exists)}
		{
			This.TurretMaximumRanges.Element[${turret}]:GetIterator[RangeIterator]
			if ${RangeIterator:First(exists)}
			{
				do
				{
					UI:UpdateConsole["obj_Ship range ${RangeIterator.Key} ${RangeIterator.Value}",LOG_DEBUG]
					if ${ChargeName.Find[${RangeIterator.Key}](exists)}
					{
						UI:UpdateConsole["obj_Ship returning",LOG_DEBUG]
						return ${RangeIterator.Value}
					}
				}
				while ${RangeIterator:Next(exists)}
			}
		}
	
		;old code incase the above breaks
		UI:UpdateConsole["obj_Ship.GetMaximumTurretRange[${turret},${ChargeType},${ChargeName}]: Using old code! ${turret} ${ChargeType} ${ChargeName} ${This.TurretMaximumRanges.Element[${turret}].Element[${ChargeName}]}",LOG_CRITICAL]
	
		variable float fBaseOptimal = ${This.TurretBaseOptimal[${turret}]}
		
		UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): base optimal: ${fBaseOptimal}",LOG_DEBUG]
		variable iterator itrWeapon
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		
		variable index:item idxAmmo
		variable iterator itrAmmo

		variable float fTempMaxRange = 0
		variable float sTempMaxRangeAmmo

		variable float fMaxTurretRange = 0
		variable string slot = ${This.TurretSlots[${turret}]}

		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]		
		
		MyShip.Module[${slot}]:DoGetAvailableAmmo[idxAmmo]
		idxAmmo:GetIterator[itrAmmo]
		if ${itrAmmo:First(exists)}
		{
			do
			{
				if ${itr${ChargeType}Pairs:First(exists)}
				{
					do
					{
						if ${itrAmmo.Value.Name.Find[${itr${ChargeType}Pairs.Key}]}
						{
							UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(): Found ammo type ${itr${ChargeType}Pairs.Key} ${itr${ChargeType}Pairs.Value}",LOG_DEBUG]
							fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itr${ChargeType}Pairs.Value}]}]
							if ${fTempMaxRange} > ${fMaxTurretRange} || ${fMaxTurretRange} == 0
							{
								UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(): New Max range: ${fTempMaxRange}",LOG_DEBUG]
								fMaxTurretRange:Set[${fTempMaxRange}]
							}
							break
						}
					}
					while ${itr${ChargeType}Pairs:Next(exists)}
				}
			}
			while ${itrAmmo:Next(exists)}
		}
		/* We have to account for the ammo we currently have loaded. */
		if ${itr${ChargeType}Pairs:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Ship.GetMaximumTurretRange: checking ${itr${ChargeType}Pairs.Key} against currently loaded ammo ${MyShip.Module[${slot}].Charge.Name}",LOG_DEBUG]
  			if ${MyShip.Module[${slot}].Charge.Name.Find[${itr${ChargeType}Pairs.Key}]}
  			{
  				fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itr${ChargeType}Pairs.Value}]}]
  				if ${fTempMaxRange} > ${fMaxTurretRange} || ${fMaxTurretRange} == 0
  				{
  					UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(): New Max range: ${fTempMaxRange}",LOG_DEBUG]
  					fMaxTurretRange:Set[${fTempMaxRange}]
  				}
  				break
  			}
			}
			while ${itr${ChargeType}Pairs:Next(exists)}
		}
		UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(): calculated Maximum turret range: ${fMaxTurretRange}",LOG_DEBUG]
		return ${fMaxTurretRange}
	}	
	
	/* float MinimumTurretRange(int turret):
	Make use of GetMinimumTurretRange to determine our minimum turret range. */
	member:float MinimumTurretRange(int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		variable float MinimumRange = 0
		
		if !${MyShip.Module[${slot}].Charge(exists)}
		{
			return ${Math.Calc[${MyShip.Module[${slot}].OptimalRange} * ${This.TurretMinRangeMod}]}
		}
		
		switch ${MyShip.Module[${slot}].Charge.GroupID}
		{
			case GROUP_AMMO
			case GROUP_ADVANCEDAUTOCANNONAMMO
			case GROUP_ADVANCEDARTILLERYAMMO
				return ${This.GetMinimumTurretRange[${turret},Ammo,${MyShip.Module[${slot}].Charge.Name}]}
			case GROUP_HYBRIDAMMO
			case GROUP_ADVANCEDBLASTERAMMO
			case GROUP_ADVANCEDRAILAMMO
				return ${This.GetMinimumTurretRange[${turret},Hybrid,${MyShip.Module[${slot}].Charge.Name}]}
			case GROUP_FREQUENCYCRYSTAL
			case GROUP_ADVANCEDBEAMLASERCRYSTAL
			case GROUP_ADVANCEDPULSELASERCRYSTAL
				return ${This.GetMinimumTurretRange[${turret},Frequency,${MyShip.Module[${slot}].Charge.Name}]}
			case GROUP_MOON
				;Figure out what the hell the correct one is since we've not yet cycled ammo
				;First check against normal ammo
				MinimumRange:Set[${This.GetMinimumTurretRange[${turret},Ammo,${MyShip.Module[${slot}].Charge.Name}]}]
				;If that didn't have a match, check against hybrid ammo
				if ${MinimumRange} == 0
				{
					MinimumRange:Set[${This.GetMinimumTurretRange[${turret},Hybrid,${MyShip.Module[${slot}].Charge.Name}]}]
				}
				;If we couldn't match against ammo or hybrid ammo, check requency
				if ${MinimumRange} == 0
				{
					MinimumRange:Set[${This.GetMinimumTurretRange[${turret},Frequency,${MyShip.Module[${slot}].Charge.Name}]}]
				}
				;If we had a match, return.
				if ${MinimumRange} != 0
				{
					return ${MinimumRange}
				}
				;If we didn't have a match... fallthrough to default
			default
				UI:UpdateConsole["obj_Ship.MinimumTurretRange: Unrecognized group for the weapon's charge, something is very broken. Group: ${MyShip.Module[${slot}].Charge(exists)} ${MyShip.Module[${slot}].Charge.Group} ${MyShip.Module[${slot}].Charge.GroupID} ${MyShip.Module[${slot}].IsReloadingAmmo} ${MyShip.Module[${slot}].IsChangingAmmo}",LOG_CRITICAL]
				return 0
		}
	}

	/* float GetMinimumTurretRange(int turret, string ChargeType):
	Calculate and return the minimum range for passed turret, taking into account the ammo types available. */
	member:float GetMinimumTurretRange(int turret, string ChargeType, string ChargeName="")
	{
		variable iterator RangeIterator
		if ${This.TurretMinimumRanges.Element[${turret}](exists)}
		{
			This.TurretMinimumRanges.Element[${turret}]:GetIterator[RangeIterator]
			if ${RangeIterator:First(exists)}
			{
				do
				{
					;UI:UpdateConsole["obj_Ship range ${RangeIterator.Key} ${RangeIterator.Value}"]
					if ${ChargeName.Find[${RangeIterator.Key}]}
					{
						;UI:UpdateConsole["obj_Ship returning"]
						return ${RangeIterator.Value}
					}
				}
				while ${RangeIterator:Next(exists)}
			}
		}
		
		/* Old code incase the above somehow breaks */
		UI:UpdateConsole["obj_Ship.GetMinimumTurretRange[${turret},${ChargeType},${ChargeName}]: Using old code!",LOG_CRITICAL]
		variable float fBaseOptimal = ${This.TurretBaseOptimal[${turret}]}
		
		variable index:item idxAmmo
		variable iterator itrAmmo

		variable float fTempMinRange = 0
		variable float sTempMinRangeAmmo

		variable float fMinTurretRange = 0

		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]		
		variable string slot = ${This.TurretSlots.Element[${turret}]}
		
		MyShip.Module[${slot}]:DoGetAvailableAmmo[idxAmmo]
		idxAmmo:GetIterator[itrAmmo]
		
		if ${itrAmmo:First(exists)}
		{
			do
			{
				if ${itr${ChargeType}Pairs:First(exists)}
				{
					do
					{
						if ${itrAmmo.Value.Name.Find[${itr${ChargeType}Pairs.Key}]}
						{
							UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): Found ammo type ${itr${ChargeType}Pairs.Key} ${itr${ChargeType}Pairs.Value}",LOG_DEBUG]
							fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itr${ChargeType}Pairs.Value}]}]
							if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
							{
								UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New min range: ${fTempMinRange}",LOG_DEBUG]
								fMinTurretRange:Set[${fTempMinRange}]
							}
							break
						}
					}
					while ${itr${ChargeType}Pairs:Next(exists)}
				}
			}
			while ${itrAmmo:Next(exists)}
		}
		/* We have to account for the ammo we currently have loaded. */
		if ${itr${ChargeType}Pairs:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Ship.GetMinimumTurretRange: checking ${itr${ChargeType}Pairs.Key} against currently loaded ammo ${MyShip.Module[${slot}].Charge.Name}",LOG_DEBUG]
  			if ${MyShip.Module[${slot}].Charge.Name.Find[${itr${ChargeType}Pairs.Key}]}
  			{
  				fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itr${ChargeType}Pairs.Value}]}]
  				if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
  				{
  					UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New min range: ${fTempMinRange}",LOG_DEBUG]
  					fMinTurretRange:Set[${fTempMinRange}]
  				}
  				break
  			}
			}
			while ${itr${ChargeType}Pairs:Next(exists)}
		}
		UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): calculated minimum turret range: ${fMinTurretRange}",LOG_DEBUG]
		return ${fMinTurretRange}
	}	
	
	/* float TurretBaseOptimal(int turret):
	Calculate and return the base optimal range for passed turret. */
	member:float TurretBaseOptimal(int turret)
	{
		variable string slot = ${This.TurretSlots.Element[${turret}]}
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
				UI:UpdateConsole["obj_Ship.TurretBaseOptimal: Unrecognized group for the weapon's charge, something is very broken. Group: ${itrWeapon.Value.Charge.Group} ${itrWeapon.Value.Charge.GroupID}",LOG_CRITICAL]
				return ${MyShip.Module[${slot}].OptimalRange}
		}
	}
	
	member:float GetTurretBaseOptimal(int turret, string ChargeType)
	{
		if ${This.TurretBaseOptimals.Element[${turret}](exists)}
		{
			return ${This.TurretBaseOptimals.Element[${turret}](exists)}
		}
		
		variable string slot = ${This.TurretSlots[${turret}]}
		variable index:item idxAmmo
		variable iterator itrAmmo
		
		variable float fBaseOptimal
		variable float fRangeMod = 0
		
		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]
		
		if !${MyShip.Module[${slot}].Charge(exists)}
		{
			fRangeMod:Set[${MyShip.Module[${slot}].OptimalRange}]
		}
			
		if ${itr${ChargeType}Pairs:First(exists)}
		{
			do
			{
				if ${MyShip.Module[${slot}].Charge.Name.Find[${itr${ChargeType}Pairs.Key}]}
				{
					UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal[${turret},${ChargeType}]: Found ammo ${itr${ChargeType}Pairs.Key}, mod ${itr${ChargeType}Pairs.Value}",LOG_DEBUG]
					fRangeMod:Set[${itr${ChargeType}Pairs.Value}]
					break
				}
			}
			while ${itr${ChargeType}Pairs:Next(exists)}
		}

		if ${fRangeMod} != 0
		{
			fBaseOptimal:Set[${Math.Calc[${MyShip.Module[${slot}].OptimalRange} / ${fRangeMod}]}]
			UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(${turret}): Turret's base optimal: ${fBaseOptimal}.",LOG_DEBUG]
		}
		UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(${turret}): Returning calculated base optimal: ${fBaseOptimal}",LOG_DEBUG]
		This.TurretBaseOptimals:Set[${turret},${fBaseOptimal}]
		return ${fBaseOptimal}
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
				UI:UpdateConsole["obj_Ship.BestAmmoTypeByRange: Unrecognized group for the weapon's charge, something is very broken. Group: ${MyShip.Module[${slot}].Charge.Group} ${MyShip.Module[${slot}].Charge.GroupID} ${MyShip.Module[${slot}].IsReloadingAmmo} ${MyShip.Module[${slot}].IsChangingAmmo}",LOG_CRITICAL]
				return ${itrWeapon.Value.Charge}
		}
	}

	/* string GetBestAmmoTypeByRange(float range, int turret, string ChargeType):
	Return a string designating the best ammo type at a given range for a given turret. */
	member:string GetBestAmmoTypeByRange(float range, int turret, string ChargeType)
	{
		variable string slot = ${This.TurretSlots[${turret}]}
		UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret},${ChargeType}): called, slot ${slot}",LOG_DEBUG]
		
		variable index:item idxAmmo
		variable iterator itrAmmo
		
		variable float fRangeMod
		variable string sCurrentAmmo
		variable float fTurretOptimal
		
		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyLookupTable:GetIterator[itrFrequencyPairs]
		HybridLookupTable:GetIterator[itrHybridPairs]
		AmmoLookupTable:GetIterator[itrAmmoPairs]
		
		variable float fOldDelta = 0
		variable float fNewDelta = 0
		variable string sBestSoFar
		variable string sHighestSoFar
		variable float fHighestSoFar = 0
		variable bool bBestFound = FALSE
				
		;Moved these down here = doesn't help at all to get available ammo for a freakin' nonexistent itrWeapon value!
		; This must have worked previously out of pure luck
		MyShip.Module[${slot}]:DoGetAvailableAmmo[idxAmmo]
		idxAmmo:GetIterator[itrAmmo]
		
		variable float fBaseOptimal = ${TurretBaseOptimals.Element[${turret}]}
		UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): fBaseOptimal: ${fBaseOptimal}",LOG_DEBUG]

		; Do some math on our range to 'reduce' it a little, i.e. if our target is at 25km, math it down to 22.5 or 25
		; This will help reduce the number of ammo changes as we can certainly hit well at that little deviation, and
		; it will help account for rats moving towards us (common).
		range:Set[${Math.Calc[${range} * 0.85]}]
		; 0.85 is pretty random. I should see if there is a "better"
		
		/*figure out the best ammo for a given range. */
		if ${itrAmmo:First(exists)}
		{
			do
			{
				if ${itr${ChargeType}Pairs:First(exists)}
				{
					do
					{
						if ${itrAmmo.Value.Name.Find[${itr${ChargeType}Pairs.Value}]}
						{
							fNewDelta:Set[${Math.Calc[${itr${ChargeType}Pairs.Key} - ${range}]}]
							if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
							{
								sBestSoFar:Set[${itr${ChargeType}Pairs.Value}]
								bBestFound:Set[TRUE]
								fOldDelta:Set[${fNewDelta}]
							}
							
							if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
							{
								fHighestSoFar:Set[${fNewDelta}]
								sHighestSoFar:Set[${itr${ChargeType}Pairs.Value}]
							}
							break
						}
					}
					while ${itr${ChargeType}Pairs:Next(exists)}
				}
			}
			while ${itrAmmo:Next(exists)}				
		}
		if ${itr${ChargeType}Pairs:First(exists)}
		{
			do
			{
				if ${MyShip.Module[${slot}].Charge.Name.Find[${itr${ChargeType}Pairs.Value}]}
				{
					UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): including already loaded ammo in our check!",LOG_DEBUG]
					fNewDelta:Set[${Math.Calc[${itr${ChargeType}Pairs.Key} - ${range}]}]
					UI:UpdateConsole["fNewDelta: ${fNewDelta}, ${Math.Calc[${itr${ChargeType}Pairs.Key} - ${range}]}, fOldDelta: ${fOldDelta}",LOG_DEBUG]
					if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
					{
						sBestSoFar:Set[${itr${ChargeType}Pairs.Value}]
						UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): sBestsoFar: ${sBestSoFar}, fNewDelta ${fNewDelta}, fOldDelta ${fOldDelta}",LOG_DEBUG]
						bBestFound:Set[TRUE]
						fOldDelta:Set[${fNewDelta}]
					}
					
					if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
					{
						fHighestSoFar:Set[${fNewDelta}]
						sHighestSoFar:Set[${itr${ChargeType}Pairs.Value}]
					}
					break
				}
			}
			while ${itr${ChargeType}Pairs:Next(exists)}
		}
		if !${bBestFound}
		{
			sBestSoFar:Set[${sHighestSoFar}]
		}
		UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range}): sBestSoFar: ${sBestSoFar}, sHighestSoFar: ${sHighestSoFar}",LOG_DEBUG]
		UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): returning ${sBestSoFar}",LOG_DEBUG]
		return ${sBestSoFar}
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
							;TODO: This may need work in the future regarding different weapon types. -- stealthy
							if ${anItemIterator.Value.Quantity} < ${Math.Calc[${aWeaponIterator.Value.MaxCharges}*${This.ModuleList_Weapon.Used}]}
							{
								UI:UpdateConsole["DEBUG: obj_Ship.IsAmmoAvailable: FALSE!", LOG_CRITICAL]
								bAmmoAvailable:Set[FALSE]
								break
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

	member:bool HasCloak()
	{
		return ${This.ModuleList_Cloaks.Used(bool)}
	}

	member:float CargoMinimumFreeSpace()
	{
		return ${Math.Calc[${_MyShip.CargoCapacity}*0.02]}
	}

	member:float CargoFreeSpace()
	{
		if ${MyShip.UsedCargoCapacity} < 0
		{
			return ${_MyShip.CargoCapacity}
		}
		return ${Math.Calc[${_MyShip.CargoCapacity}-${MyShip.UsedCargoCapacity}]}
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
		if ${This.CargoFreeSpace} <= ${Math.Calc[${_MyShip.CargoCapacity}*0.50]}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool IsDamped()
	{
		return ${_MyShip.MaxTargetRange} < ${This.m_MaxTargetRange}
	}

	member:float MaxTargetRange()
	{
		return ${m_MaxTargetRange}
	}

	method UpdateModuleList()
	{
		Validate_Ship()

		if !${Me.InSpace}
		{
			; GetModules cannot be used in station as of 07/15/2007
			UI:UpdateConsole["DEBUG: obj_Ship:UpdateModuleList called while not in space", LOG_DEBUG]
			return
		}

		/* save ship values that may change in combat */
		This.m_MaxTargetRange:Set[${_MyShip.MaxTargetRange}]
		This:SetType[${Me.ToEntity.Type}]
		This:SetTypeID[${Me.ToEntity.TypeID}]

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
		This.ModuleList_SensorBoost:Clear
		This.ModuleList_TargetPainter:Clear
		This.ModuleList_ECCM:Clear
		This.ModuleList_WeaponEnhance:Clear

		MyShip:DoGetModules[This.ModuleList]

		if !${This.ModuleList.Used} && ${MyShip.HighSlots} > 0
		{
			Defense:RunAway["ERROR: obj_Ship:UpdateModuleList - No modules found"]
			return
		}

		variable iterator Module

		UI:UpdateConsole["Module Inventory:", LOG_MINOR, 1]
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
				if ${Module.Value.ToItem.GroupID} == GROUP_TRACKINGENHANCER
				{
					This.HaveTrackingEnhancer:Set[TRUE]
				}
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
				case GROUP_ECCM
					This.ModuleList_ECCM:Insert[${Module.Value}]
					continue
				case GROUP_TRACKINGCOMPUTER
					This.ModuleList_WeaponEnhance:Insert[${Module.Value}]
					continue
				case GROUPID_DAMAGE_CONTROL
				case GROUPID_SHIELD_HARDENER
				case GROUPID_ARMOR_HARDENERS
					This.ModuleList_ActiveResists:Insert[${Module.Value}]
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
				case GROUPID_DATA_MINER
					if ${TypeID} == TYPEID_SALVAGER
					{
						This.ModuleList_Salvagers:Insert[${Module.Value}]
					}
					continue
				case GROUPID_TRACTOR_BEAM
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
					continue
				case GROUP_SENSORBOOSTER
					This.ModuleList_SensorBoost:Insert[${Module.Value}]
				case GROUP_TARGETPAINTER
					This.ModuleList_TargetPainter:Insert[${Module.Value}]
				default
					continue
			}

		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Weapons:", LOG_MINOR, 2]
		This.ModuleList_Weapon:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["Slot: ${Module.Value.ToItem.Slot} ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Weapon Enhance:",LOG_MINOR,2]
		This.ModuleList_WeaponEnhance:GetIterator[Module]
		if ${Module:First(exists)}
		{
			do
			{
				UI:UpdateConsole["	Slot: ${Module.Value.ToItem.Slot} ${Module.Value.ToItem.Name}",LOG_MINOR,4]
			}
			while ${Module:Next(exists)}
		}

		UI:UpdateConsole["ECCM:",LOG_MINOR,2]
		This.ModuleList_ECCM:GetIterator[Module]
		if ${Module:First(exists)}
		{
			do
			{
				UI:UpdateConsole["	Slot: ${Module.Value.ToItem.Slot} ${Module.Value.ToItem.Name}",LOG_MINOR,4]
			}
			while ${Module:Next(exists)}
		}
		
		UI:UpdateConsole["Active Resistance Modules:", LOG_MINOR, 2]
		This.ModuleList_ActiveResists:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Passive Modules:", LOG_MINOR, 2]
		This.ModuleList_Passive:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Mining Modules:", LOG_MINOR, 2]
		This.ModuleList_MiningLaser:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Armor Repair Modules:", LOG_MINOR, 2]
		This.ModuleList_Repair_Armor:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Shield Regen Modules:", LOG_MINOR, 2]
		This.ModuleList_Regen_Shield:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["AfterBurner Modules:", LOG_MINOR, 2]
		This.ModuleList_AB_MWD:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		if ${This.ModuleList_AB_MWD.Used} > 1
		{
			UI:UpdateConsole["Warning: More than 1 Afterburner or MWD was detected, I will only use the first one.", LOG_MINOR, 4]
		}

		UI:UpdateConsole["Salvaging Modules:", LOG_MINOR, 2]
		This.ModuleList_Salvagers:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Tractor Beam Modules:", LOG_MINOR, 2]
		This.ModuleList_TractorBeams:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Cloaking Device Modules:", LOG_MINOR, 2]
		This.ModuleList_Cloaks:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Stasis Web Modules:", LOG_MINOR, 2]
		This.ModuleList_StasisWeb:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Sensor Boost Modules:", LOG_MINOR, 2]
		This.ModuleList_SensorBoost:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}

		UI:UpdateConsole["Target Painter Modules:", LOG_MINOR, 2]
		This.ModuleList_TargetPainter:GetIterator[Module]
		if ${Module:First(exists)}
		do
		{
			UI:UpdateConsole["	 Slot: ${Module.Value.ToItem.Slot}  ${Module.Value.ToItem.Name}", LOG_MINOR, 4]
		}
		while ${Module:Next(exists)}
	}

	method UpdateBaselineUsedCargo()
	{
		Validate_Ship()

		; Store the used cargo space as the cargo hold exists NOW, with whatever is leftover in it.
		This.BaselineUsedCargo:Set[${MyShip.UsedCargoCapacity.Ceil}]
	}

	member:int MaxLockedTargets()
	{
		This:CalculateMaxLockedTargets[]
		return ${This.Calculated_MaxLockedTargets}
	}

	member:int TotalMiningLasers()
	{
		return ${This.ModuleList_MiningLaser.Used}
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
		if !${EVEBot.SessionValid}
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
		Validate_Ship()

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
		Validate_Ship()

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
		Validate_Ship()

		if ${_Me.MaxLockedTargets} < ${_MyShip.MaxLockedTargets}
		{
			Calculated_MaxLockedTargets:Set[${_Me.MaxLockedTargets}]
		}
		else
		{
			Calculated_MaxLockedTargets:Set[${_MyShip.MaxLockedTargets}]
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
			UI:UpdateConsole["Current crystal in ${SlotName} is ${LoadedAmmo}, looking for ${OreType}"]
			variable index:item CrystalList
			variable index:item CrystalListT1
			variable index:item CrystalListT2
			variable iterator CrystalIterator

			MyShip.Module[${SlotName}]:DoGetAvailableAmmo[CrystalList]

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
					UI:UpdateConsole["Switching Crystal in ${SlotName} from ${LoadedAmmo} to ${CrystalIterator.Value.Name}"]
					MyShip.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID},1]
					; This takes 2 seconds ingame, let's give it 50% more
					wait 30
					return
				}
			}
			while ${CrystalIterator:Next(exists)}
			UI:UpdateConsole["Warning: No T2 crystal found for ore type ${OreType}, checking for T1"]

			CrystalListT1:GetIterator[CrystalIterator]
			if ${CrystalIterator:First(exists)}
			do
			{
				variable string CrystalType
				CrystalType:Set[${CrystalIterator.Value.Name.Token[1, " "]}]

				;echo "DEBUG: ChangeMiningLaserCrystal Testing ${OreType} contains ${CrystalType}"
				if ${OreType.Find[${CrystalType}](exists)}
				{
					UI:UpdateConsole["Switching Crystal in ${SlotName} from ${LoadedAmmo} to ${CrystalIterator.Value.Name}"]
					MyShip.Module[${SlotName}]:ChangeAmmo[${CrystalIterator.Value.ID},1]
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
		Validate_Ship()

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

	method CycleMiningLaser(string Activate, string Slot)
	{
		Validate_Ship()

		echo CycleMiningLaser: ${Slot} Activate: ${Activate}
		if ${Activate.Equal[ON]} && \
			( ${MyShip.Module[${Slot}].IsActive} || \
			  ${MyShip.Module[${Slot}].IsGoingOnline} || \
			  ${MyShip.Module[${Slot}].IsDeactivating} || \
			  ${MyShip.Module[${Slot}].IsChangingAmmo} || \
			  ${MyShip.Module[${Slot}].IsReloadingAmmo} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Activate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[OFF]} && \
			(!${MyShip.Module[${Slot}].IsActive} || \
			  ${MyShip.Module[${Slot}].IsGoingOnline} || \
			  ${MyShip.Module[${Slot}].IsDeactivating} || \
			  ${MyShip.Module[${Slot}].IsChangingAmmo} || \
			  ${MyShip.Module[${Slot}].IsReloadingAmmo} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Tried to Deactivate the module, but it's already active or changing state."
			return
		}

		if ${Activate.Equal[ON]} && \
			(	!${MyShip.Module[${Slot}].LastTarget(exists)} || \
				!${Entity[id,${MyShip.Module[${Slot}].LastTarget.ID}](exists)} \
			)
		{
			echo "obj_Ship:CycleMiningLaser: Target doesn't exist"
			return
		}

		MyShip.Module[${Slot}]:Click
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
		Validate_Ship()

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
		Validate_Ship()

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
		Validate_Ship()

		EVE:Execute[CmdStopShip]
	}

	; Approaches EntityID to within 5% of Distance, then stops ship.  Momentum will handle the rest.
	function Approach(int EntityID, int64 Distance)
	{
		Validate_Ship()

		if ${Entity[${EntityID}](exists)}
		{
			variable float64 OriginalDistance = ${Entity[${EntityID}].Distance}
			variable float64 CurrentDistance

			If ${OriginalDistance} < ${Distance}
			{
				EVE:Execute[CmdStopShip]
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
		Validate_Ship()

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
			while ( ${CaptionCount} > ${MyShip.GetCargo} && \
					${LoopCheck} < 10 )
			{
				UI:UpdateConsole["obj_Ship: Waiting for cargo to load...(${LoopCheck})", LOG_MINOR]
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
		Validate_Ship()

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


	function WarpToID(int ID, int WarpInDistance=0)
	{
		Validate_Ship()

		if (${ID} <= 0)
		{
			UI:UpdateConsole["Error: obj_Ship:WarpToID: Id is <= 0 (${ID})"]
			return
		}

		if !${Entity[${ID}](exists)}
		{
			UI:UpdateConsole["Error: obj_Ship:WarpToID: No entity matched the ID given."]
			return
		}
#if EVEBOT_DEBUG
		UI:UpdateConsole["Debug: WarpToID ${ID} ${WarpInDistance}"]
#endif
		Entity[${ID}]:AlignTo
		call This.WarpPrepare
		while ${Entity[${ID}].Distance} >= WARP_RANGE
		{
			UI:UpdateConsole["Warping to ${Entity[${ID}].Name} @ ${EVEBot.MetersToKM_Str[${WarpInDistance}]}"]
			while !${This.WarpEntered}
			{
				Entity[${ID}]:WarpTo[${WarpInDistance}]
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
	function WarpToFleetMember( int charID, int distance=0 )
	{
		Validate_Ship()

		variable index:fleetmember FleetMembers
		variable iterator FleetMember

		FleetMembers:Clear
		Me:DoGetFleet[FleetMembers]
		FleetMembers:GetIterator[FleetMember]

		if ${FleetMember:First(exists)}
		{
			do
			{
				if ${FleetMember.Value.CharID} == ${charID} && ${Local[${FleetMember.Value.ToPilot.Name}](exists)}
				{
#if EVEBOT_DEBUG
					UI:UpdateConsole["Debug: WarpToFleetMember ${charID} ${distance}"]
#endif
					call This.WarpPrepare
					while !${Entity[OwnerID,${charID},CategoryID,6](exists)}
					{
						UI:UpdateConsole["Warping to Fleet Member: ${FleetMember.Value.ToPilot.Name}"]
						while !${This.WarpEntered}
						{
							FleetMember.Value:WarpTo[${distance}]
							wait 10
						}
						call This.WarpWait
						if ${Return} == 2
						{
							return
						}
					}
					UI:UpdateConsole["ERROR: Ship.WarpToFleetMember never reached fleet member!"]
					return
				}
			}
			while ${FleetMember:Next(exists)}
		}
		UI:UpdateConsole["ERROR: Ship.WarpToFleetMember could not find fleet member!"]
	}

	function WarpToBookMarkName(string DestinationBookmarkLabel)
	{
		Validate_Ship()

		if (!${EVE.Bookmark[${DestinationBookmarkLabel}](exists)})
		{
			UI:UpdateConsole["ERROR: Bookmark: '${DestinationBookmarkLabel}' does not exist!", LOG_CRITICAL]
			return
		}

		call This.WarpToBookMark ${EVE.Bookmark[${DestinationBookmarkLabel}].ID}
	}

	; TODO - Move this to obj_AutoPilot when it is ready - CyberTech
	function ActivateAutoPilot()
	{
		Validate_Ship()

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
			while ${Me.AutoPilotOn(exists)} && !${Me.AutoPilotOn} && (${Counter} < 10)
			wait 10
		}
		while ${Me.AutoPilotOn(exists)} && ${Me.AutoPilotOn}
		UI:UpdateConsole["Arrived - Waiting for system load"]
		wait 150
	}

	function TravelToSystem(int DestinationSystemID)
	{
		variable index:int apRoute
		variable iterator  apIterator

		EVE:ClearAllWaypoints
		wait 10
		
		while ${DestinationSystemID} != ${_Me.SolarSystemID}
		{
			EVE:DoGetToDestinationPath[apRoute]	
			UI:UpdateConsole["DEBUG: apRoute.Used = ${apRoute.Used}",LOG_DEBUG]
			if ${apRoute.Used} == 0
			{
				UI:UpdateConsole["DEBUG: To: ${DestinationSystemID} At: ${_Me.SolarSystemID}"]
				UI:UpdateConsole["Setting autopilot from ${Universe[${_Me.SolarSystemID}].Name} to ${Universe[${DestinationSystemID}].Name}"]
				Universe[${DestinationSystemID}]:SetDestination
			}
			
			call This.ActivateAutoPilot
		}
	}

	function WarpToBookMark(bookmark DestinationBookmark,bool EnterGate = TRUE)
	{
		Validate_Ship()

		variable int Counter

		if ${Me.InStation}
		{
			call Station.Undock
		}

		if ${Math.Distance[${Me.ToEntity.X}, ${Me.ToEntity.Y}, ${Me.ToEntity.Z}, ${DestinationBookmark.X}, ${DestinationBookmark.Y}, ${DestinationBookmark.Z}]} < WARP_RANGE
		{
			UI:UpdateConsole["obj_Ship:WarpToBookMark - We are already at the bookmark"]
			return
		}

		call This.WarpPrepare
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
		echo \${Entity[CategoryID,6].X} = ${Entity[CategoryID,6].X}
		echo \${Entity[CategoryID,6].Y} = ${Entity[CategoryID,6].Y}
		echo \${Entity[CategoryID,6].Z} = ${Entity[CategoryID,6].Z}
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
		declarevariable EntityID int ${DestinationBookmark.ToEntity.ID}

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
					${Entity[TypeID,TYPE_ACCELERATION_GATE](exists)}
				{
					if ${EnterGate}
					{
						call This.Approach ${Entity[TypeID,TYPE_ACCELERATION_GATE].ID} DOCKING_RANGE
						wait 10
						UI:UpdateConsole["Activating Acceleration Gate..."]
						while !${This.WarpEntered}
						{
							Entity[TypeID,TYPE_ACCELERATION_GATE]:Activate
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
						;we should not be going through acceleration gates , this is handled by the missioneer!
						return
					}
				}
				else
				{

					UI:UpdateConsole["2: Warping to bookmark ${Label} (Attempt #${WarpCounter})"]
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
		Validate_Ship()

		UI:UpdateConsole["Preparing for warp"]
		if !${This.HasCovOpsCloak}
		{
			This:Deactivate_Cloak[]
		}
		This:Deactivate_SensorBoost

		if ${This.Drones.WaitingForDrones}
		{
			UI:UpdateConsole["Drone deployment already in process, delaying warp", LOG_CRITICAL]
			do
			{
				waitframe
			}
			while ${This.Drones.WaitingForDrones}
		}

		This:DeactivateAllMiningLasers[]
		Targeting:Disable[]
		This:UnlockAllTargets[]
		call This.Drones.ReturnAllToDroneBay
	}

	member:bool InWarp()
	{
		Validate_Ship()

		if ${_Me.ToEntity.Mode} == 3
		{
			return TRUE
		}
		return FALSE
	}

	member:bool WarpEntered()
	{
		Validate_Ship()

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
		Validate_Ship()

		variable bool Warped = FALSE

		; We reload weapons here, because we know we're in warp, so they're deactivated.
		This:Reload_Weapons[TRUE]
		while ${This.InWarp}
		{
			Warped:Set[TRUE]
			wait 10
			if ${This.InteruptWarpWait}
			{
				; TODO - implement this. not sure what i was thinking of for it. i can see it's use -- CyberTech
				UI:UpdateConsole["Leaving WarpWait due to emergency condition", LOG_CRITICAL]
				This.InteruptWarpWait:Set[False]
				return 2
			}
		}
		UI:UpdateConsole["Dropped out of warp"]
		return ${Warped}
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
	Define_ModuleMethod(Activate_WeaponEnhance, Deactivate_WeaponEnhance, This.ModuleList_WeaponEnhance, FALSE)

	member:bool IsCloaked()
	{
		Validate_Ship()

		if ${Me.ToEntity(exists)} && ${_Me.ToEntity.IsCloaked}
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
			MyShip:StackAllCargo
		}
	}

	; Returns the salvager range minus 10%
	member:int OptimalSalvageRange()
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
	member:int OptimalTractorRange()
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
	member:int OptimalTargetingRange()
	{
		return ${Math.Calc[${_MyShip.MaxTargetRange}*0.90]}
	}

	; Returns the highest weapon optimal range minus 10%
	member:int OptimalWeaponRange()
	{
		return ${Math.Calc[${Config.Combat.MaxMissileRange} * 0.95]}
	}

	member:bool IsPod()
	{
		Validate_Ship()

		variable string ShipName = ${MyShip}

		if ${ShipName.Right[10].Equal["'s Capsule"]} || \
			${Me.ToEntity.GroupID} == GROUP_CAPSULE
		{
			if ${This.TypeID} != ${Me.ToEntity.TypeID}
			{
				This:UpdateModuleList[]
			}
			return TRUE
		}
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
		variable iterator itrWeapon
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		
		if ${itrWeapon:First(exists)}
		{
			do
			{
				if ${itrWeapon.Value.IsActive}
				{
					return TRUE
				}
			}
			while ${itrWeapon:Next(exists)}
		}
		return FALSE
	}

	method Reload_Weapons(bool ForceReload)
	{
		variable bool NeedReload = FALSE

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

	member:string Type()
	{
		if ${Station.Docked}
		{
			return ${This.m_Type}
		}
		else
		{
			return ${Me.ToEntity.Type}
		}
	}

	method SetType(string typeString)
	{
		;UI:UpdateConsole["obj_Ship: DEBUG: Setting ship type to ${typeString}"]
		This.m_Type:Set[${typeString}]
	}

	member:int TypeID()
	{
		if ${Station.Docked}
		{
			return ${This.m_TypeID}
		}
		else
		{
			return ${Me.ToEntity.TypeID}
		}
	}

	method SetTypeID(int typeID)
	{
		;UI:UpdateConsole["obj_Ship: DEBUG: Setting ship type ID to ${typeID}"]
		This.m_TypeID:Set[${typeID}]
	}

	function ActivateShip(string name)
	{
		Validate_Ship()

		variable index:item hsIndex
		variable iterator hsIterator
		variable string shipName

		if ${Station.Docked}
		{
			Me:DoGetHangarShips[hsIndex]
			hsIndex:GetIterator[hsIterator]

			shipName:Set[${MyShip}]
			if ${shipName.NotEqual[${name}]}
			{
				if ${hsIterator:First(exists)}
				{
					do
					{
						if ${hsIterator.Value.GivenName.Equal[${name}]}
						{
							UI:UpdateConsole["obj_Ship: Switching to ship named ${hsIterator.Value.GivenName}."]
							hsIterator.Value:MakeActive
							wait 10
							This:SetType[${hsIterator.Value.Type}]
							This:SetTypeID[${hsIterator.Value.TypeID}]
							break
						}
					}
					while ${hsIterator:Next(exists)}
				}
			}
		}
	}
}
