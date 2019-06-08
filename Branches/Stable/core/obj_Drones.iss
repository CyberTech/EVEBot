/*
	Drone class

	Main object for interacting with the drones.  Instantiated by obj_Ship, only.

	-- CyberTech

*/

objectdef obj_Drones
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable index:int64 ActiveDroneIDList
	variable int CategoryID_Drones = 18
	variable int LaunchedDrones = 0
	variable int WaitingForDrones = 0
	variable bool DronesReady = FALSE
	variable int ShortageCount

	variable int64 MiningDroneTarget=0

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Drones: Initialized", LOG_MINOR]
	}
	method Shutdown()
	{
		if !${Me.InStation}
		{
			if (${Me.ToEntity.Mode} != 3)
			{
				UI:UpdateConsole["Recalling Drones prior to shutdown..."]
				This.ActiveDroneIDList:RemoveByQuery[${LavishScript.CreateQuery[GroupID = GROUP_FIGHTERDRONE]}]
				EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			}
		}
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if ${This.WaitingForDrones}
		{
		    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
			{
				This.WaitingForDrones:Dec
    			if !${Me.InStation}
    			{
    				This.LaunchedDrones:Set[${This.DronesInSpace}]
    				if  ${This.LaunchedDrones} > 0
    				{
    					This.WaitingForDrones:Set[0]
    					This.DronesReady:Set[TRUE]

    					UI:UpdateConsole["${This.LaunchedDrones} drones deployed"]
    				}
                }

	    		This.NextPulse:Set[${Time.Timestamp}]
	    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
	    		This.NextPulse:Update
			}
		}
	}

	method LaunchAll()
	{
		if ${This.DronesInBay} > 0
		{
			UI:UpdateConsole["Launching drones..."]
			MyShip:LaunchAllDrones
			This.WaitingForDrones:Set[5]
		}
	}

	member:int DronesInBay()
	{
		variable index:item DroneList
		MyShip:GetDrones[DroneList]
		return ${DroneList.Used}
	}

	member:int DronesInSpace(bool IncludeFighters=TRUE)
	{
		Me:GetActiveDroneIDs[This.ActiveDroneIDList]
		if !${IncludeFighters}
		{
			This.ActiveDroneIDList:RemoveByQuery[${LavishScript.CreateQuery[GroupID = GROUP_FIGHTERDRONE]}]
		}
		return ${This.ActiveDroneIDList.Used}
	}

	member:bool CombatDroneShortage()
	{
		if !${This.DronesReady}
		{
			return
		}

		if (${MyShip.DronebayCapacity} > 0 && \
   			${This.DronesInBay} == 0 && \
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
			!${MyShip(exists)}
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
			;UI:UpdateConsole["obj_Drones:TransferToDroneBay: ${CargoIterator.Value.Name}"]
			CargoIterator.Value:MoveTo[${MyShip.ID}, DroneBay,1]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
		EVEWindow[MyDroneBay]:Close
		wait 10
	}


	method ReturnAllToDroneBay()
	{
		if ${This.DronesInSpace[FALSE]} > 0
		{
			UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
			This.ActiveDroneIDList:RemoveByQuery[${LavishScript.CreateQuery[GroupID = GROUP_FIGHTERDRONE]}]
			EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			EVE:Execute[CmdDronesReturnToBay]

		}
	}

	method ActivateMiningDrones()
	{
		if !${This.DronesReady}
		{
			;UI:UpdateConsole["Broken?"]
			return
		}

		if (${This.DronesInSpace} > 0) && ${MiningDroneTarget} != ${Me.ActiveTarget}
		{
			EVE:DronesMineRepeatedly[This.ActiveDroneIDList]
			
			;UI:UpdateConsole["PISSSSSSSSSSSSSSS"]
			MiningDroneTarget:Set[${Me.ActiveTarget}]
		}
	}

	member:bool IsMiningAsteroidID(int64 EntityID)
	{
		if ${MiningDroneTarget} == ${EntityID}
		{
			return TRUE
		}
		return FALSE
	}

	method SendDrones()
	{
		if !${This.DronesReady}
		{
			return
		}

		if (${This.DronesInSpace} > 0)
		{
			variable iterator DroneIterator
			variable index:activedrone ActiveDroneList
			Me:GetActiveDrones[ActiveDroneList]
			ActiveDroneList:GetIterator[DroneIterator]
			variable index:int64 returnIndex
			variable index:int64 engageIndex

			do
			{
				if ${DroneIterator.Value.ToEntity.GroupID} != GROUP_FIGHTERDRONE && \
					(${DroneIterator.Value.ToEntity.ShieldPct} < 80 || \
					${DroneIterator.Value.ToEntity.ArmorPct} < 0)
				{
					UI:UpdateConsole["Recalling Damaged Drone ${DroneIterator.Value.ID} Shield %: ${DroneIterator.Value.ToEntity.ShieldPct} Armor %: ${DroneIterator.Value.ToEntity.ArmorPct}"]
					returnIndex:Insert[${DroneIterator.Value.ID}]

				}
				else
				{
					;UI:UpdateConsole["Debug: Engage Target ${DroneIterator.Value.ID}"]
					engageIndex:Insert[${DroneIterator.Value.ID}]
				}
			}
			while ${DroneIterator:Next(exists)}
			if ${returnIndex.Used} > 0
			{
				EVE:DronesReturnToDroneBay[returnIndex]
			}
			if ${engageIndex.Used} > 0
			{
				EVE:DronesEngageMyTarget[engageIndex]
			}
		}
	}
}