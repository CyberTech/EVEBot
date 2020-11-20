/*
	Asteroids Class
		Handles selection & prioritization of asteroid fields and asteroids, as well as targeting of same.

	AsteroidGroup Class
		Handles information about a group of asteroids for weighting purposes

	-- CyberTech

*/

objectdef obj_Asteroids
{
	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 30

	variable int AsteroidCategoryID = 25

	variable index:entity AsteroidList_Surveyed
	variable index:entity AsteroidList
	; List of asteroids claimed by other bots
	variable set AsteroidList_Claimed

	variable index:bookmark BeltBookMarkList
	variable iterator BeltBookMarkIterator
	variable int64 LastBookMarkID
	variable time BeltArrivalTime

	variable int LastSurveyScanResultCount = 0
	variable time LastSurveyScanResultTime

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Event[EVE_OnSurveyScanData]:AttachAtom[This:OnSurveyScanData]
		LavishScript:RegisterEvent[EVEBot_ClaimAsteroid]

		Event[EVEBot_ClaimAsteroid]:AttachAtom[This:OnEVEBot_ClaimAsteroid]

		Logger:Log["obj_Asteroids: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVE_OnSurveyScanData]:DetachAtom[This:OnSurveyScanData]
		Event[EVEBot_ClaimAsteroid]:DetachAtom[This:OnEVEBot_ClaimAsteroid]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			variable iterator ClaimedRoids
			AsteroidList_Claimed:GetIterator[claimed]

			; Prune asteroids from the list that have poofed
			if ${ClaimedRoids:First(exists)}
			do
			{
				if !${Entity[${ClaimedRoids.Value}](exists)}
				{
					AsteroidList_Claimed:Remove[${ClaimedRoids.Value}]
				}
			}
			while ${ClaimedRoids:Next(exists)}


			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method OnSurveyScanData(int ResultCount)
	{
		LastSurveyScanResultTime:Set[${Time.Timestamp}]
		LastSurveyScanResultCount:Set[${ResultCount}]
		Logger:Log["obj_Asteroids: Survey Scan data received for ${LastSurveyScanResultCount} asteroids", LOG_DEBUG]
	}

	method OnEVEBot_ClaimAsteroid(int64 ClaimerID, int64 AsteroidID)
	{
		if ${ClaimerID} != ${Me.ID}
		{
			AsteroidList_Claimed:Add[${AsteroidID}]
		}
	}

	; TODO - remove this from here -- move to obj_Belts - CT
	function MoveToRandomBeltBookMark(bool FleetWarp=FALSE)
	{
		variable int RandomBelt = 0
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

		if !${prefix.NotNULLOrEmpty}
		{
			Logger:Log["MoveToRandomBeltBookMark: Bookmark prefix is empty, ignoring call", LOG_ERROR]
			return FALSE
		}

		EVE:RefreshBookmarks
		wait 10
		EVE:GetBookmarks[BeltBookMarkList]
		Logger:Log["MoveToRandomBeltBookMark: Found ${BeltBookMarkList.Used} total bookmarks", LOG_DEBUG]

		Logger:Log["MoveToRandomBeltBookMark: Removing bookmarks not in system, too close, and last used", LOG_DEBUG]
		BeltBookMarkList:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID != "${Me.SolarSystemID}"]}]
		BeltBookMarkList:RemoveByQuery[${LavishScript.CreateQuery[Distance <= WARP_RANGE]}]
		BeltBookMarkList:RemoveByQuery[${LavishScript.CreateQuery[ID = ${This.LastBookMarkID}]}]
		BeltBookMarkList:Collapse

		Logger:Log["MoveToRandomBeltBookMark: Found ${BeltBookMarkList.Used} possible bookmarks, filtering by prefix ${prefix}", LOG_DEBUG]

		while ${BeltBookMarkList.Used} > 0
		{
			RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used}]:Inc[1]}]
			Label:Set[${BeltBookMarkList[${RandomBelt}].Label}]

			; TODO - move this to RemoveByQuery when string.StartsWith is pushed to InnerSpace live
			if ${Label.Left[${prefix.Length}].NotEqual[${prefix}]}
			{
				Logger:Log["MoveToRandomBeltBookMark: Removing ${Label} - missing prefix ${prefix}", LOG_DEBUG]

				BeltBookMarkList:Remove[${RandomBelt}]
				BeltBookMarkList:Collapse
				RandomBelt:Set[0]
				continue
			}
			break
		}

		if ${BeltBookMarkList.Used} >= ${RandomBelt}
		{
			Logger:Log["MoveToRandomBeltBookMark: Calling WarpToBookMarkName ${BeltBookMarkList[${RandomBelt}].Label} ${FleetWarp}", LOG_DEBUG]
			call Ship.WarpToBookMark ${BeltBookMarkList[${RandomBelt}].ID} ${FleetWarp}
			Ship:Activate_SurveyScanner

			This.BeltArrivalTime:Set[${Time.Timestamp}]
			This.LastBookMarkID:Set[${BeltBookMarkList[${RandomBelt}].ID}]
			return TRUE
		}
		else
		{
			Logger:Log["DEBUG: obj_Asteroids:MoveToRandomBeltBookMark: No belt bookmarks found!", LOG_DEBUG]
		}
		return FALSE
	}

	; Pick the nearest appropriate asteroid from AsteroidList; checking claimed list and ranges.
	; If MaxDistance is 0, use natural targetng/laser range and check distance to existing roids
	; If MaxDistance is > 0, use only MaxDistance, and not the above -- intended to pick a roid to which to slowboat
	member:int64 NearestAsteroid(int64 MaxDistance=0, bool IgnoreClaimedStatus=FALSE)
	{
		variable iterator AsteroidIterator

		AsteroidList:GetIterator[AsteroidIterator]
		if !${AsteroidIterator:First(exists)}
		{
			Logger:Log["DEBUG: obj_Asteroids:NearestAsteroid: Asteroid List empty", LOG_DEBUG]
			return -1
		}

		if ${MaxDistance} == 0
		{
			MaxDistance:Set[${Ship.OptimalMiningRange}]
		}

		; Iterate thru the asteroid list, and find the first one that isn't excluded for obvious reasons.
		; Yes, this could be one giant if statement. It was harder to follow, with the bool inversions etc.
		do
		{
			if !${Entity[${AsteroidIterator.Value.ID}](exists)}
			{
				Logger:Log["DEBUG: obj_Asteroids:NearestAsteroid: Skipping ${AsteroidIterator.Value.ID} (Entity)", LOG_DEBUG]
				continue
			}
			if !${IgnoreClaimedStatus} && ${AsteroidList_Claimed.Contains[${AsteroidIterator.Value.ID}]}
			{
				; Someone else claimed it first. Oh, the vogonity!
				Logger:Log["DEBUG: obj_Asteroids:NearestAsteroid: Skipping ${AsteroidIterator.Value.ID} (Claimed)", LOG_DEBUG]
				continue
			}
			if ${AsteroidIterator.Value.IsLockedTarget} || ${AsteroidIterator.Value.BeingTargeted}
			{
				Logger:Log["DEBUG: obj_Asteroids:NearestAsteroid: Skipping ${AsteroidIterator.Value.ID} (locked/beinglocked)", LOG_DEBUG]
				continue
			}
			; Now check regular distance
			if ${AsteroidIterator.Value.Distance} >= ${MaxDistance}
			{
				Logger:Log["DEBUG: obj_Asteroids:NearestAsteroid: Skipping ${AsteroidIterator.Value.ID} (Distance > ${MaxDistance})", LOG_DEBUG]
				continue
			}

			; Check to see if we need to exclude this based on distance to ALL currently locked asteroids
			; If the candidate roid isn't within 75% of our mining range to all locked roids, skip it
			; A 14.5km Me 14.5km B
			; A <> B 29km
			variable index:entity MyTargets
			variable iterator MyTarget
			variable bool AbortLoop = FALSE
			variable float MaxDistFromTarget
			MaxDistFromTarget:Set[${Math.Calc[${Ship.OptimalMiningRange} * 0.75]}]
			Me:GetTargets[MyTargets]
			MyTargets:GetIterator[MyTarget]
			if ${AsteroidIterator.Value.Distance} > ${Ship.OptimalMiningRange}
			{
				; Only run this if the potential asteroid is going to require movement.
				if ${MyTarget:First(exists)}
				{
					do
					{
						if ${AsteroidIterator.Value.DistanceTo[${MyTarget.Value.ID}]} > ${MaxDistFromTarget}
						{
							; We have a locked asteroid that's too far from this one;  No, this is not perfect because we don't know our position
							Logger:Log["DEBUG: obj_Asteroids:NearestAsteroid: Skipping ${AsteroidIterator.Value.ID} (Distance from target ${MyTarget.Value.ID} > ${MaxDistFromTarget})", LOG_DEBUG]
							AbortLoop:Set[TRUE]
							break
						}
					}
					while ${MyTarget:Next(exists)}
					if ${AbortLoop}
					{
						continue
					}
				}
			}
			; Otherwise, we've reached a potential asteroid we can use.
			break
		}
		while ${AsteroidIterator:Next(exists)}

		if ${AsteroidIterator.Value(exists)} && ${Entity[${AsteroidIterator.Value.ID}](exists)}
		{
			return ${AsteroidIterator.Value.ID}
		}

		return -1
	}

	member:int64 MaxTravelDistanceToAsteroid()
	{
		if ${Ship.OptimalMiningRange} == 0 && ${Config.Miner.OrcaMode}
		{
			return ${Math.Calc[20000 * ${Config.Miner.MiningRangeMultipler}]}
		}
		else
		{
			return ${Math.Calc[${Ship.OptimalMiningRange} * ${Config.Miner.MiningRangeMultipler}]}
		}
	}

	function MoveToField(bool ForceMove, bool DoNotLockTarget=FALSE, bool FleetWarp=FALSE)
	{
		if !${ForceMove}
		{
			if ${This.NearestAsteroid[${This.MaxTravelDistanceToAsteroid}]} == -1
			{
				Logger:Log["ERROR: OBJ_Asteroids:MoveToField: Belt is not empty and ForceMove not set, staying here", LOG_CRITICAL]
				return
			}
		}

		; Using Last Position Bookmarks? If we have one, return to it
		if (${Config.Miner.BookMarkLastPosition} && ${Bookmarks.StoredLocationExists})
		{
			/* We have a stored location, we should return to it. */
			Logger:Log["Returning to last location (${Bookmarks.StoredLocation})"]
			call Ship.WarpToBookMarkName "${Bookmarks.StoredLocation}" ${FleetWarp}
			Ship:Activate_SurveyScanner

			This.BeltArrivalTime:Set[${Time.Timestamp}]
			Bookmarks:RemoveStoredLocation
			return
		}

		; Using Asteroid Field Bookmarks? Warp to and return
		if ${Config.Miner.UseFieldBookmarks}
		{
			call This.MoveToRandomBeltBookMark ${FleetWarp}
			return
		}

		Belts:Next
		if !${Belts.Valid}
		{
			return
		}

		call Belts.WarpTo 0
		if ${Belts.AtBelt}
		{
			Ship:Activate_SurveyScanner
			This.BeltArrivalTime:Set[${Time.Timestamp}]
		}
		else
		{
			Logger:Log["obj_Asteroids:MoveToField: Expected to be at ${Belts.Name}, but AtBelt is ${Belts.AtBelt}", LOG_WARNING]
		}
	}

	function UpdateList(int64 EntityIDForDistance=-1)
	{
		variable iterator OreTypeIterator

		if ${Config.Miner.IceMining}
		{
			Config.Miner.IceTypesRef:GetSettingIterator[OreTypeIterator]
		}
		else
		{
			Config.Miner.OreTypesRef:GetSettingIterator[OreTypeIterator]
		}

		if ${OreTypeIterator:First(exists)}
		{
			variable index:entity AsteroidListTmp
			variable index:entity AsteroidList_TotalIRTmp
			variable index:entity AsteroidList_OutOfRange
			variable index:entity AsteroidList_OutOfRangeTmp
			variable iterator AsteroidIt
			variable int Count_InRange
			variable int Count_OOR

			This.AsteroidList:Clear
; This is adding duplicates because the oretypes are treated as substrings
			do
			{
				variable string QueryStrPrefix
				QueryStrPrefix:Set["CategoryID = ${This.AsteroidCategoryID} && Name =- \"${OreTypeIterator.Key}\""]
				; This is intended to get the desired ore in the system before others do.  Its not
				; intended to empty a given radius of asteroids
				if ${Config.Miner.StripMine}
				{
					if ${EntityIDForDistance} < 0
					{
						EVE:QueryEntities[AsteroidListTmp, "${QueryStrPrefix} && Distance < ${Ship.OptimalMiningRange}"]
						EVE:QueryEntities[AsteroidList_OutOfRangeTmp, "${QueryStrPrefix} && Distance >= ${Ship.OptimalMiningRange} && Distance < ${This.MaxTravelDistanceToAsteroid}"]
					}
					else
					{
						EVE:QueryEntities[AsteroidListTmp, "${QueryStrPrefix} && DistanceTo[${EntityIDForDistance}] < ${Math.Calc[${Ship.OptimalMiningRange} + 2000]}"]
						EVE:QueryEntities[AsteroidList_OutOfRangeTmp, "${QueryStrPrefix} && DistanceTo[${EntityIDForDistance}] >= ${Math.Calc[${Ship.OptimalMiningRange} + 2000]} && DistanceTo[${EntityIDForDistance}] < ${This.MaxTravelDistanceToAsteroid}"]
					}
				}
				else
				{
					EVE:QueryEntities[AsteroidListTmp, "${QueryStrPrefix} && Distance < ${This.MaxTravelDistanceToAsteroid}"]
				}

				Count_InRange:Inc[${AsteroidListTmp.Used}]
				Count_OOR:Inc[${AsteroidList_OutOfRangeTmp.Used}]

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
			while ${OreTypeIterator:Next(exists)}

			; Get the unfiltered asteroid counts in range
			if ${Config.Miner.StripMine}
			{
				if ${EntityIDForDistance} < 0
				{
					EVE:QueryEntities[AsteroidList_TotalIRTmp, "CategoryID = ${This.AsteroidCategoryID} && Distance < ${Ship.OptimalMiningRange}"]
				}
				else
				{
					EVE:QueryEntities[AsteroidList_TotalIRTmp, "CategoryID = ${This.AsteroidCategoryID} && DistanceTo[${EntityIDForDistance}] < ${Math.Calc[${Ship.OptimalMiningRange} + 2000]}"]
				}
			}
			else
			{
				EVE:QueryEntities[AsteroidList_TotalIRTmp, "CategoryID = ${This.AsteroidCategoryID} && Distance < ${This.MaxTravelDistanceToAsteroid}"]
			}

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

			Logger:Log["obj_Asteroids:UpdateList: ${AsteroidList.Used} In Range: ${Count_InRange} OOR: ${Count_OOR} Unfiltered In Range: ${AsteroidList_TotalIRTmp.Used} asteroids found", LOG_DEBUG]
		}
		else
		{
			echo "WARNING: obj_Asteroids: Ore Type list is empty, please check config"
		}
	}

	; FieldEmpty returning TRUE should trigger a belt change.
	member:bool FieldEmpty()
	{
		if ${AsteroidList.Used} == 0 || !${Entity[${AsteroidList.Get[1].ID}](exists)}
		{
			call This.UpdateList
		}

		if ${AsteroidList.Used} == 0
		{
			return TRUE
		}
		return FALSE
	}

	function:bool TargetNextInRange(int64 DistanceToTarget=-1)
	{
		variable iterator AsteroidIterator

		if ${This.FieldEmpty}
		{
			return FALSE
		}

		This.AsteroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
			do
			{
				if ${AsteroidList_Claimed.Contains[${AsteroidIterator.Value.ID}]}
				{
					; Someone else claimed it first. Oh, the vogonity!
					continue
				}

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
									if ${AsteroidIterator.Value.DistanceTo[${Target.Value.ID}]} > ${Math.Calc[${Ship.OptimalMiningRange} * 2]}
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
				if ${AsteroidIterator.Value.IsLockedTarget} || ${AsteroidIterator.Value.BeingTargeted}
				{
					return TRUE
				}

				relay all "Event[EVEBot_ClaimAsteroid]:Execute[${Me.ID}, ${AsteroidIterator.Value.ID}]"
				Logger:Log["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
				AsteroidIterator.Value:LockTarget
				Ship:Activate_SurveyScanner

				return TRUE
			}
		}

		return FALSE
	}

	; Return FALSE if we weren't able to target a new asteroid
	; Return TRUE if we targeted a new asteroid
	; Does not move, except to approach asteroids
	function:bool TargetNext(bool CalledFromMoveRoutine=FALSE, bool DoNotLockTarget=FALSE)
	{
		variable int64 TargetAsteroid

		if ${This.FieldEmpty}
		{
			Logger:Log["obj_Asteroids: No Asteroids within overview range"]
			if ${Entity["GroupID = GROUP_ASTEROIDBELT"].Distance} < CONFIG_OVERVIEW_RANGE
			{
				This:MarkBeltAsEmpty["${Entity[GroupID = GROUP_ASTEROIDBELT].Name}"]
			}
			return FALSE
		}

		TargetAsteroid:Set[${This.NearestAsteroid[]}]
		if ${TargetAsteroid} == -1 && ${AsteroidList_Claimed.Used} > 0
		{
			; Call again, ignoring claimed status. We'll all double up and get out of here faster
			TargetAsteroid:Set[${This.NearestAsteroid[0, TRUE]}]
		}

		if ${TargetAsteroid} != -1
		{
			Logger:Log["Locking Asteroid ${TargetAsteroid}:${Entity[${TargetAsteroid}].Name}: ${EVEBot.MetersToKM_Str[${Entity[${TargetAsteroid}].Distance}]}"]
			relay all "Event[EVEBot_ClaimAsteroid]:Execute[${Me.ID}, ${Entity[${TargetAsteroid}].ID}]"
			Ship:Activate_SurveyScanner
			Entity[${TargetAsteroid}]:LockTarget
			do
			{
			  wait 30
			}
			while ${Me.TargetingCount} > 0
			return TRUE
		}

		if ${Miner.Approaching} != 0
		{
			Logger:Log["obj_Asteroids: TargetNext: No unlocked asteroids in range right now, but Miner is approaching ${Miner.Approaching}:${Entity[${Miner.Approaching}].Name}.", LOG_DEBUG]
			return TRUE
		}

		; If we're here
		;  1) There were no unlocked asteroids inside stationary range, so we need to slowboat or warp
		;  2) We may have locked asteroids that we're already mining; we don't want to move out of range
		; Return FALSE so that Miner concentrates fire on remaining targets
		if ${Ship.TotalActivatedMiningLasers} > 0
		{
			return FALSE
		}

		; Ok, there was nothing in range, we've got no lasers going.
		; Check for asteroids within sloatboat range range
		TargetAsteroid:Set[${This.NearestAsteroid[${This.MaxTravelDistanceToAsteroid}]}]
		if ${TargetAsteroid} != -1
		{
			Logger:Log["obj_Asteroids: TargetNext: No unlocked asteroids in range & All lasers idle: Approaching ${TargetAsteroid}:${Entity[${TargetAsteroid}].Name}: ${EVEBot.MetersToKM_Str[${Entity[${TargetAsteroid}].Distance}]}"]
			Miner:StartApproaching[${TargetAsteroid}]
			return TRUE
		}

		Logger:Log["obj_Asteroids: TargetNext: No Asteroids within ${EVEBot.MetersToKM_Str[${This.MaxTravelDistanceToAsteroid}]}"]
		; Clear the asteroid list. We've been thru it entirely and picked nothing. Force an update.
		This.AsteroidList:Clear
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
