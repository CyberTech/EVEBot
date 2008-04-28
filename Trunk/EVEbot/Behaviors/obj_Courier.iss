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
	variable bool bHaveCargo = FALSE

	method Initialize()
	{
		UI:UpdateConsole["obj_Courier: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}
	
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		;if ${Agents.ActiveAgent.NotEqual[${Config.Freighter.AgentName}]}
		;{
		;	Agents:SetActiveAgent[${Config.Freighter.AgentName}]
		;}
		
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${Agents.HaveMission} && !${bHaveCargo}
		{
			This.CurrentState:Set["PICKUP"]
		}
		elseif ${Agents.HaveMission} && ${bHaveCargo}
		{
			This.CurrentState:Set["DROPOFF"]
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
				call Agents.MoveTo
				call Agents.RequestCourierMission
				if ${Agents.LowSecRoute}
				{
					;call Agents.QuitMission
				}
				break
			case PICKUP
				UI:UpdateConsole["obj_Courier: MoveToPickup"]
				call Agents.MoveToPickup
				UI:UpdateConsole["obj_Courier: TransferCargoToShip"]
				wait 100
				call Cargo.TransferCargoToShip
				bHaveCargo:Set[TRUE]
				break
			case DROPOFF
				UI:UpdateConsole["obj_Courier: MoveToDropOff"]
				call Agents.MoveToDropOff
				wait 100
				UI:UpdateConsole["obj_Courier: TurnInMission"]
				call Agents.TurnInMission
				bHaveCargo:Set[FALSE]
				break
			case IDLE
				break
		}	
	}
}

