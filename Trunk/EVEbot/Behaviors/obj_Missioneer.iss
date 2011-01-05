/*
	The missioneer object

	The obj_Missioneer object is the main bot module for the
	mission running bot.

	-- GliderPro
*/

objectdef obj_Missioneer inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable string CurrentState

	method Initialize()
	{
		EVEBot.BehaviorList:Insert["Missioneer"]
		LogPrefix:Set["${This.ObjectName}"]

		This.PulseTimer:SetIntervals[2.0,4.0]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		BotModules:Insert["Missioneer"]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		if ${This.PulseTimer.Ready}
		{
			This:SetState
    		This.NextPulse:Set[${Time.Timestamp}]
			This.PulseTimer:Update
		}
	}

	method Shutdown()
	{
	}

	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${Config.Common.Behavior.NotEqual[Missioneer]}
		{
			return
		}

		if ${Defense.Hiding}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${EVEBot.ReturnToStation} && ${Me.InSpace}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${This.CurentState.Equal["RUN_MISSION"]}
		{
			return
		}
		elseif ${Agents.HaveMission}
		{
			This.CurrentState:Set["RUN_MISSION"]
		}
		else
		{
			This.CurrentState:Set["GET_MISSION"]
		}
	}

	function ProcessState()
	{
		if ${Config.Common.Behavior.NotEqual[Missioneer]}
		{
			return
		}

		switch ${This.CurrentState}
		{
			case ABORT
				call Station.Dock
				break
			case GET_MISSION
				Agents:PickAgent
				call Agents.MoveTo
				call Agents.RequestMission
				break
			case RUN_MISSION
				call Missions.RunMission
				break
			case IDLE
				break
		}
	}
}

