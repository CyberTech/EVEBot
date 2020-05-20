/*
	obj_BeltRunner
	
	Test belt iteration, warpout, etc
	
*/

objectdef obj_BeltRunner inherits obj_BaseClass
{
	variable string CurrentState = "STATE_IDLE"

	method Initialize()
	{
		EVEBot.BehaviorList:Insert["BeltRunner"]
		LogPrefix:Set["${This.ObjectName}"]

		This.PulseTimer:SetIntervals[2.0,4.0]
		Event[EVENT_EVEBOT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_EVEBOT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Disabled} || ${EVEBot.Paused}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			This:SetState
			This.PulseTimer:Update
		}
	}

	method SetState()
	{
		if ${Defense.Hiding}
		{
			This.CurrentState:Set["DEFENSE_HAS_CONTROL"]
			return
		}

		if ${Me.InStation} == TRUE
		{
			This.CurrentState:Set["STATE_DOCKED"]
			return
		}

		This.CurrentState:Set["STATE_CHANGE_BELT"]
	}

	function ProcessState()
	{
		Logger:Log["${LogPrefix}: Processing State: ${This.CurrentState}",LOG_DEBUG]
		switch ${This.CurrentState}
		{
			case STATE_WAIT_WARP
				break
			case STATE_IDLE
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
			case STATE_DOCKED
				if !${Defense.Hiding}
				{
					; TODO - this could cause dock/redock loops if armor or hull are below minimums, or if drones are still in shortage state -- CyberTech
					call Station.Undock
				}
				break
			case STATE_CHANGE_BELT
				Offense:Disable
				if ${Config.Combat.UseBeltBookmarks}
				{
					call BeltBookmarks.WarpToNext
				}
				else
				{
					call Belts.WarpToNext
				}
				Offense:Enable
				This.CurrentState:Set["STATE_WAIT"]
				break
			case STATE_WAIT
				Logger:Log["Waiting 5 seconds"]
				wait 50
				This.CurrentState:Set["STATE_IDLE"]
				break
			case STATE_ERROR
				break
			default
				Logger:Log["Error: CurrentState is unknown value ${This.CurrentState}"]
				break
		}
	}
}
