/*
	SoloJetcanMiner Class

	Handles creating and filling jetcans while mining.
	Handles jetcan names and bookmark locations.
	Handles hauling our own cans.
	
	And for now, handles going back to base to swap ships
	
	-- Aboron

BUGS:

	-cannot handle named ships that don't contain the ship type in the name - pending isxeve member extension for this (for now, just rename the ships to test)
	-jumps to new belt and doesn't increment can #
	-creates new cans while drifting to 2nd and 3rd targets,
	  or infinite-loops out creating a new can and never stops approaching a second or third target
	-probably other severe bugs not found yet

*/

objectdef obj_SoloJetcanMiner
{
	variable index:item MyCargo
	
	variable bool GetHauler
	variable bool GetMiner

	variable bool CollectJetcans
	variable int JetcanStartTime
	variable int CurrentJetcanLevel
	variable int CurrentJetcanIndex
	
	variable int Abort = FALSE
	variable string CurrentState	
	variable int FrameCounter

	method Initialize()
	{
		BotModules:Insert["SoloJetcanMiner"]
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_SoloJetcanMiner: Initialized"]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}
		
		if !${Config.Common.BotModeName.Equal[SoloJetcanMiner]}
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
		if !${Config.Common.BotModeName.Equal[SoloJetcanMiner]}
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
				;Call This.Abort_Check ; TBI
				break
			case BASE
				call Cargo.TransferOreToHangar
				call Ship.Undock
				break
			case MINE
				call Miner.Mine
				break
			case CARGOFULL
				call JetcanMyCargo
				break
			case GET_HAULER
				call Dock
				call Cargo.TransferOreToHangar
				call This.ActivateShipByName ${Config.JetcanMiner.HaulingShipName}
				call Ship.Undock
				This.GetHauler:Set[FALSE]
				break
			case COLLECT_CANS
				call RetrieveAllCans
				break
			case GET_MINER
				call Dock
				call Cargo.TransferOreToHangar
				call This.ActivateShipByName ${Config.JetcanMiner.MiningShipName}
				call Ship.Undock
				This.GetMiner:Set[FALSE]
				break
			case RUNNING
				call Dock
				EVEBot.ReturnToStation:Set[TRUE]
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
		
		if ${This.GetMiner}
		{
			This.CurrentState:Set["GET_MINER"]
			return
		}
		
		if ${This.GetHauler}
		{
			This.CurrentState:Set["GET_HAULER"]
			return
		}
		
		if ${This.CollectJetcans}
		{
			This.CurrentState:Set["COLLECT_CANS"]
			return
		}
		
		if ${Me.InStation}
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}
				
		if ${Ship.CargoFreeSpace} > ${Math.Calc[${Me.Ship.CargoCapacity}/2.1]}
		{
		 	This.CurrentState:Set["MINE"]
			return
		}
		else
		{
			This.CurrentState:Set["CARGOFULL"]
			return
		}
	}
	
	function RetrieveAllCans()
	{
		variable int ThisCan
		variable int JetcanToGet
		
		JetcanToGet:Set[0]
		do
		{
			echo "Heading to get ore from can ${JetcanToGet}"
			call Ship.WarpToBookMark "${Me.Name} ${JetcanToGet}"
			
			ThisCan:Set[${Entity["${Me.Name} ${JetcanToGet}"].ID}]
			
			echo "Remove ore from can ${ThisCan}"
			call RemoveAllFromCan ${ThisCan}
			wait 50
			
			if ${Entity["${Me.Name} ${JetcanToGet}"](exists)}
			{
				echo "Can still has ore, drop and come back"
				call Dock
				call Cargo.TransferOreToHangar
				call Ship.Undock
			}
			else
			{
				echo "Can gone, remove bookmark"
				EVE.Bookmark["${Me.Name} ${JetcanToGet}"]:Remove
				call Dock
				call Cargo.TransferOreToHangar
				call Ship.Undock
				JetcanToGet:Inc
			}
		}
		while ${JetcanToGet} <= ${This.CurrentJetcanIndex}
		echo "That should be it, go back to mining"
		
		; Reset for fresh batch
		This.CurrentJetcanIndex:Set[0]
		This.CollectJetcans:Set[FALSE]
		This.GetMiner:Set[TRUE]
	}

	function JetcanMyCargo()
	{
		variable int MyCan
		variable iterator ThisCargo
		
		echo "Calling can handler"
		MyCan:Set[${This.MyNearestMatchingJetCan["${Me.Name} ${This.CurrentJetcanIndex}"]}]
		
		if ${MyCan} != NULL
		{
			if (${Entity[${MyCan}].Distance} >= 1300) && (${Config.JetcanMiner.UseMultipleCans} == TRUE)
			{
				echo "Old can too far, making a new one..."
				This.CurrentJetcanIndex:Inc
				
				echo "Open cargo"
				call Ship.OpenCargo
				wait 20
				
				echo "Load cargo list"
				Me.Ship:DoGetCargo[This.MyCargo]
				
				This.MyCargo:GetIterator[ThisCargo]
				
				if ${ThisCargo:First(exists)}
				{
					echo "Cargo exists"
	
					do
					{
					  if ${ThisCargo.Value.CategoryID} == 25
					  {
					  	ThisCargo.Value:Jettison
							echo "jettisoned first ore found"
			        break
					  } 
					}
					while ${ThisCargo:Next(exists)}
					
					echo "Jettisoned some ore, i hope"
					
					do
					{
						wait 5
						MyCan:Set[ ${This.MyNearestMatchingJetCan["Cargo Container"]} ]
					}
					while ${MyCan} == NULL
					
					echo "Can appeared"
					
					if ${ThisCargo:Next(exists)}
					{
						echo "Moving all remaining ore to new can"
						call MoveAllToCan ${MyCan}
					}
					
					echo "Naming new Can"
					Entity[${MyCan}]:SetName["${Me.Name} ${This.CurrentJetcanIndex}"]
					wait 5
					
					UI:UpdateConsole["Setting bookmark on new can"]
					Entity[${MyCan}]:CreateBookmark["${Me.Name} ${This.CurrentJetcanIndex}"]
						
					if ${This.CurrentJetcanIndex} == 0
					{
						This.JetcanStartTime:Set[${Time.Timestamp}]
					}
				}
			}
			else
			{
				echo "Moving into old can"
				call MoveAllToCan ${MyCan}
				echo "Moved"
				
				/* Check how full this can is getting, I like mine to be one hauler load each... */
				if ${This.CurrentJetcanLevel} > ${Config.JetcanMiner.JetcanVolume}
				{
					if ${Config.JetcanMiner.UseMultipleCans}
					{
						This.CurrentJetcanIndex:Inc
					}
					else
					{
						UI:UpdateConsole["Jetcan full. Getting hauler to retrieve."]
						call Miner.Cleanup_Environment
						This.CollectJetcans:Set[TRUE]
						This.GetHauler:Set[TRUE]
					}
				}
			}
		}  
		else
		{
			echo "Starting new Can"
			if ${This.CurrentJetcanIndex} == NULL
			{
				This.CurrentJetcanIndex:Set[0]
			}
			echo "Open cargo"
			call Ship.OpenCargo
			wait 20
			
			echo "Load cargo list"
			Me.Ship:DoGetCargo[This.MyCargo]
			
			This.MyCargo:GetIterator[ThisCargo]
			
			if ${ThisCargo:First(exists)}
			{
				echo "Cargo exists"

				do
				{
				  if ${ThisCargo.Value.CategoryID} == 25
				  {
				  	ThisCargo.Value:Jettison
						echo "jettisoned first ore found"
		        break
				  } 
				}
				while ${ThisCargo:Next(exists)}
				
				echo "Jettisoned some ore, i hope"
				
				do
				{
					wait 5
					MyCan:Set[ ${This.MyNearestMatchingJetCan["Cargo Container"]} ]
				}
				while ${MyCan} == NULL
				
				echo "Can appeared"
				
				if ${ThisCargo:Next(exists)}
				{
					echo "Moving all remaining ore to new can"
					call MoveAllToCan ${MyCan}
				}
				
				echo "Naming new Can"
				Entity[${MyCan}]:SetName["${Me.Name} ${This.CurrentJetcanIndex}"]
				wait 5
				
				UI:UpdateConsole["Setting bookmark on new can"]
				Entity[${MyCan}]:CreateBookmark["${Me.Name} ${This.CurrentJetcanIndex}"]
					
				if ${This.CurrentJetcanIndex} == 0
				{
					This.JetcanStartTime:Set[${Time.Timestamp}]
				}
			}
		}
		/* Check how many minutes it's been since we jetcanned the first ore in this run */
		echo "Times: ${Time.Timestamp} - ${This.JetcanStartTime}) / 60 = ${Math.Calc[(${Time.Timestamp} - ${This.JetcanStartTime}) / 60]} compares to ${Config.JetcanMiner.JetcanLife}"
		if ${Math.Calc[(${Time.Timestamp} - ${This.JetcanStartTime}) / 60]} > ${Config.JetcanMiner.JetcanLife}
		{
			UI:UpdateConsole["Jetcan(s) getting old retrieving with hauler before it pops"]
			call Miner.Cleanup_Environment
			This.CollectJetcans:Set[TRUE]
			This.GetHauler:Set[TRUE]
		}
	}
	
	function MoveAllToCan(int Container)
	{
		variable int i
		variable int MyCargoCount
		
		if ${Entity[${Container}].Distance} >= 1300
		{
			echo "Jetcan too far, approaching..."
			Entity[${Container}]:Approach
			do
	    {
	      wait 20
	    }
	    while ${Entity[${Container}].Distance} > 1300
		}
		
		echo "Opening jetcan."
		Entity[${Container}]:OpenCargo
		wait 20
		call Ship.OpenCargo
		wait 20
		
		i:Set[1]
		MyCargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
		
		do
		{
		  if (${MyCargo.Get[${i}].CategoryID} == 25)
		  {
        echo Moving ${MyCargo.Get[${i}].Name} to ${Entity[${Container}].ID}
        MyCargo.Get[${i}]:MoveTo[${Entity[${Container}].ID}]
        wait 10
		  } 
		}
		while ${i:Inc} <= ${MyCargoCount}
		wait 10

		echo "Stacking cargo"
		Entity[${Container}]:StackAllCargo
		wait 10
		
		do
		{
			This.CurrentJetcanLevel:Set[${Entity[${Container}].UsedCargoCapacity}]
		}
		while ${This.CurrentJetcanLevel} < 0
		
		echo "Current jetcan contains ${This.CurrentJetcanLevel} m^3 of stuff."
		wait 10
		
		call Ship.CloseCargo
		wait 10
		
		Entity[${Container}]:CloseCargo
	}
	
	member:int MyNearestMatchingJetCan(string CanName)
	{
		variable index:int JetCan
		variable int JetCanCount
		variable int JetCanCounter
		variable string tempString
		
		echo "Finding may cans matching ${CanName}"
		
		JetCanCounter:Set[1]
		JetCanCount:Set[${EVE.GetEntityIDs[JetCan,GroupID,12]}]
		
		echo "did GetEntityIDs"
		
		do
		{
			if ${Entity[${JetCan.Get[${JetCanCounter}]}](exists)}
			{
				echo "checking GetEntityID"
				tempString:Set[${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.Name}]
				echo "DEBUG: owner ${tempString}"
				
				if ${tempString.Find["${Me}"]} > 0
				{
					echo "Found one of mine: ${Entity[${JetCan.Get[${JetCanCounter}]}].Name}"
					if ${Entity[${JetCan.Get[${JetCanCounter}]}].Name.Find["${CanName}"]} > 0
 						return ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}
 					else
						echo "No match"
				}
			}
			else
			{
				echo "No match"
				return NULL
			}
		}
		while ${JetCanCounter:Inc} <= ${JetCanCount}
		
		echo "No matching jetcans found"
		return NULL
	}
	
	function ActivateShipByName(string ShipName)
	{
		variable index:item MyShips
		variable int ShipCount
		variable string TestName
		
		TestName:Set["${Me.Ship}"]
		echo "My ship currently: ${TestName}"
		echo "Switching to: ${ShipName}"
		If ${TestName.Find[${ShipName}]} > 0 /* Already in that ship... */
		{
			echo "ActivateShipByName: Already in that ship"
		}
		Else
		{
			If ${Me.InStation}
			{
				EVE:Execute[OpenShipHangar]
				ShipCount:Set[${Me.Station.GetHangarShips[MyShips]}]
				do
				{
					TestName:Set["${MyShips.Get[${ShipCount}].Name}"]
					echo "Testing ship name: ${TestName}"
					If ${TestName.Find[${ShipName}]}
					{
						echo "Ship search: ${ShipName} matched: ${TestName}"
						MyShips.Get[${ShipCount}]:MakeActive
						break
					}
					ShipCount:Dec
				}
				while ${ShipCount} > 0
				
				If ${ShipCount} == 0
				{
					echo "ActivateShipByName: No ships match"
				}
				else
				{
					do
					{
						Wait 50
						MyShips.Get[${ShipCount}]:MakeActive
						Wait 50
						TestName:Set["${Me.Ship}"]
					}
					While !${TestName.Find[${ShipName}]}  /* If we just got in, we have to wait before changing ships */
				}
			}
			else
			{
				echo "ActivateShipByName: Need to be in station to get another ship"
			}
		}
	}
	
	function RemoveAllFromCan(int Container)
	{
		variable int i
		variable int ContainerCargoCount
		variable index:item ContainerCargo
		
		if ${Entity[${Container}](exists)}
		{
			if ${Entity[${Container}].Distance} >= 1300
			{
				Entity[${Container}]:Approach
				do
	      {
	        wait 20
	      }
	      while ${Entity[${Container}].Distance} > 1300
			}
			
			echo "Opening Can"
			Entity[${Container}]:OpenCargo
			wait 20
			call Ship.OpenCargo
			wait 20
			
			i:Set[1]
			ContainerCargoCount:Set[${Entity[${Container}].GetCargo[ContainerCargo]}]
			do
			{
				echo "Moving item ${i} of ${ContainerCargoCount}"
			  ContainerCargo.Get[${i}]:MoveTo[MyShip]
        wait 15
			}
			while ${i:Inc} <= ${ContainerCargoCount}
			wait 50
			
			if ${Entity[${Container}].UsedCargoCapacity} > 0
			{
				This.CurrentJetcanLevel:Set[${Entity[${Container}].UsedCargoCapacity}]
				Entity[${Container}]:CloseCargo
				wait 10
				echo "JetCan still contains ${Entity[${Container}].UsedCargoCapacity} m^3 of stuff."
			}
			else
			{
				This.CurrentJetcanLevel:Set[0]
				echo "JetCan gone"
			}
			call Ship.CloseCargo
		}
	}
}
