#include ..\core\defines.iss
/*
	Target Thread

	This thread handles target prioritization and aquisition

	-- CyberTech

*/
objectdef obj_QueueTarget
{
	variable int EntityID
	variable int TargetType
	variable int Priority

	; Does this entity have to be gone before we'll target anything else after it in the queue?
	variable bool Blocker

	; Are we currently targeting this?
	variable bool Targeting = FALSE

	method Initialize(int _EntityID, int _TargetType=0, int _Priority=0, bool _Blocker=FALSE, bool _Targeting=FALSE)
	{
		EntityID:Set[${_EntityID}]
		TargetType:Set[${_TargetType}]
		Priority:Set[${_Priority}]
		Blocker:Set[${_Blocker}]
		Targeting:Set[${_Targeting}]
	}
}

objectdef obj_EVEBOT_Targeting inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable index:obj_QueueTarget MandatoryQueue
	variable index:obj_QueueTarget TargetQueue

	variable int TargetingThisFrame = 0
	variable int Counter_TargetingJammed = 0

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["Thread: obj_EVEBOT_Targeting: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			Script:End
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${EVEBot.Paused}
			{
				This:PruneQueue[]
				if ${This.Running}
				{
					This:TargetNext[]
				}
			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	; Don't like this name -- LockedCount? PotentialLockedCount?
	member:int TargetCount()
	{
		return ${Math.Calc[${This.TargetingThisFrame} + ${Me.GetTargets} + ${Me.GetTargeting}]}
	}

	member:int QueueSize()
	{
		return ${Math.Calc[${TargetQueue.Used} + ${MandatoryQueue.Used}]}
	}

	member:bool IsQueued(int EntityID)
	{
		variable iterator Target

		if ${This.IsMandatoryQueued[${EntityID}]}
		{
			return TRUE
		}

		TargetQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if ${Target.Value.EntityID} == ${EntityID}
				{
					return TRUE
				}
			}
			while ${Target:Next(exists)}
		}
		return FALSE
	}

	member:bool IsMandatoryQueued(int EntityID)
	{
		variable iterator Target

		MandatoryQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if ${Target.Value.EntityID} == ${EntityID}
				{
					return TRUE
				}
			}
			while ${Target:Next(exists)}
		}
		return FALSE
	}

	member:bool IsTargetingJammed()
	{
		; TODO - Tune this threshold
		return ${This.Counter_TargetingJammed} > 40
	}

	method TargetEntity(int EntityID)
	{
		if ${This.TargetCount} >= ${Ship.MaxLockedTargets}
		{
			return
		}

		if ${MyShip.MaxTargetRange} <= ${Entity[${EntityID}].Distance}
		{
			return
		}

#if EVEBOT_DEBUG
		UI:UpdateConsole["Debug: TargetEntity - Target Count: ${Me.GetTargets}"]
		UI:UpdateConsole["Debug: TargetEntity - Targeting Count: ${Me.GetTargeting}"]
		UI:UpdateConsole["Debug: TargetEntity - Targeting this frame: ${This.TargetingThisFrame}"]
		UI:UpdateConsole["Debug: TargetEntity - Max Targets: ${Ship.MaxLockedTargets}"]
#endif
		if !${Entity[${EntityID}].IsLockedTarget} && !${Entity[${EntityID}].BeingTargeted} && ${Entity[${EntityID}].Name.NotEqual[NULL]}
		{
			UI:UpdateConsole["Locking ${Entity[${EntityID}].Name} (${EntityID}): ${EVEBot.MetersToKM_Str[${Entity[${EntityID}].Distance}]}"]
			Entity[${EntityID}]:LockTarget
			This.TargetingThisFrame:Inc
		}
	}

	method TargetNext()
	{
		variable iterator Target
		variable bool TargetingMandatory = FALSE

		This.TargetingThisFrame:Set[0]

		if ${MyShip.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Targeting: Jammed - Unable to target"]
			This.Counter_TargetingJammed:Inc
			return
		}
		else
		{
			if ${This.Counter_TargetingJammed}
			{
				UI:UpdateConsole["Targeting: Jamming ended"]
				This.Counter_TargetingJammed:Set[0]
			}
		}

		MandatoryQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if ${Entity[${Target.Value.EntityID}](exists)} && \
					!${Entity[${Target.Value.EntityID}].IsLockedTarget} && \
					!${Entity[${Target.Value.EntityID}].BeingTargeted} && \
					${MyShip.MaxTargetRange} > ${Entity[${Target.Value.EntityID}].Distance}
				{
					if ${This.TargetCount} >= ${Ship.MaxLockedTargets}
					{
						This:UnlockRandomTarget[]
						/*	Go ahead and return here -- we'll catch the mandatory target on the next pulse, this gives the client
							time to handle the unlock we just requested */
						return
					}
					This:TargetEntity[${Target.Value.EntityID}]
					Target.Value.Targeting:Set[TRUE]
					return
				}
				elseif ${Entity[${Target.Value.EntityID}](exists)} && \
					${Entity[${Target.Value.EntityID}].IsLockedTarget} || ${Entity[${Target.Value.EntityID}].BeingTargeted}
				{
					TargetingMandatory:Set[TRUE]
				}

				if ${Target.Value.Blocker} && ${Entity[${Target.Value.EntityID}](exists)}
				{
					; Don't target anything else until this is gone. Note that this will block if you queue a blocking entity outside targeting range. Don't be stupid.
					; Actually, no - go ahead and target any other mandatory blockers.
					return
				}
			}
			while ${Target:Next(exists)}
		}

		if ${TargetingMandatory}
		{
			return
		}

		if ${This.TargetCount} >= ${Ship.MaxLockedTargets}
		{
			return
		}

		TargetQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if ${Entity[${Target.Value.EntityID}](exists)} && \
					!${Entity[${Target.Value.EntityID}].IsLockedTarget} && \
					!${Entity[${Target.Value.EntityID}].BeingTargeted} && \
					${MyShip.MaxTargetRange} > ${Entity[${Target.Value.EntityID}].Distance}
				{
					This:TargetEntity[${Target.Value.EntityID}]
					Target.Value.Targeting:Set[TRUE]
					return
				}
			}
			while ${Target:Next(exists)}
		}
		return
	}


	method Queue(int EntityID, int Priority, int TargetType, bool Mandatory=FALSE, bool Blocker=FALSE)
	{
		if ${EntityID} == 0
		{
			UI:UpdateConsole["Targeting: Who the fuck tried to queue EntityID 0?"]
			return
		}
		if ${This.IsQueued[${EntityID}]}
		{
			UI:UpdateConsole["Targeting: Already queued ${Entity[${EntityID}].Name} (${EntityID}) Type: ${TargetType}"]
			; TODO: This needs to update the appropriate queue with the possibly new priority, targetype, mandatory settings instead of just returning - CyberTech
			return
		}

		if ${Blocker}
		{
			if !${Mandatory}
			{
				UI:UpdateConsole["Targeting: BUG: Attempted to queue ${Entity[${EntityID}].Name} as non-mandatory Blocker - forcing mandatory"]
				Mandatory:Set[TRUE]
			}

			if ${Priority}
			{
				UI:UpdateConsole["Targeting: BUG: Attempted to queue ${Entity[${EntityID}].Name} as low-priority Blocker - forcing highest"]
				Priority:Set[0]
			}
		}

		if ${Entity[${EntityID}](exists)}
		{
			This.Running:Set[TRUE]
			if ${Mandatory}
			{
				UI:UpdateConsole["Targeting: Queueing mandatory target ${Entity[${EntityID}].Name} (${EntityID}) Type: ${TargetType} Priority: ${Priority}"]

				MandatoryQueue:Insert[${EntityID}, ${TargetType}, ${Priority}, ${Blocker}]
				This:Sort[MandatoryQueue, Priority]
			}
			else
			{
				UI:UpdateConsole["Targeting: Queueing target ${Entity[${EntityID}].Name} (${EntityID}) Type: ${TargetType} Priority: ${Priority}"]
				TargetQueue:Insert[${EntityID}, ${TargetType}, ${Priority}, FALSE]
				This:Sort[TargetQueue, Priority]
			}
		}
		else
		{
			UI:UpdateConsole["Targeting: Attempted queue of non-existent entity ${EntityID}"]
		}
	}

	/* Unlock a random, non-mandatory target */
	method UnlockRandomTarget()
	{
		variable iterator Target
		variable index:cachedentity LockedTargets

		Me:DoGetTargets[LockedTargets]
		LockedTargets:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if !${This.IsMandatoryQueued[${Target.Value.ID}]}
				{
					Entity[${Target.Value.ID}]:UnlockTarget
				}
			}
			while ${Target:Next(exists)}
		}
	}

	/* Remove Queued targets which no longer exist on overview */
	method PruneQueue()
	{
		variable int Pos
		for ( Pos:Set[1]; ${Pos} <= ${MandatoryQueue.Used}; Pos:Inc )
		{
			if !${Entity[${MandatoryQueue[${Pos}].EntityID}](exists)}
			{
				MandatoryQueue:Remove[${Pos}]
			}
		}
		MandatoryQueue:Collapse

		for ( Pos:Set[1]; ${Pos} <= ${TargetQueue.Used}; Pos:Inc )
		{
			if !${Entity[${TargetQueue[${Pos}].EntityID}](exists)}
			{
				TargetQueue:Remove[${Pos}]
			}
		}
		TargetQueue:Collapse
		return
	}

	method Remove(int EntityID)
	{
		variable int Pos
		for ( Pos:Set[1]; ${Pos} <= ${MandatoryQueue.Used}; Pos:Inc )
		{
			if ${MandatoryQueue[${Pos}].EntityID} == ${EntityID}
			{
				MandatoryQueue:Remove[${Pos}]
			}
		}
		MandatoryQueue:Collapse

		for ( Pos:Set[1]; ${Pos} <= ${TargetQueue.Used}; Pos:Inc )
		{
			if ${TargetQueue[${Pos}].EntityID} == ${EntityID}
			{
				TargetQueue:Remove[${Pos}]
			}
		}
		TargetQueue:Collapse

		variable index:entity LockedTargets
		Me:DoGetTargets[LockedTargets]

		for ( Pos:Set[1]; ${Pos} <= ${LockedTargets.Used}; Pos:Inc )
		{
			if ${LockedTargets[${Pos}]} == ${EntityID}
			{
				Entity[${EntityID}]:UnlockTarget
			}
		}

		return
	}

	method Enable()
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["Targeting: Enabled"]
#endif
		This.Running:Set[TRUE]
	}

	method Disable()
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["Targeting: Disabled"]
#endif
		This.Running:Set[FALSE]
	}

	member:int DistanceFromQueue(int EntityID, int MaxDistanceWanted=2147483647)
	{
		variable iterator Target
		variable int MaxDistance
		variable int CurDistance

		if !${Entity[${EntityID}](exists)}
		{
			return
		}

		variable index:entity LockedTargets
		Me:DoGetTargets[LockedTargets]

		LockedTargets:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				CurDistance:Set[${Entity[${EntityID}].DistanceTo[${Target.Value.EntityID}]}]
				if ${CurDistance} > ${MaxDistance}
				{
					MaxDistance:Set[${CurDistance}]
				}
				if ${MaxDistance} > ${MaxDistanceWanted}
				{
					return ${MaxDistance}
				}
			}
			while ${Target:Next(exists)}
		}

		MandatoryQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				CurDistance:Set[${Entity[${EntityID}].DistanceTo[${Target.Value.EntityID}]}]
				if ${CurDistance} > ${MaxDistance}
				{
					MaxDistance:Set[${CurDistance}]
				}
				if ${MaxDistance} > ${MaxDistanceWanted}
				{
					return ${MaxDistance}
				}
			}
			while ${Target:Next(exists)}
		}

		TargetQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				CurDistance:Set[${Entity[${EntityID}].DistanceTo[${Target.Value.EntityID}]}]
				if ${CurDistance} > ${MaxDistance}
				{
					MaxDistance:Set[${CurDistance}]
				}
				if ${MaxDistance} > ${MaxDistanceWanted}
				{
					return ${MaxDistance}
				}
			}
			while ${Target:Next(exists)}
		}

		return ${MaxDistance}
	}


}

variable(global) obj_EVEBOT_Targeting Targeting

function main()
{
	EVEBot.Threads:Insert[${Script.Filename}]
	while ${Script[EVEBot](exists)}
	{
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}