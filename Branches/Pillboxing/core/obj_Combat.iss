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
	variable collection:int FactionDB
	;variable uint WpnQuery = ${LavishScript.CreateQuery[]}

	method Initialize()
	{

		ThermalDamage:Insert[27447]
		ThermalDamage:Insert[27449]
		ThermalDamage:Insert[27445]
		ThermalDamage:Insert[208]
		ThermalDamage:Insert[24525]
		ThermalDamage:Insert[31886]
		ThermalDamage:Insert[31882]
		ThermalDamage:Insert[31880]
		ThermalDamage:Insert[31884]
		ThermalDamage:Insert[23561]
		ThermalDamage:Insert[28211]
		ThermalDamage:Insert[2183]
		ThermalDamage:Insert[2185]
		ThermalDamage:Insert[2454]
		ThermalDamage:Insert[24486]
		ThermalDamage:Insert[2456]
		ThermalDamage:Insert[2444]
		ThermalDamage:Insert[2446]
		ThermalDamage:Insert[21918]
		ThermalDamage:Insert[20733]
		ThermalDamage:Insert[20797]
		ThermalDamage:Insert[200]
		ThermalDamage:Insert[238]
		ThermalDamage:Insert[204]
		EMDamage:Insert[21894]
		EMDamage:Insert[20735]
		EMDamage:Insert[20799]
		EMDamage:Insert[201]
		EMDamage:Insert[27435]
		EMDamage:Insert[27437]
		EMDamage:Insert[24490]
		EMDamage:Insert[27433]
		EMDamage:Insert[27890]
		EMDamage:Insert[207]
		EMDamage:Insert[24527]
		EMDamage:Insert[2203]
		EMDamage:Insert[2205]
		EMDamage:Insert[23525]
		EMDamage:Insert[28213]
		EMDamage:Insert[31864]
		EMDamage:Insert[31868]
		EMDamage:Insert[31866]
		EMDamage:Insert[31870]
		EMDamage:Insert[2173]
		EMDamage:Insert[2175]
		EMDamage:Insert[2193]
		EMDamage:Insert[2195]
		EMDamage:Insert[2203]
		EMDamage:Insert[2205]
		EMDamage:Insert[238]
		EMDamage:Insert[202]
		ExplosiveDamage:Insert[238]
		ExplosiveDamage:Insert[27453]
		ExplosiveDamage:Insert[199]
		ExplosiveDamage:Insert[21902]
		ExplosiveDamage:Insert[20731]
		ExplosiveDamage:Insert[20795]
		ExplosiveDamage:Insert[24488]
		ExplosiveDamage:Insert[27455]
		ExplosiveDamage:Insert[27451]
		ExplosiveDamage:Insert[206]
		ExplosiveDamage:Insert[2801]
		ExplosiveDamage:Insert[2476]
		ExplosiveDamage:Insert[2478]
		ExplosiveDamage:Insert[28215]
		ExplosiveDamage:Insert[23563]
		ExplosiveDamage:Insert[31892]
		ExplosiveDamage:Insert[31894]
		ExplosiveDamage:Insert[31890]
		ExplosiveDamage:Insert[31888]
		ExplosiveDamage:Insert[15510]
		ExplosiveDamage:Insert[2486]
		ExplosiveDamage:Insert[2488]
		ExplosiveDamage:Insert[205]
		ExplosiveDamage:Insert[21640]
		KineticDamage:Insert[238]
		KineticDamage:Insert[21918]
		KineticDamage:Insert[20733]
		KineticDamage:Insert[20797]
		KineticDamage:Insert[200]
		KineticDamage:Insert[31872]
		KineticDamage:Insert[1201]
		KineticDamage:Insert[2436]
		KineticDamage:Insert[2464]
		KineticDamage:Insert[2466]
		KineticDamage:Insert[2479]
		KineticDamage:Insert[31874]
		KineticDamage:Insert[31878]
		KineticDamage:Insert[31876]
		KineticDamage:Insert[27441]
		KineticDamage:Insert[27443]
		KineticDamage:Insert[27439]
		KineticDamage:Insert[209]
		KineticDamage:Insert[15508]
		KineticDamage:Insert[21638]
		KineticDamage:Insert[23559]
		KineticDamage:Insert[28209]
		KineticDamage:Insert[24529]
		KineticDamage:Insert[203]
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
		MishDB:Set["Illegal Activity (1 of 3)",1]
		MishDB:Set["Illegal Activity (2 of 3)",3]
		MishDB:Set["Illegal Activity (3 of 3)",3]
		FactionDB:Set["500010",3]
		FactionDB:Set["500003",1]
		FactionDB:Set["500007",1]
		FactionDB:Set["500011",4]
		FactionDB:Set["500006",3]
		FactionDB:Set["500001",3]
		FactionDB:Set["500008",1]
		FactionDB:Set["500002",4]
		FactionDB:Set["500018",3]
		FactionDB:Set["500019",1]
		FactionDB:Set["500020",3]
		FactionDB:Set["500012",1]
		FactionDB:Set["500009",3]
		FactionDB:Set["500015",4]
	}

	method Shutdown()
	{
	}

	member:int DamageTypeForMish()
	{
		;This will only return what the name implies
		variable string mission = ${Missions.MissionCache.Name[${Agents.AgentID}]}
		if ${MishDB.Element[${mission}]} > 0
		{
			return ${MishDB.Element[${mission}]}
		}
		else
		{
			UI:UpdateConsole["Mission ${mission} was not found in mishdb"]
		}
	}
	member:string DamageString(int Number)
	{
		Switch "${Number}"
		{
			case 1
				return "EM"
			case 2
				return "Thermal"
			case 3
				return "Kinetic"
			case 4
				return "Explosive"
		}
	}

	member:int GetTypeIDByDamageType(string LOCATION, int GROUPID, int DAMAGETYPE)
	{
		;This member will return the typeid matching that damage in the location specified in the parameter, with the groupID specified
		;I should probably just make the switch get the list of items from the location specified and keep every else general, but right now I only support loading from stations
		;So whateverrrr
		variable index:item ListOfItems
		variable iterator itty 
		Switch "${LOCATION}"
		{
			case HANGAR
				Me.Station:GetHangarItems[ListOfItems]
				if ${GROUPID} > 0
				{
					ListOfItems:RemoveByQuery[${LavishScript.CreateQuery[GroupID != "${GROUPID}"]}]
					ListOfItems:Collapse
					if ${ListOfItems.Used} > 0
					{
						Switch "${DAMAGETYPE}"
						{
							case 1
								EMDamage:GetIterator[itty]
								break
							case 2
								ThermalDamage:GetIterator[itty]
								break
							case 3
								KineticDamage:GetIterator[itty]
								break
							case 4
								ExplosiveDamage:GetIterator[itty]
								break
							default
								UI:UpdateConsole["What in the fuck did you pass to GetTypeIDByDamageType, ABORT ABORT ABORT"]
						}
						;now itty has an iterator of the damage type we're looking for, and listofitems contains a list of items matching our groupid, let's make some magic

					}
					else
					{
						UI:UpdateConsole["No items found matching that group ID"]
					}
				}
				else
				{
					UI:UpdateConsole["Bad GroupID passed to Combat.GetTypeIDByDamageType, abort abort!"]
				}

		}
	}

	member:int AmmoSelection()
	{
		;UI:UpdateConsole["${Ship.WEAPONGROUPID}"]
		;variable int Group = ${Ship.ModuleList_Weapon[1].ToItem.GroupID}
		;variable int Group = 510
		variable string mission = ${Missions.MissionCache.Name[${Agents.AgentID}]}
		variable int FactionID = ${Missions.MissionCache.FactionID[${Agents.AgentID}]}	
		variable int DmgType
		variable iterator ittyDamage
		variable int ReloadTypeID
		 ; Damage types on x, 1 = em, 2 = therm, 3 = kin, 4 = exp, order is descending down the page, ie em first, exp last for each groupID
		variable index:item ContainerItems
		variable int intCounter = 1
		variable iterator CargoIterator	
		;EVE:Execute[OpenHangarFloor]
		if !${Me.InSpace}
		{
			Me.Station:GetHangarItems[ContainerItems]
		}
		else
		{
			UI:UpdateConsole["You have no business calling 'Combat.AmmoSelection' from in space!"]
		}
		do
		{ 
			ContainerItems:RemoveByQuery[${LavishScript.CreateQuery[GroupID != "${Ship.AmmoGroup.Token[${intCounter},-]}"]}]		
			ContainerItems:Collapse
			if ${ContainerItems.Used} > 0
			{
				UI:UpdateConsole["AmmoSelection: ${ContainerItems.Used} stacks of ammo found in hangar for weapons."]
				break
			}
			else
			{
				Me.Station:GetHangarItems[ContainerItems]
				intCounter:Inc
			}
		}
		while ${intCounter} <= ${Math.Calc[${Ship.AmmoGroup.Count[-]}+1]}
		;If we have no items to iterate through after all our queries, return false (this should cause restockAmmo to be called)
		if ${ContainerItems.Used.Equal[0]}
		{
			UI:UpdateConsole["No ammo matching this weapon was found."]
			return -1
		}
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

		if ${FactionID} > 0
		{
			if ${FactionDB.Element[${FactionID}]} > 0
			{
				UI:UpdateConsole["Found faction ID for mission in database, reloading with ${This.DamageString[${FactionDB.Element[${FactionID}]}]} ammo."]
				DmgType:Set[${FactionDB.Element[${FactionID}]}]
			}
			else
			{
				UI:UpdateConsole["FactionID was found, but we don't have a damage type stored for it."]
			}
		}
		else
		{
			UI:UpdateConsole["No factionID found for mission, defaulting to Mish DB."]
		}
		if ${MishDB.Element[${mission}]} > 0
		{
			if ${DmgType.Equal[0]}
			{	
				UI:UpdateConsole["Found ${Missions.MissionCache.Name[${Agents.AgentID}]} in MishDB, damage type is ${This.DamageString[${MishDB.Element[${mission}]}]}"]
			}
		}
		else
		{
			if ${DmgType.Equal[0]}
			{
				UI:UpdateConsole["Mission was not found in mishDB and we have no factionID, defaulting to Thermal damage."]
				DmgType:Set[2]
			}
		}
		if ${DmgType} > 0
		{
			ContainerItems:GetIterator[CargoIterator]
			Switch "${DmgType}"
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
				UI:UpdateConsole["Restocking ammo."]
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
				;TODO, change this to a sentry drone check of some sort

				Ship:OrbitAtOptimal
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
			if ${Me.ActiveTarget.Radius} > 100 || !${Config.Combat.DontKillFrigs}
			{
				Ship:Activate_TargetPainters
				Ship:Activate_StasisWebs
				Ship:Activate_Weapons
			}
			elseif ${Me.ActiveTarget.Radius} < 100 && ${Config.Combat.DontKillFrigs}
			{
				Targets:NextTarget
			}
			if (!${Ship.Drones.DronesKillingFrigate} && ${Config.Combat.DontKillFrigs}) || \
			!${Config.Combat.DontKillFrigs}
			{
				call Ship.Drones.SendDrones
			}
			
		}
		if !${Ship.IsAmmoAvailable}
		{
			if ${Config.Combat.RestockAmmo}
			{
				UI:UpdateConsole["Setting state to restock."]
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
				${MyShip.ArmorPct} < 50 || \
				(${MyShip.ShieldPct} < 80 && ${Config.Combat.MinimumShieldPct} > 0) || \
				${MyShip.CapacitorPct} < 60 )
			{
					This.CurrentState:Set["FLEE"]
					UI:UpdateConsole["Debug: Staying in Flee State: Armor: ${MyShip.ArmorPct} Shield: ${MyShip.ShieldPct} Cap: ${MyShip.CapacitorPct}", LOG_DEBUG]
			}
			else
			{
					This.Fled:Set[FALSE]
					This.CurrentState:Set["IDLE"]
			}
		}
		elseif ${MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct}  || ${MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct} || ${MyShip.CapacitorPct} < ${Config.Combat.MinimumCapPct}
		{	
			UI:UpdateConsole["Armor is at ${MyShip.ArmorPct.Int}%%: ${MyShip.Armor.Int}/${MyShip.MaxArmor.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Shield is at ${MyShip.ShieldPct.Int}%%: ${MyShip.Shield.Int}/${MyShip.MaxShield.Int}", LOG_CRITICAL]
			UI:UpdateConsole["Cap is at ${MyShip.CapacitorPct.Int}%%: ${MyShip.Capacitor.Int}/${MyShip.MaxCapacitor.Int}", LOG_CRITICAL]
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
		if ${MyShip.ArmorPct} < 100
		{
			/* Turn on armor reps, if you have them
				Armor reps do not rep right away -- they rep at the END of the cycle.
				To counter this we start the rep as soon as any damage occurs.
			*/
			Ship:Activate_Armor_Reps[]
		}
		elseif ${MyShip.ArmorPct} > 98
		{
			Ship:Deactivate_Armor_Reps[]
		}

		if ${MyShip.ShieldPct} < 85 || ${Config.Combat.AlwaysShieldBoost}
		{   /* Turn on the shield booster, if present */
			Ship:Activate_Shield_Booster[]
		}
		elseif ${MyShip.ShieldPct} > 95 && !${Config.Combat.AlwaysShieldBoost}
		{
			Ship:Deactivate_Shield_Booster[]
		}

		if ${MyShip.CapacitorPct} < 20
		{   /* Turn on the cap booster, if present */
			Ship:Activate_Cap_Booster[]
		}
		elseif ${MyShip.CapacitorPct} > 80
		{
			Ship:Deactivate_Cap_Booster[]
		}

		if (!${This.Fled} && ${Config.Combat.LaunchCombatDrones} && \
		!${Ship.InWarp} && ${Me.TargetCount} > 0 || ${Me.ToEntity.IsWarpScrambled}) && \
		${Ship.Drones.DronesInSpace} == 0 
		{
			if ${Me.TargetCount} > 0 && ${Me.TargetedByCount} >= ${Me.TargetCount}
			{
				call Ship.Drones.LaunchAll
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
			if ${Ammospots:IsThereAmmospotBookmark}
			{
				UI:UpdateConsole["RestockAmmo: Fleeing: No ammo bookmark"]
				call This.Flee
				return
			}
			else
			{
				call Ammospots.WarpTo
				while ${Me.InSpace}
				{
					wait 10
					;VERY LAZY WORKAROUND
				}
				UI:UpdateConsole["Restocking ammo"]
				call Ship.OpenCargo
				; If a corp hangar array is on grid - drop loot
					if ${Me.InStation}
					{
						EVE:Execute[OpenHangarFloor]
						wait 10
						call Cargo.TransferCargoToHangar
						;Add stack code here
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
					UI:UpdateConsole["Ammotype found for ${Missions.MissionCache.Name[${Agents.AgentID}]}"]
					}
					else
					{
						 UI:UpdateConsole["Mish "${Missions.MissionCache.Name[${Agents.AgentID}]}" not found in mishDB"]
						 Script:Pause
						 ;return
					}
					;call This.RefillDrones
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
									CargoIterator.Value:MoveTo[MyShip,CargoHold,${QuantityToMove}]
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

	function RefillDrones()
	{
		variable index:item indDrones
		variable iterator ittyDrones
		variable bool IsFound
		variable iterator ittyDamage
		variable index:int Counter
		variable index:item ContainerItems
		variable iterator CargoIterator
		variable index:int64 DronesToMove
		EVE:Execute[OpenDroneBayOfActiveShip]
		wait 20
		;This is going to assume we're in a station for now
		;This is going to hurt...so first we're going to see what kind of drones we have in bay first...then see if they're right for our mission
		;If they're not the correct drone for our mish, we add it to the stack to be moved from bay TO hangar. If they are, we'll check how many of them we have.
		if ${Math.Calc[${MyShip.DronebayCapacity}-${MyShip.UsedDroneBayCapacity}]} <= 0
		{
			UI:UpdateConsole["Either this isn't a drone boat, or ISXEVE is returning wrong....or our drone bay is full :D."]
		}
		MyShip:GetDrones[indDrones]
		indDrones:GetIterator[ittyDrones]
		Me.Station:GetHangarItems[ContainerItems]
		ContainerItems:RemoveByQuery[${LavishScript.CreateQuery[GroupID != "100"]}]
		;Container Items will only have drones left in it now.
		ContainerItems:GetIterator[CargoIterator]
		;Now we have an iterator and index for everything in Hangar and drone bay
		if ${MishDB.Element[${Missions.MissionCache.Name[${Agents.AgentID}]}]} > 0
		{
			;UI:UpdateConsole["Found ${mission} in MishDB, damage type is ${This.DamageString[${MishDB.Element[${mission}]}]}"]
			Switch "${MishDB.Element[${Missions.MissionCache.Name[${Agents.AgentID}]}]}"
			{
				case 1
					EMDamage:GetIterator[ittyDamage]
				case 2DronebayCapacity
					ThermalDamage:GetIterator[ittyDamage]
				case 3
					KineticDamage:GetIterator[ittyDamage]
				case 4
					ExplosiveDamage:GetIterator[ittyDamage]
			}
		}
		else
		{
			UI:UpdateConsole["This mission was not found in mishDB, can't restock drones."]
			return
		}
		;At this point, ittyDamage should now contain an iterator for all the typeids that match the damagetype for the active mission
		if ${ittyDrones:First(exists)}
		{
			;Now we're going to iterate through the drones in our drone bay
			do
			{
				if ${ittyDamage:First(exists)}
				{
					;Inside the iteration for the drones in bay, we're now going to loop through all the typeids in the list of typeids for our mission type
					do
					{
						if ${ittyDamage.Value.Equal[${ittyDrones.Value.TypeID}]}
						{
							IsFound:Set[TRUE]
						}
					}
					while ${ittyDamage:Next(exists)}
				}
				;We reset the IsFound bool here ready for the next iteration, and also check it after the current one
				if ${IsFound}
				{
					IsFound:Set[FALSE]
				}
				else
				{
					UI:UpdateConsole["Found drone in bay that doesn't match our current required damage type."]
					DronesToMove:Insert[${ittyDrones.Value.ID}]
				}
			}
			while ${ittyDrones:Next(exists)}
			;Now if I've written the previous code right, DronesToMove should now contain a list of drones that we need to move to hangar
			UI:UpdateConsole["Moving ${DronesToMove.Used} items from drone bay to hangar."]
			EVE:MoveItemsTo[DronesToMove,MyStationHangar, Hangar]
			wait 50
		}
		else
		{
			UI:UpdateConsole["Combat.RefillDrones: No drones found in drone bay"]
		}
			UI:UpdateConsole["We have ${Math.Calc[${MyShip.DronebayCapacity}-${MyShip.UsedDroneBayCapacity}]} m3 to fill."]
			;So now we have no drones in our bay that aren't right for our mission (this is so when I start taking multiple damage types on a mission it's ready to use with no mods)
			Me.Station:GetHangarItems[ContainerItems]
			if ${CargoIterator:First(exists)}
			{
				do
				{
					if ${Ship.Drones.NumberOfDronesInBay[SENTRY]} < 5 && ${MyShip.DronebayCapacity} >= 150
					{
						UI:UpdateConsole["Reloading sentry drones now."]
						if ${ittyDamage:First(exists)}
						{
							do
							{
								if ${CargoIterator.Value.TypeID.Equal[${ittyDamage.Value}]} && \
									${CargoIterator.Value.Volume.Equal[25]} && \
									${Ship.Drones.IsSentryDrone[${CargoIterator.Value.TypeID}]}
									{
										call Cargo.TransferTypeIDToShip ${CargoIterator.Value.TypeID} ${Math.Calc[5-${Ship.Drones.NumberOfDronesInBay[SENTRY]}]}
									}

							}
							while ${ittyDamage:Next(exists)}
						}
					}
					elseif ${Ship.Drones.NumberOfDronesInBay[HEAVY]} < 5
					{
						;if ${ittyDamage:First(exists)}
						;{
							;do
							;{
								;if ${CargoIterator.Value.TypeID.Equal[${ittyDamage.Value}]} && \
								;	${CargoIterator.Value.Volume.Equal[25]} && \
								;	!${Ship.Drones.IsSentryDrone[${CargoIterator.Value.TypeID}]}
								;	{
									;	call Cargo.TransferTypeIDToShip ${CargoIterator.Value.TypeID} ${Math.Calc[5-${Ship.Drones.NumberOfDronesInBay[HEAVY]}]}
								;	}

							;}
							;while ${ittyDamage:Next(exists)}
						;}
					}
					elseif ${Ship.Drones.NumberOfDronesInBay[MEDIUM]} < 5 && ${MyShip.DronebayCapacity} > 100
					{
						UI:UpdateConsole["Reloading Light Drones."]
						if ${ittyDamage:First(exists)}
						{
							do
							{
								if ${CargoIterator.Value.TypeID.Equal[${ittyDamage.Value}]} && \
									${CargoIterator.Value.Volume.Equal[10]}
									{
										call Cargo.TransferTypeIDToShip ${CargoIterator.Value.TypeID} ${Math.Calc[5-${Ship.Drones.NumberOfDronesInBay[MEDIUM]}]}
									}

							}
							while ${ittyDamage:Next(exists)}
						}
					}
					elseif ${Ship.Drones.NumberOfDronesInBay[LIGHT]} < 5 && ${MyShip.DronebayCapacity} > 0
					{
						if ${ittyDamage:First(exists)}
						{
							do
							{
								if ${CargoIterator.Value.TypeID.Equal[${ittyDamage.Value}]} && \
									${CargoIterator.Value.Volume.Equal[5]}
									{
										UI:UpdateConsole["Transferring ${Math.Calc[(${MyShip.DronebayCapacity}/5)-${Ship.Drones.NumberOfDronesInBay[LIGHT]}]} of ${CargoIterator.Value.Name} to drone bay."]
										call Cargo.TransferTypeIDToShip ${CargoIterator.Value.TypeID} ${Math.Calc[(${MyShip.DronebayCapacity}/5)-${Ship.Drones.NumberOfDronesInBay[LIGHT]}]}
									}

							}
							while ${ittyDamage:Next(exists)}
						}
					}
				}
				while ${CargoIterator:Next(exists)}
			}
	}

	member:bool HaveMissionAmmo()
	{
		variable string mission = ${Missions.MissionCache.Name[${Agents.AgentID}]}
		variable int FactionID = ${Missions.MissionCache.FactionID[${Agents.AgentID}]}	
		;UI:UpdateConsole["HaveMissionAmmo: Mission name is ${mission}"]
		;variable int Group = ${Ship.ModuleList_Weapon[1].ToItem.GroupID}
		if ${Config.Combat.LastWeaponGroup} > 0
		{
			;SOMETHING
			;YA
		}
		else
		{
			UI:UpdateConsole["Can't find our Weapon type, compensate for this somehow. Odds are you started bot in a station."]
			return TRUE
		}
		;variable int Group = 510
		variable iterator ittyDamage
		variable int intCounter = 1
		variable int ReloadTypeID
		variable int DmgType
		 ; Damage types on x, 1 = em, 2 = therm, 3 = kin, 4 = exp, order is descending down the page, ie em first, exp last for each groupID
		variable index:item ContainerItems
		variable iterator CargoIterator	
		EVE:Execute[OpenHangarFloor]
		MyShip:OpenCargo
		MyShip:GetCargo[ContainerItems]
		if ${Config.Combat.LastWeaponGroup.Equal[85]}
		{
			UI:UpdateConsole["We're using hybrid weapons, I'm pretty sure these all do the same damage type."]
			return TRUE
		}
		do
		{ 
			ContainerItems:RemoveByQuery[${LavishScript.CreateQuery[GroupID != "${Ship.AmmoGroup.Token[${intCounter},-]}"]}]		
			ContainerItems:Collapse
			if ${ContainerItems.Used} > 0
			{
				UI:UpdateConsole["HaveMissionAmmo: ${ContainerItems.Used} stacks of ammo found in cargo for weapons."]
				break
			}
			else
			{
				MyShip:GetCargo[ContainerItems]
				intCounter:Inc
			}
		}
		while ${intCounter} <= ${Math.Calc[${Ship.AmmoGroup.Count[-]}+1]}
		;If we have no items to iterate through after all our queries, return false (this should cause restockAmmo to be called)
		if ${ContainerItems.Used.Equal[0]}
		{
			return FALSE
		}
		if ${FactionID} > 0
		{
			if ${FactionDB.Element[${FactionID}]} > 0
			{
				UI:UpdateConsole["Found faction ID for mission in database, reloading with ${This.DamageString[${FactionDB.Element[${FactionID}]}]} ammo."]
				DmgType:Set[${FactionDB.Element[${FactionID}]}]
			}
			else
			{
				UI:UpdateConsole["FactionID was found, but we don't have a damage type stored for it."]
			}
		}
		else
		{
			UI:UpdateConsole["No factionID found for mission, defaulting to Mish DB."]
		}
		if ${MishDB.Element[${mission}]} > 0
		{
			if ${DmgType.Equal[0]}
			{	
				UI:UpdateConsole["Found ${Missions.MissionCache.Name[${Agents.AgentID}]} in MishDB, damage type is ${This.DamageString[${MishDB.Element[${mission}]}]}"]
			}
		}
		else
		{
			if ${DmgType.Equal[0]}
			{
				UI:UpdateConsole["Mission was not found in mishDB and we have no factionID, defaulting to Thermal damage."]
				DmgType:Set[2]
			}
		}
		if ${DmgType} > 0
		{
			ContainerItems:GetIterator[CargoIterator]
			Switch "${DmgType}"
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
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]} && ${CargoIterator.Value.Quantity} > ${Math.Calc[${Ship.ModuleList_Weapon.Used}*${Ship.ModuleList_Weapon[1].MaxCharges}]}
									{
										return TRUE
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
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]} && ${CargoIterator.Value.Quantity} > ${Math.Calc[${Ship.ModuleList_Weapon.Used}*${Ship.ModuleList_Weapon[1].MaxCharges}]}
									{
										return TRUE
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
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]} && ${CargoIterator.Value.Quantity} > ${Math.Calc[${Ship.ModuleList_Weapon.Used}*${Ship.ModuleList_Weapon[1].MaxCharges}]}
									{
										return TRUE
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
									if ${ittyDamage.Value.Equal[${CargoIterator.Value.TypeID}]} && ${CargoIterator.Value.Quantity} > ${Math.Calc[${Ship.ModuleList_Weapon.Used}*${Ship.ModuleList_Weapon[1].MaxCharges}]}
									{
										return TRUE
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