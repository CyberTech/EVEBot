/* 
  Monday, August 20, 2007
  Currently Written in Development State to support only that of the miner.
*/

objectdef obj_Combat
{
	;Support Objects
	;variable obj_Defensive Defense
	;variable obj_Offensive Offense
	
	;Combat Object Variables
	variable index:entity TargetList
	variable int FrameCounter
	variable bool P_Combat
	variable iterator CurrentTarget
	
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Combat: Initialized"]
		;Event[OnFrame]:AttachAtom[This:Pulse]
	}
	
	method Shutdown()
	{
		;Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		FrameCounter:Inc
		variable int IntervalInSeconds = 8
		
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
    		if (${Me.InStation(exists)} && !${Me.InStation})
    		{		    
    			if ((!${This.P_Combat}) && ${This.CombatState})
    			{
    				This:EnterCombatState
    				Call This.Fight
    			}					
    			FrameCounter:Set[0]
    		}
    		else
    		{
    		    FrameCounter:Set[0]
    		}   
		}
	}
	
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;                                                                       ;;
	;;                                Members                                ;;
	;;                                                                       ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	member:bool CombatState()
	{
		if ${Me.Ship.ShieldPct} < 100 && ${Me.GetTargetedBy} > 0
		{
			return TRUE
		}
		return FALSE
	}
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;                                                                       ;;
	;;                               Methods                                 ;;
	;;                                                                       ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	method EnterCombatState()
	{
		UI:UpdateConsole["Entering Combat State"]
		This.P_Combat:Set[TRUE]
	}
	
	method ExitCombatState()
	{
		UI:UpdateConsole["Exiting Combat State"]
		This.P_Combat:Set[FALSE]
	}
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;                                                                       ;;
	;;                              Functions                                ;;
	;;                                                                       ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	function UpdateList()
	{	
		This.TargetList:Clear
		
			do
			{
				;echo "DEBUG: obj_Combat:Trying to update list"
				Me:DoGetTargetedBy[This.TargetList]
			}
			while ${This.TargetList.Used} == 0
		
			if ${This.TargetList.Used}
			{
				;echo "DEBUG: obj_Combat:UpdateList - Found ${This.TargetList.Used}"
			}
	}
	
	function PrepareEnviorment()
	{
		call This.UpdateList
		
		if ${Ship.Drones.DronesInSpace} == 0
		{
			if ${Ship.Drones.DronesInBay} > 0
			{
			Ship.Drones:LaunchAll[]
			}
		}	
		call This.TargetNext		
	}
	
	function TargetNext()
	{
		variable iterator TargetIterator
			
			if ${This.TargetList.Used} == 0
			{
			echo "DEBUG: Obj_Combat; No List Found, Trying to update now"
			call This.UpdateList
			}
			
			This.TargetList:GetIterator[TargetIterator]
			if ${TargetIterator:First(exists)}
		{
			do
			{
			  if ${Entity[${TargetIterator.Value}](exists)} && \
					!${TargetIterator.Value.IsLockedTarget} && \
					!${TargetIterator.Value.BeingTargeted} 
				{
						break
				}
			}
			while ${TargetIterator:Next(exists)}
			
			if ${Entity[${TargetIterator.Value}](exists)}
			{
				UI:UpdateConsole["Locking Target ${TargetIterator.Value.Name}: ${EVEBot.MetersToKM_Str[${TargetIterator.Value.Distance}]}"]			
				TargetIterator.Value:LockTarget
				while !${TargetIterator.Value.IsLockedTarget}
				{
				  wait 30
				  echo "Debug: Awaiting Lock"
				}
				echo "DEBUG: ${TargetIterator.Value.Name} Locked"
				
				call This.UpdateList
			}
		}
	}
	
	function Fight()
	{
		variable index:entity LockedTargets
		variable iterator Target
		call This.PrepareEnviorment
		

		while ${This.CombatState}
		{
			if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			{
				call This.TargetNext
			}
			
			Me:DoGetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]
			
				if ${Target:First(exists)}
				{
					do
					{	
					if ${Target.Value.CategoryID} == ${Asteroids.AsteroidCategoryID}
						{
						continue
						}
						variable int TargetID
						TargetID:Set[${Target.Value.ID}]
					}
					while ${Target:Next(exists)}
				}
	
				
				while !${Target.Value.IsActiveTarget}
				{
					Target.Value:MakeActiveTarget
				}
				
				call Ship.Drones.SendDrones
				
				while ${Target.Value.IsLockedTarget}
				{
					wait 10
						if (${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct}) || \
						(${Me.Ship.ShieldPct} > ${Config.Combat.MinimumShieldPct})
						{
							EVEBot.ReturnToStation:Set[TRUE]
							UI:UpdateConsole["Setting Return to Station"]
							call Ship.Drones.ReturnAllToDroneBay
							wait 200
							This:ExitCombatState
						}	
					}
			}
			
		This:ExitCombatState
		}	
				
}