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
	
	/* Todo: This, IsOrbiting, and Orbit should all probably be moved to a movement object. -- stealthy */
	variable int iEntityOrbiting
	variable int iEntityKeepingAtRange

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		
		BotModules:Insert["Ratter"]

		RatCache:SetUpdateFrequency[1]
		RatCache:UpdateSearchParams["Unused","CategoryID,CATEGORYID_ENTITY"]

		; Startup in fight mode, so that it checks current belt for rats, if we happen to be in one.
		This.CurrentState:Set["FIGHT"]

		UI:UpdateConsole["obj_Ratter: Initialized", LOG_MINOR]
	}


	method Pulse()
	{
		if !${Config.Common.BotMode.Equal[Ratter]}
		{
			return
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
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	/* NOTE: The order of these if statements is important!! */

	;; STATE MACHINE:  * -> IDLE -> MOVE -> PCCHECK -> FIGHT -> *
	method SetState()
	{
#ifdef EVEBOT_DEBUG
		UI:UpdateConsole["obj_Ratter: Hiding: ${Defense.Hiding}, Hide Reason: ${Defense.HideReason}"]
#endif	
		if ${Defense.Hiding}
		{
			This.CurrentState:Set["IDLE"]
			return
		}

		if ${Me.InStation} == TRUE
		{
			This.CurrentState:Set["INSTATION"]
			return
		}

		UI:UpdateConsole["obj_Ratter: NPC Check: ${This.NPCCheck}"]
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
#ifdef EVEBOT_DEBUG
		UI:UpdateConsole["obj_Ratter: Processing State: ${This.CurrentState}"]
#endif
		;UI:UpdateConsole["DEBUG: ${This.CurrentState}"]
		switch ${This.CurrentState}
		{
			case STATE_WAIT_WARP
				break
			case STATE_IDLE
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
			case IDLE
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
				             
				/* Don't worry about orbiting or keeping at range if we're a missile boat */
				/* Todo: remove this, "It's dangerous in belts" */
				if !${Config.Combat.ShouldUseMissiles} && !${This.IsKeepingAtRange}
				{               
					This:KeepAtRange[${Me.ActiveTarget.ID},${Ship.MinimumTurretRange}]
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
	
	/* Orbit(int entityId, float range):
		Orbit passed entity at passed range and record that we are orbiting this entity. */
	method Orbit(int entityId, float range)
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["obj_Ratter: Orbiting ${Entity[${entityId}].Name}, ${entityId} at range ${range}"]
#endif
		Entity[${entityId}]:Orbit[${range}]
		iEntityOrbiting:Set[${entityId}]
	}
	
	/* KeepAtRange(int entityID, float range):
	KeepAtRange passed entity at passed range and record that we are keeping this entity at range. */
	method KeepAtRange(int entityId, float range)
	{
		Entity[${entityId}]:KeepAtRange[${range}]
		iEntityKeepingAtRange:Set[${entityId}]
	}
	
	/* IsOrbiting():
		Return true if I'm currently orbiting a living entity. Otherwise, returns false. */
	member:bool IsOrbiting()
	{
		variable bool bEntityExists = FALSE
		if ${Entity[${iEntityOrbiting}](exists)} && !${Entity[${iEntityOrbiting}].Type.Find[Wreck](exists)}
		{
			bEntityExists:Set[TRUE]
		}
#if EVEBOT_DEBUG
		UI:UpdateConsole["obj_Ratter.IsOrbiting: iEntityOrbiting: ${iEntityOrbiting}, exists: ${bEntityExists}"]
#endif
		if ${iEntityOrbiting} != 0 && ${bEntityExists}
		{
			return TRUE
		}
		return FALSE
	}
	
	/* bool IsKeepingAtRange():
		Return true if I'm currently keeping a living entity at range. */
	member:bool IsKeepingAtRange()
	{
		variable bool bEntityExists = FALSE
		if ${Entity[${iEntityKeepingAtRange}](exists)} && !${Entity[${iEntityKeepingAtRange}].Type.Find[Wreck](exists)}
		{
			bEntityExists:Set[TRUE]
		}
#if EVEBOT_DEBUG
		UI:UpdateConsole["obj_Ratter.IsKeepingAtRange: iEntityKeepingAtRange: ${iEntityKeepingAtRange}, exists: ${bEntityExists}"]
#endif
		if ${iEntityKeepingAtRange} != 0 && ${bEntityExists}
		{
			return TRUE
		}
		return FALSE
	}

	/* QueueTargets(): Handle any queueing, prioritizing, chaining, etc. of rats.
		This will do pretty much nothing but queue targets. */
	method QueueTargets()
	{
		/* Activate any sensor boosters */
		Ship:Activate_SensorBoost
		
		/* Get total battleship value for chaining purposes */
		variable int iTotalBSValue = ${RatCalculator.CalcTotalBattleShipValue}
		
		variable bool bHavePriorityTarget = FALSE
		variable bool bHaveSpecialTarget = FALSE
		
		RatCache.Entities:GetIterator[RatCache.EntityIterator]
		
		/* Start iterating through */
		if ${RatCache.EntityIterator:First(exists)}
		{
			do
			{
				/* Ignore any "concord" targets */
				if ${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]}
				{
					UI:UpdateConsole["obj_Ratter: Ignoring \"concord\" target ${RatCache.EntityIterator.Value.Name}"]
					continue
				}
				
				/* Is our target a "priority" target? If so, we won't continue with the rest of the targeting/chaining until
				all priority targets are dead. Gotta kill those scrambling bastards... */
				if ${Targets.IsPriorityTarget[${RatCache.EntityIterator.Value.Name}]}
				{
					UI:UpdateConsole["obj_Ratter: We have a priority target: ${RatCache.EntityIterator.Value.Name}."]
					bHavePriorityTarget:Set[TRUE]
					/* Queue[ID, Priority, TypeID, Mandatory] */
					/* Queue it mandatory so we make sure it dies. */
					if !${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]} && !${Targeting.IsMandatoryQueued[${RatCache.EntityIterator.Value.ID}]}
					{
						UI:UpdateConsole["obj_Ratter: Queueing priority target: ${RatCache.EntityIterator.Value.Name}"]
						Targeting:Queue[${RatCache.EntityIterator.Value.ID},5,${RatCache.EntityIterator.Value.TypeID},TRUE]
					}
				}
			}
			while ${RatCache.EntityIterator:Next(exists)}
		}
		
		/* If we ended up with any priority targets, just return for now. We don't want to touch others until they're dead. */
		if ${bHavePriorityTarget}
		{
			return
		}
		
		/* Now for the fun task of figuring out chaining. */
		/* If I'm chaining spawns and either I'm chaining solo or I'm not chaining solo but there are others here... */
		/* I also only want to actually chain it if the calculated BS value is above our threshold */
		if ${Config.Combat.ChainSpawns} && (${Config.Combat.ChainSolo} || ${EVE.LocalsCount} > 1) && \
			${iTotalBSValue} >= ${Config.Combat.MinChainBounty}
		{
			/* Start iterating... */
			if ${RatCache.EntityIterator:First(exists)}
			{
				do
				{
					/* Ok, since we're chaining, we only want special rats and battleships at this point, since any priority targets
					have already been taken care of. */
					if !${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]}
					{
						if ${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]} && \
						${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)}
						{
							/* if it's a special target, we additionally want to play a sound */
							if ${Config.Common.UseSound}
							{
								PlayDetectSound
							}
							UI:UpdateConsole["obj_Ratter: Queueing special or chainable target: ${RatCache.EntityIterator.Value.Name}"]
							Targeting:Queue[${RatCache.EntityIterator.Value.ID},3,${RatCache.EntityIterator.Value.TypeID},FALSE]
						}
						else
						{
							/* If it's not a special or battleship spawn, add it to the 'do not kill' list. */
							if !${IsDoNotKill[${RatCache.EntityIterator.Value.ID}]}
							{
								UI:UpdateConsole["obj_Ratter: Adding ${RatCache.EntityIterator.Value.ID} to the \"do not kill\" list."]
								DoNotKillList:Insert[${RatCache.EntityIterator.Value.ID}]
							}
						}
					}
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
					/* If we're not chaining, we're not chaining when solo and we're alone, or the spawn doesn't meet chain requirements...
					blow it all up. */
					UI:UpdateConsole["obj_Ratter: For some reason not chaining; light 'em up."]
					if !${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]}
					{
						if ${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]}
						{
							if ${Config.Common.UseSound}
							{
								Sound:PlayDetectSound
							}
						}
						
						UI:UpdateConsole["obj_Ratter: Entity ID in light up check: ${RatCache.EntityIterator.Value.ID}"]
						Targeting:Queue[${RatCache.EntityIterator.Value.ID},3,${RatCache.EntityIterator.Value.TypeID},FALSE]
					}
				}
				while ${RatCache.EntityIterator:Next(exists)}
			}
		}
	}
	
	/* bool NPCCheck():
	return true if we have non-donotkill and non-concord npcs nearby. */
	member:bool NPCCheck()
	{
		RatCache.Entities:GetIterator[RatCache.EntityIterator]
		
		if ${RatCache.EntityIterator:First(exists)}
		{
			do
			{
				if !${This.IsDoNotKill[${RatCache.EntityIterator.Value.ID}]} && \
				!${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]}
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

