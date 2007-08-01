/*
	Asteroids & Miner classes
	
	Interacting with Asteroids & Mining of them
	
	-- CyberTech

BUGS:
	Shield Booster sometimes ends up disabled. This is a must-have, verify it every so often.

	we don't differentiate between ice fields and ore fields, need to match field type to laser type.
			
*/

objectdef obj_Asteroids
{
	variable int AsteroidCategoryID = 25
	
	variable index:entity AstroidList
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
	
	method Initialize()
	{	
		call UpdateHudStatus "obj_Asteroids: Initialized"
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
			call UpdateHudStatus "Excluding empty belt ${BeltName}"
		}
	}
	
	function MoveToRandomBeltBookMark()
	{	
		variable int curBelt	
		EVE:DoGetBookmarks[BeltBookMarkList]
		
		variable int RandomBelt

		RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used}]:Inc[1]}]

		while ${BeltBookMarkList.Used} > 0
		{
			RandomBelt:Set[${Math.Rand[${BeltBookMarkList.Used}]:Inc[1]}]

			variable string Label

			if ${BeltBookMarkList[${curBelt}].SolarSystemID} != ${Me.SolarSystemID}
			{
				continue
			}

			Label:Set[${BeltBookMarkList[${curBelt}].Label}]
			if ${Label.Token[1," "].Equal["Belt:"]} || ${Label.Token[1," "].Equal["Belt"]}
			{
				call UpdateHudStatus "Warping to Bookmark ${Label}"
				call Ship.WarpPrepare
				BeltBookMarkList[${curBelt}]:WarpTo
				call Ship.WarpWait
				This.LastBookMarkIndex:Set[${RandomBelt}]
				This.UsingMookMarks:Set[TRUE]
				return
			}
		}
	}
		
	function MoveToField(bool ForceMove)
	{
		;call MoveToBeltBookMark
		;return
		
		variable int curBelt
		variable index:entity Belts
		variable iterator BeltIterator
		variable int TryCount
	
		EVE:DoGetEntities[Belts,GroupID, GROUPID_ASTEROID_BELT]
		Belts:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			if ${ForceMove} || ${BeltIterator.Value.Distance} > 45000
			{
				; We're not at a field already, so find one
				do
				{
					curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
					TryCount:Inc
					if ${TryCount} > ${Math.Calc[${Belts.Used} * 10]}
					{
						call UpdateHudStatus "All belts empty!"
						Miner.Abort:Set[TRUE]
						return
					}
				}
				while ( !${Belts[${curBelt}].Name.Find[ASTEROID BELT](exists)} || \
						${This.IsBeltEmpty[${Belts[${curBelt}].Name}]} )
				
				call UpdateHudStatus "Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"
				call Ship.WarpToID ${Belts[${curBelt}]}
				This.UsingMookMarks:Set[TRUE]
				This.LastBeltIndex:Set[${curBelt}]
			}
			else
			{
				call UpdateHudStatus "Staying at Asteroid Belt: ${BeltIterator.Value.Name}"
			}		
		}
		else
		{
			echo "ERROR: oMining:Mine --> No asteroid belts in the area..."
			play:Set[FALSE]
			return
		}
	}
	
	function UpdateList()
	{
		Config.Miner.OreTypesRef:GetSettingIterator[This.OreTypeIterator]
		
		if ${This.OreTypeIterator:First(exists)}
		{
			do
			{
				;echo "DEBUG: obj_Asteroids: Checking for Ore Type ${This.OreTypeIterator.Key}"
				This.AstroidList:Clear
				EVE:DoGetEntities[This.AstroidList,CategoryID,${This.AsteroidCategoryID},${This.OreTypeIterator.Key}]
				wait 0.5
			}
			while ${This.AstroidList.Used} == 0 && ${This.OreTypeIterator:Next(exists)}
			
			if ${This.AstroidList.Used}
			{
					AsteroidList:GetSettingIterator[This.NextAsteroidIterator]
					echo "DEBUG: obj_Asteroids:UpdateList - Found ${This.AstroidList.Used} ${This.OreTypeIterator.Key} asteroids"
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

		This.AstroidList:GetIterator[AsteroidIterator]		
		if ${AsteroidIterator:First(exists)}
		{
			do
			{
				if ${Entity[${AsteroidIterator.Value}](exists)} && \
					!${AsteroidIterator.Value.IsLockedTarget} && \
					!${AsteroidIterator.Value.BeingTargeted} && \
					${AsteroidIterator.Value.Distance} < ${Me.Ship.MaxTargetRange} && \
					( !${Me.ActiveTarget(exists)} || ${AsteroidIterator.Value.DistanceTo[${Me.ActiveTarget.ID}]} <= ${Math.Calc[${Ship.OptimalMiningRange}* 1.3]} )
				{
						break
				}
			}
			while ${AsteroidIterator:Next(exists)}

			if ${Entity[${AsteroidIterator.Value}](exists)}
			{
				if ${AsteroidIterator.Value.IsLockedTarget} || \
					${AsteroidIterator.Value.BeingTargeted}
				{
					return TRUE
				}
				call UpdateHudStatus "Locking Asteroid ${AsteroidIterator.Value.Name}: ${Misc.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"
				AsteroidIterator.Value:LockTarget
				wait 30
				call This.UpdateList
				return TRUE
			}
			else
			{
				call This.UpdateList
				if ${Ship.TotalActivatedMiningLasers} == 0				
				{
					This.AstroidList:GetIterator[AsteroidIterator]
					AsteroidIterator:First
					variable int64 Distance
					Distance:Set[${AsteroidIterator.Value.Distance.Ceil}]
					call UpdateHudStatus "obj_Asteroids: TargetNext: No Asteroids in range & All lasers idle - Approaching nearest: ${Misc.MetersToKM_Str[${Distance}]} ETA: ${Math.Calc[${Distance}/${Me.Ship.MaxVelocity}].Ceil}s"
					call Ship.Approach ${AsteroidIterator.Value}
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

objectdef obj_Miner
{
	variable index:entity LockedTargets
	variable iterator Target
	variable int TotalTrips = 0						/* Total Times we've had to transfer to hanger */
	variable time TripStartTime
	variable int PreviousTripSeconds = 0
	variable int TotalTripSeconds = 0
	variable int AverageTripSeconds = 0
	variable int Abort = FALSE

	; Are we running out of asteroids to target?
	variable bool InsufficientAsteroids = FALSE
	
	method Initialize()
	{
		This.TripStartTime:Set[${Time.Timestamp}]
		call UpdateHudStatus "obj_Miner: Initialized"
	}
	
	; Enable defenses, launch drones
	function Prepare_Environment()
	{
		Ship:ActivateShieldRegenModules[]
		Ship.Drones:LaunchAll[]
		call Ship.OpenCargo
	}
	
	function Cleanup_Environment()
	{
		call Ship.Drones.ReturnAllToDroneBay
		Ship:UnlockAllTargets[]
		call Ship.CloseCargo

	}
	
	function Statslog()
	{
		variable string Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int.LeadingZeroes[2]}
		variable string Minutes = ${Math.Calc[(${Script.RunningTime}/1000/60)%60].Int.LeadingZeroes[2]}
		variable string Seconds = ${Math.Calc[(${Script.RunningTime}/1000)%60].Int.LeadingZeroes[2]}
		
		call UpdateStatStatus "Run ${This.TotalTrips} Done - Took ${This.PreviousTripSeconds} Seconds"
		call UpdateStatStatus "Total Run Time: ${Hours}:${Minutes}:${Seconds} - Average Run Time: ${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]} Seconds"
	} 
	
	function Mine()
	{
		
		This.TripStartTime:Set[${Time.Timestamp}]
		; Find an asteroid field, or stay at current one if we're near one.
		call Asteroids.MoveToField FALSE
		call This.Prepare_Environment
		call Asteroids.UpdateList
		
		while !${Miner.Abort} && ${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
		{				
			if !${Ship.InWarp} && ${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers}
			{
				; We've got idle lasers, and available targets. Do something with them.
	
				Me:DoGetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				if ${Target:First(exists)}
				do
				{
					if ${Target.Value.CategoryID} != ${Asteroids.AsteroidCategoryID}
					{
						continue
					}
					variable int TargetID
					TargetID:Set[${Target.Value.ID}]
					if ( ${This.InsufficientAsteroids} || \
						!${Ship.IsMiningAstroidID[${TargetID}]} )
					{
						Target.Value:MakeActiveTarget
						wait 20
	
						if ${Target.Value(exists)} && \
							${Target.Value.Distance} > ${Ship.OptimalMiningRange}
						{
							while ${Target.Value(exists)} && \
									${Target.Value.Distance} > ${Ship.OptimalMiningRange}
							{
								call Ship.Approach ${TargetID}
							}
							
							EVE:Execute[CmdStopShip]
						}
						call Ship.ActivateFreeMiningLaser
					}
				}
				while ${Target:Next(exists)}
				
				; TODO - Put multiple lasers on a roid as a fallback if we end up with more lasers than targets -- CyberTech
			}
	
			if ${Me.GetTargets} < ${Ship.SafeMaxLockedTargets}
			{
				echo Target Locking: ${Me.GetTargets} out of ${Ship.SafeMaxLockedTargets}
				call Asteroids.TargetNext
				This.InsufficientAsteroids:Set[!${Return}]
			}
		}
	
		call This.Cleanup_Environment
		This.TotalTrips:Inc
		This.PreviousTripSeconds:Set[${This.TripDuration}]
		This.TotalTripSeconds:Inc[${This.PreviousTripSeconds}]
		This.AverageTripSeconds:Set[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]
		call UpdateHudStatus "Cargo Hold has reached threshold, returning"
		call This.Statslog

	}

	member:int TripDuration()
	{
		return ${Math.Calc[${Time.Timestamp} - ${This.TripStartTime.Timestamp}]}
	}
	
	member:float VolumePerCycle(string AsteroidType)
	{
	}
	

}
