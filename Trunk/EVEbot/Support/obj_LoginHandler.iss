/*
	LoginHandler class
	
	Object to contain autologin code
	
	-- CyberTech
	
	Referenced code from Altered during object creation.

	TODO: Solve invalid config loaded at fresh startup b/c me.name is null during obj_config.

	Modified by TruPoet in such a way that it will work no matter if you're at the login screen,
	charselect, or in the game itself.

*/

objectdef obj_LoginHandler
{
	variable int FrameCounter
	variable int LoginTimer = 0
	variable string CurrentState
	variable bool Finished = FALSE

	; Added these in so no magic numbers are used
	variable int startWaitTime = 0
	variable int loginWaitTime = 2
	variable int connectWaitTime = 30
	variable int inspaceWaitTime = 60
	
	method Initialize()
	{
		echo obj_Login: Initialized
		This.CurrentState:Set[START]
	}

	method Start()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]		
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		FrameCounter:Inc
		
		variable int IntervalInSeconds = 4
		if ${This.LoginTimer} > 0
		{
			IntervalInSeconds:Set[${This.LoginTimer}]
		}
		
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			;echo DEBUG: Pulse: ${This.LoginTimer} - ${This.CurrentState}
			This:DoLogin
			
			FrameCounter:Set[0]
		}
	}
	
	function LoadExtension()
	{
		variable int Timer = 0
		variable string EXTNAME = "ISXEVE"
		
		if ${${EXTNAME}(exists)}
		{
			return
		}
	    	;echo "DEBUG: obj_Login: Loading Extension ${EXTNAME}"
		do
		{   
			wait 50
			if !${${EXTNAME}.IsLoading} && !${${EXTNAME}.IsReady}
			{
				extension -unload ${EXTNAME}
				extension ${EXTNAME}
			} 	

			Timer:Set[0]
	    
			do
			{
				if (${${EXTNAME}.IsReady})
				{
					return
				}
	           
				Timer:Inc
				waitframe
			}
			while (${Timer} < 200)
			echo "obj_Login:LoadExtension: Loading extension ${EXTNAME} timed out, retrying"
		}
		while (!${${EXTNAME}(exists)})
	 }
	
	method DoLogin()
	{
		EVE:CloseAllMessageBoxes

		;echo DEBUG: Current state: ${This.CurrentState}
		switch ${This.CurrentState}
		{
			case START
				if ${CharSelect(exists)}
				{
					This.CurrentState:Set["CONNECTING"]
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				if !${Login(exists)} && !${CharSelect(exists)}
				{
					This.CurrentState:Set["INSPACE"]
					This.LoginTimer:Set[${This.inspaceWaitTime}]
					break
				}
			case SERVERDOWN
				; echo DEBUG: Server Status: ${Login.ServerStatus}
				if ${Login.ServerStatus.NotEqual[LIVE]}
				{
					This.CurrentState:Set["SERVERDOWN"]
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				else
				{
					This.CurrentState:Set["SERVERUP"]
				}
				break
			case SERVERUP
				Login:SetUsername[${Config.Common.LoginName}]
				This.CurrentState:Set["LOGIN_ENTERED"]
				This.LoginTimer:Set[${This.loginWaitTime}]
				break
			case LOGIN_ENTERED
				Login:SetPassword[${Config.Common.LoginPassword}]
				This.CurrentState:Set["PASS_ENTERED"]
				This.LoginTimer:Set[${This.loginWaitTime}]
				break
			case PASS_ENTERED
				Login:Connect
				This.CurrentState:Set["CONNECTING"]
				This.LoginTimer:Set[${This.connectWaitTime}]
				break
			case CONNECTING
				if ${CharSelect(exists)}
				{
					;echo DEBUG: AutoLoginCharID: ${Config.Common.AutoLoginCharID}
					CharSelect:ClickCharacter[${Config.Common.AutoLoginCharID}]
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				if !${Me.Name(exists)}
				{
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				This.CurrentState:Set["INSPACE"]
				This.LoginTimer:Set[${This.inspaceWaitTime}]
				break
			case INSPACE
				run evebot/evebot
				This.Finished:Set[TRUE]
				return
				break
		}
	}
}
