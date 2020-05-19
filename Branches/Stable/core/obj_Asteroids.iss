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

	variable index:string EmptyBeltList
	variable iterator EmptyBelt

	variable index:bookmark BeltBookMarkList
	variable iterator BeltBookMarkIterator
	variable int LastBookMarkIndex
	variable int LastBeltIndex
	variable bool UsingBookMarks = FALSE
	variable time BeltArrivalTime

	variable int LastSurveyScanResultCount = 0
	variable time LastSurveyScanResultTime

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Event[EVE_OnSurveyScanData]:AttachAtom[This:OnSurveyScanData]
		LavishScript:RegisterEvent[EVEBot_ClaimAsteroid]

		Event[EVEBot_ClaimAsteroid]:AttachAtom[This:OnEVEBot_ClaimAsteroid]

		UI:UpdateConsole["obj_Asteroids: Initialized", LOG_MINOR]
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
		UI:UpdateConsole["obj_Asteroids: Survey Scan data received for ${LastSurveyScanResultCount} asteroids", LOG_DEBUG]
	}

	method OnEVEBot_ClaimAsteroid(int64 ClaimerID, int64 AsteroidID)
	{
		if ${ClaimerID} != ${Me.ID}
		{
			AsteroidList_Claimed:Add[${AsteroidID}]
		}
	}

	; Checks the belt name against the empty belt list.
	member IsBeltMarkedEmpty(string BeltName)
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
				echo "DEBUG: obj_Asteroid:IsBeltMarkedEmpty - ${BeltName} - TRUE"
				return TRUE
			}
		}
		while ${EmptyBelt:Next(exists)}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method MarkBeltAsEmpty(string BeltName)
	{
		if ${BeltName(exists)}
		{
			EmptyBeltList:Insert[${BeltName}]
			UI:UpdateConsole["Excluding empty belt ${BeltName}"]
		}
	}

	; TODO - remove this from here -- move to obj_Belts - CT
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
			Ship:Activate_SurveyScanner

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

	; Pick the nearest appropriate asteroid from AsteroidList; checking claimed list and ranges.
	; If MaxDistance is 0, use natural targetng/laser range and check distance to existing roids
	; If MaxDistance is > 0, use only MaxDistance, and not the above -- intended to pick a roid to which to slowboat
	member:int64 NearestAsteroid(int64 MaxDistance=0)
	{
		variable iterator AsteroidIterator

		AsteroidList:GetIterator[AsteroidIterator]
		if !${AsteroidIterator:First(exists)}
		{
			return -1
		}

		; Iterate thru the asteroid list, and find the first one that isn't excluded for obvious reasons.
			; Yes, this could be one giant if statement. It was harder to follow, with the bool inversions etc.
		do
		{
			if !${Entity[${AsteroidIterator.Value.ID}](exists)}
			{
				continue
			}
			if ${AsteroidList_Claimed.Contains[${AsteroidIterator.Value.ID}]}
			{
				; Someone else claimed it first. Oh, the vogonity!
				continue
			}
			if ${AsteroidIterator.Value.IsLockedTarget} || ${AsteroidIterator.Value.BeingTargeted}
			{
				continue
			}
			if ${MaxDistance} == 0
			{
				if ${AsteroidIterator.Value.Distance} >= ${Ship.OptimalMiningRange}
				{
					continue
				}
				variable index:entity MyTargets
				variable iterator MyTarget
				Me:GetTargets[MyTargets]
				MyTargets:GetIterator[MyTarget]
				variable bool AbortLoop = FALSE

				if ${MyTarget:First(exists)}
				{
					do
					{
						if ${AsteroidIterator.Value.DistanceTo[${MyTarget.Value.ID}]} > ${Ship.OptimalMiningRange}
						{
							; We have a locked asteroid that's too far from this one;  No, this is not perfect because we don't know our position
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
			else
			{
				if ${AsteroidIterator.Value.Distance} >= ${MaxDistance}
				{
					continue
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
		variable int curBelt
		variable index:entity Belts
		variable iterator BeltIterator
		variable int TryCount
		variable string beltsubstring
		variable bool AsteroidsInRange = FALSE

		if !${ForceMove}
		{
			if ${This.NearestAsteroid[${This.MaxTravelDistanceToAsteroid}]} == -1
			{
				UI:UpdateConsole["ERROR: OBJ_Asteroids:MoveToField: Belt is not empty and ForceMove not set, staying at Asteroid Belt: ${BeltIterator.Value.Name}", LOG_CRITICAL]
				return
			}
		}

		; Using Last Position Bookmarks? Warp to and return
		if (${Config.Miner.BookMarkLastPosition} && ${Bookmarks.StoredLocationExists})
		{
			/* We have a stored location, we should return to it. */
			UI:UpdateConsole["Returning to last location (${Bookmarks.StoredLocation})"]
			call Ship.TravelToSystem ${EVE.Bookmark[${Bookmarks.StoredLocation}].SolarSystemID}
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

		; Bookmarks aren't being used; check for belts in entity list
		beltsubstring:Set["ASTEROID BELT"]
		if ${Config.Miner.IceMining}
		{
			beltsubstring:Set["ICE FIELD"]
		}

		EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT && Name =- \"${beltsubstring}\""]
		Belts:GetIterator[BeltIterator]
		if !${BeltIterator:First(exists)}
		{
			UI:UpdateConsole["ERROR: OBJ_Asteroids:MoveToField: No asteroid belts or belt bookmarks found...", LOG_CRITICAL]
			#if EVEBOT_DEBUG
			UI:UpdateConsole["OBJ_Asteroids:MoveToField: Total Entities: ${EVE.EntitiesCount}", LOG_DEBUG]
			UI:UpdateConsole["OBJ_Asteroids:MoveToField: Size of Belts List ${Belts.Used}", LOG_DEBUG]
			#endif
			EVEBot.ReturnToStation:Set[TRUE]
			return
		}

		; Belt list is populated, let's pick a belt
		do
		{
			curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
			TryCount:Inc
			if ${TryCount} > ${Math.Calc[${Belts.Used} * 10]}
			{
				UI:UpdateConsole["All belts marked empty, returning to station"]
				call ChatIRC.Say "All belts marked empty!"
				EVEBot.ReturnToStation:Set[TRUE]
				return
			}
		}
		while ( ${This.IsBeltMarkedEmpty[${Belts[${curBelt}].Name}]} )

		UI:UpdateConsole["Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"]
		call Ship.WarpToID ${Belts[${curBelt}].ID} 0 ${FleetWarp}
		Ship:Activate_SurveyScanner

		This.BeltArrivalTime:Set[${Time.Timestamp}]
		This.UsingBookMarks:Set[TRUE]
		This.LastBeltIndex:Set[${curBelt}]

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
			variable index:entity AsteroidList_OutOfRange
			variable index:entity AsteroidList_OutOfRangeTmp
			variable iterator AsteroidIt
			variable int Count_InRange
			variable int Count_OOR

			This.AsteroidList:Clear

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
					EVE:QueryEntities[AsteroidListTmp, ${QueryStrPrefix}]
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

			UI:UpdateConsole["obj_Asteroids:UpdateList: ${AsteroidList.Used} (In Range: ${Count_InRange} OOR: ${Count_OOR}) asteroids found", LOG_DEBUG]
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
				UI:UpdateConsole["Locking Asteroid ${AsteroidIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
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
			UI:UpdateConsole["obj_Asteroids: No Asteroids within overview range"]
			if ${Entity["GroupID = GROUP_ASTEROIDBELT"].Distance} < CONFIG_OVERVIEW_RANGE
			{
				This:MarkBeltAsEmpty["${Entity[GroupID = GROUP_ASTEROIDBELT].Name}"]
			}
			return FALSE
		}

		TargetAsteroid:Set[${This.NearestAsteroid[]}]
		if ${TargetAsteroid} != -1
		{
			UI:UpdateConsole["Locking Asteroid ${TargetAsteroid}:${Entity[${TargetAsteroid}].Name}: ${EVEBot.MetersToKM_Str[${Entity[${TargetAsteroid}].Distance}]}"]
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
			UI:UpdateConsole["obj_Asteroids: TargetNext: No unlocked asteroids in range, but Miner is approaching something.", LOG_DEBUG]
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
			UI:UpdateConsole["obj_Asteroids: TargetNext: No unlocked asteroids in range & All lasers idle: Approaching ${TargetAsteroid}:${Entity[${TargetAsteroid}].Name}: ${EVEBot.MetersToKM_Str[${Entity[${TargetAsteroid}].Distance}]}"]
			if ${MyShip.MaxTargetRange} < ${Ship.OptimalMiningRange}
			{
				call Ship.Approach ${TargetAsteroid} ${Math.Calc[${MyShip.MaxTargetRange} - 5000]}
			}
			else
			{
				call Ship.Approach ${TargetAsteroid} ${Ship.OptimalMiningRange}
			}

			UI:UpdateConsole["Locking Asteroid ${TargetAsteroid}:${Entity[${TargetAsteroid}].Name}: ${EVEBot.MetersToKM_Str[${Entity[${TargetAsteroid}].Distance}]}"]
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

		UI:UpdateConsole["obj_Asteroids: TargetNext: No Asteroids within ${EVEBot.MetersToKM_Str[${This.MaxTravelDistanceToAsteroid}]}"]
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
