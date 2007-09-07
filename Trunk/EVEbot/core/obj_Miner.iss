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
	variable bool Abort = FALSE
	variable string CurrentState	
	variable int FrameCounter
	variable bool CombatAbort = FALSE
	
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
				Call This.Abort_Check
				break
			case BASE
				call Cargo.TransferOreToHangar
				;call Station.CheckList
				call Ship.Undock
				break
			case MINE
				call This.Mine
				break
			case MOVE
				call Astroids.ForceMove
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
				EVEBot.ReturnToStation:Set[TRUE]
				break
		}	
	}
	
	method SetState()
	{
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
			return
		}
	
		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
		
		if ${Me.InStation}
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}
		
		if
		{
			
		}
				
		if ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	This.CurrentState:Set["MINE"]
			return
		}
		
		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["CARGOFULL"]
			return
		}
	
		This.CurrentState:Set["Unknown"]
	}

	function Abort_Check()
	{ 
		call Config.Common.IncAbortCount
		; abort check, this will allow the bot to continue botting if it is a temp abort or something that can
		; if there is no abort type it will pause the script like before and wait... 
		
		if ${This.CombatAbort}
			{
				UI:UpdateConsole["Warning: Paused. Combat type abort."]
				
				if ((${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct}) && ${Ship.ArmorRepairUnits} == 0)
				{
					UI:UpdateConsole["Warning: Aborted. Script paused due to Armor Precentage."]
					Script:Pause
				}

				; To.Do NEED TO ADD CHECK FOR HULL REPAIRER in SHIP OBJECT.
				if ((${Me.Ship.StructurePct} < 100))
				{
					UI:UpdateConsole["Warning: Aborted. Script paused due to Structure Precentage."]
					
					Script:Pause
				}
				
				if ${Me.Ship.ShieldPct} < 100
				{
					UI:UpdateConsole["Warning: Aborted. Waiting for Shields to Regen."]
					while ${Me.Ship.ShieldPct} < 95
					{
						wait 20
					}
				}
				
				UI:UpdateConsole["Continuing"]
				EVEBot.ReturnToBase:Set[FALSE]
				This.CombatAbort:Set[FALSE]
				Return
			}
			
		UI:UpdateConsole["Warning: Aborted - Script Paused - Check Logs "]
		Script:Pause
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
		
	function Mine()
	{
		
		This.TripStartTime:Set[${Time.Timestamp}]
		; Find an asteroid field, or stay at current one if we're near one.
		call Asteroids.MoveToField FALSE
		call This.Prepare_Environment
		call Asteroids.UpdateList
		variable int DroneCargoMin = ${Math.Calc[(${Ship.CargoMinimumFreeSpace}*1.4)]}
		variable int Counter = 0
		
		UI:UpdateConsole["Mining"]
		
		while ( !${EVEBot.ReturnToStation} && \
				!${Ship.CargoFull} )
		{	
	
			if ${Ship.Drones.DroneShortage}
			{
				/* TODO - This should pick up drones from station instead of just docking */
				UI:UpdateConsole["Warning: Drone shortage detected, docking"]
				EVEBot.ReturnToStation:Set[TRUE]
				return
			}
			
			if (${Config.Miner.MineAlone} && ${Social.PlayerDetection}) || \
			(${Config.Miner.StandingDetection} && ${Social.StandingDetection[${Config.Miner.LowestStanding}]})
			{
				UI:UpdateConsole["Warning: Detected another player that might be hostile, Moving Now!"]
				call This.Cleanup_Environment
				call Asteroids.MoveToField TRUE
				call This.Prepare_Environment
			}
			
			if ${Config.Miner.UseJetCan} && ${Ship.CargoHalfFull}
			{
				call Cargo.TransferOreToJetCan
			}
			
			/* TODO - CyberTech: clean up this code when ArmorPct/ShieldPct wierdness is gone */
			if ( !${Me.Ship.ArmorPct(exists)} || !${Me.Ship.ShieldPct(exists)} )
			{
				do
				{
					UI:UpdateConsole["Me.Ship.ArmorPct OR Me.Ship.ShieldPct was NULL.  Waiting 2 seconds and checking again..."]
					wait 20
					Counter:Inc[20]
					if ${Counter} > 600
					{
						UI:UpdateConsole["Me.Ship.ArmorPct OR Me.Ship.ShieldPct returned NULL for longer than a minute, aborting..."]
						EVEBot.ReturnToStation:Set[TRUE]
						return
					}
				}
				while (!${Me.Ship.ArmorPct(exists)} || !${Me.Ship.ShieldPct(exists)})
				
				Counter:Set[0]
				if ( ${Me.Ship.ArmorPct} < 0 || ${Me.Ship.ShieldPct} < 0 )
				{
					do
					{
						UI:UpdateConsole["Me.Ship.ArmorPct OR Me.Ship.ShieldPct was less than zero.  Waiting 2 seconds and checking again..."]
						wait 20
						Counter:Inc[20]
						if ${Counter} > 600
						{
							UI:UpdateConsole["Me.Ship.ArmorPct OR Me.Ship.ShieldPct returned a value less than zero for longer than a minute, aborting..."]
							EVEBot.ReturnToStation:Set[TRUE]
							return
						}					
					}
					while (${Me.Ship.ArmorPct} < 0 || ${Me.Ship.ShieldPct} < 0)
				}
			}
			
			if (${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
				${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct})
			{
				/*
					TODO - CyberTech: This should be checked in a defensive class that runs regardless of which bot module is active
					instead of being checked in each module
				*/
				UI:UpdateConsole["Armor is at ${Me.Ship.ArmorPct}"]
				UI:UpdateConsole["Shield is at ${Me.Ship.ArmorPct}"]
				UI:UpdateConsole["Aborting due to defensive status"]
				
				EVEBot.ReturnToStation:Set[TRUE]
				This.CombatAbort:Set[TRUE]
				return
			}
			
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
					if ${Ship.CargoFull}
					{
						break
					}

					if ${Target.Value.CategoryID} != ${Asteroids.AsteroidCategoryID}
					{
						continue
					}
					variable int TargetID
					TargetID:Set[${Target.Value.ID}]
					
					if (${This.ConcentrateFire} || \
						!${Config.Miner.DistributeLasers} || \
						!${Ship.IsMiningAstroidID[${TargetID}]} )
					{	
						
						Target.Value:MakeActiveTarget
						wait 20
						if ${Ship.CargoFull}
						{
							break
						}
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
			wait 10
		}
				
		if ${Config.Miner.BookMarkLastPosition}
		{
			Bookmarks:StoreLocation
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
