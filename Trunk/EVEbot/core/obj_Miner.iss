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
	variable string CurrentState	
	variable int FrameCounter
	
	; Are we running out of asteroids to target?
	variable bool ConcentrateFire = FALSE
	
	method Initialize()
	{
		This.TripStartTime:Set[${Time.Timestamp}]
		BotModules:Insert["Miner"]
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Miner: Initialized"]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if !${Config.Common.BotModeName.Equal[Miner]}
		{
			; There's no reason at all for the miner to check state if it's not a miner
			return
		}
		FrameCounter:Inc

		variable int IntervalInSeconds = 2
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			This:SetState[]
			FrameCounter:Set[0]
		}
	}
	
	function ProcessState()
	{			
		if !${Config.Common.BotModeName.Equal[Miner]}
		{
			; There's no reason at all for the miner to check state if it's not a miner
			return
		}

		switch ${This.CurrentState}
		{
			case IDLE
				break
			case ABORT
				Call Dock
				break
			case BASE
				call Cargo.TransferOreToHangar
				call Ship.Undock
				break
			case COMBAT
				UI:UpdateConsole["Fighting"]
				call Combat.Fight
				break
			case MINE
				call This.Mine
				break
			case HAUL
				UI:UpdateConsole["Hauling"]
				call Hauler.Haul
				break
			case CARGOFULL
				call Dock
				break
			case RUNNING
				UI:UpdateConsole["Running Away"]
				call Dock
				ForcedReturn:Set[FALSE]
				break
		}	
	}
	
	method SetState()
	{
		if ${ForcedReturn}
		{
			This.CurrentState:Set["RUNNING"]
			return
		}
	
		if ${This.Abort} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
			return
		}
	
		if ${This.Abort}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
		
		if ${Me.InStation}
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}
		
		if !${Combat.CombatState}
		{
			This.CurrentState:Set["COMBAT"]
			return
		}
			
		if ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	This.CurrentState:Set["MINE"]
			return
		}
		
		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${ForcedSell}
		{
			This.CurrentState:Set["CARGOFULL"]
			return
		}
	
		This.CurrentState:Set["Unknown"]
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
		
		UI:UpdateStatStatus["Run ${This.TotalTrips} Done - Took ${ISXEVE.SecsToString[${This.PreviousTripSeconds}]}"]
		UI:UpdateStatStatus["Total Run Time: ${Hours}:${Minutes}:${Seconds} - Average Run Time: ${ISXEVE.SecsToString[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]}"]
	} 
	
	method DroneMining()
	{
		
		
		while (!${Miner.Abort} && \
					${Combat.CombatState} && \
				${Ship.CargoFreeSpace} >= ${DroneCargoMin})
		{	
			wait 50
			echo "Debug: Test"
		}
		
		UI:UpdateConsole["Recalling Mining Drones"]
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
		
		UI:UpdateConsole["Mining"]
		
		while ( !${Miner.Abort} && \
					${Combat.CombatState} && \
				${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace})
		{	
	
			; TODO - Add Ship.Drones.DroneShortage check in here with proper falback -- CyberTech
			
			if (!${Ship.InWarp} && \
				${Combat.CombatState} && \
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
						
						Target.Value:MakeActiveTarget
						wait 20
	
						call Ship.Approach ${TargetID} ${Ship.OptimalMiningRange}
						call Ship.ActivateFreeMiningLaser
						
						if (${Ship.Drones.DronesInSpace} > 0 && \
							${Config.Miner.UseMiningDrones})
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
		
		if !${Combat.CombatState}
		{
		return
		}
		
		call This.Cleanup_Environment
		This.TotalTrips:Inc
		This.PreviousTripSeconds:Set[${This.TripDuration}]
		This.TotalTripSeconds:Inc[${This.PreviousTripSeconds}]
		This.AverageTripSeconds:Set[${Math.Calc[${This.TotalTripSeconds}/${This.TotalTrips}]}]
		UI:UpdateConsole["Cargo Hold has reached threshold, returning"]
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
