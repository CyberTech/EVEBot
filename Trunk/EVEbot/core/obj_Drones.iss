/*
	Drone class
	
	Main object for interacting with the drones.  Instantiated by obj_Ship, only.
	
	-- CyberTech
	
*/

objectdef obj_Drones
{
	variable index:int ActiveDroneIDList
	variable int CategoryID_Drones = 18
	variable int LaunchedDrones = 0
	variable bool WaitingForDrones = FALSE
	variable bool DronesReady = FALSE
	variable int FrameCounterDrones
	variable int ShortageCount
	
	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Drones: Initialized"]
	}
	method Shutdown()
	{
	    if !${Me.InStation}
	    {
	        echo "Recalling Drones prior to EVEBOT shutdown..."
		    EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
		}
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if ${This.WaitingForDrones}
		{
			FrameCounterDrones:Inc
            variable int IntervalInSeconds = 4
				
			if ${FrameCounterDrones} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
			{
    			if (${Me.InStation(exists)} && !${Me.InStation})
    			{			    
    				This.LaunchedDrones:Set[${This.DronesInSpace}]
    				if  ${This.LaunchedDrones} > 0
    				{
    					This.WaitingForDrones:Set[FALSE]
    					This.DronesReady:Set[TRUE]
    					
    					UI:UpdateConsole["${This.LaunchedDrones} drones deployed"]
    				}					
    				FrameCounterDrones:Set[0]
                }
                else
                {
                    FrameCounterDrones:Set[0]
                }
			}
		}
	}

	method LaunchAll()
	{
		if ${Me.Ship.GetDrones} > 0
		{
			UI:UpdateConsole["Launching drones..."]
			Me.Ship:LaunchAllDrones
			This.WaitingForDrones:Set[TRUE]
		}
	}
		
	member:int DronesInBay()
	{
		return ${Me.GetActiveDroneIDs[This.ActiveDroneIDList]}
	}

	member:int DronesInSpace()
	{
		return ${Me.GetActiveDroneIDs[This.ActiveDroneIDList]}
	}
   
	member:bool CombatDroneShortage()
	{
		if !${This.DronesReady}
		{
			return
		}
		
		if (${Me.Ship.DronebayCapacity} > 0 && \
   			${Me.Ship.GetDrones} == 0 && \
   			${This.DronesInSpace} < ${Config.Combat.MinimumDronesInSpace})
   		{
			ShortageCount:Inc
   			if ${ShortageCount} > 10
   			{
   				return TRUE
   			}
   		}
   		else
   		{
   			ShortageCount:Set[0]
   		}
   		return FALSE
	}
	
	; Returns the number of Drones in our station hanger.
	member:int DronesInStation()
	{
		return ${Station.DronesInStation.Used}
	}
	
	function StationToBay()
	{
		variable int DroneQuantitiyToMove = ${Math.Calc[${Config.Common.DronesInBay} - ${This.DronesInBay}]}
		if ${This.DronesInStation} == 0 || \
			!${Me.Ship(exists)}
		{
			return
		}
		
		EVE:Execute[OpenDroneBayOfActiveShip]
		wait 15
		
		variable iterator CargoIterator
		Station.DronesInStation:GetIterator[CargoIterator]
		
		if ${CargoIterator:First(exists)}
		do
		{
			UI:UpdateConsole["obj_Drones:TransferToDroneBay: ${CargoIterator.Value.Name}"]
			CargoIterator.Value:MoveTo[DroneBay,1]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
		EVEWindow[MyDroneBay]:Close
		wait 10
	}
		
   	
	function ReturnAllToDroneBay()
	{
		while ${This.DronesInSpace} > 0
		{
			UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
			EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			if (${Me.Ship.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
				${Me.Ship.ShieldPct} < ${Config.Combat.MinimumShieldPct})
			{
				; We don't wait for drones if we're on emergency warp out
				wait 10
				return
			}
			wait 50
		}
	}
	
	function ActivateMiningDrones()
	{	
		if !${This.DronesReady}
		{
			return
		}
					
		UI:UpdateConsole["Engaging Mining Drones"]
		EVE:DronesMineRepeatedly[This.ActiveDroneIDList]
	}
	
	function SendDrones()
	{
		if !${This.DronesReady}
		{
			return
		}

		if (${This.DronesInSpace} > 0)
		{
			UI:UpdateConsole["Engaging Combat Drones"]
			EVE:DronesEngageMyTarget[This.ActiveDroneIDList]
		}
	}
}