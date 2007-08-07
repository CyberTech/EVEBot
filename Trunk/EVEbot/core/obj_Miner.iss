/*
	Miner Class
	
	Primary Miner hebavior module for EVEBot
	
	-- CyberTech

BUGS:
	Shield Booster sometimes ends up disabled. This is a must-have, verify it every so often.

*/

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
		
		while !${Miner.Abort} && \
				${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
		{				
			if !${Ship.InWarp} && \
				${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers}
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
	
						call Ship.Approach ${TargetID} ${Ship.OptimalMiningRange}
						call Ship.ActivateFreeMiningLaser
					}
				}
				while ${Target:Next(exists)}
				
				; TODO - Put multiple lasers on a roid as a fallback if we end up with more lasers than targets -- CyberTech
			}
	
			if ${Me.GetTargets} < ${Ship.SafeMaxLockedTargets}
			{
				do
				{
				 	wait 20
				}
				while ${Me.GetTargeting} > 0			
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
