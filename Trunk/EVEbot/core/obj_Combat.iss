/* 
	Acidently deleted the old one and its back up, this one I pulled from an old file and made all the changes
	I think I made before, may have some bugs still in it that I had to correct before.
   Hess   
*/

objectdef obj_Combat
{
	variable bool InCombat = FALSE
	variable bool Running = FALSE
	variable bool CombatPause = FALSE
	variable index:entity TargetList
	variable iterator NextTargetIterator
		
	method Initialize()
	{	
		call UpdateHudStatus "obj_Combat: Initialized"
	}
	
	method Shutdown()
	{
		/* Nothing to shutdown */
	}
	
	method InCombatState()
	{
		Call UpdateHudStatus "Now In Combat"
		Call This.Fight
		InCombat:Set[TRUE]
	}
	
	method ExitCombatState()
	{
		Call UpdateHudStatus "Debug: ExitCombatState"
		InCombat:Set[FALSE]
	}
	
	method Pause()
	{
		Call UpdateHudStatus "Pausing Bot to Deal with Combat"
		CombatPause:Set[TRUE]
	}
	
	method UnPause()
	{
		call UpdateHudStatus "Bot Resumed"
		CombatPause:Set[FALSE]
	}
	
	function UpdateList()
	{	
		This.TargetList:Clear
		Me:DoGetTargetedBy[This.TargetList]
		
		if ${This.TargetList.Used}
			{
					echo "DEBUG: obj_Combat:UpdateList - Found ${This.TargetList.Used}"
			}
	}
	
	method NextTarget()
	{
		TargetList:GetSettingIterator
	}
	
	function:bool TargetNext()
	{
		variable iterator TargetIterator
			
			
			if ${This.TargetList.Used} == 0
			{
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
				if ${TargetIterator.Value.IsLockedTarget} || \
					${TargetIterator.Value.BeingTargeted}
				{
					return TRUE
				}
				call UpdateHudStatus "Locking Target ${TargetIterator.Value.Name}: ${Misc.MetersToKM_Str[${TargetIterator.Value.Distance}]}"
		
		
				wait 20				
				TargetIterator.Value:LockTarget
				echo "DEBUG: Locking Target"
				do
				{
				  wait 30
				}
				while !${TargetIterator.Value.IsLockedTarget}
				call This.UpdateList
				return TRUE
			}
			return FALSE
		}
	}
	
	function Fight()
	{
		This:Pause
		call This.TargetNext
		
		while ${Me.GetTargetedBy} > 0
		{			
				Me:DoGetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				if ${Target:First(exists)}
				do
				{
					if ${Target.Value.CategoryID} == ${Asteroids.AsteroidCategoryID}
					{
						continue
					}
					variable int TargetID
					TargetID:Set[${Target.Value.ID}]
					Target.Value:MakeActiveTarget
					wait 20
	
					call Ship.Drones.SendDrones
					;To do
					;call Ship.CombatLasers
				}
				while ${Target:Next(exists)}
				
			if ${Math.Calc[${Me.GetTargets} + ${Me.GetTargeting}]} < ${Ship.MaxLockedTargets}
			{
				call This.TargetNext
			}		
		}	
		
		This:UnPause
	
		while ${Me.GetTargetedBy} == 0 && \
			 ${Me.Ship.ShieldPct} < 100
		{
				wait 10
		}
			
		This:ExitCombatState
			
		}
}