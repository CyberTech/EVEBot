 #ifndef __OBJ_COMBAT__
 #define __OBJ_COMBAT__

/*
		The combat object

		The obj_Combat object is a bot-support module designed to be used
		with EVEBOT.  It provides a common framework for combat decissions
		that the various bot modules can call.

		USAGE EXAMPLES
		--------------

		objectdef obj_Miner
		{
				variable string SVN_REVISION = "$Rev$"
				variable int Version

				variable obj_Combat Combat

				method Initialize()
				{
						;; bot module initialization
						;; ...
						;; ...
						;; call the combat object's init routine
						This.Combat:Initialize
						;; set the combat "mode"
						This.Combat:SetMode["DEFENSIVE"]
				}

				method Pulse()
				{
						if ${EVEBot.Paused}
								return
						if !${Config.Common.BotModeName.Equal[Miner]}
								return
						;; bot module frame action code
						;; ...
						;; ...
						;; call the combat frame action code
						This.Combat:Pulse
				}

				function ProcessState()
				{
						if !${Config.Common.BotModeName.Equal[Miner]}
								return

						; call the combat object state processing
						call This.Combat.ProcessState

						; see if combat object wants to
						; override bot module state.
						if ${This.Combat.Fled}
								return

						; process bot module "states"
						switch ${This.CurrentState}
						{
								;; ...
								;; ...
						}
				}
		}

		COMBAT OBJECT "MODES"
		---------------------

				* DEFENSIVE -- If under attack (by NPCs) AND damage taken exceeds threshold, fight back
				* AGGRESSIVE -- If hostile NPC is targeted, destroy it
				* TANK      -- Maintain defenses but attack nothing

				NOTE: The combat object will activate and maintain your "tank" in all modes.
					variable collection:uint DmgTypeQueries
	variable collection:uint DmgAmountQueries			It will also manage any enabled "flee" state.

		-- GliderPro
*/

