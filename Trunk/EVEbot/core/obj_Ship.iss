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
				}
			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
	
	method PopulateNameModPairs()
	{
		HybridNameModPairs:Set["Iron",1.6]
		HybridNameModPairs:Set["Tungsten",1.4]
		HybridNameModPairs:Set["Iridium",1.2]
		HybridNameModPairs:Set["Lead",1]
		HybridNameModPairs:Set["Thorium",0.875]
		HybridNameModPairs:Set["Uranium",0.75]
		HybridNameModPairs:Set["Plutonium",0.625]
		HybridNameModPairs:Set["Antimatter",0.5]
		
		AmmoNameModPairs:Set["Carbonized Lead",1.6]
		AmmoNameModPairs:Set["Nuclear",1.4]
		AmmoNameModPairs:Set["Proton",1.2]
		AmmoNameModPairs:Set["Depleted Uranium",1]
		AmmoNameModPairs:Set["Titanium Sabot",0.875]
		AmmoNameModPairs:Set["Fusion",0.75]
		AmmoNameModPairs:Set["Phased Plasma",0.625]
		AmmoNameModPairs:Set["EMP",0.5]
		
		FrequencyNameModPairs:Set["Radio",1.6]
		FrequencyNameModPairs:Set["Microwave",1.4]
		FrequencyNameModPairs:Set["Infrared",1.2]
		FrequencyNameModPairs:Set["Standard",1]
		FrequencyNameModPairs:Set["Ultraviolet",0.875]
		FrequencyNameModPairs:Set["Xray",0.75]
		FrequencyNameModPairs:Set["Gamma",0.625]
		FrequencyNameModPairs:Set["Multifrequency",0.5]
	}

	/* bool NeedAmmoChange(float range, int turret):
	Return true if we are currently using a different ammo than is optimal in specified turret. Otherwise return false. */
	member:bool NeedAmmoChange(float range, int turret)
	{
		variable string sBestAmmo = ${This.GetBestAmmoTypeByRange[${range},${turret}]}
		variable bool bFoundAmmo = FALSE
		
		variable iterator itrWeapon
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		
		if ${itrWeapon:First(exists)}
		{
			do
			{
				if ${itrWeapon.Value.Charge.Name.Find[${sBestAmmo}](exists)}
				{
					bFoundAmmo:Set[TRUE]
				}
				else
				{
					bFoundAmmo:Set[FALSE]
				}
			}
			while ${itrWeapon:Next(exists)}
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
		variable string sBestAmmo = ${This.GetBestAmmoTypeByRange[${range},${turret}]}
		UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range}): Best Ammo: ${sBestAmmo}",LOG_DEBUG]
		variable iterator itrWeapon
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		
		variable index:item idxAmmo
		variable iterator itrAmmo
		variable int iTempTurret = 0
		
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check if we're on the turret we want
				iTempTurret:Inc
				if ${iTempTurret} != ${turret}
				{
					UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range},${turret}): Skipping turret ${iTempTurret}.",LOG_DEBUG]
					continue
				}
				itrWeapon.Value:DoGetAvailableAmmo[idxAmmo]
				idxAmmo:GetIterator[itrAmmo]			
				if ${itrAmmo:First(exists)}
				{
					do
					{
						UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range},${turret}): Found best ammo: ${itrAmmo.Value.Name.Find[${sBestAmmo}](exists)}",LOG_DEBUG]
						if ${itrAmmo.Value.Name.Find[${sBestAmmo}](exists)} && !${itrWeapon.Value.Charge.Name.Find[${sBestAmmo}](exists)}
						{					
							UI:UpdateConsole["obj_Ship:LoadOptimalAmmo(${range},${turret}): Changing ammo to ${itrAmmo.Value.Name}, ${itrWeapon.Value.MaxCharges}",LOG_DEBUG]
							itrWeapon.Value:ChangeAmmo[${itrAmmo.Value.ID},${itrWeapon.Value.MaxCharges}]							
							return
						}					
					}
					while ${itrAmmo:Next(exists)}
				}
			}
			while ${itrWeapon:Next(exists)}
		}
	}

	/* float GetMaximumTurretRange(int turret)
	Calculate and return the maximum range for passed turret, taking into account available ammo. */
	member:float GetMaximumTurretRange(int turret)
	{
		variable float fBaseOptimal = ${This.GetTurretBaseOptimal[${turret}]}
		UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): base optimal: ${fBaseOptimal}",LOG_DEBUG]
		variable iterator itrWeapon
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		
		variable index:item idxAmmo
		variable iterator itrAmmo

		variable float fTempMaxRange = 0
		variable float sTempMaxRangeAmmo

		variable float fMaxTurretRange = 0
		
		variable int iTurret = 0

		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]		
		
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check if we're on the turret we want
				iTurret:Inc
				if ${iTurret} != ${turret}
				{
					UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): Skipping turret ${iTurret}.",LOG_DEBUG]
					continue
				}
				itrWeapon.Value:DoGetAvailableAmmo[idxAmmo]
				idxAmmo:GetIterator[itrAmmo]
				if ${itrAmmo:First(exists)}
				{
					do
					{
						switch ${itrAmmo.Value.GroupID}
						{
							case GROUP_AMMO
								if ${itrAmmoPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrAmmoPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): Found ammo type ${itrAmmoPairs.Key} ${itrAmmoPairs.Value}",LOG_DEBUG]
											fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value}]}]
											if ${fTempMaxRange} > ${fMaxTurretRange}
											{
												UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): New max range: ${fTempMaxRange}",LOG_DEBUG]
												fMaxTurretRange:Set[${fTempMaxRange}]
											}
											break
										}
									}
									while ${itrAmmoPairs:Next(exists)}
								}
								break
							case GROUP_FREQUENCYCRYSTAL
								if ${itrFrequencyPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrFrequencyPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): Found crystal type ${itrFrequencyPairs.Key} ${itrFrequencyPairs.Value}",LOG_DEBUG]
											fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value}]}]
											if ${fTempMaxRange} > ${fMaxTurretRange}
											{
												UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): New max range: ${fTempMaxRange}",LOG_DEBUG]
												fMaxTurretRange:Set[${fTempMaxRange}]
											}
											break
										}
									}
									while ${itrFrequencyPairs:Next(exists)}
								}
								break
							case GROUP_HYBRIDAMMO
								if ${itrHybridPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrHybridPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): Found hybrid ammo type ${itrHybridPairs.Key} ${itrHybridPairs.Value}",LOG_DEBUG]
											fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value}]}]
											if ${fTempMaxRange} > ${fMaxTurretRange}
											{
												UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): New max range: ${fTempMaxRange}",LOG_DEBUG]
												fMaxTurretRange:Set[${fTempMaxRange}]
											}
											break
										}
									}
									while ${itrHybridPairs:Next(exists)}
								}
								break
							default
								if ${itrWeapon.Value.IsReloadingAmmo} || ${itrWeapon.Value.IsChangingAmmo}
								{
									UI:UpdateConsole["obj_Ship.GetMaxTurretRange: Ammo is reloading or changing; shouldn't be called",LOG_DEBUG]
								}
								else
								{
									UI:UpdateConsole["obj_Ship.GetMaxTurretRange: Shit broke because we didn't meet a case for ammo group id.",LOG_CRITICAL]
								}
								return 1
						}
					}
					while ${itrAmmo:Next(exists)}
				}
			}
			while ${itrWeapon:Next(exists)}
		}
		iTurret:Set[0]
		/* We have to account for the ammo we currently have loaded. */
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check that this is the turret we want
				iTurret:Inc
				if ${iTurret} != ${turret}
				{
					UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(${turret}): Skipping turret ${iTurret}.",LOG_DEBUG]
					continue
				}
				switch ${itrAmmo.Value.GroupID}
				{
					case GROUP_HYBRIDAMMO
						if ${itrHybridPairs:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.GetMaxTurretRange(${turret}): checking ${itrHybridPairs.Key} against currently loaded ammo ${itrWeapon.Value.Charge.Name}",LOG_DEBUG]
  							if ${itrWeapon.Value.Charge.Name.Find[${itrHybridPairs.Key}]}
  							{
  								fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value}]}]
  								if ${fTempMaxRange} > ${fMaxTurretRange}
  								{
  									UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): New max range: ${fTempMaxRange}",LOG_DEBUG]
  									fMaxTurretRange:Set[${fTempMaxRange}]
  								}
  								break
  							}
							}
							while ${itrHybridPairs:Next(exists)}
						}
						break
					case GROUP_AMMO
						if ${itrAmmoPairs:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.GetMaxTurretRange(${turret}): checking ${itrAmmoPairs.Key} against currently loaded ammo ${itrWeapon.Value.Charge.Name}",LOG_DEBUG]
  							if ${itrWeapon.Value.Charge.Name.Find[${itrAmmoPairs.Key}]}
  							{
  								fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value}]}]
  								if ${fTempMaxRange} > ${fMaxTurretRange}
  								{
  									UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): New max range: ${fTempMaxRange}",LOG_DEBUG]
  									fMaxTurretRange:Set[${fTempMaxRange}]
  								}
  								break
  							}
							}
							while ${itrHybridPairs:Next(exists)}
						}
						break
					case GROUP_FREQUENCYCRYSTAL
						if ${itrFrequencyPairs:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.GetMaxTurretRange(${turret}): checking ${itrFrequencyPairs.Key} against currently loaded ammo ${itrWeapon.Value.Charge.Name}",LOG_DEBUG]
  							if ${itrWeapon.Value.Charge.Name.Find[${itrFrequencyPairs.Key}]}
  							{
  								fTempMaxRange:Set[${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value}]}]
  								if ${fTempMaxRange} > ${fMaxTurretRange}
  								{
  									UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): New max range: ${fTempMaxRange}",LOG_DEBUG]
  									fMaxTurretRange:Set[${fTempMaxRange}]
  								}
  								break
  							}
							}
							while ${itrFrequencyPairs:Next(exists)}
						}
						break
				}
			}
			while ${itrWeapon:Next(exists)}
		}
		UI:UpdateConsole["obj_Ship.GetMaximumTurretRange(${turret}): calculated maximum turret range: ${fMaxTurretRange}",LOG_DEBUG]
		return ${fMaxTurretRange}
	}
	
	/* float GetMinimumTurretRange(int turret):
	Calculate and return the minimum range for passed turret, taking into account the ammo types available. */
	member:float GetMinimumTurretRange(int turret)
	{
		variable float fBaseOptimal = ${This.GetTurretBaseOptimal[${turret}]}
		UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(${turret}): base optimal: ${fBaseOptimal}",LOG_DEBUG]
		variable iterator itrWeapon
		variable iterator itrWeapon2
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		This.ModuleList_Weapon:GetIterator[itrWeapon2]
		
		variable index:item idxAmmo
		variable iterator itrAmmo

		variable float fTempMinRange = 0
		variable float sTempMinRangeAmmo

		variable float fMinTurretRange = 0
		
		variable int iTurret = 0

		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]		
		
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check that this is the turret we want
				iTurret:Inc
				if ${iTurret} != ${turret}
				{
					UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(${turret}): Skipping turret ${iTurret}.",LOG_DEBUG]
					continue
				}
				itrWeapon.Value:DoGetAvailableAmmo[idxAmmo]
				idxAmmo:GetIterator[itrAmmo]
				if ${itrAmmo:First(exists)}
				{
					do
					{
						switch ${itrAmmo.Value.GroupID}
						{
							case GROUP_AMMO
								if ${itrAmmoPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrAmmoPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): Found ammo type ${itrAmmoPairs.Key} ${itrAmmoPairs.Value}",LOG_DEBUG]
											fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value}]}]
											if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
											{
												UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New min range: ${fTempMinRange}",LOG_DEBUG]
												fMinTurretRange:Set[${fTempMinRange}]
											}
											break
										}
									}
									while ${itrAmmoPairs:Next(exists)}
								}
								break
							case GROUP_FREQUENCYCRYSTAL
								if ${itrFrequencyPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrFrequencyPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): Found crystal type ${itrFrequencyPairs.Key} ${itrFrequencyPairs.Value}",LOG_DEBUG]
											fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value}]}]
											if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
											{
												UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New min range: ${fTempMinRange}",LOG_DEBUG]
												fMinTurretRange:Set[${fTempMinRange}]
											}
											break
										}
									}
									while ${itrFrequencyPairs:Next(exists)}
								}
								break
							case GROUP_HYBRIDAMMO
								if ${itrHybridPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrHybridPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): Found hybrid ammo type ${itrHybridPairs.Key} ${itrHybridPairs.Value}",LOG_DEBUG]
											fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value}]}]
											if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
											{
												UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New min range: ${fTempMinRange}",LOG_DEBUG]
												fMinTurretRange:Set[${fTempMinRange}]
											}
											break
										}
									}
									while ${itrHybridPairs:Next(exists)}
								}
								break
							default
								if ${itrWeapon.Value.IsReloadingAmmo} || ${itrWeapon.Value.IsChangingAmmo}
								{
									UI:UpdateConsole["obj_Ship.MinimumTurretRange(${turret}): Called while reloading or changing ammo, shouldn't be.",LOG_DEBUG]
								}
								else
								{
									UI:UpdateConsole["obj_Ship.GetMinimumTurretRange: GroupID is bad; ammo needs cycled. TODO: Auto cycle ammo",LOG_DEBUG]
								}
								return 1
						}
					}
					while ${itrAmmo:Next(exists)}
				}
			}
			while ${itrWeapon:Next(exists)}
		}
		iTurret:Set[0]
		/* We have to account for the ammo we currently have loaded. */
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check that this is the turret we want
				iTurret:Inc
				if ${iTurret} != ${turret}
				{
					UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(${turret}): Skipping turret ${iTurret}.",LOG_DEBUG]
					continue
				}
				switch ${itrAmmo.Value.GroupID}
				{
					case GROUP_HYBRIDAMMO
						if ${itrHybridPairs:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.GetMinimumTurretRange: checking ${itrHybridPairs.Key} against currently loaded ammo ${itrWeapon.Value.Charge.Name}",LOG_DEBUG]
  							if ${itrWeapon.Value.Charge.Name.Find[${itrHybridPairs.Key}]}
  							{
  								fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value}]}]
  								if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
  								{
  									UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New min range: ${fTempMinRange}",LOG_DEBUG]
  									fMinTurretRange:Set[${fTempMinRange}]
  								}
  								break
  							}
							}
							while ${itrHybridPairs:Next(exists)}
						}
						break
					case GROUP_AMMO
						if ${itrAmmoPairs:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.GetMinimumTurretRange: checking ${itrAmmoPairs.Key} against currently loaded ammo ${itrWeapon.Value.Charge.Name}",LOG_DEBUG]
  							if ${itrWeapon.Value.Charge.Name.Find[${itrAmmoPairs.Key}]}
  							{
  								fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value}]}]
  								if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
  								{
  									UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New Min range: ${fTempMinRange}",LOG_DEBUG]
  									fMinTurretRange:Set[${fTempMinRange}]
  								}
  								break
  							}
							}
							while ${itrHybridPairs:Next(exists)}
						}
						break
					case GROUP_FREQUENCYCRYSTAL
						if ${itrFrequencyPairs:First(exists)}
						{
							do
							{
								UI:UpdateConsole["obj_Ship.GetMinimumTurretRange: checking ${itrFrequencyPairs.Key} against currently loaded ammo ${itrWeapon.Value.Charge.Name}",LOG_DEBUG]
  							if ${itrWeapon.Value.Charge.Name.Find[${itrFrequencyPairs.Key}]}
  							{
  								fTempMinRange:Set[${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value}]}]
  								if ${fTempMinRange} < ${fMinTurretRange} || ${fMinTurretRange} == 0
  								{
  									UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): New Min range: ${fTempMinRange}",LOG_DEBUG]
  									fMinTurretRange:Set[${fTempMinRange}]
  								}
  								break
  							}
							}
							while ${itrFrequencyPairs:Next(exists)}
						}
						break
				}
			}
			while ${itrWeapon:Next(exists)}
		}
		UI:UpdateConsole["obj_Ship.GetMinimumTurretRange(): calculated minimum turret range: ${fMinTurretRange}",LOG_DEBUG]
		return ${fMinTurretRange}
	}	
	
	/* float GetTurretBaseOptimal(int turret):
	Calculate and return the base optimal range for passed turret. */
	member:float GetTurretBaseOptimal(int turret)
	{
		variable iterator itrWeapon
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		
		variable index:item idxAmmo
		variable iterator itrAmmo
		
		variable float fBaseOptimal
		variable float fRangeMod
		
		variable int iTurret = 0
		
		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]
			
		UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): {itrWeapon:First(exists)}: ${itrWeapon:First(exists)}",LOG_DEBUG]
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check if we have the turret we wanted
				iTurret:Inc
				if ${iTurret} != ${turret}
				{
					UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(${turret}): Skipping turret ${iTurret}.",LOG_DEBUG]
					continue
				}
				
				UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): .GropuID ${itrWeapon.Value.Charge.GroupID}",LOG_DEBUG]
				switch ${itrWeapon.Value.Charge.GroupID}
				{
					case GROUP_AMMO
						if ${itrAmmoPairs:First(exists)}
						{
							do
							{
								if ${itrWeapon.Value.Charge.Name.Find[${itrAmmoPairs.Key}]}
								{
									UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): Found ammo ${itrAmmoPairs.Key}, mod ${itrAmmoPairs.Value}",LOG_DEBUG]
									fRangeMod:Set[${itrAmmoPairs.Value}]
									break
								}
							}
							while ${itrAmmoPairs:Next(exists)}
						}
						break
					case GROUP_HYBRIDAMMO
						UI:UpdateConsole["obj_Ship.GTBO(): hybrid pairs first exists? ${itrHybridPairs:First(exists)}",LOG_DEBUG]
						if ${itrHybridPairs:First(exists)}
						{
							do
							{
								if ${itrWeapon.Value.Charge.Name.Find[${itrHybridPairs.Key}]}
								{
									UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): Found hybrid ammo ${itrHybridPairs.Key}, mod ${itrHybridPairs.Value}",LOG_DEBUG]
									fRangeMod:Set[${itrHybridPairs.Value}]
									break
								}
							}
							while ${itrHybridPairs:Next(exists)}
						}
						break
					case GROUP_FREQUENCYCRYSTAL
						if ${itrFrequencyPairs:First(exists)}
						{
							do
							{
								if ${itrWeapon.Value.Charge.Name.Find[${itrFrequencyPairs.Key}]}
								{
									UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): Found crystal ${itrFrequencyPairs.Key}, mod ${itrFrequencyPairs.Value}",LOG_DEBUG]
									fRangeMod:Set[${itrFrequencyPairs.Value}]
									break
								}
							}
							while ${itrFrequencyPairs:Next(exists)}
						}
						break
					default
						if ${itrWeapon.Value.IsReloadingAmmo} || ${itrWeapon.Value.IsChangingAmmo}
						{
							UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(${turret}): Called while reloading or changing ammo, shouldn't be.",LOG_DEBUG]
						}
						else
						{
							UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): Inavlid groupID, ammo needs to be cycled!",LOG_CRITICAL]
						}
						return 1
				}
				if ${fRangeMod} == 0
				{
					UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(): Range mod is 0; ammo needs cycled; returning current optimal",LOG_CRITICAL]
					fBaseOptimal:Set[${itrWeapon.Value.OptimalRange}]
					return ${fBaseOptimal}
				}
				else
				{
					fBaseOptimal:Set[${Math.Calc[${itrWeapon.Value.OptimalRange} / ${fRangeMod}]}]
					UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(${turret}): Turret's base optimal: ${fBaseOptimal}.",LOG_DEBUG]
					break
				}
			}
			while ${itrWeapon:Next(exists)}
		}
		UI:UpdateConsole["obj_Ship.GetTurretBaseOptimal(${turret}): Returning calculated base optimal: ${fBaseOptimal}",LOG_DEBUG]
		return ${fBaseOptimal}
	}

	/* string GetBestAmmoTypeByRange(float range, int turret):
	Return a string designating the best ammo type at a given range for a given turret. */
	member:string GetBestAmmoTypeByRange(float range, int turret)
	{
		UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range}): called",LOG_DEBUG]
		variable iterator itrWeapon
		variable iterator itrWeapon2
		This.ModuleList_Weapon:GetIterator[itrWeapon]
		This.ModuleList_Weapon:GetIterator[itrWeapon2]
		
		variable int iGroupId = 0
		
		variable index:item idxAmmo
		variable iterator itrAmmo
		
		variable float fRangeMod
		variable string sCurrentAmmo
		variable float fTurretOptimal
		variable int iTurret = 0
		
		variable iterator itrFrequencyPairs
		variable iterator itrHybridPairs
		variable iterator itrAmmoPairs
		FrequencyNameModPairs:GetIterator[itrFrequencyPairs]
		HybridNameModPairs:GetIterator[itrHybridPairs]
		AmmoNameModPairs:GetIterator[itrAmmoPairs]
		
		variable float fOldDelta = 0
		variable float fNewDelta = 0
		variable string sBestSoFar
		variable string sHighestSoFar
		variable float fHighestSoFar = 0
		variable bool bBestFound = FALSE
		

		
		if ${itrWeapon:First(exists)}
		{
			do
			{
				; Check if the turret we're iterating is the turret we want.
				iTurret:Inc
				if ${iTurret} != ${turret}
				{
					; Looks like it isn't, which means we can continue in order to skip all the logic.
					UI:UpdateConsole["obj_Ship: Skipping turret ${iTurret} because we want best ammo for turret ${turret}.",LOG_DEBUG]
					continue
				}
				
				;Moved these down here = doesn't help at all to get available ammo for a freakin' nonexistent itrWeapon value!
				; This must have worked previously out of pure luck
				itrWeapon.Value:DoGetAvailableAmmo[idxAmmo]
				idxAmmo:GetIterator[itrAmmo]
			
				UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range}): getting base optimal...",LOG_DEBUG]
				variable float fBaseOptimal = ${This.GetTurretBaseOptimal[${turret}]}
				UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range}): fBaseOptimal: ${fBaseOptimal}",LOG_DEBUG]

				; Do some math on our range to 'reduce' it a little, i.e. if our target is at 25km, math it down to 22.5 or 25
				; This will help reduce the number of ammo changes as we can certainly hit well at that little deviation, and
				; it will help account for rats moving towards us (common).
				range:Set[${Math.Calc[${range} * 0.85]}]
				; 0.85 is pretty random. I should see if there is a "better"
			
				/*figure out the best ammo for a given range. */
				switch ${itrWeapon.Value.Charge.GroupID}
				{
					case GROUP_AMMO
						if ${itrAmmo:First(exists)}
						{
							do
							{
								if ${itrAmmoPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrAmmoPairs.Key}]}
										{
											fNewDelta:Set[${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value} - ${range}]}]
											if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
											{
												sBestSoFar:Set[${itrAmmoPairs.Key}]
												bBestFound:Set[TRUE]
												fOldDelta:Set[${fNewDelta}]
											}
											
											if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
											{
												fHighestSoFar:Set[${fNewDelta}]
												sHighestSoFar:Set[${itrAmmoPairs.Key}]
											}
											break
										}
									}
									while ${itrAmmoPairs:Next(exists)}
								}
							}
							while ${itrAmmo:Next(exists)}				
						}
						if ${itrWeapon2:First(exists)}
						{
							iTurret:Set[0]
							do
							{
								iTurret:Inc
								if ${iTurret} != ${turret}
								{
									; Looks like it isn't, which means we can continue in order to skip all the logic.
									UI:UpdateConsole["obj_Ship: Skipping turret ${iTurret} because we want best ammo for turret ${turret}.",LOG_DEBUG]
									continue
								}
								if ${itrAmmoPairs:First(exists)}
								{
									do
									{
										if ${itrWeapon2.Value.Charge.Name.Find[${itrAmmoPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): including already loaded ammo in our check!",LOG_DEBUG]
											fNewDelta:Set[${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value} - ${range}]}]
											UI:UpdateConsole["fNewDelta: ${fNewDelta}, ${Math.Calc[${fBaseOptimal} * ${itrAmmoPairs.Value} - ${range}]}, fOldDelta: ${fOldDelta}",LOG_DEBUG]
											if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
											{
												sBestSoFar:Set[${itrAmmoPairs.Key}]
												UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): sBestsoFar: ${sBestSoFar}, fNewDeelta ${fNewDelta}, fOldDelta ${fOldDelta}",LOG_DEBUG]
												bBestFound:Set[TRUE]
												fOldDelta:Set[${fNewDelta}]
											}
											
											if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
											{
												fHighestSoFar:Set[${fNewDelta}]
												sHighestSoFar:Set[${itrAmmoPairs.Key}]
											}
											break
										}
									}
									while ${itrAmmoPairs:Next(exists)}
								}
							}
							while ${itrWeapon2:Next(exists)}
						}
						if !${bBestFound}
						{
							sBestSoFar:Set[${sHighestSoFar}]
						}
						UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range}): sBestSoFar: ${sBestSoFar}, sHighestSoFar: ${sHighestSoFar}",LOG_DEBUG]
						break
					case GROUP_HYBRIDAMMO
						if ${itrAmmo:First(exists)}
						{
							do
							{
								if ${itrHybridPairs:First(exists)}
								{
									do
									{
										UI:UpdateConsole["Checking ${itrAmmo.Value.Name} against ${itrHybridPairs.Key}...",LOG_DEBUG]
										if ${itrAmmo.Value.Name.Find[${itrHybridPairs.Key}]}
										{
											fNewDelta:Set[${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value} - ${range}]}]
											UI:UpdateConsole["fNewDelta: ${fNewDelta}, ${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value} - ${range}]}, fOldDelta: ${fOldDelta}",LOG_DEBUG]
											/* We want our delta to be positive or 0 = meaning it'll hit at or above target range */
											/* If our new delta is smaller than the old delta - meaning it'll hit closer to the rat even if it overshoots - we want it */
											/* we'll also take it if oldDelta is 0 and we have nothing to compare against */
											if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
											{
												sBestSoFar:Set[${itrHybridPairs.Key}]
												UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}) sBestSoFar: ${sBestSoFar}, fNewDeelta ${fNewDelta}, fOldDelta ${fOldDelta}",LOG_DEBUG]
												bBestFound:Set[TRUE]
												fOldDelta:Set[${fNewDelta}]
											}
											
											UI:UpdateConsole["fHighestSoFar: ${fHighestSoFar}",LOG_DEBUG]
											if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
											{
												fHighestSoFar:Set[${fNewDelta}]
												sHighestSoFar:Set[${itrHybridPairs.Key}]
											}
											break
										}
									}
									while ${itrHybridPairs:Next(exists)}
								}
							}
							while ${itrAmmo:Next(exists)}				
						}
						if ${itrWeapon2:First(exists)}
						{
							iTurret:Set[0]
							do
							{
								iTurret:Inc
								if ${iTurret} != ${turret}
								{
									; Looks like it isn't, which means we can continue in order to skip all the logic.
									UI:UpdateConsole["obj_Ship: Skipping turret ${iTurret} because we want best ammo for turret ${turret}.",LOG_DEBUG]
									continue
								}
								if ${itrHybridPairs:First(exists)}
								{
									do
									{
										if ${itrWeapon2.Value.Charge.Name.Find[${itrHybridPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): including already loaded ammo in our check!",LOG_DEBUG]
											fNewDelta:Set[${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value} - ${range}]}]
											UI:UpdateConsole["fNewDelta: ${fNewDelta}, ${Math.Calc[${fBaseOptimal} * ${itrHybridPairs.Value} - ${range}]}, fOldDelta: ${fOldDelta}",LOG_DEBUG]
											if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
											{
												sBestSoFar:Set[${itrHybridPairs.Key}]
												UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): sBestsoFar: ${sBestSoFar}, fNewDeelta ${fNewDelta}, fOldDelta ${fOldDelta} ",LOG_DEBUG]
												bBestFound:Set[TRUE]
												fOldDelta:Set[${fNewDelta}]
											}
											
											if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
											{
												fHighestSoFar:Set[${fNewDelta}]
												sHighestSoFar:Set[${itrHybridPairs.Key}]
											}
											break
										}
									}
									while ${itrHybridPairs:Next(exists)}
								}
							}
							while ${itrWeapon2:Next(exists)}
						}
						if !${bBestFound}
						{
							sBestSoFar:Set[${sHighestSoFar}]
						}			
						UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range}): sBestSoFar: ${sBestSoFar}, sHighestSoFar: ${sHighestSoFar}",LOG_DEBUG]
						break
					case GROUP_FREQUENCYCRYSTAL
						if ${itrAmmo:First(exists)}
						{
							do
							{
								if ${itrFrequencyPairs:First(exists)}
								{
									do
									{
										if ${itrAmmo.Value.Name.Find[${itrFrequencyPairs.Key}]}
										{
											fNewDelta:Set[${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value} - ${range}]}]
											UI:UpdateConsole["fNewDelta: ${fNewDelta}, ${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value} - ${range}]}, fOldDelta: ${fOldDelta}",LOG_DEBUG]
											if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
											{
												sBestSoFar:Set[${itrFrequencyPairs.Key}]
												UI:UpdateConsole["obj_Ship.GetBestAmmo: sBestsoFar: ${sBestSoFar}, fNewDeelta ${fNewDelta}, fOldDelta ${fOldDelta} ",LOG_DEBUG]
												bBestFound:Set[TRUE]
												fOldDelta:Set[${fNewDelta}]
											}
											
											if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
											{
												fHighestSoFar:Set[${fNewDelta}]
												sHighestSoFar:Set[${itrFrequencyPairs.Key}]
											}
											break
										}
									}
									while ${itrFrequencyPairs:Next(exists)}
								}
							}
							while ${itrAmmo:Next(exists)}				
						}
						if ${itrWeapon2:First(exists)}
						{
							iTurret:Set[0]
							do
							{
								iTurret:Inc
								if ${iTurret} != ${turret}
								{
									; Looks like it isn't, which means we can continue in order to skip all the logic.
									UI:UpdateConsole["obj_Ship: Skipping turret ${iTurret} because we want best ammo for turret ${turret}.",LOG_DEBUG]
									continue
								}
								if ${itrFrequencyPairs:First(exists)}
								{
									do
									{
										if ${itrWeapon2.Value.Charge.Name.Find[${itrFrequencyPairs.Key}]}
										{
											UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange[${range}]: including already loaded ammo in our check!",LOG_DEBUG]
											fNewDelta:Set[${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value} - ${range}]}]
											UI:UpdateConsole["fNewDelta: ${fNewDelta}, ${Math.Calc[${fBaseOptimal} * ${itrFrequencyPairs.Value} - ${range}]}, fOldDelta: ${fOldDelta}",LOG_DEBUG]
											if ${fNewDelta} > 0 && (${fNewDelta} < ${fOldDelta} || ${fOldDelta} == 0)
											{
												sBestSoFar:Set[${itrFrequencyPairs.Key}]
												UI:UpdateConsole["obj_Ship.GetBestAmmo: sBestsoFar: ${sBestSoFar}, fNewDeelta ${fNewDelta}, fOldDelta ${fOldDelta} ",LOG_DEBUG]
												bBestFound:Set[TRUE]
												fOldDelta:Set[${fNewDelta}]
											}
											
											if ${fHighestSoFar} == 0 || ${fNewDelta} > ${fHighestSoFar}
											{
												fHighestSoFar:Set[${fNewDelta}]
												sHighestSoFar:Set[${itrFrequencyPairs.Key}]
											}
											break
										}
									}
									while ${itrFrequencyPairs:Next(exists)}
								}
							}
							while ${itrWeapon2:Next(exists)}
						}
						if !${bBestFound}
						{
							sBestSoFar:Set[${sHighestSoFar}]
						}
						break
					UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): sBestSoFar: ${sBestSoFar}, sHighestSoFar: ${sHighestSoFar}",LOG_DEBUG]
				}							
			}
			while ${itrWeapon:Next(exists)}
		}		
		UI:UpdateConsole["obj_Ship.GetBestAmmoTypeByRange(${range},${turret}): returning ${sBestSoFar}",LOG_DEBUG]
		; for shits and giggles, reset iTurret
		iTurret:Set[0]
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
							; TODO - CyberTech - this check needs to be dynamic, not hardcoded at 6 highslots.
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
		this:SetTypeID[${Me.ToEntity.TypeID}]

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
		; just handle missiles for now
		/* fuck you, we're handling turrets */
		if ${Config.Combat.ShouldUseMissiles}
		{
			return ${Config.Combat.MaxMissileRange}
		}
		else
		{
			UI:UpdateConsole["obj_Ship.OptimalWeaponRange(): getting checked"]
			return ${This.GetMinimumTurretRange}
		}
		
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
