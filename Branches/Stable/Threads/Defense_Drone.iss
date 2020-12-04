#include ../core/defines.iss
/*
	Drone Defense Thread - Simple Drone defense, if attacked, notify all to launch drones and attack

	-- CyberTech
*/

objectdef obj_Hostile
{
	variable int64 ReporterID
	variable int64 HostileID
	variable time TimeAdded

	method Initialize(int64 _ReporterID = 0, int64 _HostileID = 0)
	{
		ReporterID:Set[${_ReporterID}]
		HostileID:Set[${_HostileID}]
		TimeAdded:Set[${Time.Timestamp}]
	}
}

objectdef obj_Defense_Drone inherits obj_BaseClass
{
	variable bool Enabled = TRUE
	variable int CurrentState = 0

	variable weakref EVEBotScript
	variable weakref Ship

	; Limits how often we send commands
	variable obj_PulseTimer DroneCommandTimer
	variable obj_PulseTimer DroneLaunchDelay		/* Delay for initial launch of drones */

	;	This is a list of IDs for rats which are attacking a team member
	variable index:obj_Hostile HostileTargets

	; The currently targeted/ing entity. We're only guaranteed one target slot, so we need to track this
	variable entity CurrentTarget

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This.PulseTimer:SetIntervals[1.5,2.5]
		DroneCommandTimer:SetIntervals[2.0,4.5]
		DroneLaunchDelay:SetIntervals[5.0,25.0]
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		Logger:Log["Thread: ${LogPrefix}: Initialized", LOG_MINOR]

		LavishScript:RegisterEvent[EVEBot_AttackerReport]
		Event[EVEBot_AttackerReport]:AttachAtom[This:Event_AttackerReport]

		LavishScript:RegisterEvent[EVEBot_AttackerDeceased]
		Event[EVEBot_AttackerDeceased]:AttachAtom[This:Event_AttackerDeceased]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
		Event[EVEBot_AttackerReport]:DetachAtom[This:Event_AttackerReport]
		Event[EVEBot_AttackerDeceased]:DetachAtom[This:Event_AttackerDeceased]
	}

	method SetOwnerScript(string Owner)
	{
		Ship:SetReference["Script[${Owner}].VariableScope.Ship"]
		EVEBotScript:SetReference["Script[${Owner}].VariableScope"]
	}

	;This method is triggered by an event.  If triggered, it means a team-mate is under attack by an NPC and what it is.
	method Event_AttackerReport(int64 ReporterID, int64 AttackerID)
	{
		if ${This.isKnownHostile[${AttackerID}]}
		{
			Logger:Log["${LogPrefix}:Event_AttackerReport Ignored ${AttackerID} from ${ReporterID}, already known", LOG_DEBUG]
			return
		}
		HostileTargets:Insert[${ReporterID}, ${AttackerID}]
		Logger:Log["${LogPrefix}: Added ${Entity[${AttackerID}].Name}(${AttackerID}) to attackers list, reported by ${ReporterID} Attackers: ${HostileTargets.Used}"]
	}

	;This method is triggered by an event.  If triggered, it means a team-mate is under attack by an NPC and what it is.
	method Event_AttackerDeceased(int64 ReporterID, int64 AttackerID)
	{
		Logger:Log["${LogPrefix}: Removed deceased ${Entity[${AttackerID}].Name}(${AttackerID}) from attackers list, reported by ${ReporterID} Attackers: ${HostileTargets.Used}"]
	}

	method Pulse()
	{
		if !${EVEBot(exists)} || !${EVEBot.Loaded} || ${EVEBot.Disabled} || ${Script.Paused}
		{
			return
		}

		if !${EVEBotScript.Config.Combat.EnableDroneDefense}
		{
			return
		}

		if ${Navigator.Busy}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			if ${Me.InSpace}
			{
				This:CheckAttack
			}

			This.PulseTimer:Update
		}
	}

	function ProcessState()
	{
		if !${EVEBotScript.Config.Combat.EnableDroneDefense} || ${EVEBot.Disabled}
		{
			return
		}

		if !${Me.InSpace}
		{
			return
		}

		if ${Navigator.Busy}
		{
			return
		}

		if !${Ship.InWarp}
		{
			; TODO - Defense config
			if ${Ship.Drones.DronesInSpace[FALSE]} > 0
			{
				if !${EVEBotScript.Config.Combat.LaunchCombatDrones}
				{
					if ${DroneCommandTimer.Ready}
					{
						Ship.Drones:ReturnAllToDroneBay["Defense_Drones", "Launch Combat Drones Disabled"]
						DroneCommandTimer:Update
						return
					}
				}
				elseif !${This.isAnyAttackerPresent} && !${Entity[IsTargetingMe = TRUE](exists)}
				{
					if ${DroneCommandTimer.Ready}
					{
						Ship.Drones:ReturnAllToDroneBay["Defense_Drones", "0/${HostileTargets.Used} attackers in range"]
						DroneCommandTimer:Update
						return
					}
				}
			}

			if ${HostileTargets.Used} == 0
			{
				return
			}

			if ${EVEBotScript.Config.Combat.LaunchCombatDrones}
			{
				This:ChooseTarget
				if ${This.CurrentTarget.ID(exists)} && ${This.CurrentTarget.WreckID} == -1
				{
					if ${Ship.Drones.DronesInSpace[FALSE]} == 0 && !${This.DroneLaunchDelay.Restarted}
					{
						This.DroneLaunchDelay:Update
					}
					elseif ${DroneLaunchDelay.Ready}
					{
						; Will launch drones, or if we've lost some, launch more to get to max drone capability
						Ship.Drones:LaunchAll["Defense_Drones"]
					}
				}
			}

			call Defend
		}
	}

	member:bool isKnownHostile(int64 HostileID)
	{
		variable iterator hostiletarget
		HostileTargets:GetIterator[hostiletarget]
		if ${hostiletarget:First(exists)}
		{
			do
			{
				if ${Math.Calc64[${hostiletarget.Value.HostileID} == ${HostileID}]}
				{
					;Logger:Log["${LogPrefix}:isKnownHostile Found ${hostiletarget.Value.HostileID}=${HostileID}", LOG_DEBUG]
					return TRUE
				}
			}
			while ${hostiletarget:Next(exists)}
		}
		;Logger:Log["${LogPrefix}:isKnownHostile ${HostileID} unknown", LOG_DEBUG]
		return FALSE
	}

	member:bool isReporterPresent(int64 ReporterID)
	{
		variable iterator hostiletarget
		HostileTargets:GetIterator[hostiletarget]
		if ${hostiletarget:First(exists)}
		{
			do
			{
				if ${Math.Calc64[${hostiletarget.Value.ReporterID} == ${ReporterID}]}
				{
					return TRUE
				}
			}
			while ${hostiletarget:Next(exists)}
		}
		return FALSE
	}

	member:int64 isAnyReporterPresent()
	{
		variable iterator hostiletarget
		HostileTargets:GetIterator[hostiletarget]
		if ${hostiletarget:First(exists)}
		{
			do
			{
				if ${Entity[${hostiletarget.Value.ReporterID}](exists)} && ${Entity[${hostiletarget.Value.ReporterID}].WreckID} == -1
				{
					return ${hostiletarget.Value.ReporterID}
				}
			}
			while ${hostiletarget:Next(exists)}
		}
		return 0
	}

	member:int64 isAnyAttackerPresent()
	{
		variable iterator hostiletarget
		HostileTargets:GetIterator[hostiletarget]
		if ${hostiletarget:First(exists)}
		{
			do
			{
				;Logger:Log["${LogPrefix}:isAnyAttackerPresent checking for ${hostiletarget.Value.HostileID}", LOG_DEBUG]
				if ${Entity[${hostiletarget.Value.HostileID}](exists)} && ${Entity[${hostiletarget.Value.HostileID}].WreckID} == -1
				{
					return ${hostiletarget.Value.HostileID}
				}
			}
			while ${hostiletarget:Next(exists)}
		}
		return 0
	}

	;This method is used to trigger an event.  It tells our team-mates we are under attack by an NPC and what it is.
	method CheckAttack()
	{
		variable iterator CurrentAttacker
		variable index:attacker Attackers

		Me:GetAttackers[Attackers]
		Attackers:RemoveByQuery[${LSQueryCache[!IsNPC]}]
		Attackers:Collapse
		Attackers:GetIterator[CurrentAttacker]
		if ${CurrentAttacker:First(exists)}
		{
			do
			{
				if !${This.isKnownHostile[${CurrentAttacker.Value.ID}]}
				{
					Logger:Log["${LogPrefix}: Alerting team to kill ${CurrentAttacker.Value.Name}(${CurrentAttacker.Value.ID})"]
					relay all "Event[EVEBot_AttackerReport]:Execute[${MyShip.ID}, ${CurrentAttacker.Value.ID}]"
				}
			}
			while ${CurrentAttacker:Next(exists)}
		}
	}

	;	This function's purpose is to defend against rats which are attacking our team.  Goals:
	;	*	Don't use up our targets, we need those for mining - Only one target should ever be used for a rat.
	function Defend()
	{
		if !${This.CurrentTarget.ID(exists)}
		{
			return
		}
		if !${This.CurrentTarget.IsLockedTarget}
		{
			; Wait longer
			return
		}
		if ${Navigator.Busy}
		{
			return
		}
		if !${DroneCommandTimer.Ready}
		{
			return
		}

		variable index:activedrone ActiveDroneList

		Me:GetActiveDrones[ActiveDroneList]
		;ActiveDroneList:ForEach["Logger:Log[Drone: \${ForEach.Value.ID} \${ForEach.Value.State} \${ForEach.Value.Target}]"]
		ActiveDroneList:RemoveByQuery[${LSQueryCache[State != ENTITY_STATE_IDLE]}]
		;Logger:Log["${LogPrefix}: Found ${ActiveDroneList.Used} drones in state 0", LOG_DEBUG]
		ActiveDroneList:Collapse

		if ${ActiveDroneList.Used} > 0
		{
			; TODO - we need to control access to the active target so we don't fight over it
			This.CurrentTarget:MakeActiveTarget
			wait 50 ${Math.Calc64[${Me.ActiveTarget.ID} == ${This.CurrentTarget.ID}]}

			Logger:Log["${LogPrefix}: Sending ${ActiveDroneList.Used} idle drones to attack ${This.CurrentTarget.Name}(${This.CurrentTarget.ID})"]
			EVE:DronesEngageMyTarget[ActiveDroneList]
			Ship:Activate_Weapons[${This.CurrentTarget.ID}]
			DroneCommandTimer:Update
		}
	}

	method ChooseTarget()
	{
		if !${This.isAnyAttackerPresent}
		{
			return
		}
; TODO - why would ${This.CurrentTarget(exists)} return true, but ${This.CurrentTarget} return null
		if ${This.CurrentTarget.ID(exists)}
		{
			if ${This.CurrentTarget.IsLockedTarget} || ${This.CurrentTarget.BeingTargeted}
			{
				return
			}
			; Otherwise, we didn't properly lock the first time we tried, so let it try again (or switch targets)
		}

		if ${Ship.AvailableTargets} == 0
		{
			Logger:Log["${LogPrefix}: Unable to target attacker; no free target slots. Where's my reserve?", LOG_WARNING]
			return
		}

		variable iterator CurrentHostile

		;HostileTargets:RemoveByQuery[${LSQueryCache[ID =~ NULL]}]
		;HostileTargets:Collapse
		HostileTargets:GetIterator[CurrentHostile]
		if ${CurrentHostile:First(exists)}
		do
		{
			if !${Entity[${CurrentHostile.Value.HostileID}](exists)}
			{
				;HostileTargets:Remove[${CurrentHostile.Value.HostileID}]
				;CurrentHostile:First
				continue
			}

			if ${Entity[${CurrentHostile.Value.HostileID}].GroupID} == GROUPID_WRECK
			{
				Logger:Log["${LogPrefix}: Removing deceased attacker ${CurrentHostile.Value.HostileID}:${Entity[${CurrentHostile.Value.HostileID}].Name}"]
				HostileTargets:Remove[${CurrentHostile.Value.HostileID}]
				CurrentHostile:First
				relay all "Event[EVEBot_AttackerDeceased]:Execute[${MyShip.ID}, ${CurrentHostile.Value.HostileID}]"
				continue
			}
			if ${Entity[${CurrentHostile.Value.HostileID}].Distance} < ${Ship.OptimalTargetingRange} && \
				${Entity[${CurrentHostile.Value.HostileID}].Distance} < ${Me.DroneControlDistance}
				{
					Entity[${CurrentHostile.Value.HostileID}]:LockTarget
					This.CurrentTarget:Set[${CurrentHostile.Value.HostileID}]
					Logger:Log["${LogPrefix}: Targeting ${This.CurrentTarget.ID}:${This.CurrentTarget.Name}"]
					break
				}
		}
		while ${CurrentHostile:Next(exists)}
	}

}

variable(global) obj_Defense_Drone Defense_Drone

function main(string OwnerScript)
{
	Defense_Drone:SetOwnerScript[${OwnerScript}]
	EVEBot.Threads:Insert[${Script.Filename}]
	while ${EVEBot(exists)} && !${EVEBot.Loaded}
	{
		wait 1
	}
	while ${EVEBot(exists)}
	{
		call Defense_Drone.ProcessState
		wait ${Math.Rand[15]}
	}
	echo "${APP_NAME} exited, unloading ${Script.Filename}"
}
