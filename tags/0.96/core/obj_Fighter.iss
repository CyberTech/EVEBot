/* 

Skeleton for Fighter
 								- Hessinger

*/
objectdef obj_Fighter
{
	/* The name of the player we are fighting for (null if using m_corpName) */
	variable string m_playerName
	
	/* The name of the corp we are fighting for (null if using m_playerName) */
	variable string m_corpName
	
	/* When this flag is set to TRUE the fighter should return to base */
	variable bool m_abort
	
	method Initialize(string player, string corp)
	{	
		m_abort:Set[FALSE]
		
		if (${player.Length} && ${corp.Length})
		{
			echo "ERROR: obj_Fighter:Initialize -- cannot use a player and a corp name.  One must be blank"
		}
		else
		{			
			if ${player.Length}
			{
				m_playerName:Set[${player}]
			}
			
			if ${corp.Length}
			{
				m_corpName:Set[${corp}]
			}
			
			if (!${player.Length} && !${corp.Length})
			{
				echo "WARNING: obj_Fighter:Initialize -- player and corp name are blank.  Defaulting to ${Me.Corporation}"
				m_corpName:Set[${Me.Corporation}]
			} 
		}
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
	/* the bot will undock and seek out the gang memeber.  After the */
	/* member is safe the bot will zero this out.                    */
	variable int m_gangMemberID

	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable int FrameCounter
	
	method Initialize(string player, string corp)
	{
		This[parent]:Initialize[${player},${corp}]		
		
		if ${m_playerName.Length} 
		{
			UI:UpdateConsole["obj_Fighter: Initialized. Fighting for ${m_playerName}."]
		}
		elseif ${m_corpName.Length} 
		{
			UI:UpdateConsole["obj_Fighter: Initialized. Fighting for ${m_corpName}."]
		}
		Event[OnFrame]:AttachAtom[This:Pulse]
		BotModules:Insert["Fighter"]
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		if !${Config.Common.BotModeName.Equal[Fighter]}
		{
			return
		}
		FrameCounter:Inc

		variable int IntervalInSeconds = 2
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			call This.DevelopmentTest
			This:SetState[]
			FrameCounter:Set[0]
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
				Call Dock
				break
			case BASE
				call Ship.Undock
				break
			case COMBAT
				UI:UpdateConsole["Fighting"]
				break
			case RUNNING
				UI:UpdateConsole["Running Away"]
				call Dock
				ForcedReturn:Set[FALSE]
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
		
		if ${ForcedReturn}
		{
			This.CurrentState:Set["RUNNING"]
			return
		}
	
		if ${This.Abort} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
			return
		}
	
		if ${This.Abort}
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