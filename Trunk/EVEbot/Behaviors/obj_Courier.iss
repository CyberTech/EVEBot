/*
	The courier object
	
	The obj_Courier object is a bot mode designed to be used with 
	obj_Freighter bot module in EVEBOT.  It will obtain and complete
	courier missions for a single agent.
	
	-- GliderPro	
*/

/* obj_Courier is a "bot-mode" which is similar to a bot-module.
 * obj_Courier runs within the obj_Freighter bot-module.  It would 
 * be very straightforward to turn obj_Courier into a independent 
 * bot-module in the future if it outgrows its place in obj_Freighter.
 */
objectdef obj_Courier
{
	/* the bot logic is currently based on a state machine */
	variable string CurrentState

	method Initialize()
	{
		UI:UpdateConsole["obj_Courier: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}
	
	/* NOTE: The order of these if statements is important!! */
	/* obj_Courier tasks:
	 *	MOVING_TO_AGENT
	 *	GETTING_MISSION
	 *	MOVING_TO_PICKUP
	 *	LOADING_CARGO
	 *	MOVING_TO_DROPOFF
	 *	UNLOADING_CARGO
	 *	TURNING_IN_MISSION
	 *  (repeat)
	 */
	method SetState()
	{
		if ${Agents.ActiveAgent.NotEqual[${Config.Freighter.AgentName}]}
		{
			Agents:SetActiveAgent[${Config.Freighter.AgentName}]
		}
		
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${Agents.HaveMission}
		{
			This.CurrentState:Set["START_MISSION"]
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
			case IDLE
				break
		}	
	}
}

