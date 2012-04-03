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
	variable time DroneTimer
	variable uint LightDroneQuery = ${LavishScript.CreateQuery[Volume > "5"]}
	variable uint MediumDroneQuery = ${LavishScript.CreateQuery[Volume != "10"]}
	variable uint LargeDroneQuery = ${LavishScript.CreateQuery[Volume < "25"]}
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
    		    EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
    		}
		}
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	member:bool IsSentryDrone(int TypeID)
	{
		Switch ${TypeID}
		{
			case 23561
			case 28211
			case 31886
			case 31868
			case 23525
			case 28213
			case 23559
			case 28209
			case 31878
			case 31894
			case 23563
			case 28215
				return TRUE
			default
				return FALSE
		}
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
  				if (${This.LaunchedDrones} > 0)
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

	function LaunchLightDrones()
	{
		if ${This.WaitingForDrones} > 0
		{
			return
		}
		UI:UpdateConsole["Launching Light Drones."]
		variable index:item ListOfDrones
		variable iterator itty
		variable index:int64 ToLaunch
		MyShip:GetDrones[ListOfDrones]
		ListOfDrones:RemoveByQuery[${LightDroneQuery}]
		ListOfDrones:Collapse
		if ${ListOfDrones.Used} > 0
		{	
			ListOfDrones:GetIterator[itty]
			itty:First
			do
			{
			
				ToLaunch:Insert[${itty.Value.ID}]
			}
			while ${itty:Next(exists)} && ${ToLaunch.Used} < 5
			EVE:LaunchDrones[ToLaunch]
		}
		else
		{
			UI:UpdateConsole["No light drones in bay"]
			;We should probably flee here and restock drones, hopefully no one loses a ship before this becomes a problem, but it shouldn't unless our secondary drones are popped in mission
		}
	}

	method LaunchMediumDrones()
	{
		if ${This.WaitingForDrones} > 0
		{
			return
		}
		UI:UpdateConsole["Launching Medium Drones."]
		variable index:item ListOfDrones
		variable iterator itty
		variable index:int64 ToLaunch
		MyShip:GetDrones[ListOfDrones]
		ListOfDrones:RemoveByQuery[${MediumDroneQuery}]
		ListOfDrones:Collapse 
		if ${ListOfDrones.Used} > 0
		{	
			ListOfDrones:GetIterator[itty]
			itty:First
			do
			{
				UI:UpdateConsole["Launching ${itty.Value.Name}."]
				Launch:Insert[${itty.Value.ID}]
			}
			while ${itty:Next(exists)} && ${ToLaunch.Used} < 5
			EVE:LaunchDrones[ToLaunch]
		}
		else
		{
			UI:UpdateConsole["No Medium drones in bay"]
			;We should probably flee here and restock drones, hopefully no one loses a ship before this becomes a problem, but it shouldn't unless our secondary drones are popped in mission
		}
	}

	function LaunchSentryDrones()
	{
		if ${This.WaitingForDrones} > 0
		{
			return
		}
		UI:UpdateConsole["Launching Sentry drones in bay."]
		variable index:item ListOfDrones
		variable iterator itty
		variable index:int64 ToLaunch
		MyShip:GetDrones[ListOfDrones]
		ListOfDrones:RemoveByQuery[${LargeDroneQuery}]
		ListOfDrones:Collapse
		if ${ListOfDrones.Used} > 0
		{
			ListOfDrones:GetIterator[itty]
			itty:First
			do
			{	
				ToLaunch:Insert[${itty.Value.ID}]
			}
			while ${itty:Next(exists)} && ${ToLaunch.Used} < 5
		}
		if ${ToLaunch.Used} > 0
		{
			EVE:LaunchDrones[ToLaunch]
		}
		else
		{
			UI:UpdateConsole["No sentry drones found in bay, we should probably flee here."]
		}
	}

	member:int64 DroneTarget()
	{
		variable index:activedrone ListOfDrones
		if ${ListOfDrones.Used} > 0
		{
			return ${ListOfDrones[1].Target.ID}
		}	
	}

	function LaunchAll()
	{
		variable index:item ListOfDrones
		;This includes a check for sentry/heavy drones, going to have to put some SERIOUS beef into this method to select *which* drones to launch
		if ${This.DronesInBay} > 0 && \
		(${Me.ActiveTarget.Name.NotEqual["Kruul's Pleasure Garden"]} && \
		${Time.Timestamp} > ${DroneTimer.Timestamp} && \
		${MyShip.DronebayCapacity} <= 50
		{
			UI:UpdateConsole["Launching drones..."]
			MyShip:LaunchAllDrones
			This.WaitingForDrones:Set[5]
		}
		if ${MyShip.DronebayCapacity} > 50 && ${MyShip.DronebayCapacity} < 125
		{
			if ${Me.ActiveTarget.Radius} > 100
			{
				This:LaunchMediumDrones
			}
			if ${Me.ActiveTarget.Radius} < 100 
			{
				call This.LaunchLightDrones
			}
			This.WaitingForDrones:Set[5]
		}
	}

	member:int DronesInBay()
	{
		variable index:item DroneList
		variable iterator Itty
		MyShip:GetDrones[DroneList]
		DroneList:GetIterator[Itty]
		if ${DroneList.Used} <= 3
		{
			if ${Itty:First(exists)}
			{
				do
				{
					if ${Itty.Value.Quantity} > 1
					{
						return 5
						;assume we've refilled if there's a stack
					}
				}
				while ${Itty:Next(exists)}
			}
		}
		else
		{
			return ${DroneList.Used}
		}
	}

	member:int DronesInSpace()
	{
		Me:GetActiveDroneIDs[This.ActiveDroneIDList]
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
   			${This.DronesInSpace} < 3
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
			CargoIterator.Value:MoveTo[DroneBay,1]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
		EVEWindow[MyDroneBay]:Close
		wait 10
	}

	member:bool DronesKillingFrigate()
	{
		variable index:activedrone ListOfDrones
		Me:GetActiveDrones[ListOfDrones]
		if ${ListOfDrones[1].Target.Radius} < 100 && ${ListOfDrones[1].Target(exists)}
		{
			return TRUE
		}
		else
		{
			return FALSE
		}
	}
	
	function ReturnAllToDroneBay()
	{
		if ${This.WaitingForDrones} > 0
		{
			return	
		}
		
		Me:GetActiveDroneIDs[This.ActiveDroneIDList]
		UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
		EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
		wait 20
		
		while ${This.DronesInSpace} > 0
		{
			if ${MyShip.ArmorPct} < (${Config.Combat.MinimumArmorPct}-10)  || \ 
			${MyShip.ShieldPct} < (${Config.Combat.MinimumShieldPct} - 10) || \
			(${MyShip.ShieldPct} < 15 && ${Config.Combat.MinimumShieldPct} > 0) || \
			${MyShip.ArmorPct} < 15
			{
				UI:UpdateConsole["OUR SHIT IS FUCKED UP FUCK THE DRONES"]
				break
			}
			wait 20
		}
		
		return
	}

	member:int DronesOut()
	{
		;I think I'll make this member return the VOLUME of the first Drone in space, this will work fine unless we're going to do hybrid size launching (which is stupid!)
		variable index:activedrone ListOfDrones
		Me:GetActiveDrones[ListOfDrones]
		if ${ListOfDrones.Used} > 0
		{
			return ${Math.Calc[${ListOfDrones[1].ToEntity.Radius}-10]}
		}
		else
		{
			;UI:UpdateConsole["obj_drones: No drones in space, can't return drone type. Why is this member being checked?"]
			return 0
		}
	}

	method ActivateMiningDrones()
	{
		if !${This.DronesReady}
		{
			return
		}

		if (${This.DronesInSpace} > 0)
		{
			EVE:DronesMineRepeatedly[This.ActiveDroneIDList]
		}
	}

	member:int NumberOfDronesInBay(string DroneType)
	{
		variable index:item ListOfDrones
		variable iterator itty
		variable int Counter = 0
		MyShip:GetDrones[ListOfDrones]
		Switch "${DroneType}"
		{
			case SENTRY
			case HEAVY
				ListOfDrones:RemoveByQuery[${LavishScript.CreateQuery[Volume < "25"]}]
				break
			case MEDIUM
				ListOfDrones:RemoveByQuery[${LavishScript.CreateQuery[Volume != "10"]}]
				break
			case LIGHT
				ListOfDrones:RemoveByQuery[${LavishScript.CreateQuery[Volume > "5"]}]
				break
		}
		;At this point in time the ListOfDrones will only contain drones matching the volume of the type we're looking for
		ListOfDrones:Collapse
		ListOfDrones:GetIterator[itty]
		if ${itty:First(exists)}
		{
			do
			{
				if ${DroneType.Equal[SENTRY]}
				{
					if ${This.IsSentryDrone[${itty.Value.TypeID}]}
					{
						Counter:Inc[${itty.Value.Quantity}]
					}
				}
				else
				{
					Counter:Inc[${itty.Value.Quantity}]
				}
			}
			while ${itty:Next(exists)}
			return ${Counter}
		}
		else
		{
			return 0
		}

	}
	method SetAllDronesToReturn()
	{
		Me:GetActiveDroneIDs[This.ActiveDroneIDList]
		EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]	
	}

	method SendDrones()
	{
		variable iterator DroneIterator
		variable index:activedrone ActiveDroneList
		variable index:int64 engageIndex
		if !${This.DronesReady}
		{
			return
		}

		if ${MyShip.DronebayCapacity} > 50 && ${MyShip.DronebayCapacity} < 125
		{
			if ${Me.ActiveTarget.Radius} < 100 && ${This.DronesOut} != 10
			{
				This:SetAllDronesToReturn			
			}
			elseif ${Me.ActiveTarget.Radius} > 100 && ${This.DronesOut} > 5
			{
				This:SetAllDronesToReturn
			}
			return
		}
		if (${This.DronesInSpace} > 0)
		{
			Me:GetActiveDrones[ActiveDroneList]
			ActiveDroneList:GetIterator[DroneIterator]
			do
			{
				if ${DroneIterator.Value.ToEntity.ShieldPct} < 95
				{
					;UI:UpdateConsole["Recalling Damaged Drone ${DroneIterator.Value.ID}"]
					;UI:UpdateConsole["Debug: Shield: ${DroneIterator.Value.ToEntity.ShieldPct}, Armor: ${DroneIterator.Value.ToEntity.ArmorPct}, Structure: ${DroneIterator.Value.ToEntity.StructurePct}"]
					This:SetAllDronesToReturn					
					DroneTimer:Set[${Time.Timestamp}]
					DroneTimer.Second:Inc[30]
					DroneTimer:Update
					return
				}
				else
				{
					;This is a check to see if drones are returning (if they are we don't want them to engage fuck all), also a check to see if this drones target is our activetarget
					if (${DroneIterator.Value.State} != 4)
					{
						;UI:UpdateConsole["Debug: Engage Target ${DroneIterator.Value.ID}"]
						engageIndex:Insert[${DroneIterator.Value.ID}]
					}
				}
			}
			while ${DroneIterator:Next(exists)}

			if (${engageIndex.Used} > 0)
			{
				if ${Me.ActiveTarget.Distance} < ${Me.DroneControlDistance}
				{
					EVE:DronesEngageMyTarget[engageIndex]
				}
			}
		}
	}
}