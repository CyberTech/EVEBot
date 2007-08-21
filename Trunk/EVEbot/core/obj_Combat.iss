/* 
  Monday, August 20, 2007
  Currently Written in Development State to support only that of the miner.
*/

objectdef obj_Combat
{
	;Support Objects
	variable obj_Defensive Defense
	variable obj_Offensive Offense
	
	;Combat Object Variables
	variable index:entity TargetList
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Combat: Initialized"]
	}
	
	method Shutdown()
	{
	}
	
	;Current Reference for bot state... not great because of the pct thing... 
	; need to find a better way to identify combat state
	member:bool CombatState()
	{
		if ${Me.Ship.ShieldPct} < 100 && ${Me.GetTargetedBy} > 0
		{
			return FALSE
		}
		return TRUE
	}
	
	function UpdateList()
	{	
		This.TargetList:Clear
		
			do
			{
				echo "DEBUG: obj_Combat:Trying to update list"
				Me:DoGetTargetedBy[This.TargetList]
			}
			while ${This.TargetList.Used} == 0
		
		if ${This.TargetList.Used}
			{
					echo "DEBUG: obj_Combat:UpdateList - Found ${This.TargetList.Used}"
			}
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
				UI:UpdateConsole["Locking Target ${TargetIterator.Value.Name}: ${Misc.MetersToKM_Str[${TargetIterator.Value.Distance}]}"]			
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
		call This.UpdateList
		if ${Ship.Drones.DronesInSpace} == 0
		{
		Ship.Drones:LaunchAll[]
		}
		wait 10
		while ${Me.GetTargetedBy} > 0
		{
			if ${Math.Calc[${Me.GetTargets} + ${Me.GetTargeting}]} < ${Ship.MaxLockedTargets}
				{
				call This.TargetNext
				}

			while ${Me.GetTargeting} > 0
			{
			wait 10	
			}
			
			Me:DoGetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]
			wait 10
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
					
					while ${Target.Value.IsLockedTarget}
					{
						wait 10
						if ${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct}
						{
							Miner.Abort:Set[TRUE]
							UI:UpdateConsole["Shit! Shit! We gotta run fast.. Lets hope we survive this."]
							call Ship.Drones.ReturnAllToDroneBay
							return
						}	
					}
			}
			while ${Target:Next(exists)}
		}	
		UI:UpdateConsole["GG! We didn't get our shit blown up this time"]
		return
	}
}

objectdef obj_Defensive
{
	method Initialize()
	{
		UI:UpdateConsole["obj_Defensive: Initialized"]
	}
}

objectdef obj_Offensive
{
	method Initialize()
	{
		UI:UpdateConsole["obj_Defensive: Initialized"]
	}
}