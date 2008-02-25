/*
	The combat object
	
	The obj_Combat object is a bot-support module designed to be used
	with EVEBOT.  It provides a common framework for combat decissions
	that the various bot modules can call.
	
	USAGE EXAMPLES
	--------------
	
	objectdef obj_Miner
	{
		variable obj_Combat m_Combat
		
		method Initialize()
		{
			;; bot module initialization
			;; ...
			;; ...
			;; call the combat object's init routine
			m_Combat:Initialize
			;; set the combat "mode"
			m_Combat:SetMode["DEFENSIVE"]
		}
		
		method Shutdown()
		{
			;; bot module deinitialization
			;; ...
			;; ...
			;; call the combat object's deinit routine
			m_Combat:Shutdown
		}
		
		method Pulse()
		{
			if ${EVEBot.Paused}
				return
			if !${Config.Common.BotModeName.Equal[Miner]}
				return
			;; bot module frame action code
			;; ...
			;; ...
			;; call the combat frame action code
			m_Combat:Pulse
		}
		
		function ProcessState()
		{				
			if !${Config.Common.BotModeName.Equal[Miner]}
				return
		    
			; call the combat object state processing
			m_Combat:ProcessState
			
			; see if combat object wants to 
			; override bot module state.
			if ${m_Combat.Override}
				return
		    		    
			; process bot module "states"
			switch ${This.CurrentState}
			{
				;; ...
				;; ...
			}
		}		
	}
	
	-- GliderPro	
*/

objectdef obj_Combat
{
	variable int    m_FrameCounter
	variable bool   m_Override
	variable string m_CombatMode
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Combat: Initialized"]
	}
	
	method Shutdown()
	{
	}
	
	method Pulse()
	{
		m_FrameCounter:Inc
		variable int IntervalInSeconds = 8
		
		if ${m_FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			; set our "state" here
		}
	}
	
	method SetMode(string newMode)
	{
		m_CombatMode:Set[${newMode}]
	}
	
	member:string Mode()
	{
		return ${m_CombatMode}
	}
	
	member:bool Override()
	{
		return ${m_Override}
	}
	
	function ProcessState()
	{
		m_Override:Set[FALSE]		
	}			
}