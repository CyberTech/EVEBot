/*
	Asteroids class
	
	Main object for interacting with Asteroids
	
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

	variable index:bookmark BeltBookMarkList
	variable iterator BeltBookMarkIterator
	variable int LastBookMarkIndex
	variable int LastBeltIndex
	variable bool UsingBookMarks = FALSE
	
	method Initialize()
	{	
		call UpdateHudStatus "obj_Asteroids: Initialized"
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
	
		EVE:DoGetEntities[Belts,GroupID,9]
		Belts:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			if ${ForceMove} || ${BeltIterator.Value.Distance} > 25000
			{
				; We're not at a field already, so find one
				curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
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
					( !${Me.ActiveTarget(exists)} || ${AsteroidIterator.Value.DistanceTo[${Me.ActiveTarget.ID}]} <= ${Math.Calc[${Ship.OptimalMiningRange}*1.5]} )
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
				call UpdateHudStatus "Locking Asteroid ${AsteroidIterator.Value.Name} (${AsteroidIterator.Value.Distance.Ceil}m)"
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
					AsteroidIterator:First
					variable float64 Distance = ${AsteroidIterator.Value.Distance.Ceil}
					call UpdateHudStatus "obj_Asteroids: TargetNext: No Asteroids in Targeting Range & Lasers Idle - Approaching nearest: ${Distance}m ETA: ${Math.Calc[${Distance}/${Me.Ship.MaxVelocity}].Ceil}s"
					call Ship.Approach ${AsteroidIterator.Value}
				}
				return FALSE
			}
		}
		else
		{
			echo "DEBUG: obj_Asteroids: No Asteroids within overview range"
			call This.MoveToField TRUE
			return FALSE
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
	
	function Mine()
	{
		
		This.RunStartTime:Set[${Time.Timestamp}]
		; Find an asteroid field, or stay at current one if we're near one.
		call Asteroids.MoveToField FALSE
		call This.Prepare_Environment
		call Asteroids.UpdateList
		
		while ${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
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
					if !${Ship.IsMiningAstroidID[${TargetID}]}
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
			}
		}
	
		call This.Cleanup_Environment
		This.TotalTrips:Inc
		This.PreviousTripSeconds:Set[${This.TripDuration}]
		This.TotalTripSeconds:Inc[${This.PreviousTripSeconds}]
		This.AverageTripSeconds:Set[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]		
		call UpdateHudStatus "Cargo Hold has reached threshold, returning"
	}

	member:int TripDuration()
	{
		return ${Math.Calc[${Time.Timestamp} - ${This.TripStartTime.Timestamp}]}
	}
	
	member:float VolumePerCycle(string AsteroidType)
	{
	}
}
