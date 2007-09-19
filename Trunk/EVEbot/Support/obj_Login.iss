/*
	Login class
	
	Object to contain autologin code
	
	-- CyberTech
	
	Referenced code from Altered during object creation.

	TODO: Solve invalid config loaded at fresh startup b/c me.name is null during obj_config.

*/

objectdef obj_Login
{
	variable int FrameCounter
	variable int LoginTimer = 0
	variable string CurrentState
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Login: Initialized"]
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
			if ${Login(exists)}
			{
				echo ${This.CurrentState}
				This:DoLogin
			}
			
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
	    echo "obj_Login: Loading Extension ${EXTNAME}"
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
		if !${Login(exists)}
		{
			return
		}
		
		EVE:CloseAllMessageBoxes

		switch ${This.CurrentState}
		{
			case START
			case SERVERDOWN
				if ${Login.Serverstatus.NotEqual[LIVE]}
				{
					This.CurrentState:Set["SERVERDOWN"]
					This.LoginTimer:Set[150]
					return
				}
				else
				{
					This.CurrentState:Set["SERVERUP"]
				}
				break
			case SERVERUP
				Login:SetUsername[${Config.Common.LoginName}]
				This.CurrentState:Set["LOGIN_ENTERED"]
				This.LoginTimer:Set[2]
				return
				break
			case LOGIN_ENTERED
				Login:SetPassword[${Config.Common.LoginPassword}]
				This.CurrentState:Set["PASS_ENTERED"]
				This.LoginTimer:Set[2]
				return
				break
			case PASS_ENTERED
				Login:Connect
				This.CurrentState:Set["CONNECTING"]
				This.LoginTimer:Set[60]
				return
				break
			case CONNECTING
				if (!${Login.IsConnecting} || !${CharSelect(exists)})
				{
					This.CurrentState:Set["START"]
					This.LoginTimer:Set[60]
					return
				}
				if ${CharSelect(exists)}
				{
					CharSelect:ClickCharacter[${Config.Common.AutoLoginCharID}]
					This.LoginTimer:Set[60]
					return
				}
				if !${Me.Name(exists)}
				{
					This.LoginTimer:Set[10]
					return
				}
				This.CurrentState:Set["INSPACE"]
				This.LoginTimer:Set[300]
				return
				break
			case INSPACE
				run EVEBot/EVEBot.iss
				return
				break
		}
	}
}