objectdef obj_Combat
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable time NextPulse
	variable int PulseIntervalInSeconds = 5

	variable string CombatMode
	variable string CurrentState = "IDLE"
	variable bool   Fled = FALSE
	variable index:int EMDamage
	variable index:int KineticDamage
	variable index:int ThermalDamage
	variable index:int ExplosiveDamage
	variable index:int LightDrone
	variable time DroneTimer
	variable collection:int MishDB

	method Initialize()
	{
		ThermalDamage:Insert[27447]
		ThermalDamage:Insert[27449]
		ThermalDamage:Insert[27445]
		ThermalDamage:Insert[208]
		EMDamage:Insert[27435]
		EMDamage:Insert[27437]
		EMDamage:Insert[27433]
		EMDamage:Insert[27890]
		EMDamage:Insert[207]
		ExplosiveDamage:Insert[27453]
		ExplosiveDamage:Insert[27455]
		ExplosiveDamage:Insert[27451]
		ExplosiveDamage:Insert[206]
		KineticDamage:Insert[27441]
		KineticDamage:Insert[27443]
		KineticDamage:Insert[27439]
		KineticDamage:Insert[209]
		MishDB:Set["Silence The Informant", 2]
		MishDB:Set["Worlds Collide", 3]
		MishDB:Set["The Score", 1]
		MishDB:Set["The Right Hand of Zazzmatazz", 2]
		MishDB:Set["The Wildcat Strike", 1]
		MishDB:Set["Vengeance", 3]
		MishDB:Set["The Guristas Spies", 3]
		MishDB:Set["Massive Attack", 1]
		MishDB:Set["Intercept The Saboteurs", 3]
		MishDB:Set["Recon (1 of 3)", 3]
		MishDB:Set["Recon (2 of 3)", 2]
		MishDB:Set["The Assault", 3]
		MishDB:Set["Duo of Death", 3]	
		MishDB:Set["Infiltrated Outposts", 1]
		MishDB:Set["The Damsel In Distress", 2]
		MishDB:Set["Unauthorized Military Presence", 1]
		MishDB:Set["Cargo Delivery", 3]
		MishDB:Set["Gone Berserk", 3]
		MishDB:Set["Pirate Invasion", 1]
		MishDB:Set["Angel Extravaganza", 4]
		MishDB:Set["Guristas Extravaganza", 3]
		MishDB:Set["Enemies Abound (1 of 5)", 2]
		MishDB:Set["Enemies Abound (3 of 5)", 2]
		MishDB:Set["Enemies Abound (4 of 5)", 2]
		MishDB:Set["Enemies Abound (5 of 5)", 3]
		MishDB:Set["Smuggler Interception", 1]
		MishDB:Set["Stop The Thief", 2]
		MishDB:Set["Attack of the Drones", 1]
		MishDB:Set["Rogue Drone Harassment", 1]
		MishDB:Set["The Wildcat Strike", 1]
		MishDB:Set["Dread Pirate Scarlet", 3]
		MishDB:Set[" The Assault ", 3]
		MishDB:Set[" The Assault", 3]
	}

	method Shutdown()
	{
	}
	
	member:int AmmoSelection()
	{
		variable string mission = ${Missions.MissionCache.Name[${Agents.AgentID}]}
		UI:UpdateConsole["${Ship.WEAPONGROUPID}"]
		;variable int Group = ${Ship.ModuleList_Weapon[1].ToItem.GroupID}
		;variable int Group = 510
		variable int AmmoGroup
		variable iterator ittyDamage
		variable string DmgType
		variable int ReloadTypeID
		 ; Damage types on x, 1 = em, 2 = therm, 3 = kin, 4 = exp, order is descending down the page, ie em first, exp last for each groupID
		 if ${Group.Equal[0]}
		{
			if !${Me.InSpace}
			{
				UI:UpdateConsole["Unable to obtain module type, trying to undock and shit in order to compensate."]
				EVE:Execute[CmdExitStation]
				;while !${Me.InSpace}
				;{
				;	wait 20
				;}
				wait 150
				Ship:UpdateModuleList
				wait 5
				;Group:Set[${Ship.ModuleList_Weapon[1].ToItem.GroupID}]
				Entity[Type =- "Station"]:Dock
				while ${Me.InSpace}
				{
					wait 10
				}
			}
		}
		Switch "${Ship.WEAPONGROUPID}"
		{
			case 509
			 	AmmoGroup:Set[384]
			case 508
			 	AmmoGroup:Set[89]
			case 510
				AmmoGroup:Set[385]
			case 74
				AmmoGroup:Set[85]
		}
		variable index:item ContainerItems
		variable iterator CargoIterator	
		;EVE:Execute[OpenHangarFloor]
		MyShip:OpenCargo
		if !${Me.InSpace}
		{
			Me.Station:GetHangarItems[ContainerItems]
		}
		else
		{
			MyShip:GetCargo[ContainerItems]
		}
		UI:UpdateConsole["${AmmoGroup}"]
		ContainerItems:RemoveByQuery[${LavishScript.CreateQuery[GroupID != "${AmmoGroup}"]}]
		ContainerItems:Collapse
		UI:UpdateConsole["Found ${ContainerItems.Used} ammo stacks suitable for this weapon"]
		;This needs to be more advanced that it is now, but for now we won't select ammo type based on fuck all except groupID
		if ${AmmoGroup.Equal[85]}
		{
			if ${ContainerItems.Used} > 0
			{
				return ${ContainerItems[1].TypeID}
			}
			else
			{
				UI:UpdateConsole["No items found to reload with, returning -1"]
				return -1
			}
		}
		if ${MishDB.Element[${mission}]} > 0
		{
			UI:UpdateConsole["Found ${mission} in MishDB, damage type is ${MishDB.Element[${mission}]}"]
			ContainerItems:GetIterator[CargoIterator]
			Switch "${MishDB.Element[${mission}]}"
			{
				case 1
					if ${CargoIterator:First(exists)}
					{
						do
						{
							EMDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return ${CargoIterator.Value.TypeID}
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
				case 2
					if ${CargoIterator:First(exists)}
					{
						do
						{
							ThermalDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return ${CargoIterator.Value.TypeID}
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
				case 3
					if ${CargoIterator:First(exists)}
					{
						do
						{
							KineticDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return ${CargoIterator.Value.TypeID}
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
				case 4
					if ${CargoIterator:First(exists)}
					{
						do
						{
							ExplosiveDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return ${CargoIterator.Value.TypeID}
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
			}
			return -1
		}
		
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			This.ManageTank
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:SetState

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method SetState()
	{
		if ${Me.InStation} == TRUE
		{
			This.CurrentState:Set["INSTATION"]
			return
		}

		if ${Ship.IsPod}
		{
			UI:UpdateConsole["Warning: We're in a pod, running"]
			This.CurrentState:Set["FLEE"]
			return
		}

		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["FLEE"]
			return
		}

		if ${Me.TargetCount} > 0
		{
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			This.CurrentState:Set["IDLE"]
		}
	}

	method SetMode(string newMode)
	{
		This.CombatMode:Set[${newMode}]
	}

	member:string Mode()
	{
		return ${This.CombatMode}
	}

	function ProcessState()
	{
		if ${This.CurrentState.NotEqual["INSTATION"]}
		{
			if ${Me.ToEntity.IsWarpScrambled}
			{
				; TODO - we need to quit if a red warps in while we're scrambled -- cybertech
				UI:UpdateConsole["Warp Scrambled: Ignoring System Status"]
			}
			elseif !${Social.IsSafe} || ${Social.PossibleHostiles}
			{
				UI:UpdateConsole["Debug: Fleeing: Local isn't safe"]
				call This.Flee
				return
			}
			call This.ManageTank
		}

		switch ${This.CurrentState}
		{
			case INSTATION
				if ${Social.IsSafe}
				{
					call Station.Undock
				}
				break
			case IDLE
				break
			case FLEE
				call This.Flee
				break
			case RESTOCK
				call This.RestockAmmo
				break
			case FIGHT
				call This.Fight
				break
		}
	}


	function Fight()
	{
		Ship:Deactivate_Cloak
		while ${Ship.IsCloaked}
		{
			waitframe
		}
		;Ship:Offline_Cloak
		;Ship:Online_Salvager

		; Reload the weapons -if- ammo is below 30% and they arent firing
		;Ship:Reload_Weapons[FALSE]
		Ship:Activate_AfterBurner
		Ship:Activate_SensorBoost
		if ${Me.ToEntity.Mode} != 1 || ((${Entity[TypeID = "17831"].Distance} < 10000 && ${Entity[TypeID = "17831"](exists)}) || (${Entity[Name =- "Beacon"].Distance} < 10000 && ${Entity[Name =- "Beacon"](exists)}))
		{

			if ${Config.Combat.OrbitAtOptimal}
			{
				if !${Ship.Drones.IsDroneBoat}
				{
					;don't orbit if we're in a drone boat

					Ship:OrbitAtOptimal
				}
			}
			else
			{
				Me.ActiveTarget:Orbit[${Config.Combat.OrbitDistance}]
			}
		}
		; Activate the weapons, the modules class checks if there's a target (no it doesn't - ct)
		if ${Ship.TotalActivatedWeapons} > 0 && ${Ship.ChangedTarget}
		{
			Ship:Deactivate_TargetPainters
			Ship:Deactivate_StasisWebs
			Ship:Deactivate_Weapons
		}
		else
		{
			;UI:UpdateConsole["Feuer frei!"]
			Ship:Activate_TargetPainters
			Ship:Activate_StasisWebs
			Ship:Activate_Weapons
			if ${Me.ActiveTarget(exists)} && ${Me.ActiveTarget.ShieldPct} > 80
			{
				if ${Me.ActiveTarget.Radius} < 100 && ${Ship.Drones.DronesOut} > 10
				{
					UI:UpdateConsole["Active target is a frigate for sure, switching to smaller drones"]
					call Ship.Drones.ReturnAllToDroneBay
					Ship.Drones:LaunchLightDrones
					;might have to fix
				}
			}
			Ship.Drones:SendDrones
		}
		if !${Ship.IsAmmoAvailable}
		{
			if ${Config.Combat.RestockAmmo}
			{
				UI:UpdateConsole["Restocking Ammo: Low ammo"]
				This.CurrentState:Set["RESTOCK"]
				return
			}
			elseif ${Config.Combat.RunOnLowAmmo}
			{
				UI:UpdateConsole["Fleeing: Low due to ammo"]
				; TODO - what to do about being warp scrambled in this case?
				call This.Flee
				return
			}
		}
	}

	function Flee()
	{
		call ChatIRC.Say "Fleeing for some reason, TODO: add checking and reporting as to reason."
		This.CurrentState:Set["FLEE"]
		This.Fled:Set[TRUE]
		Ship:Deactivate_AfterBurner
		if ${Config.Combat.RunToStation}
		{
			call This.FleeToStation
		}
	else
		{
			call This.FleeToSafespot
		}
	}

	function FleeToStation()
	{
		if !${Station.Docked}
		{
			call Station.Dock
		}
	}

	function FleeToSafespot()
	{
		if ${Safespots.IsAtSafespot}
		{
			if !${Ship.IsCloaked}
			{
				Ship:Activate_Cloak[]
			}
		}
		else
		{
			; Are we at the safespot and not warping?
			if ${Me.ToEntity.Mode} != 3
			{
				call Safespots.WarpTo
				wait 30
			}
		}
	}

	method CheckTank()
	{
		if ${This.Fled}
		{
			/* don't leave the "fled" state until we regen */
			if (${Ship.IsPod} || \
				${Me.Ship.ArmorPct} < 50 || \
				(${Me.Ship.ShieldPct} < 80 && ${Config.Combat.MinimumShieldPct} > 0) || \
				${Me.Ship.CapacitorPct} < 60 )
			{
					This.CurrentState:Set["FLEE"]
					UI:UpdateConsole["Debug: Staying in Flee State: Armor: ${Me.Ship.ArmorPct} Shield: ${Me.Ship.ShieldPct} Cap: ${Me.Ship.CapacitorPct}", LOG_DEBUG]
			}
			else
			{
					This.Fled:Set[FALSE]
					This.CurrentState:Set["IDLE"]
			}
		}
		elseif ${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct}  || ${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct} || ${Me.Ship.CapacitorPct} < ${Config.Combat.MinimumCapPct}
		{	
			UI:UpdateConsole["Armor is at ${Me.Ship.ArmorPct.Int}%%: ${Me.Ship.Armor.Int}/${Me.Ship.MaxArmor.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${Me.Ship.ShieldPct.Int}%%: ${Me.Ship.Shield.Int}/${Me.Ship.MaxShield.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Cap is at ${Me.Ship.CapacitorPct.Int}%%: ${Me.Ship.Capacitor.Int}/${Me.Ship.MaxCapacitor.Int}", LOG_CRITICAL]
			if ${Me.ToEntity.IsWarpScrambled}
			{
				UI:UpdateConsole["Warp Scrambled: Fighting", LOG_CRITICAL]
			}
			else
			{
				UI:UpdateConsole["Fleeing due to defensive status", LOG_CRITICAL]
				This.CurrentState:Set["FLEE"]
			}
		}
	}

	function ManageTank()
	{
		if ${Me.Ship.ArmorPct} < 100
		{
			/* Turn on armor reps, if you have them
				Armor reps do not rep right away -- they rep at the END of the cycle.
				To counter this we start the rep as soon as any damage occurs.
			*/
			Ship:Activate_Armor_Reps[]
		}
		elseif ${Me.Ship.ArmorPct} > 98
		{
			Ship:Deactivate_Armor_Reps[]
		}

		if ${Me.Ship.ShieldPct} < 85 || ${Config.Combat.AlwaysShieldBoost}
		{   /* Turn on the shield booster, if present */
			Ship:Activate_Shield_Booster[]
		}
		elseif ${Me.Ship.ShieldPct} > 95 && !${Config.Combat.AlwaysShieldBoost}
		{
			Ship:Deactivate_Shield_Booster[]
		}

		if ${Me.Ship.CapacitorPct} < 20
		{   /* Turn on the cap booster, if present */
			Ship:Activate_Cap_Booster[]
		}
		elseif ${Me.Ship.CapacitorPct} > 80
		{
			Ship:Deactivate_Cap_Booster[]
		}

		if !${This.Fled} && ${Config.Combat.LaunchCombatDrones} && ${Ship.Drones.DronesInSpace} == 0 && !${Ship.InWarp} && ${Me.TargetCount} > 0 
		{
			if ${Me.TargetCount} > 0 && ${Me.TargetedByCount} >= ${Me.TargetCount}
			{
				Ship.Drones:LaunchAll[]
			}
			else
			{
				UI:UpdateConsole["Waiting on aggro before launching drones"]
			}
		}

		; Activate shield (or armor) hardeners
		; If you don't have hardeners this code does nothing.
		if ${Me.TargetedByCount} > 0
		{
			Ship:Activate_Hardeners[]
		}

		This:CheckTank
	}

/* This does the following:
	1) Checks for a CHA on grid. If one exists, it drops off all inventory
	2) Checks for a GSC, and fills cargo with ammo
*/
	function RestockAmmo()
	{
		if !${Ship.IsAmmoAvailable} || !${This.HaveMissionAmmo}
		{
			UI:UpdateConsole["Restocking ammunition."]
			call ChatIRC.Say "Low ammunition, restocking ammo."
			variable int QuantityToMove
			variable index:item ContainerItems
			variable iterator CargoIterator	
			variable index:item indDrones
			variable int typetorefill = -1
			variable float64 ToFill = ${Math.Calc[${MyShip.DronebayCapacity} - ${MyShip.UsedDronebayCapacity}]}
			UI:UpdateConsole["We have ${ToFill} m3 of space in dronebay to fill. ${MyShip.DronebayCapacity} - ${MyShip.UsedDronebayCapacity}"]
			if ${Ammospots:IsThereAmmospotBookmark}
			{
				UI:UpdateConsole["RestockAmmo: Fleeing: No ammo bookmark"]
				call This.Flee
				return
			}
			else
			{
				MyShip:GetDrones[indDrones]
				call Ammospots.WarpTo
				while ${Me.InSpace}
				{
					wait 10
					;VERY LAZY WORKAROUND
				}
				EVE:Execute[OpenDroneBayOfActiveShip]
				wait 20
				ToFill:Set[${Math.Calc[${MyShip.DronebayCapacity} - ${MyShip.UsedDronebayCapacity}]}]
				UI:UpdateConsole["Restocking ammo"]
				call Ship.OpenCargo
				; If a corp hangar array is on grid - drop loot
					if ${Me.InStation}
					{
						EVE:Execute[OpenHangarFloor]
						wait 10
						call Cargo.TransferCargoToHangar
						wait 15
						Me.Station:StackAllHangarItems
						wait 20
						ContainerItems:Clear
						Me.Station:GetHangarItems[ContainerItems]
						UI:UpdateConsole["Refilling from station!"] 
					}
					else
					{
						if ${Entity["TypeID = 17621"].ID} != NULL
						{
							UI:UpdateConsole["Restocking from ${Entity["TypeID = 17621"]} (${Entity["TypeID = 17621"].ID})"]
							call Ship.Approach ${Entity["TypeID = 17621"].ID} 2000
							call Ship.OpenCargo
							Entity["TypeID = 17621"]:OpenCargo

							; Drop off all loot/leftover ammo
							; TODO - don't dump the ammo we're using for our own weapons. Do dump other ammo that we might have looted.
							if !${Me.InStation}
							{
							call Cargo.TransferCargoToCorpHangarArray
							UI:UpdateConsole["FAILURE"]
							Entity["TypeID = 17621"]:GetCargo[ContainerItems]
							}

						}

						; If there is no CHA, but there is a GSC, Take Ammo, do not drop off items
						else
						{
							UI:UpdateConsole["Restocking from ${Entity["GroupID =340"]} (${Entity["GroupID = 340"].ID})"]
							call Ship.Approach ${Entity["GroupID = 340"].ID} 2000

							Entity["GroupID = 340"]:OpenCargo
							wait 30
							Entity["GroupID = 340"]:GetCargo[ContainerItems]
						}
					}
					ContainerItems:GetIterator[CargoIterator]
					UI:UpdateConsole["Found ${ContainerItems.Used} items to loop through!"]
					if ${This.AmmoSelection} > 0
					{
					UI:UpdateConsole["Ammo found for ${Missions.MissionCache.Name[${Agents.AgentID}]} ${This.AmmoSelection[${Missions.MissionCache.Name[${Agents.AgentID}]},${Ship.ModuleList_Weapon[1].ToItem.GroupID}]}"]
					}
					else
					{
						 UI:UpdateConsole["Mish "${Missions.MissionCache.Name[${Agents.AgentID}]}" not found in mishDB"]
						 return
					}
					if  ${ToFill} > 0
					{
							UI:UpdateConsole["Drones need refilling, doing that now"]
						if ${Math.Calc[${ToFill}/25]} >= 5
						{
							;ADD HEAVY DRONE SUPPORT
						}
						if ${Math.Calc[${ToFill}/10]} >= 5
						{
							;ADD MED DRONE SUPPORT
						}
						if  ${Math.Calc[${ToFill}/5]} > 1
						{
							typetorefill:Set[2466]
							UI:UpdateConsole["Reloading drones with type ${typetorefill}"]
						}
						else
						{
							UI:UpdateConsole["${Math.Calc[${ToFill}/5]} drones to fill"]
						}
					}
					if ${typetorefill} > 0
					{
						if ${CargoIterator:First(exists)}
						{	
								
							do
							{
								if ${CargoIterator.Value.TypeID} == ${typetorefill}
								{
									QuantityToMove:Set[${Math.Calc[${ToFill}/${CargoIterator.Value.Volume}]}]
									UI:UpdateConsole["Transferring ${QuantityToMove} drones to bay"]
									;CargoIterator.Value:MoveTo[DroneBay,${QuantityToMove}]
									;Drone reloading is fucked m8
									wait 30
									break
								}	
							}
							while ${CargoIterator:Next(exists)}
						}
					}
					if ${CargoIterator:First(exists)}
					{	

						do
						{
							if ${CargoIterator.Value.TypeID} == ${This.AmmoSelection}
							{
								UI:UpdateConsole["Trying to move ammo now!"]
								if (${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}) > ${Ship.CargoFreeSpace}
								{
									QuantityToMove:Set[${Math.Calc[(${Ship.CargoFreeSpace} - ${Missions.MissionCache.Volume[${Agents.AgentID}]}) / ${CargoIterator.Value.Volume}]}]
								}
								else
								{
									QuantityToMove:Set[${CargoIterator.Value.Quantity}]
								}

								UI:UpdateConsole["TransferListToShip: Loading Cargo: ${QuantityToMove} units (${Math.Calc[${QuantityToMove} * ${CargoIterator.Value.Volume}]}m3) of ${CargoIterator.Value.Name}"]
								UI:UpdateConsole["TransferListToShip: Loading Cargo: DEBUG: TypeID = ${CargoIterator.Value.TypeID}, GroupID = ${CargoIterator.Value.GroupID}"]
								if ${QuantityToMove} > 0
								{
									CargoIterator.Value:MoveTo[${MyShip.ID},CargoHold,${QuantityToMove}]
									wait 30
									EVEWindow[ByName,${MyShip.ID}]:StackAll
									wait 10
								}

								if ${Ship.CargoFreeSpace} <= ${Math.Calc[${Missions.MissionCache.Volume[${Agents.AgentID}]} + 5]}
								{
									UI:UpdateConsole["DEBUG: RestockAmmo Done: Ship Cargo: ${Ship.CargoFreeSpace} < ${Missions.MissionCache.Volume[${Agents.AgentID}]}", LOG_DEBUG]
									break
								}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
					else
					{
						UI:UpdateConsole["DEBUG: obj_Cargo:TransferListToShip: Nothing found to move"]
						UI:UpdateConsole["Debug: Fleeing: No ammo left in can"]
						call This.Flee
						return
					}	
			}
		}
	}
	member:bool HaveMissionAmmo()
	{
		variable string mission = ${Missions.MissionCache.Name[${Agents.AgentID}]}
		;variable int Group = ${Ship.ModuleList_Weapon[1].ToItem.GroupID}
		if ${Ship.WEAPONGROUPID} > 0
		{
			;SOMETHING
			;YA
		}
		else
		{
			return TRUE
		}
		;variable int Group = 510
		variable int AmmoGroup
		variable iterator ittyDamage
		variable string DmgType
		variable int ReloadTypeID
		 ; Damage types on x, 1 = em, 2 = therm, 3 = kin, 4 = exp, order is descending down the page, ie em first, exp last for each groupID
		 Switch "${Ship.WEAPONGROUPID}"
		 {
			case 509
			 	AmmoGroup:Set[384]
			case 508
			 	AmmoGroup:Set[89]
			case 510
				AmmoGroup:Set[385]
		}
		variable index:item ContainerItems
		variable iterator CargoIterator	
		EVE:Execute[OpenHangarFloor]
		MyShip:OpenCargo
		MyShip:GetCargo[ContainerItems]
		ContainerItems:RemoveByQuery[${LavishScript.CreateQuery[GroupID != "${AmmoGroup}"]}]		
		ContainerItems:Collapse
		UI:UpdateConsole["HaveMissionAmmo: ${ContainerItems.Used} stacks of ammo found in cargo for weapons."]
		if ${MishDB.Element[${mission}]} > 0
		{
			UI:UpdateConsole["HaveMissionAmmo: Found ${mission} in MishDB, damage type is ${MishDB.Element[${mission}]}"]
			ContainerItems:GetIterator[CargoIterator]
			Switch "${MishDB.Element[${mission}]}"
			{
				case 1
					if ${CargoIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["Ammo found is ${CargoIterator.Value.Name}."]
							EMDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return TRUE
										UI:UpdateConsole["Mission ammo found in cargo: Type 1"]
									}									  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
					break
				case 2
					if ${CargoIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["Ammo found is ${CargoIterator.Value.Name}."]
							ThermalDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return TRUE
										UI:UpdateConsole["Mission ammo found in cargo: Type 2"]
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
					break
				case 3
					if ${CargoIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["Ammo found is ${CargoIterator.Value.Name}."]
							KineticDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return TRUE
										UI:UpdateConsole["Mission ammo found in cargo: Type 3"]
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
					break
				case 4
					if ${CargoIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["Ammo found is ${CargoIterator.Value.Name}."]
							ExplosiveDamage:GetIterator[ittyDamage]
							if ${ittyDamage:First(exists)}
							{
								do
								{
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]}
									{
										return TRUE
										UI:UpdateConsole["Mission ammo found in cargo: Type 4"]
									}  
								}
								while ${ittyDamage:Next(exists)}
							}
						}
						while ${CargoIterator:Next(exists)}
					}
					break
				}
			}
			return FALSE
		
	}
}

#endif /* __OBJ_COMBAT__ */