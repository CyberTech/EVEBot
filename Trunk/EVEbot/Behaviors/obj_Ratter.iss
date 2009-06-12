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
	variable int PulseIntervalInSeconds = 1
	variable float RatWaitCounter

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]

		BotModules:Insert["Ratter"]
		Defense.Option_RunIfTargetJammed:Set[FALSE]

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
		UI:UpdateConsole["obj_Ratter: Hiding: ${Defense.Hiding}"]
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


		if ${Me.GetTargets} > 0 || ${Me.GetTargetedBy} > 0
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
				Offense:Enable
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
		Ship:Activate_SensorBoost

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
		This:PlayerCheck
	}

	method QueueTargets()
	{
		Ship:Activate_SensorBoost

		variable index:entity idxEntities
		variable iterator itrEntity

		/* Get a list of all entities near us. */
		EVE:DoGetEntities[idxEntities, CategoryID, CATEGORYID_ENTITY]
		idxEntities:GetIterator[itrEntity]

		/* Assume there are entities near us - this should only be called after the NPC check. */
		/* Queue non-players and non-concord, etc. We really only want to queue rats. */
		if ${itrEntity:First(exists)}
		{
			do
			{
				if ${itrEntity.Value.IsNPC} && \
					!${itrEntity.Value.IsLockedTarget} && \
					!${Offense.IsConcordTarget[${itrEntity.Value.GroupID}]}
				{
					/*	Since ISXEVE doesn't tell us -what- is warp scrambling us just check our target against
						known priority targets. Also be sure to not queue targets currently in warp. */

					/* Queue[ID, Priority, TypeID, Mandatory] */
					if !${Targeting.IsQueued[${itrEntity.Value.ID}]} && ${itrEntity.Value.Mode} != 3
					{
						if ${Targets.IsPriorityTaraget[${itrEntity.Value.Name}]}
						{
							; If it's a priority target (web/scram/jam) make it mandatory and kill it first.
							Targeting:Queue[${itrEntity.Value.ID},5,${itrEntity.Value.TypeID},TRUE]
						}
						elseif ${Targets.IsSpecialTarget[${itrEntity.Value.Name}]}
						{
							; If it's not a priority target but is a special target, kill it second. I can escape from special targets.
							Targeting:Queue[${itrEntity.Value.ID},3,${itrEntity.Value.TypeID},FALSE]
							UI:UpdateConsole["Special spawn Detected at ${Entity[GroupID, GROUP_ASTEROIDBELT]}: ${itrEntity.Value.Name}", LOG_CRITICAL]
							Sound:PlayDetectSound
						}
						else
						{
							; If it's neither a special nor priority target, add it with a priority of 1 (low).
							Targeting:Queue[${itrEntity.Value.ID},1,${itrEntity.Value.TypeID},FALSE]
						}
					}
				}
			}
			while ${itrEntity:Next(exists)}
		}
	}
}

