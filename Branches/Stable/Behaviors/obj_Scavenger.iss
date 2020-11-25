/*
	The scavenger object

	The obj_Scavenger object is a bot mode designed to be used with
	obj_Freighter bot module in EVEBOT.  It warp to asteroid belts
	snag some loot and warp off.

	-- GliderPro
*/

/* obj_Scavenger is a "bot-mode" which is similar to a bot-module.
 * obj_Scavenger runs within the obj_Freighter bot-module.  It would
 * be very straightforward to turn obj_Scavenger into a independent
 * bot-module in the future if it outgrows its place in obj_Freighter.
 */
objectdef obj_Scavenger inherits obj_BaseClass
{
	variable string CurrentState
	variable bool bHaveCargo = FALSE

	variable index:entity LockedTargets
	variable iterator Target

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		; Not a top level behavior
		Behaviors.Loaded:Remove[${This.ObjectName}]

		;PulseTimer:SetIntervals[0.5,1.0]
		;Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		;Event[EVENT_EVEBOT_ONFRAME]:DetachAtom
	}

	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${Config.Common.CurrentBehavior.NotEqual[Scavenger]}
		{
			return
		}

		if ${EVEBot.ReturnToStation} && ${Me.InSpace}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${MyShip.UsedCargoCapacity} <= ${Math.Calc[${MyShip.CargoCapacity}*.95]}
		{
			This.CurrentState:Set["SCAVENGE"]
			return
		}
		elseif ${MyShip.UsedCargoCapacity} > ${Math.Calc[${MyShip.CargoCapacity}*.95]}
		{
			This.CurrentState:Set["DROPOFFTOCHA"]
			return
		}
		else
		{
			Logger:Log["obj_Scavenger: ERROR!  Unknown State."]
			This.CurrentState:Set["Unknown"]
		}
	}

	function ProcessState()
	{
		if ${Config.Common.CurrentBehavior.NotEqual[Scavenger]}
		{
			return
		}

		switch ${This.CurrentState}
		{
			case ABORT
				call Station.Dock
				break
			case SCAVENGE
				wait 10
				call This.SalvageSite
				;call Asteroids.MoveToRandomBeltBookMark
				;wait 10
				;call This.WarpToFirstNonEmptyWreck
				;wait 10
				;call This.LootClosestWreck
				break
			case DROPOFFTOSTATION
				call Station.Dock
				wait 100
				call Cargo.TransferCargoToStationHangar
				wait 100
				break
			case DROPOFFTOCHA
				call This.DropAtCHA
				break
			case FLEE
				call This.Flee
				break
			case IDLE
				break
		}
	}

	function DropAtCHA()
	{
		variable index:item ContainerItems
		variable iterator CargoIterator

		; TODO - This will find the first bookmark matching this name, even if it's out of the system. This would be bad. Need to iterate and find the right one.
		if !${EVE.Bookmark[${Config.Combat.AmmoBookmark}](exists)}
		{
			Logger:Log["DroppingOffLoot: Fleeing: No ammo bookmark"]
			call This.Flee
			return
		}
		else
		{
			call Ship.WarpToBookMarkName ${Config.Combat.AmmoBookmark}
			Logger:Log["Dropping off Loot"]
			; If a corp hangar array is on grid - drop loot
			if ${Entity[TypeID = 17621].ID} != NULL
			{
				Logger:Log["Dropping off Loot at ${Entity[TypeID = 17621]} (${Entity[TypeID = 17621].ID})"]
				call Ship.Approach ${Entity[TypeID = 17621].ID} 1500
				Entity[${Entity[TypeID = 17621].ID}]:Open

				call Cargo.TransferCargoToCorpHangarArray
				return
			}
		}
		This.CurrentState:Set["SCAVENGE"]
	}

	function SalvageSite()
	{
		Ship:Activate_SensorBoost
		variable index:entity Wrecks
		variable iterator     Wreck
		variable index:item   Items
		variable iterator     Item
		variable index:int64  ItemsToMove
		variable float        TotalVolume = 0
		variable float        ItemVolume = 0
		variable int QuantityToMove

		Logger:Log["Salvaging Site"]
		while (${Ship.CargoFreeSpace} >= 100)
		{

			if (${Config.Miner.StandingDetection} && \
				${Social.StandingDetection[${Config.Miner.LowestStanding}]}) || \
				!${Social.IsSafe}
			{
				call This.Flee
				return
			}

			if ${Ship.TotalTargeting} < ${Ship.SafeMaxLockedTargets}
			{
				call This.TargetNext
			}

			EVE:QueryEntities[Wrecks, "GroupID = GROUPID_WRECK"]
			Logger:Log["obj_Scavenger: DEBUG: Found ${Wrecks.Used} wrecks."]
			if ${Ship.TotalActivatedTractorBeams} < ${Ship.TotalTractorBeams}
			{
				if ${Me.TargetingCount} < ${Ship.SafeMaxLockedTargets}
				{
					;echo "getting another target"
					call This.TargetNext
				}
				while ${Me.TargetingCount} > 0
				{
					wait 10
				}
				Me:GetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				if ${Target:First(exists)}
				do
				{
					;echo "doing stuff"
					if !${Ship.IsTractoringWreckID[${Target.Value.ID}]} && ${Target.Value.Distance} > 2500
					{
						;echo "Tactoring"
						Target.Value:MakeActiveTarget
						while !${Target.Value.ID.Equal[${Me.ActiveTarget.ID}]} && ${Me.TargetingCount} != 0
						{
							wait 5
						}
						if ${Target.Value.Distance} > ${Ship.OptimalTractorRange}
						{

							call Ship.Approach ${Target.Value.ID} ${Ship.OptimalTractorRange}
						}
						Call Ship.ActivateFreeTractorBeam
					}
					elseif ${Target.Value.Distance} < 2500
					{
						;echo "within range, attempted to turn off tractor beam"
						variable iterator ModuleIter

						Ship.ModuleList_TractorBeams:GetIterator[ModuleIter]
						if ${ModuleIter:First(exists)}
						do
						{
							;echo "Checking a Beam"
							if (${ModuleIter.Value.TargetID} == ${Target.Value.ID})
							{
								;echo "Beam found, turning it off"
								ModuleIter.Value:Click
							}
						}
						while ${ModuleIter:Next(exists)}
					}

				}
				while ${Target:Next(exists)}
			}

			if ${Ship.TotalActivatedSalvagers} < ${Ship.TotalSalvagers}
			{
				Me:GetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				if ${Target:First(exists)}
				do
				{
					if !${Ship.IsSalvagingWreckID[${Target.Value.ID}]} && ${Target.Value.Distance} < 2500
					{
						;echo "Salvaging"

						;echo "Salvaging: target in range"
						Target.Value:MakeActiveTarget
						while !${Target.Value.ID.Equal[${Me.ActiveTarget.ID}]} && ${Me.TargetingCount} != 0
						{
							;echo "Salvaging: waiting for switch"
							wait 5
						}

						;echo "Salvaging: Looting"
						call Ship.Approach ${Target.Value.ID} LOOT_RANGE
						call Inventory.ShipCargo.Activate
						Target.Value:Open
						wait 10
						Target.Value:GetCargo[Items]
						Logger:Log["obj_Scavenger: DEBUG:  Wreck contains ${Items.Used} items."]

						Items:GetIterator[Item]
						if ${Item:First(exists)}
						{
							do
							{
								;Logger:Log["obj_Ratter: Found ${Item.Value.Quantity} x ${Item.Value.Name} - ${Math.Calc[${Item.Value.Quantity} * ${Item.Value.Volume}].Precision[2]}m3"]
								if (${Math.Calc[${Item.Value.Quantity}*${Item.Value.Volume}]}) > ${Ship.CargoFreeSpace}
								{
									/* Move only what will fit, minus 1 to account for CCP rounding errors. */
									QuantityToMove:Set[${Math.Calc[${Ship.CargoFreeSpace} / ${Item.Value.Volume} - 1]}]
									if ${QuantityToMove} <= 0
									{
										Logger:Log["ERROR: obj_Ratter: QuantityToMove = ${QuantityToMove}!"]
										break
									}
								}
								else
								{
									QuantityToMove:Set[${Item.Value.Quantity}]
								}

								Logger:Log["obj_Ratter: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Item.Value.Volume}].Precision[2]}m3"]
								if ${QuantityToMove} > 0
								{
									Item.Value:MoveTo[${MyShip.ID}, CargoHold, ${QuantityToMove}]
									wait 5
								}

								if ${Ship.CargoFull}
								{
									Logger:Log["DEBUG: obj_Ratter: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}", LOG_DEBUG]
									break
								}
							}
							while ${Item:Next(exists)}
						}
						Call Ship.ActivateFreeSalvager
					}
				}
				while ${Target:Next(exists)}
			}
		}

		Ship:Deactivate_SensorBoost
	}


	function TargetNext()
	{
		variable index:entity Wrecks
		variable iterator     Wreck

		EVE:QueryEntities[Wrecks, "GroupID = GROUPID_WRECK"]
		Wrecks:GetIterator[Wreck]

		if ${Wreck:First(exists)}
		{
			do
			{
				if ${Entity[${Wreck.Value.ID}](exists)} && \
					!${Wreck.Value.IsLockedTarget} && \
					!${Wreck.Value.BeingTargeted} && \
					${Wreck.Value.Distance} < ${MyShip.MaxTargetRange} && \
					( !${Me.ActiveTarget(exists)} || ${Wreck.Value.DistanceTo[${Me.ActiveTarget.ID}]} <= ${Ship.OptimalTractorRange} )
				{
					break
				}
			}
			while ${Wreck:Next(exists)}

			if ${Wreck.Value(exists)} && \
				${Entity[${Wreck.Value.ID}](exists)}
			{
				if ${Wreck.Value.IsLockedTarget} || \
					${Wreck.Value.BeingTargeted}
				{
					return TRUE
				}
				Logger:Log["Locking Wreck ${Wreck.Value.Name}: ${EVEBot.MetersToKM_Str[${Wreck.Value.Distance}]}"]

				Wreck.Value:LockTarget
				do
				{
					wait 10
				}
				while ${Me.TargetingCount} > 0

			}
		}
		else
		{
			if ${Ship.TotalActivatedTractorBeams} == 0
			{
				This.Wrecks:GetIterator[Wreck]
				if !${Wreck:First(exists)}
				{
					Logger:Log["obj_Scavenger: TargetNext: No Wrecks on-grid, Going Home"]
					call This.Flee
				}
			}
		}
	}

	function Flee()
	{
		Ship:Deactivate_SensorBoost
		This.CurrentState:Set["FLEE"]
		This.Fled:Set[TRUE]

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
			if ${Me.ToEntity.Mode} != 3
			{
				call Safespots.WarpTo
				wait 30
			}
		}
	}
}

