/* 

Skeleton for Fighter
 								- Hessinger

*/
objectdef obj_Fighter
{
	method Initialize()
	{			
		UI:UpdateConsole["obj_Fighter: Initialized", LOG_MINOR]
	}
	
	method Shutdown()
	{
		
	}
		
	method SetupEvents()
	{
		
	}
	
}

objectdef obj_CombatFighter inherits obj_Fighter
{
	/* This variable is set by a remote event.  When it is non-zero, */
	/* the bot will undock and seek out the fleet member.  After the */
	/* member is safe the bot will zero this out.                    */
	variable int m_FleetMemberID

	/* the bot logic is currently based on a state machine */
	variable string CurrentState

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	
	method Initialize()
	{
		UI:UpdateConsole["obj_CombatFighter: Initialized", LOG_MINOR]
		Event[OnFrame]:AttachAtom[This:Pulse]
		BotModules:Insert["Fighter"]
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Fighter]}
		{
			return
		}
		
	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
		    call This.DevelopmentTest
    		This:SetState[]

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}
	
	function ProcessState()
	{			
		if !${Config.Common.BotModeName.Equal[Fighter]}
		{
			return
		}

		switch ${This.CurrentState}
		{
			case DEVELOPMENT
				call This.DevelopmentTest
				break
			case IDLE
				break
			case ABORT
				Call Station.Dock
				break
			case BASE
				call Station.Undock
				break
			case COMBAT
				UI:UpdateConsole["Fighting"]
				break
			case RUNNING
				UI:UpdateConsole["Running Away"]
				call Station.Dock
				EVEBot.ReturnToStation:Set[FALSE]
				break
		}	
	}
	
	method SetState()
	{
		
		if ${Me.Ship(exists)}
		{
			This.CurrentState:Set["DEVELOPMENT"]
			return
		}
		
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
			return
		}
	
		if ${EVEBot.ReturnToStationt}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
	
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
			return
		}
	
		if ${EVEBot.ReturnToStationt}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
		
		if ${Me.InStation}
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}
	
		This.CurrentState:Set["Unknown"]
	}
	
	function DevelopmentTest()
	{
		/* Development Test */
		UI:UpdateConsole["Development Patch"]
	}
}