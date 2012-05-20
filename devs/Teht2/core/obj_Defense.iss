/*

	Defense Class
	
	Primary defense behavior module for EVEBot
	
	-- Tehtsuo
	
*/

objectdef obj_Defense
{
	;	Versioning information
	variable string SVN_REVISION = "$Rev: 2248 $"
	variable int Version
	
	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	
	
	
	
/*	
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will Process.
*/	
	
	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This.NextPulse:Set[${Time.Timestamp}]
		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
		This.NextPulse:Update
		
		UI:UpdateConsole["obj_Defense: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}	
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}
		
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${Miner.CurrentState.Equal[MINE]} && ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
			{
				This:Process
			}
			if ${Miner.CurrentState.Equal[ORCA]} && ${Config.Combat.LaunchCombatDrones} && !${Ship.InWarp}
			{
				This:Process
			}			
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}	
	

/*	
;	Step 1:  	Method used by the Pulse event.
;				
*/	
	
	
	method Process()
	{
		variable bool ActiveLockedTargets=FALSE
		variable int64 Attacking=-1
		
		if ${Ship.AttackingTeam.Used} > 0
		{
			variable iterator GetData
			Ship.AttackingTeam:GetIterator[GetData]
			if ${GetData:First(exists)}
				do
				{
					if ${Entity[${GetData.Value}](exists)} && ${Entity[${GetData.Value}].Distance} < ${Ship.OptimalTargetingRange} && !${Entity[${GetData.Value}].IsLockedTarget} && !${${GetData.Value}].BeingTargeted}
					{
						Entity[${GetData.Value}]:LockTarget
					}
					if ${Entity[${GetData.Value}](exists)} && ${Entity[${GetData.Value}].Distance} < ${Me.DroneControlDistance} && ${Entity[${GetData.Value}].IsLockedTarget}
					{
						if ${Attacking} == -1
						{
							Attacking:Set[${GetData.Value}]
						}
						ActiveLockedTargets:Set[TRUE]
					}
					if !${Entity[${GetData.Value}](exists)}
					{
						Ship.AttackingTeam:Remove[${GetData.Value}]
					}
				}
				while ${GetData:Next(exists)}
		}

		if ${Ship.Drones.DronesInSpace} > 0 && ${Ship.AttackingTeam.Used} == 0
		{
			UI:UpdateConsole["obj_Defense: Recalling Drones"]
			Ship.Drones:ReturnAllToDroneBay
		}

		if ${Ship.Drones.DronesInSpace} == 0  && ${ActiveLockedTargets}
		{
			UI:UpdateConsole["obj_Defense: Deploying drones to defend"]
			Ship.Drones:LaunchAll
		}

		if  ${Attacking} != -1 && !${Entity[${Attacking}].IsActiveTarget} && ${Entity[${Attacking}].IsLockedTarget} && ${Entity[${Attacking}](exists)}
		{
			Entity[${Attacking}]:MakeActiveTarget
		}
			
		if ${Attacking} != -1 && ${Entity[${Attacking}].IsActiveTarget} && ${Entity[${Attacking}].IsLockedTarget} && ${Entity[${Attacking}](exists)}
		{
			variable index:activedrone ActiveDroneList
			variable iterator DroneIterator
			variable index:int64 AttackDrones

			Me:GetActiveDrones[ActiveDroneList]
			ActiveDroneList:GetIterator[DroneIterator]
			if ${DroneIterator:First(exists)}
				do
				{
					if ${DroneIterator.Value.State} == 0
					{
						AttackDrones:Insert[${DroneIterator.Value.ID}]
					}
				}
				while ${DroneIterator:Next(exists)}

			if ${AttackDrones.Used} > 0
			{
				UI:UpdateConsole["obj_Defense: Sending ${AttackDrones.Used} Drones to attack ${Entity[${Attacking}].Name}"]
				EVE:DronesEngageMyTarget[AttackDrones]
			}
		}				
	}
}