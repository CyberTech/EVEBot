/*
	The missioneer object
	
	The obj_Missioneer object is the main bot module for the
	mission running bot.
	
	-- GliderPro	
*/

objectdef obj_Missioneer
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string CurrentState
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	
	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		BotModules:Insert["Missioneer"]
		UI:UpdateConsole["obj_Missioneer: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Missioneer]}
		{
			return
		}
		
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:SetState
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
	method SetState()
	{
		if ${EVEBot.ReturnToStation} && !${_Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${Agents.HaveMission}
		{
			This.CurrentState:Set["RUN_MISSION"]
		}
		elseif !${Agents.HaveMission}
		{
			This.CurrentState:Set["GET_MISSION"]
		}
		else
		{
			This.CurrentState:Set["Unknown"]
		}
	}

	function ProcessState()
	{
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

