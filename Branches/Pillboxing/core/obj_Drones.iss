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

	method LaunchDrones(string SIZE)
	{
		variable index:item ListOfDrones
		variable iterator itty
		variable index:int64 ToLaunch
		MyShip:GetDrones[ListOfDrones]
		Switch "${SIZE}"
		{
			case LARGE
				ListOfDrones:RemoveByQuery[${LargeDroneQuery}]
				break
			case MEDIUM
				ListOfDrones:RemoveByQuery[${MediumDroneQuery}]
				break
			case LIGHT
				ListOfDrones:RemoveByQuery[${LightDroneQuery}]
				break
		}
		ListOfDrones:Collapse
		if ${ListOfDrones.Used} > 0
		{	
			ListOfDrones:GetIterator[itty]
			itty:First
			do
			{
				if ${itty.Value.Quantity} > 1
				{
					UI:UpdateConsole["This is a stack of drones, this may or may not fuck with things, but I suggest you manually launch them at least once. If it does fuck with things please report this to Pillboxing"]
				}
				ToLaunch:Insert[${itty.Value.ID}]
			}
			while ${itty:Next(exists)} && ${ToLaunch.Used} < 5
			EVE:LaunchDrones[ToLaunch]
		}
		else
		{
			UI:UpdateConsole["No ${SIZE.Lower} drones in bay"]
			;We should probably flee here and restock drones, hopefully no one loses a ship before this becomes a problem, but it shouldn't unless our secondary drones are popped in mission
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

	method LaunchPrimaryDrones()
	{
		if ${MyShip.DronebayCapacity} > 25 && ${MyShip.DronebayCapacity} < 125
		{
			This:LaunchDrones[MEDIUM]
		}
		elseif ${MyShip.DronebayCapacity.Equal[125]}
		{
			This:LaunchDrones[HEAVY]
		}
		elseif ${MyShip.DronebayCapacity} > 0 && ${MyShip.DronebayCapacity} <=25
		{
			This:LaunchDrones[LIGHT]
		}
	}

	method LaunchSecondaryDrones()
	{
		This:LaunchDrones[LIGHT]
	}

	function LaunchAll()
	{
		variable index:item ListOfDrones
		;This includes a check for sentry/heavy drones, going to have to put some SERIOUS beef into this method to select *which* drones to launch
		;BEEF IS ALMOST DONE, need to add support for just medium drones.
		if ${Time.Timestamp} > ${DroneTimer.Timestamp}
		{
			if ${This.NumberOfDronesInBay[LIGHT]} > 0 && \
			${Me.ActiveTarget.Name.NotEqual["Kruul's Pleasure Garden"]} && \
			${MyShip.DronebayCapacity} <= 50
			{
				UI:UpdateConsole["Launching drones..."]
				This:LaunchPrimaryDrones
				This.WaitingForDrones:Set[5]
				return
			}
			if ${Me.ActiveTarget.Radius} > 100 
			{
				This:LaunchPrimaryDrones
			}
			else
			{
				This:LaunchSecondaryDrones
			}
			This.WaitingForDrones:Set[5]
		}
		else
		{
			UI:UpdateConsole["Sorry sir, can't launch drones for another...I don't know how to calculate how long. Be patient :)."]
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
			if ${Me.ActiveTarget.Radius} < 100 && ${This.DronesOut} > 5
			{
				UI:UpdateConsole["We're frighting a frigate and have primary drones out, swapping to secondary."]
				This:SetAllDronesToReturn			
			}
			elseif ${Me.ActiveTarget.Radius} > 100 && ${This.DronesOut} != 10
			{
				UI:UpdateConsole["We're frighting something larger than a frigate and have secondary drones out, swapping to primary."]
				This:SetAllDronesToReturn
			}
			return
		}
		if ${MyShip.DronebayCapacity} >= 125
		{
			if ${Me.ActiveTarget.Radius} < 100 && ${This.DronesOut} > 5
			{
				UI:UpdateConsole["We're frighting a frigate and have primary drones out, swapping to secondary."]
				This:SetAllDronesToReturn			
			}
			elseif ${Me.ActiveTarget.Radius} > 100 && ${This.DronesOut} < 25
			{
				UI:UpdateConsole["We're frighting something larger than a frigate and have secondary drones out, swapping to primary."]
				This:SetAllDronesToReturn
			}
		}
		if (${This.DronesInSpace} > 0)
		{
			if ${Me.TargetedByCount} < ${Me.TargetCount}
			{
				This:SetAllDronesToReturn
				UI:UpdateConsole["We no longer have all agro, sucking drones back in my lord!"]
				return
			}
			Me:GetActiveDrones[ActiveDroneList]
			ActiveDroneList:GetIterator[DroneIterator]
			do
			{
				if ${DroneIterator.Value.ToEntity.ShieldPct} < 95
				{
					UI:UpdateConsole["Recalling Drones, a drone has sustained damage"]
					UI:UpdateConsole["Debug: Shield: ${DroneIterator.Value.ToEntity.ShieldPct}, Armor: ${DroneIterator.Value.ToEntity.ArmorPct}, Structure: ${DroneIterator.Value.ToEntity.StructurePct}"]
					This:SetAllDronesToReturn					
					DroneTimer:Set[${Time.Timestamp}]
					DroneTimer.Second:Inc[30]
					DroneTimer:Update
					return
				}
				else
				{
					;This is a check to see if drones are returning (if they are we don't want them to engage fuck all)
					if (${DroneIterator.Value.State} != 4)
					{
						if (${Targets.ToTarget.Used} > 0 && !${Targets.IsPriorityTarget[${DroneIterator.Value.Target.ID}]} && \
						 ${Combat.Config.DontKillFrigs} && ${Targets.IsPriorityTarget[${Me.ActiveTarget.ID}]}) || \
						!${Combat.Config.DontKillFrigs} || \
						(${Targets.ToTarget.Used.Equal[0]} && ${Combat.Config.DontKillFrigs} && ${Me.ActiveTarget.Radius} > 100)
						{
							;My fuck what a clusterfuck of an if statement!
							;UI:UpdateConsole["Debug: Engage Target ${DroneIterator.Value.ID}"]
							engageIndex:Insert[${DroneIterator.Value.ID}]
						}
					}
					else
					{
						UI:UpdateConsole["Drone is currently returning, drones not engaging"]
						;if one is returning all should be, and I'm pretty sure this will spam 4 more times otherwise, should be fine to call return here
						return
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
				else
				{
					UI:UpdateConsole["Active target is beyond drone control range, drones not engaging."]
				}
			}
		}
	}
}