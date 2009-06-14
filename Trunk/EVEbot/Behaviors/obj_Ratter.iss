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
	
	/* Used for calculating battleship chain values */
	variable obj_Targets_Rats RatCalculator
	
	variable bool bPlayerCheck
	
	/* Todo: This, IsOrbiting, and Orbit should all probably be moved to a movement object. -- stealthy */
	variable int iEntityOrbiting

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

		UI:UpdateConsole["obj_Ratter: Rat Check: ${Targets.NPC}"]
		if ${Me.GetTargets} > 0 || (${Targets.NPC} && !${Targets.PC})
		{
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			This.CurrentState:Set["STATE_CHANGE_BELT"]
		}
	}
	
	/* bool RatCheck():
		Return true if we have rats (NOT CONCORD) near us
		Also take chaining into account*/
	member:bool RatCheck()
	{
		RatCalculator:CalcTotalBattleShipValue
		UI:UpdateConsole["obj_Ratter: RatCheck: Entities: ${RatCache.Entities.Size}"]
		if ${RatCache.Entities.Size} > 0
		{
			RatCache.Entities:GetIterator[RatCache.EntityIterator]
			if ${RatCache.EntityIterator:First(exists)}
			{
				do
				{
					UI:UpdateConsole["obj_Ratter: Rat Check: IsConcordTarget: ${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]}"]
					if !${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]}
					{
						UI:UpdateConsole["obj_Ratter: Should Chain: ${Config.Combat.ChainSpawns} ${Config.Combat.ChainSolo} ${EVE.LocalsCount} ${RatCalculator.TotalBattleShipValue} ${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)}"]
						if (${Config.Combat.ChainSpawns} && (${Config.Combat.ChainSolo} || !${Config.Combat.ChainSolo} && ${EVE.LocalsCount} > 1) && \
							${RatCalculator.TotalBattleShipValue} >= ${Config.Combat.MinChainBounty} && ${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)}) || \
							!${Config.Combat.ChainSpawns}
						{
							return TRUE
						}
					}
				}
				while ${RatCache.EntityIterator:Next(exists)}
			}
		}
		return FALSE
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
				elseif ${Targets.NPC}
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
				RatCalculator:UpdateTargetList
				UI:UpdateConsole[Updating target list: ${RatCalculator.UpdateSucceeded}]
				if !${RatCalculator.UpdateSucceeded}
				{
					Targeting:Disable
					This.State:Set["STATE_CHANGE_BELT"]
				}               
				/* Don't worry about orbiting or keeping at range if we're a missile boat */
				/* Todo: remove this, "It's dangerous in belts" */
				if !${Config.Combat.ShouldUseMissiles} && !${This.IsOrbiting}
				{               
					This:Orbit[${Me.ActiveTarget.ID},${Ship.MinimumTurretRange}]
				}               
				/* This:QueueTargets */
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
			if ${Targets.PC} || ${Targets.NPC}
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

	method QueueTargets()
	{
		Ship:Activate_SensorBoost

;		/* Iterate through the entities in entitycache. */
;		RatCache.Entities:GetIterator[RatCache.EntityIterator]
;		
;		/* Interface with the legacy code */
;		RatCalculator.Targets:Set[${RatCache.Entities}]
;		RatCalculator.Targets:GetIterator[RatCalculator.Target]
;		RatCalculator:CalcTotalBattleShipValue[]
;		
;		/* Basically, we want to kill everything if:
;			1) We're chaining and it doesn't meet our required value
;			2) We're not chanining
;			If we are chaining and it DOES meet required value, kill everything but low-value non-scram/jams.
;			If the only low-values are scram/jam, tough titties itty bitty.
;			obj_Targets code *does* ignore non-battleship ships when chaining. */
;
;		/* Assume there are entities near us - this should only be called after the NPC check. */
;		/* Queue non-players and non-concord, etc. We really only want to queue rats. */
;		if ${RatCache.EntityIterator:First(exists)}
;		{
;			do
;			{
;				if ${RatCache.EntityIterator.Value.IsNPC} && \
;					!${RatCache.EntityIterator.Value.IsLockedTarget} && \
;					!${Offense.IsConcordTarget[${RatCache.EntityIterator.Value.GroupID}]}
;				{
;					/*	Since ISXEVE doesn't tell us -what- is warp scrambling us just check our target against
;						known priority targets. Also be sure to not queue targets currently in warp. */
;
;					/* Queue[ID, Priority, TypeID, Mandatory] */
;#if EVEBOT_DEBUG
;					UI:UpdateConsole["obj_Ratter: ##LOGGING## RatCache.EntityIterator.Value.Mode: ${RatCache.EntityIterator.Value.Mode}"]
;#endif
;					if !${Targeting.IsQueued[${RatCache.EntityIterator.Value.ID}]} && ${RatCache.EntityIterator.Value.Mode} != 3
;					{
;						if ${Targets.IsPriorityTaraget[${RatCache.EntityIterator.Value.Name}]}
;						{
;							; If it's a priority target (web/scram/jam) make it mandatory and kill it first.
;							Targeting:Queue[${RatCache.EntityIterator.Value.ID},5,${RatCache.EntityIterator.Value.TypeID},TRUE]
;						}
;						elseif ${Targets.IsSpecialTarget[${RatCache.EntityIterator.Value.Name}]}
;						{
;							; If it's not a priority target but is a special target, kill it second. I can escape from special targets.
;							Targeting:Queue[${RatCache.EntityIterator.Value.ID},3,${RatCache.EntityIterator.Value.TypeID},FALSE]
;							UI:UpdateConsole["Special spawn Detected at ${Entity[GroupID, GROUP_ASTEROIDBELT]}: ${RatCache.EntityIterator.Value.Name}", LOG_CRITICAL]
;							Sound:PlayDetectSound
;						}
;						else
;						{
;							; If it's neither a special nor priority target, add it with a priority of 1 (low).
;							/* This should be where I decide whether or not to queue based on chaining. */
;							/* If I'm chaining spawns and either I'm chaining solo or I'm not chaining solo but there are people in local */
;							/* I also only want to chain if the calculated value is above our threshold */
;							UI:UpdateConsole["obj_Ratter: Should Chain: ${Config.Combat.ChainSpawns} ${Config.Combat.ChainSolo} ${EVE.LocalsCount} ${RatCalculator.TotalBattleShipValue}"]
;							if ${Config.Combat.ChainSpawns} && (${Config.Combat.ChainSolo} || !${Config.Combat.ChainSolo} && ${EVE.LocalsCount} > 1) && \
;								${RatCalculator.TotalBattleShipValue} >= ${Config.Combat.MinChainBounty}
;							{
;								/* Since I'm chaining, only queue the battleships */
;								if ${RatCache.EntityIterator.Value.Group.Find["Battleship"](exists)}
;								{
;									Targeting:Queue[${RatCache.EntityIterator.Value.ID},1,${RatCache.EntityIterator.Value.TypeID},FALSE]
;								}
;							}
;							else
;							{
;								/* If I'm not chaining, just kill it all. */
;								Targeting:Queue[${RatCache.EntityIterator.Value.ID},1,${RatCache.EntityIterator.Value.TypeID},FALSE]
;							}
;						}
;					}
;				}
;			}
;			while ${RatCache.EntityIterator:Next(exists)}
;		}
	}
}

