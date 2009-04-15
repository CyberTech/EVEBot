

objectdef obj_MissionCombat
{
	variable string SVN_REVISION = "$Rev: 988 $"
	variable int Version
	variable obj_MissionCombatConfig MissionCombatConfig

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable string CurrentState

	variable int roomNumber = 0
	variable index:string targetBlacklist
	variable index:string priorityTargets
	variable string lootItem
	variable bool CommandComplete = FALSE
	variable bool MissionComplete = FALSE
	variable bool MissionUnderway = FALSE
	variable Time timeout
	variable iterator CommandIterator
	
	method Initialize()
	{
		;attach our pulse atom to the onframe even so we fire the pulse every frame
;		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	method Pulse()
	{
		if !${Config.Common.BotMode.Equal[Missioneer]}
		{
			; finish if we are not running missions, should be we finish if we are not running a combat mission
			return
		}
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				; if evebot is not paused we should figure out what state we want to be in
				This:SetState
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
;	method Shutdown()
;	{
;		; detach the atom when we get garbaged
;		Event[OnFrame]:DetachAtom[This:Pulse]
;	}

/* All of this should be getting called from Behaviors/obj_Missioneer.iss so
it will be handling the getting and turning in of missions. However, we do
need to handle going to locations for objectives. */
method SetState()
{
	/* Let defense handle any hiding */
	if ${Defense.Hiding}
	{
		This.CurrentState:Set["IDLE"]
	}
	/* Check if we're at our current objective's location - if not, we need
	to go to it. */
	
	/* If we're at the current objective's location, do an action for it. */
	
	/* If objective is complete, check for more objectives. If more exist, switch to next.
	Otherwise, mission is complete. */
	
	/* If we're looting/salvaging we'll probably need to switch to our loot/salvage
	ship. Go to the ship's location, get in it, come back. */
	
	/* If we're salvaging and here in our salvager, start salvaging/looting. */
	
	/* Go home, unload cargo, switch back to normal ship if we're in our salvager,
	let missioneer turnin. */
}

method ProcessState()
{
	switch ${This.CurrentState}
	{
		case "IDLE"
			break
		/* Somewhere in here will be a call to a method in this class that will
		process the objective command. It will not be done from the FSM. */
	}
}



;	method SetState()
;	{
;		; we have an iterator that should be set to the first command in a series of commands in a mission
;		if ${CommandIterator.IsValid}
;		{
;			;we find whatever action is to be taken , it should be an attribute called "Action"
;			switch ${This.${CommandIterator.Value.FindAttribute["Action"].String}}
;			{
;				case "Approach":
;				{
;					CurrentState:Set["Approach"]
;				}
;				case "ApproachNoBlock":
;				{
;					CurrentState:Set["ApproachNoBlock"]
;				}
;				case "Kill":
;				{
;					CurrentState:Set["Kill"]
;				}
;				case "CheckForLoot":
;				{
;					CurrentState:Set["CheckForLoot"]
;				}
;				case "ClearRoom":
;				{
;					CurrentState:Set["ClearRoom"]
;				}
;				case "KillAgressors":
;				{
;					CurrentState:Set["KillAgressors"]
;				}
;				case "NextRoom":
;				{
;					CurrentState:Set["NextRoom"]
;				}
;				case "TargetPrioritys":
;				{
;					CurrentState:Set["TargetPriorities"]
;				}
;				case "WaitForAggro":
;				{
;					CurrentState:Set["WaitForAggro"]
;				}
;			}
;		}
;		else
;		{
;			;if our command iterator is not valid ,we either ran out of commands or we have not been given any
;			CurrentState:Set["Idle"]
;		}
;	}
;
;	method ProccessState()
;	{
;		if !${Config.Common.BotMode.Equal[Missioneer]}
;		{
;			; There's no reason at all for the bot to be doing this if it's not a missioneer
;			return
;		}
;		switch ${This.CurrentState}
;		{
;			case "Approach":
;			{
;				call This.Approach ${CommandIterator.Value.FindAttribute["Target"].String}
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "ApproachNoBlock":
;			{
;				This:ApproachNoBlock[${CommandIterator.Value.FindAttribute["Target"].String}]
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "Kill":
;			{
;				call This.Kill ${CommandIterator.Value.FindAttribute["Target"].String}
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "CheckForLoot":
;			{
;				call This.LootItem ${CommandIterator.Value.FindAttribute["Item"]} ${CommandIterator.Value.FindAttribute["ContainerType"]}
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "ClearRoom":
;			{				
;				call This.ClearRoom
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "KillAgressors":
;			{
;				call This.KillAggressors
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "NextRoom":
;			{
;				call This.NextRoom
;				if ${Return}
;				{
;					CommandIterator:Next
;				}
;			}
;			case "TargetPriorities":
;			{
;				variable iterator settingIterator
;				CommandIterator:GetSettingIterator[settingIterator]
;				This:TargetPriorities settingIterator					
;			}
;			case "WaitForAggro":
;			{
;				
;				if ${This.AggroCount > 0}
;				{
;					CommandIterator:Next
;				}
;			}
;			case Idle:
;			return
;		}
;	}

	function:bool RunMission(settingsetref commandPile)
	{
		variable time breakTime
		variable int  gateCounter = 0
		variable int  doneCounter = 0
		variable iterator CommandIterator
		variable iterator ParameterIterator
		while TRUE
		{
			commandPile:GetSetIterator[CommandIterator]
			if ${CommandIterator:First(exists)}
			{
				do
				{
					if !${Combat.Fled}
					{
						CommandIterator.Value:GetSettingIterator[ParameterIterator]
						if ${ParameterIterator:First(exists)}
						{
							do
							{
								if !${Defense.Hiding}
								{
									UI:UpdateConsole["obj_MissionCombat: DEBUG: Calling ${CommandIterator.Value.FindAttribute[Action].String} parameter : ${ParameterIterator.Value.String}"]
									call This.${CommandIterator.Value.FindAttribute["Action"].String} "${ParameterIterator.Value.String}"
								}
								else
								{
									return FALSE
								}
							}
							while ${ParameterIterator:Next(exists)}
						}
						else
						{
							if !${Defense.Hiding}
							{
								UI:UpdateConsole["obj_MissionCombat: DEBUG: Calling ${CommandIterator.Value.FindAttribute[Action].String}"]
								call This.${CommandIterator.Value.FindAttribute["Action"].String}
							}
							else
							{
								return FALSE
							}
						}
					}
					else
					{
						break
					}
					wait 20 ; pause here as running stuff like checkcans after hostilecount reaches zero can be too fast sometimes
				}
				while ${CommandIterator:Next(exists)}
				UI:UpdateConsole["obj_MissionCombat: DEBUG: Mission commands exhausted , mission complete? "]
				return TRUE
			}
			UI:UpdateConsole["obj_MissionCombat: DEBUG: no commands for mission!"]
			return FALSE
		}
	}


	; ------ USER AVALIABLE FUNCTIONS - users will be able to call these ones!
	; TODO - this should not be a function, it should be a method
	function TargetAggros()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable bool blacklisted = FALSE
		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		;;UI:UpdateConsole["GetTargeting = ${_Me.GetTargeting}, GetTargets = ${_Me.GetTargets}"]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.IsTargetingMe} && !${Targeting.IsQueued[${targetIterator.Value.ID}]}
				{
					targetBlacklist:GetIterator[blackListIterator]
					; Check the target blacklist and ignore anything on it
					if ${blackListIterator:First(exists)}
					{
						do
						{
							if ${blackListIterator.Value.Equal[${targetIterator.Value.Name}]}
							{
								blacklisted:Set[TRUE]
								break
							}
							echo ${targetIterator.Value.Name}

						}
						while ${blackListIterator:Next(exists)}
					}
					if !${blacklisted}
					{
						; target is not blacklisted so lock it up
						Targeting:Queue[${targetIterator.Value.ID},1,1,FALSE]
					}
					else
					{
						blacklisted:Set[FALSE]
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}

	; TODO - move guts into movement thread
	function UseGateStructure(string gateName)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLEOBJECT]
		targetIndex:GetIterator[targetIterator]
		if ${targetIterator:First(exists)}
		{
			do
			{

				if ${targetIterator.Value.Name.Equal[${gateName}]}
				{
					call Ship.Approach ${targetIterator.Value.ID} DOCKING_RANGE
					wait 10
					call Ship.WarpPrepare
					ui:UpdateConsole["Activating Acceleration Gate..."]
					while !${Ship.WarpEntered}
					{
						targetIterator.Value:Activate
						wait 50
					}
					call Ship.WarpWait
					break
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}

	; TODO - move into movement thread
	function ApproachGate()
	{
		Entity[TypeID,TYPE_ACCELERATION_GATE]:Approach
		wait 10
	}

	; TODO - move guts into Ship.Approach except for roonumer:inc
	function NextRoom()
	{
		call Ship.Approach ${Entity[TypeID,TYPE_ACCELERATION_GATE].ID} DOCKING_RANGE
		wait 10
		call Ship.WarpPrepare
		ui:UpdateConsole["Activating Acceleration Gate..."]
		while !${Ship.WarpEntered}
		{
			Entity[TypeID,TYPE_ACCELERATION_GATE]:Activate
			wait 50
			/* ADD CODE TO UNSTICK SHIP HERE */
		}
		call Ship.WarpWait
		roomNumber:Inc
	}

	; TODO - should be method
	function IgnoreEntity(string entityName)
	{
		targetBlacklist:Insert[${entityName}]
	}

	; TODO - should be method
	function PrioritzeEntity(string entityName)
	{
		priorityTargets:Insert[${entityName}]
	}

	; TODO - should be calling ship.approach (eventually movement thread)
	function Approach(string entityName)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable entity closestMatch
		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.Name.Equal[${entityName}]}
				{
					if ${targetIterator.Value.Distance < closestMatch.Distance}
					{
						closestMatch = targetIterator.Value
					}
				}
			}
			while ${targetIterator:Next(exists)}
			Entity[${closestMatch.EntityID}]:Approach
		}
	}

	; TODO - infinite loop. should be part of FSM
	function WaitAggro(int aggroCount = 1)
	{
		while TRUE
		{
			if ${This.AggroCount} >= ${aggroCount}
			{
				break
			}
		}
	}

	; TODO - should be part of FSM
	function KillAggressors()
	{
		while TRUE
		{
			call This.TargetAggros
			wait 50
			if ${This.AggroCount < 1}
			{
				break
			}
			waitframe
		}
	}

	; TODO - should be part of FSM
	function ClearRoom()
	{
		while TRUE
		{
			call This.TargetAggros
			wait 20
			if ${This.HostileCount} < 1
			{
				UI:UpdateConsole["obj_MissionCombat.ClearRoom: DEBUG: Hostile count is zero! Room cleared"]
				break
			}
			if ${This.AggroCount} < 1
			{
				UI:UpdateConsole["obj_MissionCombat.ClearRoom: DEBUG: No aggression, Pulling nearest"]
				call This.PullNearest
				wait 20
			}
			waitframe
		}
	}

	; TODO - spams targeting queue. spams ship.approach. move logic to FSM
	function Kill(string entityName)
	{
		; For the moment this will find the closest entity with a matching name
		variable index:entity targetIndex
		variable iterator     targetIterator
		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.Name.Equal[${entityName}]}
				{
					do
					{
						Targeting:Queue[${targetIterator.Value.ID},1,1,TRUE]
						if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
						{
							call Ship.Approach ${targetIterator.Value.ID} ${Ship.OptimalTargetingRange}
						}
					}
					while ${targetIterator.Value.Name(exists)}
					break
				}
			}
			while ${targetIterator:Next(exists)}

		}
	}

	; TODO: Waiting for next wave should be part of FSM
	function Waves(int timeoutMinutes)
	{
		UI:UpdateConsole["obj_Missions.Waves: DEBUG: Waiting for waves , timeout ${timeoutMinutes} minutes"]
		variable time WaitTimeOut
		while TRUE
		{
			call This.ClearRoom
			WaitTimeOut:Set[${Time.Timestamp}]
			WaitTimeOut.Minute:Inc[${timeoutMinutes}]
			WaitTimeOut:Update

			while ${This.HostileCount} < 1
			{
				if ${Time.Timestamp} >= ${WaitTimeOut.Timestamp}
				{
					UI:UpdateConsole["obj_Missions.Waves: DEBUG: No hostiles present after timer expired, Waves finished"]
					return
				}
			}
		}
	}

	; TODO: FSM
	function WaitTargetQueueZero()
	{
		while ${Math.Calc[${Targeting.QueueSize} + ${Targeting.TargetCount}]} > 0
		{
			waitframe
		}
	}

	; TODO: Move to Targeting.SelectTarget module
	function PullNearest()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		/* FOR NOW just pull the closest target */
		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}
				{
					;UI:UpdateConsole["obj_Missions: DEBUG: Pulling ${targetIterator.Value} (${targetIterator.Value.ID})..."]
					UI:UpdateConsole["obj_Missions: DEBUG: Group = ${targetIterator.Value.Group} GroupID = ${targetIterator.Value.GroupID} IsNPCTarget : ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}"]

					if !${Targeting.IsQueued[${targetIterator.Value.ID}]}
					{
						Targeting:Queue[${targetIterator.Value.ID},1,1,FALSE]
					}

					if ${targetIterator.Value.Distance} > ${Ship.OptimalWeaponRange}
					{

						call Ship.Approach ${targetIterator.Value.ID} ${Ship.OptimalWeaponRange}
					}
					while !${targetIterator.Value(exists)}
					{
						;pew pew untill something targets us or it dies
						if ${targetIterator.Value.Distance} > ${Ship.${Ship.OptimalWeaponRange}}
						{
							call Ship.Approach ${targetIterator.Value.ID} ${Ship.OptimalWeaponRange}
						}
						waitframe
						if ${This.AggroCount} > 0
						{
							break
						}
					}
					return
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}

	; TODO: FSM
	function KillStructure(string structureName)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${structureName.Equal[${targetIterator.Value.Name}]}
				{
					UI:UpdateConsole["obj_Missions.KillStructure: DEBUG: Found ${structureName} shooting it"]
					do
					{
						Targeting:Queue[${targetIterator.Value.ID},1,1,TRUE]
						if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
						{
							call Ship.Approach ${targetIterator.Value.ID} ${Ship.OptimalTargetingRange}
						}
					}
					while ${targetIterator.Value.Name(exists)}
					break
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}

	; TODO: LS doesn't support get/set calls, so don't try to fake them. things should just set lootItem directly
	function LootItem(string Item)
	{
		lootItem:Set["${Item}"]
	}

	; TODO - FSM - this function could last 30 minutes in it's current form!
	function CheckSpawnContainers()
	{
		variable iterator containerIterator
		variable index:entity containerIndex
		EVE:DoGetEntities[containerIndex, GroupID, GROUPID_SPAWN_CONTAINER]
		containerIndex:GetIterator[containerIterator]
		if ${containerIterator:First(exists)}
		{
			UI:UpdateConsole["obj_Missions: There are ${containerIndex.Used} cargo containers nearby."]
			do
			{
				call Ship.Approach ${containerIterator.Value.ID} LOOT_RANGE
				call This.LootEntity ${containerIterator.Value.ID}
				if ${Return} > 0
				{
					; for now assume there is only one bit of loot to loot!
					break
				}
			}
			while ${containerIterator:Next(exists)}
		}
	}

	; TODO - FSM - this function could last 30 minutes in it's current form!
	; TODO - Functionally identical to CheckSpawnContainers
	function CheckCans()
	{
		variable iterator containerIterator
		variable index:entity containerIndex
		EVE:DoGetEntities[containerIndex, TypeID, 23]
		containerIndex:GetIterator[containerIterator]
		if ${containerIterator:First(exists)}
		{
			UI:UpdateConsole["obj_Missions: There are ${containerIndex.Used} cargo containers nearby."]
			do
			{
				call Ship.Approach ${containerIterator.Value.ID} LOOT_RANGE
				call This.LootEntity ${containerIterator.Value.ID}
				if ${Return} > 0
				{
					; for now assume there is only one bit of loot to loot!
					break
				}
			}
			while ${containerIterator:Next(exists)}
		}
	}

	; TODO - FSM - this function could last 30 minutes in it's current form!
	; TODO - Functionally identical to CheckSpawnContainers and CheckWrecks
	function CheckWrecks(string shipName)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUPID_WRECK]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.Name.Find[${shipName}]} > 0
				{
					call Ship.Approach ${targetIterator.Value.ID} LOOT_RANGE
					call This.LootEntity ${targetIterator.Value.ID}
					if ${Return} > 0
					{
						; for now assume there is only one bit of loot to loot!
						break
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}

	; TODO - I see no reason to have an approach for a specific object type when name is adequate
	function ApproachCollidableObject(string objectName)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLEOBJECT]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.Name.Equal[${objectName}]}
				{
					targetIterator.Value:Approach
					break
				}
			}
			while ${targetIterator:Next(exists)}
		}
	}

	; ------------------ END OF USER FUNCTIONS

	; TODO - use of targetBlacklist appears to be more of a target ignore list; rename as appropriate
	member:int AggroCount()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable int hostileCount = 0

		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${targetIterator.Value.IsTargetingMe}
				{
					targetBlacklist:GetIterator[blackListIterator]
					if ${blackListIterator:First(exists)}
					{
						do
						{
							if ${blackListIterator.Value.Equal[${targetIterator.Value.Name}]}
							{
								continue
							}
							hostileCount:Inc
						}
						while ${blackListIterator:Next(exists)}
					}
					else
					{
						hostileCount:Inc
						echo ${hostileCount}
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
		return ${hostileCount}
	}

	; TODO - move to obj_Target
	member:bool IsNPCTarget(int groupID)
	{
		switch ${groupID}
		{
			case GROUP_LARGECOLLIDABLEOBJECT
			case GROUP_LARGECOLLIDABLESHIP
			case GROUP_LARGECOLLIDABLESTRUCTURE
			case GROUP_SENTRYGUN
			case GROUP_CONCORDDRONE
			case GROUP_CUSTOMSOFFICIAL
			case GROUP_POLICEDRONE
			case GROUP_CONVOYDRONE
			case GROUP_FACTIONDRONE
			case GROUP_BILLBOARD
			return FALSE
			break
			default
			return TRUE
			break
		}

		return TRUE
	}

	; TODO - move to Target.TargetSelect module
	; TODO move blacklist/ignorelist to same
	member:int HostileCount()
	{
		variable index:entity targetIndex
		variable iterator     targetIterator
		variable iterator blackListIterator
		variable int hostileCount = 0
		variable bool blackListed = FALSE

		EVE:DoGetEntities[targetIndex, CategoryID, CATEGORYID_ENTITY]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsNPCTarget[${targetIterator.Value.GroupID}]}
				{
					targetBlacklist:GetIterator[blackListIterator]
					if ${blackListIterator(exists)}
					{
						do
						{
							if ${blackListIterator.Value.Equal[${targetIterator.Value.Name}]}
							{
								blackListed:Set[TRUE]
								break
							}
						}
						while ${blackListIterator:Next(exists)}
						if !${blackListed}
						{
							hostileCount:Inc
						}
						else
						{
							blackListed:Set[FALSE]
						}
					}
				}
			}
			while ${targetIterator:Next(exists)}
		}
		return ${hostileCount}
	}

	member:int ContainerCount()
	{
		return 0
	}

	member:bool GatePresent()
	{
		variable index:entity gateIndex

		EVE:DoGetEntities[gateIndex, TypeID, TYPE_ACCELERATION_GATE]

		UI:UpdateConsole["obj_Missions: DEBUG There are ${gateIndex.Used} gates nearby."]

		return ${gateIndex.Used} > 0
	}

	member:bool IsSpecialStructure(int agentID,string structureName)
	{
		variable string missionName

		;;;UI:UpdateConsole["obj_Agents: DEBUG: IsSpecialStructure(${agentID},${structureName}) >>> ${This.MissionCache.Name[${agentID}]}"]

		missionName:Set[${This.MissionCache.Name[${agentID}]}]
		if ${missionName.NotEqual[NULL]}
		{
			UI:UpdateConsole["obj_Missions: DEBUG: missionName = ${missionName}"]
			if ${missionName.Equal["avenge a fallen comrade"]} && ${structureName.Equal["habitat"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["break their will"]} && ${structureName.Equal["repair outpost"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["the hidden stash"]} && ${structureName.Equal["warehouse"]}
			{
				return TRUE
			}
			elseif ${missionName.Equal["secret pickup"]} && ${structureName.Equal["recon outpost"]}
			{
				return TRUE
			}
		}

		return FALSE
	}

	member:bool SpecialStructurePresent(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		UI:UpdateConsole["obj_Missions: DEBUG: SpecialStructurePresent found ${targetIndex.Used} structures"]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialStructure[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return TRUE
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return FALSE
	}

	member:int SpecialStructureID(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialStructure[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return ${targetIterator.Value.ID}
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return -1
	}

	member:bool IsSpecialWreck(int agentID,string wreckName)
	{
		variable string missionName

		;;;UI:UpdateConsole["obj_Missions: DEBUG: IsSpecialWreck(${agentID},${wreckName}) >>> ${This.MissionCache.Name[${agentID}]}"]

		missionName:Set[${This.MissionCache.Name[${agentID}]}]
		if ${missionName.NotEqual[NULL]}
		{
			UI:UpdateConsole["obj_Missions: DEBUG: missionName = ${missionName}"]
			if ${missionName.Equal["smuggler interception"]} && \
			${wreckName.Find["transport"]} > 0
			{
				return TRUE
			}
			; elseif {...}
			; etc...
		}

		return FALSE
	}

	member:bool SpecialWreckPresent(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		UI:UpdateConsole["obj_Missions: DEBUG: SpecialWreckPresent found ${targetIndex.Used} wrecks",LOG_MINOR]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialWreck[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return TRUE
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return FALSE
	}

	member:int SpecialWreckID(int agentID)
	{
		variable index:entity targetIndex
		variable iterator     targetIterator

		EVE:DoGetEntities[targetIndex, GroupID, GROUP_LARGECOLLIDABLESTRUCTURE]
		targetIndex:GetIterator[targetIterator]

		if ${targetIterator:First(exists)}
		{
			do
			{
				if ${This.IsSpecialWreck[${agentID},${targetIterator.Value.Name}]} == TRUE
				{
					return ${targetIterator.Value.ID}
				}
			}
			while ${targetIterator:Next(exists)}
		}

		return -1
	}

	; TODO - move to obj_Cargo
	function:int LootEntity(int entityID)
	{
		variable index:item ContainerCargo
		variable iterator Cargo
		variable int QuantityToMove
		variable int lootedamount = 0
		UI:UpdateConsole["DEBUG: obj_Missions.LootEntity  ${typeID}"]

		Entity[${entityID}]:OpenCargo
		wait 80
		Entity[${entityID}]:DoGetCargo[ContainerCargo]
		ContainerCargo:GetIterator[Cargo]
		if ${Cargo:First(exists)}
		{
			do
			{
				UI:UpdateConsole["DEBUG: obj_Missions.LootEntity: Found ${Cargo.Value.Quantity} x ${Cargo.Value.Name} - ${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}m3"]

				if ${Cargo.Value.Name.Equal[${lootItem}]}
				{
					QuantityToMove:Set[${Cargo.Value.Quantity}]

					UI:UpdateConsole["DEBUG: obj_Missions.LootEntity: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
					if ${QuantityToMove} > 0
					{
						Cargo.Value:MoveTo[MyShip,${QuantityToMove}]
						lootedamount:Inc[${QuantityToMove}]
						wait 30
					}
				}
			}
			while ${Cargo:Next(exists)}
		}
		Me.Ship:StackAllCargo
		wait 10
		return ${lootedamount}
	}

	;TODO - move to obj_Cargo
	;TODO - member will fail if called without cargo open
	member:bool HaveLoot(int agentID)
	{
		variable int        QuantityRequired
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		;;Agents:SetActiveAgent[${Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${EVEDB_Items.Volume[${itemName}]}]}]

		;;; Check the cargohold of your ship
		MyShip:DoGetCargo[CargoIndex]
		CargoIndex:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				TypeID:Set[${CargoIterator.Value.TypeID}]
				ItemQuantity:Set[${CargoIterator.Value.Quantity}]
				;;UI:UpdateConsole["DEBUG: HaveLoot: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				(${ItemQuantity} >= ${QuantityRequired})
				{
					UI:UpdateConsole["DEBUG: HaveLoot: Found required items in ship's cargohold."]
					haveCargo:Set[TRUE]
				}
			}
			while ${CargoIterator:Next(exists)}
		}

		return ${haveCargo}
	}
}
