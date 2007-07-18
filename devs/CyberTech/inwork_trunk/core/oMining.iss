/*
	Asteroids class
	
	Main object for interacting with Asteroids
	
	-- CyberTech
	
*/
objectdef obj_Asteroids
{
	variable int AsteroidCategoryID = 25
	
	variable index:entity AstroidList
	variable iterator OreTypeIterator
	
	method Initialize()
	{
		
	}
	
	method CheckBeltBookMarks()
	{
		variable index:bookmark Bookmarks
		variable iterator Bookmark
		
		EVE:DoGetBookmarks[Bookmarks]
		Bookmarks:GetIterator[Bookmark]
		
		if ${Bookmark:First(exists)}
		do
		{
			echo ${Bookmark.Value.Label} - ${Bookmark.Value.Type} ${Bookmark.Value.TypeID}
		}
		while ${Bookmark:Next(exists)}
	}
	
	function MoveToField(bool ForceMove)
	{
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
				call WarpTo ${Belts[${curBelt}]}
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
		OreTypes:GetSettingIterator[This.OreTypeIterator]
		
		if ${This.OreTypeIterator:First(exists)}
		{
			do
			{
				;echo "DEBUG: obj_Asteroids: Checking for Ore Type ${This.OreTypeIterator.Value}"
				This.AstroidList:Clear
				EVE:DoGetEntities[This.AstroidList,CategoryID,${This.AsteroidCategoryID},${This.OreTypeIterator.Value}]
				wait 0.5
			}
			while ${This.AstroidList.Used} == 0 && ${This.OreTypeIterator:Next(exists)}
			
			;if ${This.AstroidList.Used}
			;{
			;		echo "DEBUG: obj_Asteroids:UpdateList - Found ${This.AstroidList.Used} ${This.OreTypeIterator.Value asteroids"
			;}
		}
		else
		{
			echo "WARNING: obj_Asteroids: Ore Type list is empty, please check config"
		}
	}
	
	function:bool TargetNext()
	{
		variable iterator AsteroidIterator

		This.AstroidList:GetIterator[AsteroidIterator]
		if ${AsteroidIterator:First(exists)}
		{
			do
			{
				if ${Entity[${AsteroidIterator.Value}](exists)} && \
					!${AsteroidIterator.Value.IsLockedTarget} && \
					!${AsteroidIterator.Value.BeingTargeted} && \
					${AsteroidIterator.Value.Distance} < ${Me.Ship.MaxTargetRange}
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
				call UpdateHudStatus "Locking Asteroid ${AsteroidIterator.Value.Name}"
				AsteroidIterator.Value:LockTarget
				wait 20
				return TRUE
				call This.UpdateList
			}
			else
			{
				call This.UpdateList
				if ${Ship.TotalActivatedMiningLasers} == 0				
				{
					echo "obj_Asteroids: TargetNext: No Asteroids in Targeting Range & lasers idle - Approaching nearest"
					AsteroidIterator:First
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

function Mine()
{
	Asteroids:CheckBeltBookMarks[]
	variable index:entity LockedTargets

	; Find an asteroid field, or stay at current one if we're near one.
	call Asteroids.MoveToField FALSE
	
	;Call LaunchDrones
	;don't use that if you have offensive med or low slot...
	call ActivateDefense
	
	
	call UpdateHudStatus "Opening Cargo Hold for mining..."
	call Ship.OpenCargo
	call Asteroids.UpdateList
	
	; TODO - Change this to use the known mining laser slots instead of hardcoding slot 0.
	while ${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
	{				
		if ${Ship.TotalActivatedMiningLasers} < ${Ship.TotalMiningLasers} && \
			( ${Me.GetTargets} > ${Ship.TotalActivatedMiningLasers} || \
			  ${Ship.TotalMiningLasers} > ${Math.Calc[${Ship.MaxLockedTargets} - 1]} )
			
		{
			; We've got idle lasers, and available targets. Do something with them.

			Me:DoGetTargets[LockedTargets]
			variable iterator TargetIterator
			LockedTargets:GetIterator[TargetIterator]

			if ${TargetIterator:First(exists)}
			do
			{
				if ${TargetIterator.Value.CategoryID} != ${Asteroids.AsteroidCategoryID}
				{
					continue
				}

				variable int TargetID
				TargetID:Set[${TargetIterator.Value.ID}]
				if !${Ship.IsMiningAstroidID(${TargetID})}
				{
					TargetIterator.Value:MakeActiveTarget
					wait 20

					if ${TargetIterator.Value(exists)} && \
						${TargetIterator.Value.Distance} > ${Ship.OptimalMiningRange}
					{
						while ${TargetIterator.Value(exists)} && \
								${TargetIterator.Value.Distance} > ${Ship.OptimalMiningRange}
						{
							call Ship.Approach ${TargetID}
						}
						
						EVE:Execute[CmdStopShip]
					}
					call Ship.ActivateFreeMiningLaser
				}
			}
			while ${TargetIterator:Next(exists)}
			
			; TODO - Put multiple lasers on a roid as a fallback if we end up with more lasers than targets -- CyberTech
		}

		if ${Me.GetTargets} < ${Math.Calc[${Ship.MaxLockedTargets} - 1]}
		{
			echo Target Locking: ${Me.GetTargets} out of ${Math.Calc[${Ship.MaxLockedTargets} - 1]}
			call Asteroids.TargetNext
		}
		wait 30
	}
	call UpdateHudStatus "Cargo Hold has reached threshold"
	call UpdateHudStatus "Finished Mining...Closing cargo hold"

	call Ship.CloseCargo
}