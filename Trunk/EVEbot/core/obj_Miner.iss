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
	variable string m_botState	
	
	; Are we running out of asteroids to target?
	variable bool ConcentrateFire = FALSE
	
	method Initialize()
	{
		This.TripStartTime:Set[${Time.Timestamp}]
		call UpdateHudStatus "obj_Miner: Initialized"
	}
	
	function ProcessState()
	{
		This:SetBotState[]
		
		/* update the global bot state (which is displayed on the UI) */
		botstate:Set[${m_botState}]
		
		switch ${m_botState}
		{
			case IDLE
				break
			case ABORT
				UI:UpdateConsole["Aborting operation: Returning to base"]
				Call Dock
				break
			case BASE
				call Cargo.TransferOreToHangar
				call Ship.Undock
				break
			case COMBAT
				UI:UpdateConsole["FIRE ZE MISSILES!!!"]
				call ShieldNotification
				break
			case MINE
				UI:UpdateConsole["Mining"]
				call Miner.Mine
				break
			case HAUL
				call UpdateHudStatus "Hauling"
				call Hauler.Haul
				break
			case CARGOFULL
				call Dock
				break
			case RUNNING
				call UpdateHudStatus "Running Away"
				call Dock
				ForcedReturn:Set[FALSE]
				break
		}	
	}
	
	method SetBotState()
	{
		if ${ForcedReturn}
		{
			m_botState:Set["RUNNING"]
			return
		}
	
		if ${Miner.Abort} && !${Me.InStation}
		{
			m_botState:Set["ABORT"]
			return
		}
	
		if ${Miner.Abort}
		{
			m_botState:Set["IDLE"]
			return
		}
		
		if ${Me.InStation}
		{
	  		m_botState:Set["BASE"]
	  		return
		}
		
		if (${Me.ToEntity.ShieldPct} < ${MinShieldPct})
		{
			m_botState:Set["COMBAT"]
			return
		}
			
		if ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	m_botState:Set["MINE"]
			return
		}
		
		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${ForcedSell}
		{
			m_botState:Set["CARGOFULL"]
			return
		}
	
		m_botState:Set["None"]
		return
	}

	; Enable defenses, launch drones
	function Prepare_Environment()
	{
		Ship:Activate_Shield_Booster[]
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
		
		call UpdateStatStatus "Run ${This.TotalTrips} Done - Took ${ISXEVE.SecsToString[${This.PreviousTripSeconds}]}"
		call UpdateStatStatus "Total Run Time: ${Hours}:${Minutes}:${Seconds} - Average Run Time: ${ISXEVE.SecsToString[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]}"
	} 
	
	method DroneMining()
	{
		
		
		while (!${Miner.Abort} && \
				${Ship.CargoFreeSpace} >= ${DroneCargoMin})
		{	
			wait 50
			echo "Debug: Test"
		}
		
		call UpdateHudStatus "Recalling Mining Drones"
		EVE:DronesReturnToDroneBay[Ship.ActiveDroneIDList]
	}
	
	function Mine()
	{
		
		This.TripStartTime:Set[${Time.Timestamp}]
		; Find an asteroid field, or stay at current one if we're near one.
		call Asteroids.MoveToField FALSE
		call This.Prepare_Environment
		call Asteroids.UpdateList
		variable int DroneCargoMin = ${Math.Calc[(${Ship.CargoMinimumFreeSpace}*1.4)]}
		
		while (!${Miner.Abort} && \
				${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace})
		{	
	
			if (!${Ship.InWarp} && \
				${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers})
			{
				; We've got idle lasers, and available targets. Do something with them.
	
				while ${Me.GetTargeting} > 0
				{
				 	wait 10
				}				
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
					
					if ( ${This.ConcentrateFire} || \
						!${Ship.IsMiningAstroidID[${TargetID}]} )
					{
						while ${Combat.CombatPause}== TRUE
						{
							wait 50
							echo "DEBUG: Obj_Miner In Combat Pause Loop"
						}
						
						
						Target.Value:MakeActiveTarget
						wait 20
	
						call Ship.Approach ${TargetID} ${Ship.OptimalMiningRange}
						call Ship.ActivateFreeMiningLaser
						
						if (${Ship.Drones.DronesInSpace} > 0 && \
							${Config.Miner.MiningDrones} > 0)
						{
						call Ship.Drones.ActivateMiningDrones
						}
					}
				}
				while ${Target:Next(exists)}
			}
	
			if ${Math.Calc[${Me.GetTargets} + ${Me.GetTargeting}]} < ${Ship.SafeMaxLockedTargets}
			{
				call Asteroids.TargetNext
				This.ConcentrateFire:Set[!${Return}]
				;echo DEBUG: Target Locking: ${Math.Calc[${Me.GetTargets} + ${Me.GetTargeting}].Int} out of ${Ship.SafeMaxLockedTargets} (Limited Asteroids: ${This.ConcentrateFire})
			}
			else
			{
				if ( ${Me.GetTargets} >= ${Ship.SafeMaxLockedTargets} && \
					 ${Ship.TotalMiningLasers} > ${Ship.SafeMaxLockedTargets} )
				{
					This.ConcentrateFire:Set[TRUE]
				}					
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
