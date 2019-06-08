/*
	Asteroids Class
		Handles selection & prioritization of asteroid fields and asteroids, as well as targeting of same.

	AsteroidGroup Class
		Handles information about a group of asteroids for weighting purposes

	-- CyberTech

BUGS:
	we don't differentiate between ice fields and ore fields, need to match field type to laser type.

*/

objectdef obj_AsteroidGroup
{
}

objectdef obj_Asteroids
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable int AsteroidCategoryID = 25

	variable index:entity BestAsteroidList
	variable index:entity AsteroidList
	variable iterator OreTypeIterator

	; Should only be referenced inside NextAsteroid()
	variable iterator NextAsteroidIterator

	variable index:string EmptyBeltList
	variable iterator EmptyBelt

	variable index:bookmark BeltBookMarkList
	variable iterator BeltBookMarkIterator
	variable int LastBookMarkIndex
	variable int LastBeltIndex
	variable bool UsingBookMarks = FALSE
	variable time BeltArrivalTime
	variable float MaxDistanceToAsteroid

	method Initialize()
	{
		UI:UpdateConsole["obj_Asteroids: Initialized", LOG_MINOR]
	}

	; Checks the belt name against the empty belt list.
	member IsBeltEmpty(string BeltName)
	{
		if !${BeltName(exists)}
		{
			return FALSE
		}

		EmptyBeltList:GetIterator[EmptyBelt]
		if ${EmptyBelt:First(exists)}
		do
		{
			if ${EmptyBelt.Value.Equal[${BeltName}]}
			{
				echo "DEBUG: obj_Asteroid:IsBeltEmpty - ${BeltName} - TRUE"
				return TRUE
			}
		}
		while ${EmptyBelt:Next(exists)}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method BeltIsEmpty(string BeltName)
	{
		if ${BeltName(exists)}
		{
			EmptyBeltList:Insert[${BeltName}]
			UI:UpdateConsole["Excluding empty belt ${BeltName}"]
		}
	}

	function MoveToRandomBeltBookMark(bool FleetWarp=FALSE)
	{
		variable int RandomBelt
		variable string Label
		variable string prefix

		if ${Config.Miner.IceMining}
		{
			prefix:Set[${Config.Labels.IceBeltPrefix}]
		}
		else
		{
			prefix:Set[${Config.Labels.OreBeltPrefix}]
		}

		variable float Distance
		EVE:RefreshBookmarks
		wait 10
		EVE:GetBookmarks[BeltBookMarkList]
		BeltBookMarkList:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID != "${Me.SolarSystemID}"]}]
		BeltBookMarkList:Collapse
		; This needs to be initialized somewhere. May as well be here! -- Valerian
		RandomBelt:Set[1]

		while ${BeltBookMarkList.Used} > 1
		{
			RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used(int):Dec}]:Inc[1]}]
			Label:Set[${BeltBookMarkList[${RandomBelt}].Label}]
			if ${Label.Left[${prefix.Length}].NotEqual[${prefix}]}
			{
				BeltBookMarkList:Remove[${RandomBelt}]
				BeltBookMarkList:Collapse
				RandomBelt:Set[1]
				continue
			}

			if ${BeltBookMarkList[${RandomBelt}].X(exists)}
			{
				Distance:Set[${Math.Distance[${BeltBookMarkList[${RandomBelt}].X},${BeltBookMarkList[${RandomBelt}].Y},${BeltBookMarkList[${RandomBelt}].Z},${Me.ToEntity.X},${Me.ToEntity.Y},${Me.ToEntity.Z}]}]
			}
			else
			{
				Distance:Set[${Math.Distance[${BeltBookMarkList[${RandomBelt}].ToEntity.X},${BeltBookMarkList[${RandomBelt}].ToEntity.Y},${BeltBookMarkList[${RandomBelt}].ToEntity.Z},${Me.ToEntity.X},${Me.ToEntity.Y},${Me.ToEntity.Z}]}]
			}
			if ${Distance} < WARP_RANGE
			{
				; Must remove this belt to avoid inf loops
				BeltBookMarkList:Remove[${RandomBelt}]
				BeltBookMarkList:Collapse
				RandomBelt:Set[1]
				continue
			}
			break
		}
		if ${BeltBookMarkList.Used}
		{
			UI:UpdateConsole["Debug: WarpToBookMarkName to ${BeltBookMarkList[${RandomBelt}].Label} from MoveToRandomBeltBookMark Line _LINE_ ", LOG_DEBUG]
			call Ship.WarpToBookMark ${BeltBookMarkList[${RandomBelt}].ID} ${FleetWarp}

			This.BeltArrivalTime:Set[${Time.Timestamp}]
			This.LastBookMarkIndex:Set[${RandomBelt}]
			This.UsingBookMarks:Set[TRUE]
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Asteroids:MoveToRandomBeltBookMark: No belt bookmarks found!", LOG_DEBUG]
		}
		return
	}

	function MoveToField(bool ForceMove, bool IgnoreTargeting=FALSE, bool FleetWarp=FALSE)
	{
		variable int curBelt
		variable index:entity Belts
		variable iterator BeltIterator
		variable int TryCount
		variable string beltsubstring
		variable bool AsteroidsInRange = FALSE

		if ${Config.Miner.IceMining}
		{
			beltsubstring:Set["ICE FIELD"]
		}
		else
		{
			beltsubstring:Set["ASTEROID BELT"]
		}

		EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
		Belts:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			if !${ForceMove}
			{
				call TargetNext TRUE ${IgnoreTargeting}
				AsteroidsInRange:Set[${Return}]
			}

			if ${ForceMove} || !${AsteroidsInRange}
			{
				if (${Config.Miner.BookMarkLastPosition} && \
					${Bookmarks.StoredLocationExists})
				{
					/* We have a stored location, we should return to it. */
					UI:UpdateConsole["Returning to last location (${Bookmarks.StoredLocation})"]
					call Ship.TravelToSystem ${EVE.Bookmark[${Bookmarks.StoredLocation}].SolarSystemID}
					call Ship.WarpToBookMarkName "${Bookmarks.StoredLocation}" ${FleetWarp}
					This.BeltArrivalTime:Set[${Time.Timestamp}]
					Bookmarks:RemoveStoredLocation
					return
				}
				if ${Config.Miner.UseFieldBookmarks}
				{
					call This.MoveToRandomBeltBookMark ${FleetWarp}
					return
				}

				; We're not at a field already, so find one
				do
				{
					curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
					TryCount:Inc
					if ${TryCount} > ${Math.Calc[${Belts.Used} * 10]}
					{
						UI:UpdateConsole["All belts empty!"]
						call ChatIRC.Say "All belts empty!"
						EVEBot.ReturnToStation:Set[TRUE]
						return
					}
				}
				while ( !${Belts[${curBelt}].Name.Find[${beltsubstring}](exists)} || \
						${This.IsBeltEmpty[${Belts[${curBelt}].Name}]} )

				UI:UpdateConsole["EVEBot thinks we're not at a belt.  Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"]
				call Ship.WarpToID ${Belts[${curBelt}].ID} 0 ${FleetWarp}
				This.BeltArrivalTime:Set[${Time.Timestamp}]
				This.UsingBookMarks:Set[TRUE]
				This.LastBeltIndex:Set[${curBelt}]
			}
			else
			{
				;UI:UpdateConsole["Staying at Asteroid Belt: ${BeltIterator.Value.Name}"]
			}
		}
		else
		{
			/* There is a corner case here, in the event the user is in a system with no overview-visible
				bookmarks, but has Belt bookmarks to hidden belts. We duplicate this code here from above
				to avoid yet another level of */

			if (${Config.Miner.BookMarkLastPosition} && \
				${Bookmarks.StoredLocationExists})
			{
				/* We have a stored location, we should return to it. */
				UI:UpdateConsole["Returning to last location (${Bookmarks.StoredLocation})"]
				call Ship.WarpToBookMarkName "${Bookmarks.StoredLocation}"
				This.BeltArrivalTime:Set[${Time.Timestamp}]
				Bookmarks:RemoveStoredLocation
				return
			}

			if ${Config.Miner.UseFieldBookmarks}
			{
				call This.MoveToRandomBeltBookMark
				return
			}

			UI:UpdateConsole["ERROR: OBJ_Asteroids:MoveToField: No asteroid belts in the area...", LOG_CRITICAL]
			#if EVEBOT_DEBUG
			UI:UpdateConsole["OBJ_Asteroids:MoveToField: Total Entities: ${EVE.EntitiesCount}", LOG_DEBUG]
			UI:UpdateConsole["OBJ_Asteroids:MoveToField: Size of Belts List ${Belts.Used}", LOG_DEBUG]
			#endif
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}
	}

	method Find_Best_Asteroids()
	{
		Config.Miner.OreTypesRef:GetSettingIterator[This.OreTypeIterator]

		if ${This.OreTypeIterator:First(exists)}
		{
			do
			{
				;echo "DEBUG: obj_Asteroids: Checking for Ore Type ${This.OreTypeIterator.Key}"
				This.AsteroidList:Clear
				EVE:QueryEntities[This.AsteroidList, "CategoryID = ${This.AsteroidCategoryID} && Name =- ${This.OreTypeIterator.Key}"]

				This.AsteroidList:GetIterator[AsteroidIterator]
				if ${AsteroidIterator:First(exists)}
				do
				{

					This.BestAsteroidList:Insert[${AsteroidIterator.Value.ID}]
				}
				while ${This.Asteroidlist:Next(exists)}

				;This.BestAsteroidList:Insert[${This.AsteroidList
			}
			while ( (${This.BestAsteroidList.Used} < 10) && (${This.OreTypeIterator:Next(exists)}) )

			if ${This.AsteroidList.Used}
			{
					;echo "DEBUG: obj_Asteroids:UpdateList - Found ${This.AsteroidList.Used} ${This.OreTypeIterator.Key} asteroids"
			}
		}
		else
		{
			echo "WARNING: obj_Asteroids: Ore Type list is empty, please check config"
		}

	}

	function UpdateList(int64 EntityIDForDistance=-1)
	{
		variable index:entity AsteroidListTmp
		variable index:entity AsteroidList_OutOfRange
		variable index:entity AsteroidList_OutOfRangeTmp
		variable iterator AsteroidIt

		if ${Ship.OptimalMiningRange} == 0 && ${Config.Miner.OrcaMode} || ${Config.Miner.UseMiningDrones} && ${Ship.TotalMiningLasers} == 0
		{
			This.MaxDistanceToAsteroid:Set[${Math.Calc[20000 * ${Config.Miner.MiningRangeMultipler}]}]
		}
		else
		{
			This.MaxDistanceToAsteroid:Set[${Math.Calc[${Ship.OptimalMiningRange} * ${Config.Miner.MiningRangeMultipler}]}]
		}

		if ${Config.Miner.IceMining}
		{
			Config.Miner.IceTypesRef:GetSettingIterator[This.OreTypeIterator]
		}
		else
		{
			Config.Miner.OreTypesRef:GetSettingIterator[This.OreTypeIterator]
		}

		if ${This.OreTypeIterator:First(exists)}
		{
			This.AsteroidList:Clear
			do
			{
				; This is intended to get the best ore in the system before others do.  Its not
				; intended to empty a given radius of asteroids
				if ${Config.Miner.StripMine}
				{
					if ${EntityIDForDistance} < 0
					{
						EVE:QueryEntities[AsteroidListTmp, "CategoryID = ${This.AsteroidCategoryID} && Name =- \"${This.OreTypeIterator.Key}\" && Distance < ${Ship.OptimalMiningRange}"]
						EVE:QueryEntities[AsteroidList_OutOfRangeTmp, "CategoryID = ${This.AsteroidCategoryID} && Name =- \"${This.OreTypeIterator.Key}\" && Distance >= ${Ship.OptimalMiningRange}"]
					}
					else
					{
						EVE:QueryEntities[AsteroidListTmp, "CategoryID = ${This.AsteroidCategoryID} && Name =- \"${This.OreTypeIterator.Key}\" && DistanceTo[${EntityIDForDistance}] < ${Math.Calc[${Ship.OptimalMiningRange} + 2000]}"]
						EVE:QueryEntities[AsteroidList_OutOfRangeTmp, "CategoryID = ${This.AsteroidCategoryID} && Name =- \"${This.OreTypeIterator.Key}\" && DistanceTo[${EntityIDForDistance}] >= ${Math.Calc[${Ship.OptimalMiningRange} + 2000]}"]
					}
				}
				else
				{
					EVE:QueryEntities[AsteroidListTmp, "CategoryID = ${This.AsteroidCategoryID} && Name =- \"${This.OreTypeIterator.Key}\""]
				}

				variable int Count
				variable int Max
				; Randomize the first 15 in-range asteroids in the list so that all the miners don't glom on the same one.
				if !${Config.Miner.IceMining} && ${AsteroidListTmp.Used} > 3
				{
					Max:Set[${AsteroidListTmp.Used}]
					if ${Max} > 15
					{
						Max:Set[15]
					}
					for (Count:Set[0] ; ${Count} < ${Max} ; Count:Inc)
					{
						AsteroidListTmp:Swap[${Math.Rand[${Max}]:Inc},${Math.Rand[${Max}]:Inc}]
					}
				}
				; Append the in-range asteroids of the current ore type to the final list
				AsteroidListTmp:GetIterator[AsteroidIt]
				if ${AsteroidIt:First(exists)}
				{
					do
					{
						This.AsteroidList:Insert[${AsteroidIt.Value.ID}]
					}
					while ${AsteroidIt:Next(exists)}
				}

				; Randomize the first 10 out of range asteroids in the list so that all the miners don't glom on the same one.
				if !${Config.Miner.IceMining} && ${AsteroidList_OutOfRangeTmp.Used} > 3
				{
					Max:Set[${AsteroidList_OutOfRangeTmp.Used}]
					if ${Max} > 10
					{
						Max:Set[10]
					}
					for (Count:Set[0] ; ${Count} < ${Max} ; Count:Inc)
					{
						AsteroidList_OutOfRangeTmp:Swap[${Math.Rand[${Max}]:Inc},${Math.Rand[${Max}]:Inc}]
					}
				}
				; Append the asteroids of the current ore type to the out of range tmp list; later we'll append it to the fully populated in-range list
				AsteroidList_OutOfRangeTmp:GetIterator[AsteroidIt]
				if ${AsteroidIt:First(exists)}
				{
					do
					{
						AsteroidList_OutOfRange:Insert[${AsteroidIt.Value.ID}]
					}
					while ${AsteroidIt:Next(exists)}
				}

			}
			while ${This.OreTypeIterator:Next(exists)}

			if ${Config.Miner.StripMine}
			{
				; Append the out-of-range asteroid list to the in-range list; so the miner can decide to move or not as it runs thru it.
				AsteroidList_OutOfRange:GetIterator[AsteroidIt]
				if ${AsteroidIt:First(exists)}
				{
					do
					{
						This.AsteroidList:Insert[${AsteroidIt.Value.ID}]
					}
					while ${AsteroidIt:Next(exists)}
				}
			}

			UI:UpdateConsole["OBJ_Asteroids:UpdateList: ${AsteroidList.Used} (In Range: ${AsteroidListTmp.Used} OOR: ${AsteroidList_OutOfRangeTmp.Used}) asteroids found", LOG_DEBUG]
		}
		else
		{
			echo "WARNING: obj_Asteroids: Ore Type list is empty, please check config"
		}
	}

	member:int64 NearestAsteroid()
	{
		; TODO - add a Mercoxit checkbox to ui, and pass the config val as a param to this member for whether to include merc or not.
		return ${Entity["CategoryID = ${This.AsteroidCategoryID} && TypeID != 11396"].ID}
	}


	method NextAsteroid()
	{
		AsteroidList:GetSettingIterator
	}

	member:bool FieldEmpty()
	{
		variable iterator AsteroidIterator
		if ${AsteroidList.Used} == 0
		{
			call This.UpdateList
		}

		This.AsteroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
			return FALSE
		}
		return TRUE
	}
	;	If you are a drone exclusive miner, you probably want your targets to be close to each other
	function:bool TargetInClusters(int64 DistanceToTarget=-1)
	{
		variable iterator AsteroidIterator

		if ${AsteroidList.Used} == 0
		{
			call This.UpdateList
		}

		This.AsteroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
			do
			{
				if ${DistanceToTarget} == -1
				{
					
					if ${Entity[${AsteroidIterator.Value.ID}](exists)} && \
						!${AsteroidIterator.Value.IsLockedTarget} && \
						!${AsteroidIterator.Value.BeingTargeted} && \
						${AsteroidIterator.Value.Distance} < ${MyShip.MaxTargetRange} && \
						${AsteroidIterator.Value.Distance} < ${Ship.OptimalMiningRange}
					{
						break
					}
				}
				else
				{
					if ${Entity[${AsteroidIterator.Value.ID}](exists)} && \
						!${AsteroidIterator.Value.IsLockedTarget} && \
						!${AsteroidIterator.Value.BeingTargeted} && \
						${AsteroidIterator.Value.Distance} < ${MyShip.MaxTargetRange} && \
						${AsteroidIterator.Value.DistanceTo[${DistanceToTarget}]} < 10000
					{
						variable iterator Target
						variable bool IsWithinRangeOfOthers=TRUE
						Targets:UpdateLockedAndLockingTargets
						Targets.LockedOrLocking:GetIterator[Target]
						if ${Target:First(exists)}
							do
							{
								if ${AsteroidIterator.Value.CategoryID} == ${Asteroids.AsteroidCategoryID}
								{
									
										if ${AsteroidIterator.Value.DistanceTo[${Target.Value.ID}]} > 30000
										{
											IsWithinRangeOfOthers:Set[FALSE]
										}
								}
							}
							while ${Target:Next(exists)}
						if ${IsWithinRangeOfOthers}
							break
					}
				}
			}
			while ${AsteroidIterator:Next(exists)}

			if ${AsteroidIterator.Value(exists)} && ${Entity[${AsteroidIterator.Value.ID}](exists)}
			{
				if ${AsteroidIterator.Value.IsLockedTarget} || \
					${AsteroidIterator.Value.BeingTargeted}
				{
					return TRUE
				}

				UI:UpdateConsole["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
				AsteroidIterator.Value:LockTarget

				call This.UpdateList
				return TRUE
			}
			else
			{
				call This.UpdateList
				return FALSE
			}
		}
		call This.MoveToField TRUE
		return FALSE
	}
	
	function:bool TargetNextInRange(int64 DistanceToTarget=-1)
	{
		variable iterator AsteroidIterator

		if ${AsteroidList.Used} == 0
		{
			call This.UpdateList
		}

		This.AsteroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
			do
			{
				if ${DistanceToTarget} == -1
				{
					
					if ${Entity[${AsteroidIterator.Value.ID}](exists)} && \
						!${AsteroidIterator.Value.IsLockedTarget} && \
						!${AsteroidIterator.Value.BeingTargeted} && \
						${AsteroidIterator.Value.Distance} < ${MyShip.MaxTargetRange} && \
						${AsteroidIterator.Value.Distance} < ${Ship.OptimalMiningRange}
					{
						break
					}
				}
				else
				{
					if ${Entity[${AsteroidIterator.Value.ID}](exists)} && \
						!${AsteroidIterator.Value.IsLockedTarget} && \
						!${AsteroidIterator.Value.BeingTargeted} && \
						${AsteroidIterator.Value.Distance} < ${MyShip.MaxTargetRange} && \
						${AsteroidIterator.Value.DistanceTo[${DistanceToTarget}]} < ${Math.Calc[${Ship.OptimalMiningRange} + 2000]}
					{
						variable iterator Target
						variable bool IsWithinRangeOfOthers=TRUE
						Targets:UpdateLockedAndLockingTargets
						Targets.LockedOrLocking:GetIterator[Target]
						if ${Target:First(exists)}
							do
							{
								if ${AsteroidIterator.Value.CategoryID} == ${Asteroids.AsteroidCategoryID}
								{
									
										if ${AsteroidIterator.Value.DistanceTo[${Target.Value.ID}]} > 30000
										{
											IsWithinRangeOfOthers:Set[FALSE]
										}
								}
							}
							while ${Target:Next(exists)}
						if ${IsWithinRangeOfOthers}
							break
					}
				}
			}
			while ${AsteroidIterator:Next(exists)}

			if ${AsteroidIterator.Value(exists)} && ${Entity[${AsteroidIterator.Value.ID}](exists)}
			{
				if ${AsteroidIterator.Value.IsLockedTarget} || \
					${AsteroidIterator.Value.BeingTargeted}
				{
					return TRUE
				}

				UI:UpdateConsole["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
				AsteroidIterator.Value:LockTarget

				call This.UpdateList
				return TRUE
			}
			else
			{
				call This.UpdateList
				return FALSE
			}
		}
		return FALSE
	}

	function:bool TargetNext(bool CalledFromMoveRoutine=FALSE, bool IgnoreTargeting=FALSE)
	{
		variable iterator AsteroidIterator

		if ${AsteroidList.Used} == 0
		{
			call This.UpdateList
		}

		This.AsteroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
			do
			{
				if ${Entity[${AsteroidIterator.Value.ID}](exists)} && \
					!${AsteroidIterator.Value.IsLockedTarget} && \
					!${AsteroidIterator.Value.BeingTargeted} && \
					${AsteroidIterator.Value.Distance} < ${MyShip.MaxTargetRange} && \
					( !${Me.ActiveTarget(exists)} || ${AsteroidIterator.Value.DistanceTo[${Me.ActiveTarget.ID}]} <= 25000 )
				{
					break
				}
			}
			while ${AsteroidIterator:Next(exists)}

			if ${AsteroidIterator.Value(exists)} && \
				${Entity[${AsteroidIterator.Value.ID}](exists)}
			{
				if ${AsteroidIterator.Value.IsLockedTarget} || \
					${AsteroidIterator.Value.BeingTargeted}
				{
					return TRUE
				}

				;; This member does not exist in obj_Combat!!  -- GP
				;;while ${Combat.CombatPause}
				;;{
				;;	wait 30
				;;	echo "DEBUG: Obj_Asteroids In Combat Pause Loop"
				;;}

				if !${IgnoreTargeting}
				{
					UI:UpdateConsole["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
					AsteroidIterator.Value:LockTarget
					do
					{
					  wait 30
					}
					while ${Me.TargetingCount} > 0
				}

				call This.UpdateList
				return TRUE
			}
			else
			{
				call This.UpdateList
				if ${Ship.TotalActivatedMiningLasers} == 0
				{
					if ${Ship.CargoFull}
					{
						return FALSE
					}
					This.AsteroidList:GetIterator[AsteroidIterator]
					if ${AsteroidIterator:First(exists)}
					{
						if ${AsteroidIterator.Value.Distance} < ${This.MaxDistanceToAsteroid}
						{
							UI:UpdateConsole["obj_Asteroids: TargetNext: No Asteroids in range & All lasers idle: Approaching nearest"]
							if ${MyShip.MaxTargetRange} < ${Ship.OptimalMiningRange} || ${Config.Miner.UseMiningDrones} && ${Ship.TotalMiningLasers} == 0
							{
								call Ship.Approach ${AsteroidIterator.Value.ID} 1000
							}
							else
							{
								call Ship.Approach ${AsteroidIterator.Value.ID} ${Math.Calc[${Ship.OptimalMiningRange} - 5000]}
							}
						}
						else
						{
							UI:UpdateConsole["obj_Asteroids: TargetNext: No Asteroids within ${EVEBot.MetersToKM_Str[${This.MaxDistanceToAsteroid}]}, changing fields."]
							/* The nearest asteroid is farfar away.  Let's just warp out. */

							if ${CalledFromMoveRoutine}
							{
								; Don't do any movement, we're being called from inside another movement function
								return FALSE
							}
							call This.MoveToField TRUE
							return TRUE
						}
					}
				}
				return FALSE
			}
		}
		else
		{
			UI:UpdateConsole["obj_Asteroids: No Asteroids within overview range"]
			if ${Entity["GroupID = GROUP_ASTEROIDBELT"].Distance} < CONFIG_OVERVIEW_RANGE
			{
				This:BeltIsEmpty["${Entity[GroupID = GROUP_ASTEROIDBELT].Name}"]
			}
			if ${CalledFromMoveRoutine}
			{
				; Don't do any movement, we're being called from inside another movement function
				return FALSE
			}
			call This.MoveToField TRUE
			return TRUE
		}
		return FALSE
	}

	member:int LockedAndLocking()
	{
		variable iterator Target
		variable int AsteroidsLocked=0
		Targets:UpdateLockedAndLockingTargets
		Targets.LockedOrLocking:GetIterator[Target]

		if ${Target:First(exists)}
		do
		{
			if ${Target.Value.CategoryID} == ${Asteroids.AsteroidCategoryID}
			{
				AsteroidsLocked:Inc
			}
		}
		while ${Target:Next(exists)}
		return ${AsteroidsLocked}
	}
}
