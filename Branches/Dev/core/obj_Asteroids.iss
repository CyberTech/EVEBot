/*
	Asteroids Class
		Handles selection & prioritization of asteroid fields and asteroids, as well as targeting of same.

	AsteroidGroup Class
		Handles information about a group of asteroids for weighting purposes

	-- CyberTech

BUGS:
	we don't differentiate between ice fields and ore fields, need to match field type to laser type.

*/

objectdef obj_Asteroids
{
	variable string LogPrefix

	variable index:entity AsteroidList

	variable int Asteroid_CacheID
	variable iterator Asteroid_CacheIterator

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
		LogPrefix:Set["${This.ObjectName}"]

		This:Populate_AsteroidFilter

		Logger:Log["${This.LogPrefix}: Initialized", LOG_MINOR]
	}

	; Checks the belt name against the empty belt list.
	member IsBeltMarkedEmpty(string BeltName)
	{
		echo "obj_Asteroids.IsBeltMarkedEmpty is deprecated"
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
				echo "DEBUG: obj_Asteroid:IsBeltMarkedEmpty - ${BeltName} - TRUE"
				return TRUE
			}
		}
		while ${EmptyBelt:Next(exists)}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method MarkBeltEmpty(string BeltName)
	{
		if ${BeltName(exists)}
		{
			EmptyBeltList:Insert[${BeltName}]
			Logger:Log["Excluding empty belt ${BeltName}"]
		}
	}

	member:int Count()
	{
		; FOR NOW just return count of all asteroids.  add filtering later.
		return ${EntityCache.Count[${This.Asteroid_CacheID}]}
	}

	function MoveToField(bool ForceMove)
	{
		variable int curBelt
		variable int TryCount
		variable string beltsubstring
		variable bool AsteroidsInRange = FALSE
		variable iterator BeltIterator
		
		if ${Config.Miner.IceMining}
		{
			beltsubstring:Set["ICE FIELD"]
		}
		else
		{
			beltsubstring:Set["ASTEROID BELT"]
		}

		EntityCache.EntityFilters.Get[${CacheID_Belts}].Entities:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			if !${ForceMove}
			{
				call ChooseTargets TRUE
				Logger:Log["DEBUG: MoveToField: T.QS: ${Targeting.QueueSize}"]
				AsteroidsInRange:Set[${Targeting.QueueSize}]
			}

#if EVEBOT_DEBUG
			Logger:Log["DEBUG: MoveToField: ForceMove=${ForceMove} AsteroidsInRange=${AsteroidsInRange}"]
#endif
			if ${ForceMove} || !${AsteroidsInRange}
			{
				This.AsteroidList:Clear

				if (${Config.Miner.BookMarkLastPosition} && \
					${Bookmarks.StoredLocationExists})
				{
					/* We have a stored location, we should return to it. */
					Logger:Log["Returning to last location (${Bookmarks.StoredLocation})"]
					call Ship.WarpToBookMarkName "${Bookmarks.StoredLocation}"
					This.BeltArrivalTime:Set[${Time.Timestamp}]
					Bookmarks:RemoveStoredLocation
					return
				}

				if ${Config.Miner.UseFieldBookmarks}
				{
					call BeltBookmarks.WarpToRandom
					return
				}

				; We're not at a field already, so find one
				do
				{
					curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
					TryCount:Inc
					if ${TryCount} > ${Math.Calc[${Belts.Used} * 10]}
					{
						Logger:Log["All belts empty!", LOG_CRITICAL]
						EVEBot.ReturnToStation:Set[TRUE]
						return
					}
				}
				while ( !${Belts[${curBelt}].Name.Find[${beltsubstring}](exists)} || \
						${This.IsBeltMarkedEmpty[${Belts[${curBelt}].Name}]} )

				Logger:Log["Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"]
				call Ship.WarpToID ${Belts[${curBelt}]}
				This.BeltArrivalTime:Set[${Time.Timestamp}]
				This.UsingMookMarks:Set[TRUE]
				This.LastBeltIndex:Set[${curBelt}]
			}
			else
			{
				Logger:Log["Staying at Asteroid Belt: ${BeltIterator.Value.Name}"]
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
				Logger:Log["Returning to last location (${Bookmarks.StoredLocation})"]
				call Ship.WarpToBookMarkName "${Bookmarks.StoredLocation}"
				This.BeltArrivalTime:Set[${Time.Timestamp}]
				Bookmarks:RemoveStoredLocation
				return
			}

			if ${Config.Miner.UseFieldBookmarks}
			{
				call BeltBookmarks.WarpToRandom
				return
			}

			Logger:Log["ERROR: OBJ_Asteroids:MoveToField: No asteroid belts in the area...", LOG_CRITICAL]
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}
	}

	method Populate_AsteroidFilter()
	{
		variable iterator OreTypeIterator
		variable string Filter = "CategoryID = CATEGORYID_ORE"
		variable string TypeFilter

		switch ${Config.Miner.MinerType}
		{
			case Ice
				Config.Miner.IceTypesRef:GetSettingIterator[OreTypeIterator]
				break
			case Ore
				Config.Miner.OreTypesRef:GetSettingIterator[OreTypeIterator]
				break
			case Ore - Mercoxit
				Config.Miner.MercoxitTypesRef:GetSettingIterator[OreTypeIterator]
				break
			Default
				Logger:Log["ERROR: OBJ_Asteroids:Populate_AsteroidFilter: Config.Miner.MinerType is unknown: ${Config.Miner.MinerType}", LOG_CRITICAL]
				Config.Miner.OreTypesRef:GetSettingIterator[OreTypeIterator]
				break
		}

		if ${OreTypeIterator:First(exists)}
		{
			TypeFilter:Set["("]
			do
			{
				if ${OreTypeIterator.Value.FindAttribute[Enabled, 1]} == 1
				{
					Logger:Log["DEBUG: obj_Asteroids:Populate_AsteroidFilter: Adding ore type ${OreTypeIterator.Value} to query", LOG_DEBUG]
					if ${TypeFilter.Length} > 1
					{
						TypeFilter:Concat[" || "]
					}

					TypeFilter:Concat["TypeID = ${OreTypeIterator.Key}"]
					;echo TypeID: ${OreTypeIterator.Key}
					;echo Ore Name: ${OreTypeIterator.Value}
					;echo Enabled: ${OreTypeIterator.Value.FindAttribute[Enabled]}
					;echo Priority: ${OreTypeIterator.Value.FindAttribute[Priority]}
				}
				else
				{
					Logger:Log["DEBUG: obj_Asteroids:Populate_AsteroidFilter: Skipping disabled ore: ${OreTypeIterator.Key}", LOG_DEBUG]
				}
			}
			while ${OreTypeIterator:Next(exists)}

			if ${TypeFilter.Length} > 1
			{
				TypeFilter:Concat[")"]
				Filter:Concat[" && "]
				Filter:Concat[${TypeFilter}]
			}
			Logger:Log["DEBUG: obj_Asteroids:Populate_AsteroidFilter: Filter is ${Filter}", LOG_DEBUG]
			EntityCache:DeleteFilter[${This.Asteroid_CacheID}]
			This.Asteroid_CacheID:Set[${EntityCache.AddFilter["obj_Asteroids", ${Filter}, 20]}]
			EntityCache.EntityFilters.Get[${This.Asteroid_CacheID}].Entities:GetIterator[Asteroid_CacheIterator]
		}
		else
		{
			Logger:Log["WARNING: obj_Asteroids:Populate_AsteroidFilter: Ore Type list is empty, please check config"]
		}
	}

	member:int SelectBestGroup()
	{
		variable iterator AsteroidIterator

		variable int BestAsteroidID
		variable int BestAsteroidValue
		;variable int BestAsteroidNeighborCount

		This.AsteroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
		}

	}

	method UpdateAsteroidList()
	{
		variable index:entity asteroid_index
		variable index:entity AsteroidList_outofrange

		This.AsteroidList:Clear
		AsteroidList_outofrange:Clear
		if ${Asteroid_CacheIterator:First(exists)}
		{
			do
			{
				/* This is intended to get the best ore in the system before others do.  Its not
					intended to empty a given radius of asteroids */
				if ${Config.Miner.StripMine}
				{
					if ${Asteroid_CacheIterator.Value.Distance} < ${Ship.OptimalMiningRange}
					{
						This.AsteroidList:Insert[${Asteroid_CacheIterator.Value.ID}]
					}
					else
					{
						AsteroidList_outofrange:Insert[${Asteroid_CacheIterator.Value.ID}]
					}
				}
				else
				{
					This.AsteroidList:Insert[${Asteroid_CacheIterator.Value.ID}]
				}
			}
			while ${Asteroid_CacheIterator:Next(exists)} && ${This.AsteroidList.Used} < ${Ship.TotalMiningLasers}
		}

		if ${Config.Miner.StripMine}
		{
			/* Append the OOR index to the good one */
			AsteroidList_outofrange:GetIterator[asteroid_iterator]
			if ${Asteroid_CacheIterator:First(exists)}
			{
				do
				{
					This.AsteroidList:Insert[${Asteroid_CacheIterator.Value.ID}]
				}
				while ${Asteroid_CacheIterator:Next(exists)}
			}
		}
	}

	function:bool ChooseTargets(bool CalledFromMoveRoutine=FALSE)
	{
		variable iterator AsteroidIterator
		variable int IndexPos = 1
		variable int MaxDistBetweenAsteroids = ${Math.Calc[${Ship.OptimalMiningRange}* 1.1]}

		if ${This.AsteroidList.Used} < ${Ship.TotalMiningLasers}
		{
			This:UpdateAsteroidList
		}

		This.MaxDistanceToAsteroid:Set[${Math.Calc[${Ship.OptimalMiningRange} * ${Config.Miner.MiningRangeMultipler}]}]

		Logger:Log["DEBUG: obj_Asteroids:ChooseTargets: Checking ${This.AsteroidList.Used} asteroids", LOG_DEBUG]
		if ${This.AsteroidList.Used}
		{
			variable int AsteroidID
			for ( IndexPos:Set[1]; ${IndexPos} <= ${This.AsteroidList.Used}; IndexPos:Inc )
			{
				AsteroidID:Set[${This.AsteroidList[${IndexPos}]}]
				Logger:Log["DEBUG: obj_Asteroids:ChooseTargets: ${IndexPos}: ID: ${AsteroidID} EntityResult: ${Entity[${AsteroidID}]}", LOG_DEBUG]
				if ${Entity[${AsteroidID}](exists)} && \
					${Targeting.TargetCount} < ${Ship.MaxLockedTargets} && \
					${Targeting.QueueSize} < ${Ship.MaxLockedTargets} && \
					!${Targeting.IsQueued[${AsteroidID}]} && \
					${This.AsteroidList[${IndexPos}].Distance} < ${MyShip.MaxTargetRange} && \
					${Targeting.DistanceFromQueue[${AsteroidID},${MaxDistBetweenAsteroids}]} < ${MaxDistBetweenAsteroids}
				{
					Targeting:Queue[${This.AsteroidList[${IndexPos}].ID}]
					This.AsteroidList:Remove[${IndexPos}]
				}
			}
			This.AsteroidList:Collapse

			if ${Targeting.QueueSize} == 0
			{
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
							Logger:Log["${This.ObjectName}: ChooseTargets: No Asteroids in range & All lasers idle: Approaching nearest"]
							call Ship.Approach ${AsteroidIterator.Value} ${Ship.OptimalMiningRange}
						}
						else
						{
							Logger:Log["${This.ObjectName}: ChooseTargets: No Asteroids within ${EVEBot.MetersToKM_Str[${This.MaxDistanceToAsteroid}], changing fields."]
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
			Logger:Log["${This.ObjectName}: No Asteroids within overview range"]
			if ${Entity[GroupID = GROUP_ASTEROIDBELT].Distance} < CONFIG_OVERVIEW_RANGE
			{
				This:MarkBeltEmpty["${Entity[GroupID = GROUP_ASTEROIDBELT]}"]
			}
			call This.MoveToField TRUE
			return TRUE
		}
		return FALSE
	}
}