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

	; Are we currently targeting this?
	variable bool Targeting = FALSE

	method Initialize(int _EntityID, int _TargetType=0, int _Priority=0, bool _Targeting=FALSE)
	{
		EntityID:Set[${_EntityID}]
		TargetType:Set[${_TargetType}]
		Priority:Set[${_Priority}]
		Targeting:Set[${_Targeting}]
	}
}

objectdef obj_EVEBOT_Targeting inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev: 728 $"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable index:obj_QueueTarget MandatoryQueue
	variable index:obj_QueueTarget TargetQueue

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		Script[EVEBot].VariableScope.UI:UpdateConsole["obj_EVEBOT_Targeting: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${Script[EVEBot].VariableScope.EVEBot.Paused}
		{
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:PruneQueue[]
			if ${This.Running}
			{
				This:TargetNext[]
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	member:int QueueSize()
	{
		return ${Math.Calc[${TargetQueue.Used} + ${MandatoryQueue.Used}]}
	}

	member:bool IsQueued(int EntityID)
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

	method TargetEntity(int EntityID)
	{
		if ${Math.Calc[${Script[EVEBot].VariableScope._Me.GetTargets} + ${Script[EVEBot].VariableScope._Me.GetTargeting}]} >= ${Script[EVEBot].VariableScope.Ship.MaxLockedTargets}
		{
			return
		}

		UI:UpdateConsole["Debug: Current Targets: ${Math.Calc[${Script[EVEBot].VariableScope._Me.GetTargets} + ${Script[EVEBot].VariableScope._Me.GetTargeting}]}"]
		UI:UpdateConsole["Debug: Max Targets: ${Script[EVEBot].VariableScope.Ship.MaxLockedTargets}"]
				
		if !${Entity[${EntityID}].IsLockedTarget} && !${Entity[${EntityID}].BeingTargeted}
		{
			UI:UpdateConsole["Locking ${Entity[${EntityID}].Name} (${EntityID}): ${Script[EVEBot].VariableScope.EVEBot.MetersToKM_Str[${AsteroidIterator.Value.Distance}]}"]
			Entity[${EntityID}]:LockTarget
		}
	}

	method TargetNext()
	{
		variable iterator Target
		variable bool TargetingMandatory = FALSE
	
		MandatoryQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if !${Entity[${Target.Value.EntityID}].IsLockedTarget} && !${Entity[${Target.Value.EntityID}].BeingTargeted}
				{
					/* TODO - check to see if target list is full. if it is, unlock a target. */
					if ${Math.Calc[${Script[EVEBot].VariableScope._Me.GetTargets} + ${Script[EVEBot].VariableScope._Me.GetTargeting}]} >= ${Script[EVEBot].VariableScope.Ship.MaxLockedTargets}
					{
						This:UnlockRandomTarget[]
						/*	Go ahead and return here -- we'll catch the mandatory target on the next pulse, this gives the client
							time to handle the unlock we just requested */
						return
					}
					This:TargetEntity[${Target.Value.EntityID}]
					Target.Value.Targeting:Set[TRUE]
					TargetingMandatory:Set[TRUE]
				}
			}
			while ${Target:Next(exists)}
		}

		if ${TargetingMandatory}
		{
			return
		}

		if ${Math.Calc[${Script[EVEBot].VariableScope._Me.GetTargets} + ${Script[EVEBot].VariableScope._Me.GetTargeting}]} >= ${Script[EVEBot].VariableScope.Ship.MaxLockedTargets}
		{
			return
		}

		TargetQueue:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				echo Name = ${Entity[${Target.Value.EntityID}].Name}
				echo IsLockedTarget = ${Entity[${Target.Value.EntityID}].IsLockedTarget}
				echo BeingTargeted = ${Entity[${Target.Value.EntityID}].BeingTargeted}
				
				if !${Entity[${Target.Value.EntityID}].IsLockedTarget} && \
					!${Entity[${Target.Value.EntityID}].BeingTargeted}
				{
					This:TargetEntity[${Target.Value.EntityID}]
					Target.Value.Targeting:Set[TRUE]
				}
				else
				{
					echo Already targeted
				}
			}
			while ${Target:Next(exists)}
		}
		return
	}


	method Queue(int EntityID, int Priority, int TargetType, bool Mandatory)
	{

		if ${This.IsQueued[${EntityID}]}
		{
			Script[EVEBot].VariableScope.UI:UpdateConsole["Targeting: Already queued ${Entity[${EntityID}].Name} (${EntityID}) Type: ${TargetType}"]
			return
		}

		if ${Entity[${EntityID}](exists)}
		{
			This.Running:Set[TRUE]
			if ${Mandatory}
			{
				Script[EVEBot].VariableScope.UI:UpdateConsole["Targeting: Queueing mandatory target ${Entity[${EntityID}].Name} (${EntityID}) Type: ${TargetType}"]
				MandatoryQueue:Insert[${EntityID}, ${TargetType}, ${Priority}]
				This:Sort[MandatoryQueue, Priority]
			}
			else
			{
				Script[EVEBot].VariableScope.UI:UpdateConsole["Targeting: Queueing target ${Entity[${EntityID}].Name} (${EntityID}) Type: ${TargetType}"]
				TargetQueue:Insert[${EntityID}, ${TargetType}, ${Priority}]
				This:Sort[TargetQueue, Priority]
			}
		}
		else
		{
			Script[EVEBot].VariableScope.UI:UpdateConsole["Targeting: Attempted queue of non-existent entity ${EntityID}"]
		}
	}

	/* Unlock a random, non-mandatory target */
	method UnlockRandomTarget()
	{
		variable iterator Target
		variable index:entity LockedTargets

		Me:DoGetTargets[LockedTargets]
		LockedTargets:GetIterator[Target]
		if ${Target:First(exists)}
		{
			do
			{
				if !${This.IsMandatoryQueued[${Target.Value.EntityID}]}
				{
					Entity[${Target.Value.EntityID}]:UnlockTarget
				}
			}
			while ${Target:Next(exists)}
		}
	}
	
	/* Remove Queued targets which no longer exist on overview */
	method PruneQueue()
	{
		variable int Pos
		for ( Pos:Set[1]; ${Pos} < ${MandatoryQueue.Used}; Pos:Inc )
		{
			if !${Entity[${MandatoryQueue[${Pos}].EntityID}](exists)}
			{
				MandatoryQueue:Remove[${Pos}]
			}
		}
		MandatoryQueue:Collapse

		for ( Pos:Set[1]; ${Pos} < ${TargetQueue.Used}; Pos:Inc )
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
		for ( Pos:Set[1]; ${Pos} < ${MandatoryQueue.Used}; Pos:Inc )
		{
			if ${MandatoryQueue[${Pos}].EntityID} == ${EntityID}
			{
				MandatoryQueue:Remove[${Pos}]
			}
		}
		MandatoryQueue:Collapse

		for ( Pos:Set[1]; ${Pos} < ${TargetQueue.Used}; Pos:Inc )
		{
			if ${TargetQueue[${Pos}].EntityID} == ${EntityID}
			{
				TargetQueue:Remove[${Pos}]
			}
		}
		TargetQueue:Collapse

		variable index:entity LockedTargets
		Me:DoGetTargets[LockedTargets]

		for ( Pos:Set[1]; ${Pos} < ${LockedTargets.Used}; Pos:Inc )
		{
			if ${LockedTargets[${Pos}]} == ${EntityID}
			{
				Entity[${EntityID}]:UnlockTarget
			}
		}

		return
	}

	method Remove(int EntityID)
	{
		variable int Pos
		for ( Pos:Set[1]; ${Pos} < ${MandatoryQueue.Used}; Pos:Inc )
		{
			if ${MandatoryQueue[${Pos}].EntityID} == ${EntityID}
			{
				MandatoryQueue:Remove[${Pos}]
			}
		}

		for ( Pos:Set[1]; ${Pos} < ${TargetQueue.Used}; Pos:Inc )
		{
			if ${TargetQueue[${Pos}].EntityID} == ${EntityID}
			{
				TargetQueue:Remove[${Pos}]
			}
		}

		variable index:entity LockedTargets
		Me:DoGetTargets[LockedTargets]

		for ( Pos:Set[1]; ${Pos} < ${LockedTargets.Used}; Pos:Inc )
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
		This.Running:Set[TRUE]
	}

	method Disable()
	{
		This.Running:Set[FALSE]
	}
}

variable(global) obj_EVEBOT_Targeting Targeting

function main()
{
	while ${Script[EVEBot](exists)}
	{
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}