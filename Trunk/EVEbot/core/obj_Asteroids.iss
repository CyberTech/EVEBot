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
		UI:UpdateConsole["obj_Asteroids: Initialized"]
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
		EVE:DoGetBookmarks[BeltBookMarkList]
		
		variable int RandomBelt

		RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used}]:Inc[1]}]

		while ${BeltBookMarkList.Used} > 0
		{
			RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used}]:Inc[1]}]

			if ${BeltBookMarkList[${RandomBelt}].SolarSystemID} != ${Me.SolarSystemID}
			{
				continue
			}

			variable string Label
			Label:Set[${BeltBookMarkList[${RandomBelt}].Label}]

			variable string prefix
			if ${Config.Miner.IceMining}
			{
				prefix:Set[${Config.Labels.IceBeltPrefix}]
			}
			else
			{
				prefix:Set[${Config.Labels.OreBeltPrefix}]
			}

			if ${Label.Left[${prefix.Length}].Equal[${prefix}]}
			{
				UI:UpdateConsole["Warping to Bookmark ${Label}"]
				call Ship.WarpPrepare
				BeltBookMarkList[${RandomBelt}]:WarpTo
				call Ship.WarpWait
				This.BeltArrivalTime:Set[${Time.Timestamp}]
				This.LastBookMarkIndex:Set[${RandomBelt}]
				This.UsingBookMarks:Set[TRUE]
				return
			}
		}
	}
		
	function MoveToField(bool ForceMove)
	{
		if ${Config.Miner.UseFieldBookmarks}
		{
			call This.MoveToRandomBeltBookMark
			return
		}
		
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
		
		variable int curBelt
		variable index:entity Belts
		variable iterator BeltIterator
		variable int TryCount
		variable string beltsubstring
		
		if ${Config.Miner.IceMining}
		{
			beltsubstring:Set["ICE FIELD"]
		}
		else
		{
			beltsubstring:Set["ASTEROID BELT"]
		}
		
		EVE:DoGetEntities[Belts,GroupID, GROUPID_ASTEROID_BELT]
		Belts:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			if ${ForceMove} || ${BeltIterator.Value.Distance} > 55000
			{
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
				call Ship.WarpToID ${Belts[${curBelt}]}
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
			UI:UpdateConsole["ERROR: oMining:Mine --> No asteroid belts in the area..."]
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
				EVE:DoGetEntities[This.AsteroidList,CategoryID,${This.AsteroidCategoryID},${This.OreTypeIterator.Key}]

				This.AsteroidList:GetIterator[AsteroidIterator]		
				if ${AsteroidIterator:First(exists)}
				do
				{	
					
					This.BestAsteroidList:Insert[${AsteroidIterator.Value}]
				}
				while ${This.Asteroidlist:Next(exists)}
				
				;This.BestAsteroidList:Insert[${This.AsteroidList
				wait 0.5
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
				if ${This.OreTypeIterator.Key.Find[Veldspar]} > 0 && !${Config.Miner.IncludeVeldspar}
				{
					continue
				}
				
				EVE:DoGetEntities[asteroid_index,CategoryID,${This.AsteroidCategoryID}, ${This.OreTypeIterator.Key}]
				asteroid_index:GetIterator[asteroid_iterator]
				if ${asteroid_iterator:First(exists)}
				{
					do
					{
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
	
	function:bool TargetNext()
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
				if ${Entity[${AsteroidIterator.Value}](exists)} && \
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
				${Entity[${AsteroidIterator.Value}](exists)}
			{
				if ${AsteroidIterator.Value.IsLockedTarget} || \
					${AsteroidIterator.Value.BeingTargeted}
				{
					return TRUE
				}
				UI:UpdateConsole["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
				
				while ${Combat.CombatPause}
				{
					wait 30
					echo "DEBUG: Obj_Asteroids In Combat Pause Loop"
				}
								
				AsteroidIterator.Value:LockTarget
				do
				{
				  wait 30
				}
				while ${Me.GetTargeting} > 0
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
							call Ship.Approach ${AsteroidIterator.Value} ${Ship.OptimalMiningRange}
						}
						else
						{
							UI:UpdateConsole["obj_Asteroids: TargetNext: No Asteroids within ${EVEBot.MetersToKM_Str[${This.MaxDistanceToAsteroid}], changing fields."]
							/* The nearest asteroid is farfar away.  Let's just warp out. */
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
			echo "DEBUG: obj_Asteroids: No Asteroids within overview range"
			This:BeltIsEmpty["${Entity[GroupID, GROUPID_ASTEROID_BELT]}"]
			call This.MoveToField TRUE
			return TRUE
		}
		return FALSE
	}
}
