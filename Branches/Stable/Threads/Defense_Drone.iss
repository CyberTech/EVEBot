#include ../core/defines.iss
/*
	Drone Defense Thread - Simple Drone defense, if attacked, notify all to launch drones and attack

	-- CyberTech
*/

objectdef obj_Defense_Drone inherits obj_BaseClass
{
	variable bool Enabled = TRUE
	variable int CurrentState = 0

	variable weakref EVEBotScript
	variable weakref Ship

	; Limits how often we send commands
	variable obj_PulseTimer DroneCommandTimer

	;	This is a list of IDs for rats which are attacking a team member
	variable set HostileTargets

	; The currently targeted/ing entity. We're only guaranteed one target slot, so we need to track this
	variable entity CurrentTarget

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This.PulseTimer:SetIntervals[0.5,1.5]
		DroneCommandTimer:SetIntervals[1.0,2.5]
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		Logger:Log["Thread: ${LogPrefix}: Initialized", LOG_MINOR]

		LavishScript:RegisterEvent[EVEBot_AttackerReport]
		Event[EVEBot_AttackerReport]:AttachAtom[This:Event_AttackerReport]

	}

	method SetOwnerScript(string Owner)
	{
		Ship:SetReference["Script[${Owner}].VariableScope.Ship"]
		EVEBotScript:SetReference["Script[${Owner}].VariableScope"]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
		Event[EVEBot_AttackerReport]:DetachAtom[This:Event_AttackerReport]
	}

	;This method is triggered by an event.  If triggered, it means a team-mate is under attack by an NPC and what it is.
	method Event_AttackerReport(int64 value)
	{
		if ${HostileTargets.Contains[${value}]}
		{
			return
		}
		HostileTargets:Add[${value}]
		Logger:Log["${LogPrefix}: Added ${Entity[${value}].Name}(${value}) to attackers list. Attackers: ${HostileTargets.Used}"]
	}

	method Pulse()
	{
		if !${EVEBot(exists)} || !${EVEBot.Loaded} || ${EVEBot.Disabled}
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
			if (${HostileTargets.Used} == 0 || !${EVEBotScript.Config.Combat.LaunchCombatDrones}) && ${Ship.Drones.DronesInSpace[FALSE]} > 0
			{
				; In case the user disables it during operation
				Ship.Drones:ReturnAllToDroneBay["Defense_Drones"]
				return
			}

			if ${HostileTargets.Used} == 0
			{
				return
			}

			if ${EVEBotScript.Config.Combat.LaunchCombatDrones}
			{
				This:ChooseTarget
				if ${This.CurrentTarget(exists)}
				{
					; Will launch drones, or if we've lost some, launch more to get to max drone capability
					Ship.Drones:LaunchAll["Defense_Drones"]
				}
			}

			call Defend
		}
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
				if !${HostileTargets.Contains[${CurrentAttacker.Value.ID}]}
				{
					Logger:Log["${LogPrefix}: Alerting team to kill ${CurrentAttacker.Value.Name}(${CurrentAttacker.Value.ID})"]
					Relay all -event EVEBot_AttackerReport ${CurrentAttacker.Value.ID}
				}
			}
			while ${CurrentAttacker:Next(exists)}
		}
	}

	;	This function's purpose is to defend against rats which are attacking our team.  Goals:
	;	*	Don't use up our targets, we need those for mining - Only one target should ever be used for a rat.
	function Defend()
	{
		if !${This.CurrentTarget(exists)}
		{
			return
		}
		if !${This.CurrentTarget.IsLockedTarget}
		{
			; Wait longer
			return
		}

		if !${DroneCommandTimer.Ready}
		{
			return
		}

		if ${Navigator.Busy}
		{
			return
		}

		variable index:activedrone ActiveDroneList

		Me:GetActiveDrones[ActiveDroneList]
		ActiveDroneList:RemoveByQuery[${LSQueryCache[State != 0]}]
		;Logger:Log["${LogPrefix}: Found ${ActiveDroneList.Used} drones in state 0", LOG_DEBUG]
		ActiveDroneList:Collapse

		if ${ActiveDroneList.Used} > 0
		{
			; TODO - we need to control access to the active target so we don't fight over it
			This.CurrentTarget:MakeActiveTarget
			wait 50 ${Me.ActiveTarget.ID} == ${This.CurrentTarget.ID}

			Logger:Log["${LogPrefix}: Sending ${ActiveDroneList.Used} drones to attack ${This.CurrentTarget.Name}"]
			EVE:DronesEngageMyTarget[ActiveDroneList]
			DroneCommandTimer:Update
		}
	}

	method ChooseTarget()
	{
		if ${HostileTargets.Used} == 0
		{
			return
		}

		if ${This.CurrentTarget(exists)}
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
			if !${Entity[${CurrentHostile.Value}](exists)}
			{
				;HostileTargets:Remove[${CurrentHostile.Value}]
				;CurrentHostile:First
				continue
			}
			if ${Entity[${CurrentHostile.Value}].Distance} < ${Ship.OptimalTargetingRange} && \
				${Entity[${CurrentHostile.Value}].Distance} < ${Me.DroneControlDistance}
				{
					Entity[${CurrentHostile.Value}]:LockTarget
					This.CurrentTarget:Set[${CurrentHostile.Value}]
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
