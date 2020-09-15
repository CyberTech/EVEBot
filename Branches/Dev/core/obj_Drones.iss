/*
	Drone class

	Main object for interacting with the drones.  Instantiated by obj_Ship, only.

	-- CyberTech

*/

objectdef obj_Drones
{
	variable time NextPulse
	variable int PulseIntervalInSeconds = 3

	variable index:int64 ActiveDroneIDList
	variable int CategoryID_Drones = 18
	variable int LaunchedDrones = 0
	variable int WaitingForDrones = 0
	variable bool DronesReady = FALSE
	variable int ShortageCount

	variable string ActiveDroneType

	variable collection:float StoredDroneArmor
	variable collection:float StoredDroneShield
	variable index:int64	RecalledDrones
	variable iterator RecalledDroneIterator

	; All Drones
	;variable collection:int DroneCollection

	variable index:int64 ActiveDroneIDs
	variable iterator ActiveDroneID
	variable index:activedrone ActiveDrones
	variable iterator ActiveDrone
	variable index:item DronesInBay
	variable iterator DroneInBay

	; Initialize Specific Drone Lists
	variable index:int64 SniperDrones
	variable iterator SniperDrone
	variable index:int64 SentryDrones
	variable iterator SentryDrone
	variable index:int64 HeavyDrones
	variable iterator HeavyDrone
	variable index:int64 MediumDrones
	variable iterator MediumDrones

	; Specific Drone TypeID Lists
	variable index:int64 SniperDroneTypeIDs
	variable iterator SniperDroneTypeID
	variable index:int64 SentryDroneTypeIDs
	variable iterator SentryDroneTypeID
	variable index:int64 HeavyDroneTypeIDs
	variable iterator HeavyDroneTypeID
	variable index:int64 MediumDroneTypeIDs
	variable iterator MediumDroneTypeID

	method Initialize()
	{
		SniperDroneTypeIDs:Insert[23559]
		SniperDroneTypeIDs:Insert[23525]
		SniperDroneTypeIDs:Insert[23563]
		SniperDroneTypeIDs:Insert[28209]
		SniperDroneTypeIDs:Insert[28213]
		SniperDroneTypeIDs:Insert[28215]
		SentryDroneTypeIDs:Insert[23561]
		SentryDroneTypeIDs:Insert[28211]
		HeavyDroneTypeIDs:Insert[2476]
		HeavyDroneTypeIDs:Insert[2193]
		HeavyDroneTypeIDs:Insert[1201]
		HeavyDroneTypeIDs:Insert[2444]
		HeavyDroneTypeIDs:Insert[2478]
		HeavyDroneTypeIDs:Insert[2195]
		HeavyDroneTypeIDs:Insert[2436]
		HeavyDroneTypeIDs:Insert[2446]
		MediumDroneTypeIDs:Insert[2183]
		MediumDroneTypeIDs:Insert[15510]
		MediumDroneTypeIDs:Insert[2173]
		MediumDroneTypeIDs:Insert[15508]
		MediumDroneTypeIDs:Insert[2185]
		MediumDroneTypeIDs:Insert[21640]
		MediumDroneTypeIDs:Insert[2175]
		MediumDroneTypeIDs:Insert[21638]

		;get the drone type iterators
		SniperDroneTypeIDs:GetIterator[SniperDroneTypeID]
		SentryDroneTypeIDs:GetIterator[SentryDroneTypeID]
		HeavyDroneTypeIDs:GetIterator[HeavyDroneTypeID]
		MediumDroneTypeIDs:GetIterator[MediumDroneTypeID]

		ActiveDroneType:Set["None"]

		;echo "Sniper Drones in Bay: " ${This.HaveSniperDroneInBay}
		;echo "Sentry Drones in Bay: " ${This.HaveSentryDroneInBay}
		;echo "Heavy Drones in Bay : " ${This.HaveHeavyDroneInBay}
		;echo "Medium Drones in Bay: " ${This.HaveMediumDroneInBay}

		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["obj_Drones: Initialized", LOG_MINOR]
	}
	method Shutdown()
	{
		if ${Me.InSpace}
		{
			if (${Me.ToEntity.Mode} != 3)
			{
				Logger:Log["Recalling Drones prior to shutdown..."]
				EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			}
		}
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				if ${Me.InSpace}
				{
					if ${This.WaitingForDrones}
					{
						This.WaitingForDrones:Dec
						This.LaunchedDrones:Set[${This.DronesInSpace}]
						if  ${This.LaunchedDrones} > 0
						{
							This.WaitingForDrones:Set[0]
							This.DronesReady:Set[TRUE]
							Logger:Log["${This.LaunchedDrones} drones deployed"]
						}
					}
					else
					{
						This:CheckDroneHP
					}
				}
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
	/* CheckDroneHP - This method is here to iterate through all the drones, check their shield/armor % against
	any known previous value, if they haven't already been recalled, recall them, and store the current shield/armor hp. */
	method CheckDroneHP()
	{
		; TODO: Create obj_DroneStatus and store index:obj_DroneStatus to store hp/shield/armor in one construct and reduce code here.
		This:GetActiveDrones[]
		This.ActiveDrones:GetIterator[This.ActiveDrone]
		variable bool recalledDrone = FALSE
		variable bool relaunch = TRUE

		/* iterate over the index */
		if ${ActiveDrone:First(exists)}
		{
			do
			{
				;only do the checks if the drone has a valid ToEntity
				if ${ActiveDrone.Value.ToEntity(exists)} && ${ActiveDrone.Value.State} != ENTITY_STATE_COMBAT
				{
					Logger:Log["obj_Drones: Drone ${ActiveDrone.Value.ID}: Armor %: ${ActiveDrone.Value.ToEntity.ArmorPct}, Stored: ${StoredDroneArmor.Element[${ActiveDrone.Value.ID}]}, Shield %: ${ActiveDrone.Value.ToEntity.ShieldPct}, Stored: ${StoredDroneShield.Element[${ActiveDrone.Value.ID}]}",LOG_DEBUG]
					/* Only compare hp if the stored hp isn't null and activedrone is a valid entity*/
					Logger:Log["obj_Drones: Drone ${ActiveDrone.Value.ID}, state: ${ActiveDrone.Value.State}",LOG_DEBUG]
					if ${StoredDroneArmor.Element[${ActiveDrone.Value.ID}](exists)} && \
						${Math.Calc[${StoredDroneArmor.Element[${ActiveDrone.Value.ID}]} - ${ActiveDrone.Value.ToEntity.ArmorPct}]} > 2
					{
						if ${ActiveDrone.Value.ToEntity.ArmorPct} < ${StoredDroneArmor.Element[${ActiveDrone.Value.ID}]}
						{
							Logger:Log["obj_Drones: Drone ${ActiveDrone.Value.ID} is losing armor (${ActiveDrone.Value.ToEntity.ArmorPct} < ${StoredDroneArmor.Element[${ActiveDrone.Value.ID}]}). Recalling."]
							if ${ActiveDrone.Value.ToEntity.ArmorPct} < 50
							{
								;Recall it and do not relaunch it
								;This:RecallDrone[${ActiveDrone.Value},FALSE]
								;This:QuickReturnAllToDroneBay
								relaunch:Set[FALSE]
							}
							else
							{
								;This:RecallDrone[${ActiveDrone.Value}]
							  ;This:QuickReturnAllToDroneBay
							}
							;Flip our 'recalled' flag
							recalledDrone:Set[TRUE]
						}
					}
					/* Store current HP */
					StoredDroneArmor:Set[${ActiveDrone.Value.ID},${ActiveDrone.Value.ToEntity.ArmorPct}]
					;only do the shield check if we haven't already recalled
					if !${recalledDrone} && ${StoredDroneShield.Element[${ActiveDrone.Value.ID}](exists)} && \
						${Math.Calc[${StoredDroneShield.Element[${ActiveDrone.Value.ID}]} - ${ActiveDrone.Value.ToEntity.ShieldPct}]} > 2

					{
						if ${ActiveDrone.Value.ToEntity.ShieldPct} < ${StoredDroneShield.Element[${ActiveDrone.Value.ID}]}
						{
							Logger:Log["obj_Drones: Drone ${ActiveDrone.Value.ID} is losing shield (${ActiveDrone.Value.ToEntity.ShieldPct} < ${StoredDroneShield.Element[${ActiveDrone.Value.ID}]}). Recalling."]
							;This:RecallDrone[${ActiveDrone.Value}]
							;This:QuickReturnAllToDroneBay
							recalledDrone:Set[TRUE]
						}
					}
					StoredDroneShield:Set[${ActiveDrone.Value.ID},${ActiveDrone.Value.ToEntity.ShieldPct}]

				}
			}
			while ${ActiveDrone:Next(exists)} && !${recalledDrone}
		}
		if ${recalledDrone}
		{
			;This:QuickReturnAllToDroneBay
			;This:RecallDrone[${ActiveDrone.Value},${relaunch}]
			;return
			This:QuickReturnAllToDroneBay
			;This:QuickScoopAllToDroneBay
		}
	}

	member DroneIsRecalled(int64 DroneID)
	{
		/* Get an iterator to the recalled drones */
		RecalledDrones:GetIterator[RecalledDroneIterator]

		/* Iterate the index */
		if ${RecalledDroneIterator:First(exists)}
		{
			do
			{
				if ${RecalledDroneIterator.Value} == ${DroneID}
				{
					return TRUE
				}
			}
			while ${RecalledDroneIterator:Next(exists)}
		}
		return FALSE
	}

	method RecallDrone(activedrone Drone, bool Relaunchable=TRUE)
	{
		if ${Drone.ToEntity(exists)} && ${Drone.State} != ENTITY_STATE_DEPARTING && ${Drone.State} != ENTITY_STATE_DEPARTING_2
		{
			Logger:Log["obj_Drones: Recalling drone ${Drone.ID}, Relaunchable: ${Relaunchable}"]
			if !${Relaunchable}
			{
				RecalledDrones:Insert[${Drone.ID}]
			}
			Drone.ToEntity:ReturnToDroneBay
		}
	}

	method LaunchAll()
	{
		if ${MyShip.GetDrones} > 0
		{
			Logger:Log["Launching all drones..."]
			MyShip:LaunchAllDrones
			This.WaitingForDrones:Set[5]
		}
	}

	member:bool ShouldLaunchCombatDrones()
	{
		;Logger:Log["obj_Drones:ShouldLaunchCombatDrones(): ${Ship.InWarp} ${Defense.Hiding} ${Offense.HaveFullNPCAggro}",LOG_DEBUG]
		if ${Ship.InWarp} || ${Defense.Hiding}
		{
			return FALSE
		}

		if ${Offense.HaveFullNPCAggro} || ${Config.Common.Behavior.Equal["Missioneer"]}
		{
			return TRUE
		}
		return FALSE
	}

	member:int DronesInBay()
	{
		variable index:item DroneList
		MyShip:GetDrones[DroneList]
		return ${DroneList.Used}
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
		variable int DroneQuantitiyToMove = ${Math.Calc[${Config.Common.MinimumDronesInBay} - ${This.DronesInBay}]}
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
			;Logger:Log["obj_Drones:TransferToDroneBay: ${CargoIterator.Value.Name}"]
			CargoIterator.Value:MoveTo[${MyShip.ID}, DroneBay,1]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
		EVEWindow[MyDroneBay]:Close
		wait 10
	}

	method QuickReturnAllToDroneBay()
	{
		if ${This.ActiveDrone:First(exists)}
		{
			do
			{
				if ${This.ActiveDrone.Value.ToEntity.Distance} < 2500
				{
					This.ActiveDrone.Value.ToEntity:ScoopToDroneBay
					Logger:Log["obj_Drones: Scooping drone ${This.ActiveDrone.Value.ToEntity.Name} (${This.ActiveDrone.Value.ToEntity.ID})"]
					return
				}

				if ${This.ActiveDrone.Value.State} != ENTITY_STATE_DEPARTING && ${This.ActiveDrone.Value.State} != ENTITY_STATE_DEPARTING_2
				{
					EVE:Execute[CmdDronesReturnToBay]
					Logger:Log["obj_Drones: Returning all drones to bay."]
					return
				}
			}
			while ${This.ActiveDrone:Next(exists)}
		}
	}

	method QuickReturnAllToOrbit()
	{
		if ${This.ActiveDrone:First(exists)}
		{
			do
			{
				if ${This.ActiveDrone.Value.ToEntity.Distance} > 5000 &&
					${This.ActiveDrone.Value.State} != ENTITY_STATE_DEPARTING && 
					${This.ActiveDrone.Value.State} != ENTITY_STATE_DEPARTING_2
				{
					Logger:Log["obj_Drones: Returning all drones to orbit."]
					EVE:Execute[CmdDronesReturnAndOrbit]
					return
				}
			}
			while ${This.ActiveDrone:Next(exists)}
		}
	}

	function ReturnAllToDroneBay()
	{
		while ${This.DronesInSpace} > 0
		{
			Logger:Log["Recalling ${This.ActiveDroneIDList.Used} Drones"]
			;EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			EVE:Execute[CmdDronesReturnToBay]
			if (${MyShip.ArmorPct} < ${Config.Combat.MinimumArmorPct} || \
				${MyShip.ShieldPct} < ${Config.Combat.MinimumShieldPct})
			{
				; We don't wait for drones if we're on emergency warp out
				wait 10
				return
			}
			wait 50
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
;			variable index:int64 returnIndex
			variable index:int64 engageIndex

			if ${DroneIterator:First(exists)}
			{
				do
				{
					;This is all obsoleted by CheckDroneHP.
;					if ${DroneIterator.Value.ToEntity.ShieldPct} < 50 || \
;						${DroneIterator.Value.ToEntity.ArmorPct} < 80 || \
;						${DroneIterator.Value.ToEntity.StructurePct} < 100
;					{
;						Logger:Log["Recalling Damaged Drone ${DroneIterator.Value.ID}"]
;						;Logger:Log["Debug: Shield: ${DroneIterator.Value.ToEntity.ShieldPct}, Armor: ${DroneIterator.Value.ToEntity.ArmorPct}, Structure: ${DroneIterator.Value.ToEntity.StructurePct}"]
;						returnIndex:Insert[${DroneIterator.Value.ID}]
;
;					}
;					else
;					{
						; if Drone's target isn't our active target
						Logger:Log["obj_Drones: DroneIterator.Value.Target.ID: ${DroneIterator.Value.Target.ID}, Me.ActiveTarget.ID: ${Me.ActiveTarget.ID}",LOG_DEBUG]
						if ${DroneIterator.Value.Target.ID} != ${Me.ActiveTarget.ID} && \
							${DroneIterator.Value.State} != ENTITY_STATE_DEPARTING && \
							${DroneIterator.Value.State} != ENTITY_STATE_DEPARTING_2 && \
							(!${Config.Combat.ConserveDrones} || !${DroneIsRecalled[${DroneIterator.Value.ID}]})
						{
							engageIndex:Insert[${DroneIterator.Value.ID}]
						}
;					}
				}
				while ${DroneIterator:Next(exists)}
;				EVE:DronesReturnToDroneBay[returnIndex]
				EVE:DronesEngageMyTarget[engageIndex]
			}
		}
	}

/*
	Below here are the members/methods from Cade -- they are entirely untested in evebot,
	and I want to rearchitect some of it (generic calls instead of drone-type specific,
	etc)
*/
	method GetActiveDrones()
	{
		Me:GetActiveDrones[This.ActiveDrones]
	}

	method GetActiveDroneIDs()
	{
		Me:GetActiveDroneIDs[This.ActiveDroneIDs]
	}

	method GetDronesInBay()
	{
		variable int i = 1

		; Specific Drone Lists
		variable index:int64 SniperDrones
		variable iterator SniperDrone
		variable index:int64 SentryDrones
		variable iterator SentryDrone
		variable index:int64 HeavyDrones
		variable iterator HeavyDrone
		variable index:int64 MediumDrones
		variable iterator MediumDrones

		do
		{
			if ${This.IsSniperDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				SniperDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
			elseif ${This.IsSentryDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				SentryDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
			elseif ${This.IsHeavyDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				HeavyDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
			elseif ${This.IsMediumDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				MediumDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
		}
		while ${i:Inc} <= ${This.NumDronesInBay}
	}

	method LaunchDrones()
	{
		variable int i = 1

		; Build Specific Drone Lists
		do
		{
			if ${This.IsSniperDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				SniperDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
			elseif ${This.IsSentryDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				SentryDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
			elseif ${This.IsHeavyDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				HeavyDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
			elseif ${This.IsMediumDrone[${MyShip.Drone[${i}].TypeID}]}
			{
				MediumDrones:Insert[${MyShip.Drone[${i}].ID}]
			}
		}
		while ${i:Inc} <= ${This.NumDronesInBay}


		; Call Correct Drone Type Launch Function
		switch ${This.BestDroneType}
		{
			case Sniper
			{
				This:LaunchSniperDrones
				return
			}
			case Sentry
			{
				This:LaunchSentryDrones
				return
			}
			case Heavy
			{
				This:LaunchHeavyDrones
				return
			}
			case Medium
			{
				This:LaunchMediumDrones
				return
			}
		}
	}

	method LaunchSniperDrones()
	{
		if ${This.HaveSniperDroneInBay}
		{
			;echo "Launching Sniper Drones..."
			EVE:LaunchDrones[This.SniperDrones]
			This.ActiveDroneType:Set["Sniper"]
		}
	}

	method LaunchSentryDrones()
	{
		if ${This.HaveSentryDroneInBay}
		{
			;echo "Launching Sentry Drones..."
			EVE:LaunchDrones[This.SentryDrones]
			This.ActiveDroneType:Set["Sentry"]
		}
	}

	method LaunchHeavyDrones()
	{
		if ${This.HaveHeavyDroneInBay}
		{
			;echo "Launching Heavy Drones..."
			EVE:LaunchDrones[This.HeavyDrones]
			This.ActiveDroneType:Set["Heavy"]
		}
	}

	method LaunchMediumDrones()
	{
		if ${This.HaveMediumDroneInBay}
		{
			;echo "Launching Medium Drones..."
			EVE:LaunchDrones[This.MediumDrones]
			This.ActiveDroneType:Set["Medium"]
		}
	}

	method EngageDrones()
	{
		;echo "Engaging Drones..."
		EVE:DronesEngageMyTarget[This.ActiveDroneIDs]
	}

	method ReturnDrones()
	{
		;echo "Returning Drones"
		if ${This.NumActiveDrones} > 0
		{
			EVE:DronesReturnToDroneBay[This.ActiveDroneIDs]
		}
	}

	method ScoopDrones()
	{

	}

	method ActivateBestDroneTarget()
	{

	}

	method DroneSafetyScoop()
	{
		variable index:int64 ScoopedDrones

		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
		{
			do
			{
				if ${Entity[${ActiveDroneID.Value}].ShieldPct} < 50 && ${Entity[${ActiveDroneID.Value}].ShieldPct} != NULL
				{
					if ${Entity[${ActiveDroneID.Value}].Distance} < 1500
					{
						ScoopedDrones:Insert[${ActiveDroneID.Value}]
						echo "Scooping Drone: " ${ActiveDroneID.Value} ${Entity[${ActiveDroneID.Value}].ShieldPct}
						;EVE:DronesScoopToDroneBay[${ScoopedDrones}]
					}
				}
			}
			while ${ActiveDroneID:Next(exists)}
		}
		EVE:DronesScoopToDroneBay[ScoopedDrones]
	}


; ####################    MEMBERS


	member:int NumDronesInBay()
	{
		return ${MyShip.GetDrones}
	}

	member:int NumActiveDrones()
	{
		;echo "NumActiveDrones"
		return ${Me.GetActiveDroneIDs[This.ActiveDroneIDs]}
	}

	member:bool AreMaxDronesActive()
	{
		if ${Me.GetActiveDroneIDs} < ${Me.MaxActiveDrones}
			return TRUE

		return FALSE
	}

	member:string BestDroneType()
	{
		if ${Me.GetTargets} == 0
		{
			;echo "No Targets - Best Drone Type = NULL"
			return NULL
		}

		variable string activetargetgroup = ${Me.ActiveTarget.Group}
		variable int targetdistance = ${Me.ActiveTarget.Distance}

		Me:GetActiveDrones[This.ActiveDrones]

		if ${targetdistance} > 30000 && (${This.HaveSniperDroneInBay} || ${This.HaveActiveSniperDrone})
		{
			return "Sniper"
		}

		if ${targetdistance} > 15000 && (${This.HaveSentryDroneInBay} || ${This.HaveActiveSentryDrone})
		{
			return "Sentry"
		}

		if (${activetargetgroup.Find["Battleship"]} != NULL || ${activetargetgroup.Find["Battlecruiser"]} != NULL) && (${This.HaveHeavyDroneInBay} || ${This.HaveActiveHeavyDrone})
		{
			return "Heavy"
		}

		if ${This.HaveMediumDroneInBay} || ${This.HaveActiveMediumDrone}
		{
			return "Medium"
		}

		if ${This.HaveHeavyDroneInBay} || ${This.HaveActiveHeavyDrone}
		{
			return "Heavy"
		}
; smalls?
; ecm drones?
		else
		{
			echo "Cant find best drone type"
			return NULL
		}
	}

	member:bool HaveSniperDroneInBay()
	{
		variable int i = 1
		do
		{
			switch ${MyShip.Drone[${i}]}
			{
				case Bouncer I
				case Bouncer II
				case Warden I
				case Warden II
				case Curator I
				case Curator II
				{
					;echo "Have Sniper Drone in Bay"
					return TRUE
				}
			}
		}
		while ${i:Inc} <= ${This.NumDronesInBay}
		return FALSE
	}

	member:bool HaveSentryDroneInBay()
	{
		variable int i = 1
		do
		{
			switch ${MyShip.Drone[${i}]}
			{
				case Garde I
				case Garde II
				{
					;echo "Have Sentry Drone in Bay"
					return TRUE
				}
			}
		}
		while ${i:Inc} <= ${This.NumDronesInBay}
		return FALSE
	}

	member:bool HaveHeavyDroneInBay()
	{
		variable int i = 1
		do
		{
			switch ${MyShip.Drone[${i}]}
			{
				case Praetor I
				case Praetor II
				case Wasp I
				case Wasp II
				case Ogre I
				case Ogre II
				case Berserker I
				case Berserker II
				{
					;echo "Have Heavy Drone in Bay"
					return TRUE
				}
			}
		}
		while ${i:Inc} <= ${This.NumDronesInBay}
		return FALSE
	}

	member:bool HaveMediumDroneInBay()
	{
		variable int i = 1
		do
		{
			switch ${MyShip.Drone[${i}]}
			{
				case Infiltrator I
				case Infiltrator II
				case Vespa I
				case Vespa II
				case Hammerhead I
				case Hammerhead II
				case Valkyrie I
				case Valkyrie II
				{
					;echo "Have Medium Drone in Bay"
					return TRUE
				}
			}
		}
		while ${i:Inc} <= ${This.NumDronesInBay}
		return FALSE
	}

	member:bool HaveActiveSniperDrone()
	{
		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
			do
			{
				if ${This.IsSniperDrone[${Entity[${ActiveDroneID.Value}].TypeID}]}
					return TRUE
			}
			while ${ActiveDroneID:Next(exists)}
		return FALSE
	}

	member:bool HaveActiveSentryDrone()
	{
		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
			do
			{
				if ${This.IsSentryDrone[${Entity[${ActiveDroneID.Value}].TypeID}]}
					return TRUE
			}
			while ${ActiveDroneID:Next(exists)}

		return FALSE
	}

	member:bool HaveActiveHeavyDrone()
	{
		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
			do
			{
				if ${This.IsHeavyDrone[${Entity[${ActiveDroneID.Value}].TypeID}]}
					return TRUE
			}
			while ${ActiveDroneID:Next(exists)}

		return FALSE
	}

	member:bool HaveActiveMediumDrone()
	{
		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
			do
			{
				if ${This.IsMediumDrone[${Entity[${ActiveDroneID.Value}].TypeID}]}
					return TRUE
			}
			while ${ActiveDroneID:Next(exists)}

		return FALSE
	}

	member:bool IsSniperDrone(int typeid)
	{
		if ${SniperDroneTypeID:First(exists)}
			do
			{
				if ${SniperDroneTypeID.Value} == ${typeid}
					return TRUE
			}
			while ${SniperDroneTypeID:Next(exists)}

		return FALSE
	}

	member:bool IsSentryDrone(int typeid)
	{
		if ${SentryDroneTypeID:First(exists)}
			do
			{
				if ${SentryDroneTypeID.Value} == ${typeid}
					return TRUE
			}
			while ${SentryDroneTypeID:Next(exists)}

		return FALSE
	}

	member:bool IsHeavyDrone(int typeid)
	{
		if ${HeavyDroneTypeID:First(exists)}
			do
			{
				if ${HeavyDroneTypeID.Value} == ${typeid}
					return TRUE
			}
			while ${HeavyDroneTypeID:Next(exists)}

		return FALSE
	}

	member:bool IsMediumDrone(int typeid)
	{
		if ${MediumDroneTypeID:First(exists)}
			do
			{
				if ${MediumDroneTypeID.Value} == ${typeid}
					return TRUE
			}
			while ${MediumDroneTypeID:Next(exists)}

		return FALSE
	}

	member:bool DroneNeedsRepair()
	{
		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
			do
			{
				if ${Entity[${ActiveDroneID.Value}].ArmorPct} < 75
					return TRUE
			}
			while ${ActiveDroneID:Next(exists)}
		return FALSE
	}

	member:bool DronesNeedSafetyScoop()
	{
		ActiveDroneIDs:GetIterator[ActiveDroneID]
		if ${ActiveDroneID:First(exists)}
		{
			do
			{
				if ${Entity[${ActiveDroneID.Value}].ShieldPct} < 50 && ${Entity[${ActiveDroneID.Value}].ShieldPct} != NULL
				{
					if ${Entity[${ActiveDroneID.Value}].Distance} < 1500
					{
						return TRUE
					}
				}
			}
			while ${ActiveDroneID:Next(exists)}
		}
	}
}