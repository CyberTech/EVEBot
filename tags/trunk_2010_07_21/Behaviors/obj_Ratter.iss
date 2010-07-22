/*
	The ratter object

	The obj_Ratter object is a bot module designed to be used with
	EVEBOT.  The ratter bot will warp from belt to belt and wtfbbqpwn
	any NPC ships it finds.

	-- GliderPro
*/

objectdef obj_Ratter
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CurrentState
	variable time NextPulse
	variable int PulseIntervalInSeconds = 5
	variable float RatWaitCounter

	/* Cache for NPCs */
	variable obj_EntityCache RatCache
	variable index:int DoNotKillList

	/* Used for calculating battleship chain values */
	variable obj_Targets_Rats RatCalculator

	variable bool bPlayerCheck

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		BotModules:Insert["Ratter"]
		RatCache:UpdateSearchParams["Unused","CategoryID,CATEGORYID_ENTITY,radius,100000"]
		; Startup in fight mode, so that it checks current belt for rats, if we happen to be in one.
		This.CurrentState:Set["FIGHT"]

		UI:UpdateConsole["obj_Ratter: Initialized", LOG_MINOR]
	}


	method Pulse()
	{
		if !${Config.Common.BotMode.Equal[Ratter]}
		{
			if ${RatCache.PulseIntervalInSeconds} == 1
			{
				RatCache:SetUpdateFrequency[600]
			}
			return
		}
		
		if ${RatCache.PulseIntervalInSeconds} != 1
		{
			RatCache:SetUpdateFrequency[1]
		}

	  if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				This:SetState[]
			}

			bPlayerCheck:Set[${Targets.PC}]

    	This.NextPulse:Set[${Time.Timestamp}]
    	This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    	This.NextPulse:Update
		}
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	/* NOTE: The order of these if statements is important!! */

	;; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> *
	method SetState()
	{
		UI:UpdateConsole["obj_Ratter: Hiding: ${Defense.Hiding}, Hide Reason: ${Defense.HideReason}",LOG_DEBUG]
		if ${Defense.Hiding}
		{
			This.CurrentState:Set["DEFENSE_HAS_CONTROL"]
			return
		}

		if ${Me.InStation} == TRUE
		{
			This.CurrentState:Set["INSTATION"]
			return
		}

		UI:UpdateConsole["obj_Ratter: NPC Check: ${This.NPCCheck}",LOG_DEBUG]
		if ${Me.GetTargets} > 0 || (${This.NPCCheck} && !${Targets.PC})
		{
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			This.CurrentState:Set["STATE_CHANGE_BELT"]
		}
	}

	function ProcessState()
	{
		if !${Config.Common.BotMode.Equal[Ratter]}
		{
			return
		}
		UI:UpdateConsole["obj_Ratter: Processing State: ${This.CurrentState}",LOG_DEBUG]
		;UI:UpdateConsole["DEBUG: ${This.CurrentState}"]
		switch ${This.CurrentState}
		{
			case STATE_WAIT_WARP
				break
			case STATE_IDLE
			case IDLE
				break
			case DEFENSE_HAS_CONTROL
				if !${Defense.Hiding}
				{
					This.CurrentState:Set["STATE_IDLE"]
				}
				break
			case STATE_ABORT
				Call Station.Dock
				break
			case INSTATION
			case STATE_DOCKED
				if !${Defense.Hiding}
				{
					; TODO - this could cause dock/redock loops if armor or hull are below minimums, or if drones are still in shortage state -- CyberTech
					call Station.Undock
				}
				break
			case STATE_CHANGE_BELT
				Offense:Disable
				; TODO - check for use of belt bookmark object instead - CyberTech
				;if ${Config.Miner.UseFieldBookmarks}
				;{
				;	call BeltBookmarks.WarpToNext
				;}
				;else
				;{
					call Belts.WarpToNext
				;}
				Ship:Activate_SensorBoost
				This.CurrentState:Set["WAITING_FOR_RATS_1"]
				break
			case WAITING_FOR_RATS_1
				This.RatWaitCounter:Inc[0.5]
				if ${Targets.PC}
				{
					This.CurrentState:Set["STATE_CHANGE_BELT"]
				}
				elseif ${This.NPCCheck}
				{
					This.CurrentState:Set["WAITING_FOR_RATS_2"]
				}
				elseif ${This.RatWaitCounter} > 30
				{
					UI:UpdateConsole["Rats didn't show up, moving"]
					This.CurrentState:Set["STATE_CHANGE_BELT"]
				}
				else
				{
					wait 0.5
				}
				break
			case WAITING_FOR_RATS_2
				if ${This.RatWaitCounter} > 1
				{
					; If we had to wait for rats, Wait another second to try to let them get into range/out of warp
					wait 10
				}
				This.RatWaitCounter:Set[0]
				This.CurrentState:Set["FIGHT"]
				break
			case FIGHT
				if !${Offense.Running}
				{
					Offense:Enable
				}
				if !${Targeting.Running}
				{
					Targeting:Enable
				}

				This:QueueTargets
				break
			case STATE_ERROR
				UI:UpdateConsole["CurrentState is ERROR"]
				break
			default
				UI:UpdateConsole["Error: CurrentState is unknown value ${This.CurrentState}"]
				break
		}
	}

	function Move()
	{
		call Belts.WarpToNext

		; TODO - CyberTech - Make this a proper solution instead of this half-ass piss
		; Wait for the rats to warp into the belt. Reports are between 10 and 20 seconds.
		/* I plan to at the very least align to the next belt before waiting so that we'll
		be aligned and ready to go in case nothing shows up after our 30-second waitfest or
		social suddenly becomes unsafe. */
		variable int Count
		for (Count:Set[0] ; ${Count}<=30 ; Count:Inc)
		{
			if ${Targets.PC} || ${This.NPCCheck}
			{
				break
			}
			wait 10
		}

		if (${Count} > 1)
		{
			; If we had to wait for rats, Wait another second to try to let them get into range/out of warp
			wait 10
		}
	}

	/* QueueTargets(): Handle any queueing, prioritizing, chaining, etc. of rats.
		This will do pretty much nothing but queue targets. */
	method QueueTargets()
	{
		/* Activate any sensor boosters */
		Ship:Activate_SensorBoost

		/* Get total battleship value for chaining purposes */
		variable int iTotalBSValue = ${RatCalculator.CalcTotalBattleShipValue}

		variable bool bHaveSpecialTarget = FALSE
		variable bool bHaveMultipleTypes = FALSE
		variable bool bHavePriorityTarget = FALSE
		variable bool iTempTypeID

		RatCache.Entities:GetIterator[RatCache.EntityIterator]

		/* Start iterating through */
		if ${RatCache.EntityIterator:First(exists)}
		{
			do
			{
				/* Check for multiple types (if we only have one type of rat it's likely an in-progress chain) */
				if ${iTempTypeID} == 0
				{
					iTempTypeID:Set[${RatCache.EntityIterator.Value.TypeID}]
				}
				if ${iTempTypeID} != ${RatCache.EntityIterator.Value.TypeID}
				{
					bHaveMultipleTypes:Set[TRUE]
				}

				/* If this target is already queue in any way, continue on. */
				if ${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]} || ${Targeting.IsMandatoryQueued[${RatCache.EntityIterator.Value.ID}]} || \
					${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]} || ${This.IsDoNotKill[${RatCache.EntityIterator.Value.ID}]}
				{
					if ${Targeting.IsMandatoryQueued[${RatCache.EntityIterator.Value.ID}]}
					{
						bHavePriorityTarget:Set[TRUE]
					}
					UI:UpdateConsole["obj_Ratter: ${RatCache.EntityIterator.Value.ID} is queued, concord, or DNK, skipping in priority target iteration.", LOG_DEBUG]
					continue
				}

				/* Is our target a "priority" target? If so, we won't continue with the rest of the targeting/chaining until
				all priority targets are dead. Gotta kill those scrambling bastards... */
				if ${Targets.IsPriorityTarget[${RatCache.EntityIterator.Value.Name}]}
				{
					UI:UpdateConsole["obj_Ratter: We have a priority target: ${RatCache.EntityIterator.Value.Name}."]
					bHavePriorityTarget:Set[TRUE]
					/* 	method Queue(int EntityID, int Priority, int TargetType, bool Mandatory=FALSE, bool Blocker=FALSE) */
					/* Queue it mandatory so we make sure it dies. */
					UI:UpdateConsole["obj_Ratter: Queueing priority target: ${RatCache.EntityIterator.Value.Name}"]
					Targeting:Queue[${RatCache.EntityIterator.Value.ID},0,${RatCache.EntityIterator.Value.TypeID},TRUE,FALSE]
				}
			}
			while ${RatCache.EntityIterator:Next(exists)}
		}

		/* Now for the fun task of figuring out chaining. */
		/* If I'm chaining spawns and either I'm chaining solo or I'm not chaining solo but there are others here... */
		/* I also only want to actually chain it if the calculated BS value is above our threshold */
		if (${Config.Combat.ChainSpawns} || (${Config.Combat.ChainSolo} && ${EVE.LocalsCount} == 1)) && \
			${iTotalBSValue} >= ${Config.Combat.MinChainBounty}
		{
			/* Start iterating... */
			if ${RatCache.EntityIterator:First(exists)}
			{
				do
				{
					; If the target is already queued, just continue.
					if ${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]} || ${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]} || \
						${This.IsDoNotKill[${RatCache.EntityIterator.Value.ID}]}
					{
						UI:UpdateConsole["obj_Ratter: ${RatCache.EntityIterator.Value.ID} already queued, concord, or DNK, skipping", LOG_DEBUG]
						continue
					}

					; Since we're chaining, if it isn't a special spawn or a battleship, and we've already queued any priority targets, we don't want it.
					; Add it to do not kill.
					UI:UpdateConsole["obj_Ratter: Find Battleship? Name: ${RatCache.EntityIterator.Value.Name}, Group: ${RatCache.EntityIterator.Value.Group}, Exists? ${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)}, Mutli? ${bHaveMultipleTypes}", LOG_DEBUG]
					if !${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)} && !${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]} && !${bHavePriorityTarget}
					{
						UI:UpdateConsole["obj_Ratter: ${RatCache.EntityIterator.Value.Name} isn't a battleship or special target and we have no priority targets -- adding to DNK list.", LOG_DEBUG]
						DoNotKillList:Insert[${RatCache.EntityIterator.Value.ID}]
						continue
					}

					; If we have a special target, queue it higher priority.
					; Currently it does nothing because combat doesn't detect "higher priority" targets
					if ${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]}
					{
						UI:UpdateConsole["obj_Ratter: Queueing special target ${RatCache.EntityIterator.Value.Name}, ${RatCache.EntityIterator.Value.ID}.",LOG_CRITICAL]
						if ${Config.Common.UseSound}
						{
							Sound:PlayDetectSound
						}
						Targeting:Queue[${RatCache.EntityIterator.Value.ID},1,${RatCache.EntityIterator.Value.TypeID},FALSE,FALSE]
						continue
					}

					; Basically, the only way we get this far is our entity is a battleship we haven't queued.
					; So queue it!
					UI:UpdateConsole["obj_Ratter: Queueing chainable battleship ${RatCache.EntityIterator.Value.Name}",LOG_DEBUG]
					Targeting:Queue[${RatCache.EntityIterator.Value.ID},2,${RatCache.EntityIterator.Value.TypeID},FALSE,FALSE]
				}
				while ${RatCache.EntityIterator:Next(exists)}
			}
		}
		else
		{
			if ${RatCache.EntityIterator:First(exists)}
			{
				do
				{
					; If the target is already queued, just continue.
					if ${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]} || ${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]} || \
						${This.IsDoNotKill[${RatCache.EntityIterator.Value.ID}]}
					{
						UI:UpdateConsole["obj_Ratter: ${RatCache.EntityIterator.Value.ID} already queued, concord, or DNK, skipping", LOG_DEBUG]
						continue
					}

					; If we have a special target, queue it higher priority.
					; Currently it does nothing because combat doesn't detect "higher priority" targets
					if ${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]}
					{
						UI:UpdateConsole["obj_Ratter: Not chaining, queueing special target ${RatCache.EntityIterator.Value.Name}, ${RatCache.EntityIterator.Value.ID}.",LOG_CRITICAL]
						if ${Config.Common.UseSound}
						{
							Sound:PlayDetectSound
						}
						Targeting:Queue[${RatCache.EntityIterator.Value.ID},1,${RatCache.EntityIterator.Value.TypeID},FALSE,FALSE]
						continue
					}

					UI:UpdateConsole["obj_Ratter: Not chaining, queueing target ${RatCache.EntityIterator.Value.Name}.",LOG_DEBUG]
					Targeting:Queue[${RatCache.EntityIterator.Value.ID},2,${RatCache.EntityIterator.Value.TypeID},FALSE,FALSE]
				}
				while ${RatCache.EntityIterator:Next(exists)}
			}
		}
	}

	/* bool NPCCheck():
	return true if we have non-donotkill and non-concord npcs nearby and non-singletype */
	member:bool NPCCheck()
	{
		RatCache.Entities:GetIterator[RatCache.EntityIterator]
		variable bool HaveMultipleTypes = FALSE
		variable int TempTypeID
		if ${RatCache.EntityIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Ratter: ${RatCache.EntityIterator.Value.Type} ${RatCache.EntityIterator.Value.TypeID} ${RatCache.EntityIterator.Value.Group} ${RatCache.EntityIterator.Value.GroupID}",LOG_DEBUG]
				if ${TempTypeID} == 0
				{
					TempTypeID:Set[${RatCache.EntityIterator.Value.TypeID}]
				}
				if ${TempTypeID} != ${RatCache.EntityIterator.Value.TypeID}
				{
					HaveMultipleTypes:Set[TRUE]
					break
				}
			}
			while ${RatCache.EntityIterator:Next(exists)}
		}
		UI:UpdateConsole["obj_Ratter: HaveMultipleTypes? ${HaveMultipleTypes}",LOG_DEBUG]
		if ${RatCache.EntityIterator:First(exists)}
		{
			do
			{
				if !${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]} && \
				(${Targets.IsPriorityTarget[${RatCache.EntityIterator.Value.Name}]} || \
				${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]} || \
				${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)} || \
				${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]} || ${Targeting.IsMandatoryQueued[${RatCache.EntityIterator.Value.ID}]} || \
				(!${This.IsDoNotKill[${RatCache.EntityIterator.Value.ID}]} && ${HaveMultipleTypes})) || \
				!${Config.Combat.ChainSpawns}
				{
					return TRUE
				}
			}
			while ${RatCache.EntityIterator:Next(exists)}
		}
		return FALSE
	}

	/* bool IsDoNotKill(int entityID):
	return true if given entity ID is on our do not kill list, otherwise return false */
	member:bool IsDoNotKill(int entityID)
	{
		variable iterator DoNotKillIterator
		DoNotKillList:GetIterator[DoNotKillIterator]

		if ${DoNotKillIterator:First(exists)}
		{
			do
			{
				if ${DoNotKillIterator.Value} == ${entityID}
				{
					return TRUE
				}
			}
			while ${DoNotKillIterator:Next(exists)}
		}
		return FALSE
	}
}
