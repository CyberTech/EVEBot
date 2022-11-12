/*

	The obj_AnomRatter object is a bot module designed to be used with
	EVEBOT. This is a heavily modified version of obj_Ratter

*/

objectdef obj_AnomRatter inherits obj_BaseClass
{
	variable string CurrentState
	variable obj_Combat Combat
	variable bool MTUDeployed = FALSE
	variable int OrbitDistance = 1000
	variable bool WeAreRunningSite = FALSE

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This.PulseTimer:SetIntervals[2.0,4.0]
		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

;		This.Rat_CacheID:Set[${EntityCache.AddFilter[${This.ObjectName}, CategoryID = CATEGORYID_ENTITY && IsNPC = 1 && IsMoribund = 0, 2.0]}]
;		EntityCache.EntityFilters.Get[${This.Rat_CacheID}].Entities:GetIterator[Rat_CacheIterator]

		This.CurrentState:Set["LOOT"]
		Targets:ResetTargets
		;; call the combat object's init routine
		This.Combat:Initialize
		;; set the combat "mode"
		This.Combat:SetMode["AGGRESSIVE"]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}


	method Pulse()
	{
		if ${EVEBot.Disabled} || ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.CurrentBehavior.Equal[AnomRatter]}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			This:SetState

			This.PulseTimer:Update
		}

		;; call the combat frame action code
		This.Combat:Pulse
	}

	method Shutdown()
	{
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom
	}

	/* NOTE: The order of these if statements is important!! */

	;; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> LOOT -> DROP -> *
	method SetState()
	{
		if ${Config.Common.CurrentBehavior.NotEqual[AnomRatter]}
		{
			return
		}
		/* Combat module handles all fleeing states now */
		switch ${This.CurrentState}
		{
			case IDLE
				This.CurrentState:Set["MOVE"]
				break
			default
				break
		}
	}

	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{
		if ${Config.Common.CurrentBehavior.NotEqual[AnomRatter]}
		{
			return
		}

		; call the combat object state processing
		call This.Combat.ProcessState

		;Logger:Log["Debug: AnomRatter: This.Combat.Fled = ${This.Combat.Fled} This.CurrentState = ${This.CurrentState} Social.IsSafe = ${Social.IsSafe}"]

		; see if combat object wants to
		; override bot module state.
		if ${This.Combat.Fled}
			return

		switch ${This.CurrentState}
		{
			case MOVE
				call This.Move
				break
			case FIGHT
				call This.Fight
				break
			case LOOT
				call This.Loot
				break
			case DROP
				call This.Drop
				break
		}
	}

	function Move()
	{
		if ${Social.IsSafe}
		{
			Ship:Deactivate_Weapons
			Ship:Deactivate_Tracking_Computer
			Ship:Deactivate_ECCM
			Ship:WarpPrepare

			Logger:Log["Debug: Time to find an anom and warp to it"]
			variable index:systemanomaly MyAnomalies
    		variable iterator MyAnomalies_Iterator

    		MyShip.Scanners.System:GetAnomalies[MyAnomalies]
    		MyAnomalies:GetIterator[MyAnomalies_Iterator]
			Logger:Log["Debug: Anoms found, looking for one we can warp to"]
			if (${MyAnomalies_Iterator:First(exists)} && !${WeAreRunningSite} && !${Bookmarks.StoredLocationExists})
			
				do
        		{    
					;this is a guristas haven
					Logger:Log["Debug: Checking each anom till we find one we want to run"]
            		if (${MyAnomalies_Iterator.Value.DungeonID} == 110980 && !${AnomSites.Contains[${MyAnomalies_Iterator.Value.Name}]} && !${WeAreRunningSite})
            		{
						Logger:Log["Debug: Anom Found and it isn't the one we are currently at so lets warp to it"]
						relay all AnomSites:Add[${MyAnomalies_Iterator.Value.Name}]
						wait 20
            			MyAnomalies_Iterator.Value:WarpTo[30000, FALSE]
                        WeAreRunningSite:Set[TRUE]
           		 		break
            		}    
        		}
       			 while ${MyAnomalies_Iterator:Next(exists)}
			}
            if (${Bookmarks.CheckForStoredLocation} && ${WeAreRunningSite})
            {
                Bookmarks.StoredLocation:WarpTo[0, FALSE]
                wait 30
                Bookmarks.RemoveStoredLocation
            }

		; Wait for the rats to warp into the Anom. Reports are between 10 and 20 seconds.
		variable int Count
		for (Count:Set[0] ; ${Count}<=17 ; Count:Inc)
		{
			if ((${Config.Combat.AnomalyAssistMode} && (${Targets.NPC} || !${Social.IsSafe})) || \
				(!${Config.Combat.AnomalyAssistMode} && (${Targets.PC} || ${Targets.NPC} || !${Social.IsSafe})))
			{
				break
			}
			wait 10
			if !${Social.IsSafe}
			{
				return
			}
		}

		if (${Count} > 1)
		{
			; If we had to wait for rats, Wait another second to try to let them get into range/out of warp
			wait 10
		}
		call This.PlayerCheck

		Count:Set[0]
		if ${Config.Combat.AnomalyAssistMode}
		{
			while (${Count:Inc} < 10) && ${Social.IsSafe} && ${Targets.NPC}
			{
				wait 10
				if !${Social.IsSafe}
				{
					return
				}
			}
		}
		else
		{
			while (${Count:Inc} < 10) && ${Social.IsSafe} && !${Targets.PC} && ${Targets.NPC}
			{
				wait 10
				if !${Social.IsSafe}
				{
					return
				}
			}
		}
	}

	function PlayerCheck()
	{
		if ((${Config.Combat.AnomalyAssistMode} && ${Targets.NPC}) || \
			(!${Config.Combat.AnomalyAssistMode} && (!${Targets.PC} && ${Targets.NPC})))
		{
			Logger:Log["PlayerCheck - Fight"]
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			Logger:Log["PlayerCheck - Move"]
			This.CurrentState:Set["MOVE"]
		}
	}

	function Fight()
	{	/* combat logic */
		;; just handle targetting, obj_Combat does the rest
		Ship:Activate_Armor_Reps
		Ship:Activate_SensorBoost
		Ship:Activate_Tracking_Computer
		Ship:Activate_ECCM
		if (!${Entity[Name == "Mobile Tractor Unit"]} && (${Me.ToEntity.Mode} != 3))
		{
			Logger:Log["Debug: Close ship computer pop up"]
			EVEWindow[ByCaption, Information].Button[ok_dialog_button]:Press
			wait 10
			Logger:Log["Debug: Lets check if the inventory window is open"]
			if !${EVEWindow[Inventory](exists)}
			{
				echo "Opening Inventory..."
		        EVE:Execute[OpenInventory]
		        wait 10
			}
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
			wait 50
			MyShip.Cargo[Mobile Tractor Unit]:LaunchForSelf
			wait 30
			Logger:Log["Debug: Now orbit the MTU"]
			Entity[Name == "Mobile Tractor Unit"]:Orbit[${OrbitDistance}]
            Ship:Activate_AfterBurner
			Bookmarks:CreateBookMark[FALSE, "Ratting Site"]
			MTUDeployed:Set[TRUE]
		}


		if ${Targets.TargetNPCs} && ${Social.IsSafe}
		{
			if ${Targets.SpecialTargetPresent}
			{
				Logger:Log["Special spawn Detected - ${Targets.m_SpecialTargetName}!", LOG_CRITICAL]
				call Sound.PlayDetectSound
				; Wait 5 seconds
				wait 50
			}
		}
		else
		{
			if ${Config.Combat.LootMyKills}
			{
                Entity[Name == "Mobile Tractor Unit"]:ScoopToCargoHold
				Ship:WarpPrepare
                Ship.Drones:ReturnAllToDroneBay["Combat", "Moving"]
                WeAreRunningSite:Set[FALSE]
				wait 50
                if (${Drones.DronesInSpace[FALSE]} == 0)
                {
				This.CurrentState:Set["LOOT"]
                }
                return
			}
			else
			{
				Entity[Name == "Mobile Tractor Unit"]:ScoopToCargoHold
				Ship:WarpPrepare
                Ship.Drones:ReturnAllToDroneBay["Combat", "Moving"]
                WeAreRunningSite:Set[FALSE]
				wait 50
                if (${Drones.DronesInSpace[FALSE]} == 0)
                {
				This.CurrentState:Set["IDLE"]
                }
                return
			}
		}
	}

	function Loot()
	{
		variable index:entity Wrecks
		variable iterator     Wreck
		variable index:item   Items
		variable iterator     Item
		variable index:int64  ItemsToMove
		variable float        TotalVolume = 0
		variable float        ItemVolume = 0
		variable int QuantityToMove

		EVE:QueryEntities[Wrecks, "GroupID = GROUP_WRECK && Distance <= WARP_RANGE"]
		Wrecks:GetIterator[Wreck]
		if ${Wreck:First(exists)}
		{
			do
			{
				if ${Wreck.Value(exists)} && \
					!${Wreck.Value.IsWreckEmpty} && \
					${Wreck.Value.HaveLootRights} && \
					${Targets.IsSpecialTargetToLoot[${Wreck.Value.Name}]}
				{
					call Ship.Approach ${Wreck.Value.ID} LOOT_RANGE
					if ((${Config.Combat.AnomalyAssistMode} && ${Targets.NPC}) || \
						(!${Config.Combat.AnomalyAssistMode} && (!${Targets.PC} && ${Targets.NPC})))
					{
						This.CurrentState:Set["FIGHT"]
						break
					}
					call Inventory.ShipCargo.Activate
					Wreck.Value:Open
					wait 10
					Wreck.Value:GetCargo[Items]
					Logger:Log["obj_AnomRatter: DEBUG:  Wreck contains ${Items.Used} items.", LOG_DEBUG]

					Items:GetIterator[Item]
					if ${Item:First(exists)}
					{
						do
						{
							Logger:Log["obj_AnomRatter: Found ${Item.Value.Quantity} x ${Item.Value.Name} - ${Math.Calc[${Item.Value.Quantity} * ${Item.Value.Volume}].Precision[2]}m3"]
							if (${Item.Value.Quantity} * ${Item.Value.Volume}) > ${Ship.CargoFreeSpace}
							{
								/* Move only what will fit, minus 1 to account for CCP rounding errors. */
									QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${Item.Value.Volume} - 1]}]
								if ${QuantityToMove} <= 0
								{
								Logger:Log["ERROR: obj_AnomRatter: QuantityToMove = ${QuantityToMove}!"]
								This.CurrentState:Set["DROP"]
								break
								}
							}
							else
							{
								QuantityToMove:Set[${Item.Value.Quantity}]
							}

							Logger:Log["obj_AnomRatter: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Item.Value.Volume}].Precision[2]}m3"]
							if ${QuantityToMove} > 0
							{
								Item.Value:MoveTo[${MyShip.ID},CargoHold,${QuantityToMove}]
								wait 30
							}

							if ${Ship.CargoFull}
							{
								Logger:Log["DEBUG: obj_AnomRatter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
								This.CurrentState:Set["DROP"]
								break
							}
						}
						while ${Item:Next(exists)}
					}
				}
				if ${Ship.CargoFull}
				{
					Logger:Log["DEBUG: obj_AnomRatter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
					This.CurrentState:Set["DROP"]
					break
				}
			}
			while ${Wreck:Next(exists)}
		}

		if ${This.CurrentState.Equal["LOOT"]}
		{
		  This.CurrentState:Set["IDLE"]
		}
	}

	function Drop()
	{
		call Station.Dock
		wait 100
		call Cargo.TransferCargoToStationHangar
		wait 100
		; need to restock ammo here
		This.CurrentState:Set["IDLE"]
	}
}
