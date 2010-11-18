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
	variable int Rat_CacheID
	variable iterator Rat_CacheIterator

	variable index:int64 DoNotKillList

	/* Used for calculating battleship chain values */
	variable obj_Targets_Rats RatCalculator

	variable bool bPlayerCheck

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		BotModules:Insert["Ratter"]

		This.Rat_CacheID:Set[${EntityCache.AddFilter["obj_Ratter", CategoryID = CATEGORYID_ENTITY && IsNPC = 1 && IsMoribund = 0, 2.0]}]
		EntityCache.EntityFilters.Get[${This.Rat_CacheID}].Entities:GetIterator[Rat_CacheIterator]

		; Startup in fight mode, so that it checks current belt for rats, if we happen to be in one.
		This.CurrentState:Set["FIGHT"]

		UI:UpdateConsole["obj_Ratter: Initialized", LOG_MINOR]
	}


	method Pulse()
	{
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
		if ${Config.Common.BotMode.NotEqual[Ratter]}
		{
			return
		}

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
		if ${Config.Common.BotMode.NotEqual[Ratter]}
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
					wait 5
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

		/* Start iterating through */
		if ${This.Rat_CacheIterator:First(exists)}
		{
			do
			{
				/* Check for multiple types (if we only have one type of rat it's likely an in-progress chain) */
				if ${iTempTypeID} == 0
				{
					iTempTypeID:Set[${This.Rat_CacheIterator.Value.TypeID}]
				}
				if ${iTempTypeID} != ${This.Rat_CacheIterator.Value.TypeID}
				{
					bHaveMultipleTypes:Set[TRUE]
				}

				/* If this target is already queue in any way, continue on. */
				if ${Targeting.IsQueued[${This.Rat_CacheIterator.Value.ID}]} || ${Targeting.IsMandatoryQueued[${This.Rat_CacheIterator.Value.ID}]} || \
					${Offense.IsConcordTarget[${This.Rat_CacheIterator.Value.GroupID}]} || ${This.IsDoNotKill[${This.Rat_CacheIterator.Value.ID}]}
				{
					if ${Targeting.IsMandatoryQueued[${This.Rat_CacheIterator.Value.ID}]}
					{
						bHavePriorityTarget:Set[TRUE]
					}
					UI:UpdateConsole["obj_Ratter: ${This.Rat_CacheIterator.Value.ID} is queued, concord, or DNK, skipping in priority target iteration.", LOG_DEBUG]
					continue
				}

				/* Is our target a "priority" target? If so, we won't continue with the rest of the targeting/chaining until
				all priority targets are dead. Gotta kill those scrambling bastards... */
				if ${Targets.IsPriorityTarget[${This.Rat_CacheIterator.Value.Name}]}
				{
					UI:UpdateConsole["obj_Ratter: We have a priority target: ${This.Rat_CacheIterator.Value.Name}."]
					bHavePriorityTarget:Set[TRUE]
					/* 	method Queue(int64 EntityID, int Priority, int TargetType, bool Mandatory=FALSE, bool Blocker=FALSE) */
					/* Queue it mandatory so we make sure it dies. */
					UI:UpdateConsole["obj_Ratter: Queueing priority target: ${This.Rat_CacheIterator.Value.Name}"]
					Targeting:Queue[${This.Rat_CacheIterator.Value.ID},0,${This.Rat_CacheIterator.Value.TypeID},TRUE,FALSE]
				}
			}
			while ${This.Rat_CacheIterator:Next(exists)}
		}

		/* Now for the fun task of figuring out chaining. */
		/* If I'm chaining spawns and either I'm chaining solo or I'm not chaining solo but there are others here... */
		/* I also only want to actually chain it if the calculated BS value is above our threshold */
		if (${Config.Combat.ChainSpawns} || (${Config.Combat.ChainSolo} && ${EVE.LocalsCount} == 1)) && \
			${iTotalBSValue} >= ${Config.Combat.MinChainBounty}
		{
			/* Start iterating... */
			if ${This.Rat_CacheIterator:First(exists)}
			{
				do
				{
					; If the target is already queued, just continue.
					if ${Targeting.IsQueued[${This.Rat_CacheIterator.Value.ID}]} || ${Offense.IsConcordTarget[${This.Rat_CacheIterator.Value.GroupID}]} || \
						${This.IsDoNotKill[${This.Rat_CacheIterator.Value.ID}]}
					{
						UI:UpdateConsole["obj_Ratter: ${This.Rat_CacheIterator.Value.ID} already queued, concord, or DNK, skipping", LOG_DEBUG]
						continue
					}

					; Since we're chaining, if it isn't a special spawn or a battleship, and we've already queued any priority targets, we don't want it.
					; Add it to do not kill.
					UI:UpdateConsole["obj_Ratter: Find Battleship? Name: ${This.Rat_CacheIterator.Value.Name}, Group: ${This.Rat_CacheIterator.Value.Group}, Exists? ${This.Rat_CacheIterator.Value.Group.Find["Battleship"](exists)}, Mutli? ${bHaveMultipleTypes}", LOG_DEBUG]
					if !${This.Rat_CacheIterator.Value.Group.Find["Battleship"](exists)} && !${Targets.IsSpecialTarget[${This.Rat_CacheIterator.Value.Name}]} && !${bHavePriorityTarget}
					{
						UI:UpdateConsole["obj_Ratter: ${This.Rat_CacheIterator.Value.Name} isn't a battleship or special target and we have no priority targets -- adding to DNK list.", LOG_DEBUG]
						DoNotKillList:Insert[${This.Rat_CacheIterator.Value.ID}]
						continue
					}

					; If we have a special target, queue it higher priority.
					; Currently it does nothing because combat doesn't detect "higher priority" targets
					if ${Targets.IsSpecialTarget[${This.Rat_CacheIterator.Value.Name}]}
					{
						UI:UpdateConsole["obj_Ratter: Queueing special target ${This.Rat_CacheIterator.Value.Name}, ${This.Rat_CacheIterator.Value.ID}.",LOG_CRITICAL]
						if ${Config.Common.UseSound}
						{
							Sound:PlayDetectSound
						}
						Targeting:Queue[${This.Rat_CacheIterator.Value.ID},1,${This.Rat_CacheIterator.Value.TypeID},FALSE,FALSE]
						continue
					}

					; Basically, the only way we get this far is our entity is a battleship we haven't queued.
					; So queue it!
					UI:UpdateConsole["obj_Ratter: Queueing chainable battleship ${This.Rat_CacheIterator.Value.Name}",LOG_DEBUG]
					Targeting:Queue[${This.Rat_CacheIterator.Value.ID},2,${This.Rat_CacheIterator.Value.TypeID},FALSE,FALSE]
				}
				while ${This.Rat_CacheIterator:Next(exists)}
			}
		}
		else
		{
			if ${This.Rat_CacheIterator:First(exists)}
			{
				do
				{
					; If the target is already queued, just continue.
					if ${Targeting.IsQueued[${This.Rat_CacheIterator.Value.ID}]} || ${Offense.IsConcordTarget[${This.Rat_CacheIterator.Value.GroupID}]} || \
						${This.IsDoNotKill[${This.Rat_CacheIterator.Value.ID}]}
					{
						UI:UpdateConsole["obj_Ratter: ${This.Rat_CacheIterator.Value.ID} already queued, concord, or DNK, skipping", LOG_DEBUG]
						continue
					}

					; If we have a special target, queue it higher priority.
					; Currently it does nothing because combat doesn't detect "higher priority" targets
					if ${Targets.IsSpecialTarget[${This.Rat_CacheIterator.Value.Name}]}
					{
						UI:UpdateConsole["obj_Ratter: Not chaining, queueing special target ${This.Rat_CacheIterator.Value.Name}, ${This.Rat_CacheIterator.Value.ID}.",LOG_CRITICAL]
						if ${Config.Common.UseSound}
						{
							Sound:PlayDetectSound
						}
						Targeting:Queue[${This.Rat_CacheIterator.Value.ID},1,${This.Rat_CacheIterator.Value.TypeID},FALSE,FALSE]
						continue
					}

					UI:UpdateConsole["obj_Ratter: Not chaining, queueing target ${This.Rat_CacheIterator.Value.Name}.",LOG_DEBUG]
					Targeting:Queue[${This.Rat_CacheIterator.Value.ID},2,${This.Rat_CacheIterator.Value.TypeID},FALSE,FALSE]
				}
				while ${This.Rat_CacheIterator:Next(exists)}
			}
		}
	}

	; return true if we have non-donotkill and non-concord npcs nearby and non-singletype
	member:bool NPCCheck()
	{
		variable iterator CachedEntityIterator
		EntityCache.FilteredEntities.Get[${This.Rat_CacheID}]:GetIterator[CachedEntityIterator]
		variable bool HaveMultipleTypes = FALSE
		variable int TempTypeID
		if ${CachedEntityIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Ratter: ${CachedEntityIterator.Value.Type} ${CachedEntityIterator.Value.TypeID} ${CachedEntityIterator.Value.Group} ${CachedEntityIterator.Value.GroupID}",LOG_DEBUG]
				if ${TempTypeID} == 0
				{
					TempTypeID:Set[${CachedEntityIterator.Value.TypeID}]
				}
				if ${TempTypeID} != ${CachedEntityIterator.Value.TypeID}
				{
					HaveMultipleTypes:Set[TRUE]
					break
				}
			}
			while ${CachedEntityIterator:Next(exists)}
		}
		UI:UpdateConsole["obj_Ratter: HaveMultipleTypes? ${HaveMultipleTypes}",LOG_DEBUG]
		if ${CachedEntityIterator:First(exists)}
		{
			do
			{
				if !${Offense.IsConcordTarget[${CachedEntityIterator.Value.GroupID}]} && \
				(${Targets.IsPriorityTarget[${CachedEntityIterator.Value.Name}]} || \
				${Targets.IsSpecialTarget[${CachedEntityIterator.Value.Name}]} || \
				${CachedEntityIterator.Value.Group.Find["Battleship"](exists)} || \
				${Targeting.IsQueued[${CachedEntityIterator.Value.ID}]} || ${Targeting.IsMandatoryQueued[${CachedEntityIterator.Value.ID}]} || \
				(!${This.IsDoNotKill[${CachedEntityIterator.Value.ID}]} && ${HaveMultipleTypes})) || \
				!${Config.Combat.ChainSpawns}
				{
					return TRUE
				}
			}
			while ${CachedEntityIterator:Next(exists)}
		}
		return FALSE
	}

	/* bool IsDoNotKill(int64 entityID):
	return true if given entity ID is on our do not kill list, otherwise return false */
	member:bool IsDoNotKill(int64 entityID)
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
