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

	function MoveToRandomBeltBookMark()
	{
		BeltBookMarkList:Clear
		EVE:GetBookmarks[BeltBookMarkList]

		variable int RandomBelt
		variable string Label
		variable string prefix

		variable int count
		variable int used

		if ${Config.Miner.IceMining}
		{
			prefix:Set[${Config.Labels.IceBeltPrefix}]
		}
		else
		{
			prefix:Set[${Config.Labels.OreBeltPrefix}]
		}
		used:Set[${BeltBookMarkList.Used}]
		/* Let's eliminate all bookmarks that don't match our prefix 
		/* and system first. */
		for ( count:Set[1] ; ${count} <= ${used} ; count:Inc )
		{
			Label:Set[${BeltBookMarkList[${count}].Label}]
			if (${BeltBookMarkList[${count}].SolarSystemID} != ${Me.SolarSystemID} || \
				${Label.Left[${prefix.Length}].NotEqual[${prefix}]})
			{
				BeltBookMarkList:Remove[${count}]
				continue
			}
		}
		BeltBookMarkList:Collapse
		variable float Distance
		do
		{
			RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used(int):Dec}]:Inc[1]}]

			Label:Set[${BeltBookMarkList[${RandomBelt}].Label}]
			if ${BeltBookMarkList[${RandomBelt}].X(exists)}
				Distance:Set[${Math.Distance[${BeltBookMarkList[${RandomBelt}].X},${BeltBookMarkList[${RandomBelt}].Y},${BeltBookMarkList[${RandomBelt}].Z},${Me.ToEntity.X},${Me.ToEntity.Y},${Me.ToEntity.Z}]}]
			else
				Distance:Set[${Math.Distance[${BeltBookMarkList[${RandomBelt}].ToEntity.X},${BeltBookMarkList[${RandomBelt}].ToEntity.Y},${BeltBookMarkList[${RandomBelt}].ToEntity.Z},${Me.ToEntity.X},${Me.ToEntity.Y},${Me.ToEntity.Z}]}]

			if ${Distance} > WARP_RANGE
			{
				break
			}
		}
		while ${BeltBookMarkList.Used} > 1

		if ${BeltBookMarkList.Used} /* If it's 0, we don't have any matching bookmarks, don't try to set autopilot to NULL. */
		{
			call Ship.WarpToBookMark ${BeltBookMarkList[${RandomBelt}].ID}

			This.BeltArrivalTime:Set[${Time.Timestamp}]
			This.LastBookMarkIndex:Set[${RandomBelt}]
			This.UsingBookMarks:Set[TRUE]
		}
		else
		{
			UI:UpdateConsole["DEBUG: obj_Asteroids:MoveToRandomBeltBookMark: No belt bookmarks found!",LOG_DEBUG]
		}
		return
	}

	function MoveToField(bool ForceMove)
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
				call TargetNext TRUE
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

				UI:UpdateConsole["Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"]
				call Ship.WarpToID ${Belts[${curBelt}].ID}
				This.BeltArrivalTime:Set[${Time.Timestamp}]
				This.UsingMookMarks:Set[TRUE]
				This.LastBeltIndex:Set[${curBelt}]
			}
			else
			{
				UI:UpdateConsole["Staying at Asteroid Belt: ${BeltIterator.Value.Name}"]
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

	function UpdateList()
	{
		variable index:entity asteroid_index
		variable index:entity AsteroidList_outofrange
		variable iterator asteroid_iterator

		This.MaxDistanceToAsteroid:Set[${Math.Calc[${Ship.OptimalMiningRange} * ${Config.Miner.MiningRangeMultipler}]}]

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
				EVE:QueryEntities[asteroid_index, "CategoryID = ${This.AsteroidCategoryID} && Name =- \"${This.OreTypeIterator.Key}\""]
				asteroid_index:GetIterator[asteroid_iterator]
				if ${asteroid_iterator:First(exists)}
				{
					do
					{
						/* This is intended to get the best ore in the system before others do.  Its not
							intended to empty a given radius of asteroids */
						if ${Config.Miner.StripMine}
						{
							if ${asteroid_iterator.Value.Distance} < ${Ship.OptimalMiningRange}
							{
								This.AsteroidList:Insert[${asteroid_iterator.Value.ID}]
							}
							else
							{
								AsteroidList_outofrange:Insert[${asteroid_iterator.Value.ID}]
							}
						}
						else
						{
							This.AsteroidList:Insert[${asteroid_iterator.Value.ID}]
						}
					}
					while ${asteroid_iterator:Next(exists)}
				}
			}
			while ${This.AsteroidList.Used} < ${Ship.TotalMiningLasers} && ${This.OreTypeIterator:Next(exists)}

			if ${Config.Miner.StripMine}
			{
				/* Append the OOR index to the good one */
				AsteroidList_outofrange:GetIterator[asteroid_iterator]
				if ${asteroid_iterator:First(exists)}
				{
					do
					{
						This.AsteroidList:Insert[${asteroid_iterator.Value.ID}]
					}
					while ${asteroid_iterator:Next(exists)}
				}
			}
		}
		else
		{
			echo "WARNING: obj_Asteroids: Ore Type list is empty, please check config"
		}
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

	function:bool TargetNext(bool CalledFromMoveRoutine=FALSE)
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
					${AsteroidIterator.Value.Distance} < ${Me.Ship.MaxTargetRange} && \
					( !${Me.ActiveTarget(exists)} || ${AsteroidIterator.Value.DistanceTo[${Me.ActiveTarget.ID}]} <= ${Math.Calc[${Ship.OptimalMiningRange}* 1.1]} )
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
				UI:UpdateConsole["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]

				;; This member does not exist in obj_Combat!!  -- GP
				;;while ${Combat.CombatPause}
				;;{
				;;	wait 30
				;;	echo "DEBUG: Obj_Asteroids In Combat Pause Loop"
				;;}

				AsteroidIterator.Value:LockTarget
				do
				{
				  wait 30
				}
				while ${Me.TargetingCount} > 0

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
							call Ship.Approach ${AsteroidIterator.Value.ID} ${Ship.OptimalMiningRange}
						}
						else
						{
							UI:UpdateConsole["obj_Asteroids: TargetNext: No Asteroids within ${EVEBot.MetersToKM_Str[${This.MaxDistanceToAsteroid}], changing fields."]
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
				This:BeltIsEmpty["${Entity[GroupID = GROUP_ASTEROIDBELT]}"]
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
}
