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
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable time NextPulse

	variable int LoginTimer = 0
	variable string CurrentState
	variable int PulseIntervalInSeconds = 1

	; Added these in so no magic numbers are used
	variable int startWaitTime = 0
	variable int loginWaitTime = 2
	variable int connectWaitTime = 10
	variable int inspaceWaitTime = 60
	variable int evebotWaitTime = 30

	method Initialize()
	{
		UI:UpdateConsole["${This.ObjectName}: Initialized", LOG_MINOR]
		This.CurrentState:Set["START"]
	}

	method Start()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		This.NextPulse:Set[${Time.Timestamp}]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${This.LoginTimer} > 0
		{
			This.PulseIntervalInSeconds:Set[${This.LoginTimer}]
			UI:UpdateConsole["DEBUG: Pulse: ${This.LoginTimer} - ${This.CurrentState}", LOG_DEBUG]
			This.LoginTimer:Set[0]
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:DoLogin

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	function LoadExtension()
	{
		variable int Timer = 0
		variable string EXTNAME = "ISXEVE"

		if ${${EXTNAME}(exists)} && ${${EXTNAME}.IsReady}
		{
			return
		}

		wait 50 ${${EXTNAME}.IsReady}

		UI:UpdateConsole["Login: Loading Extension ${EXTNAME}", LOG_MINOR]
		do
		{
			if !${${EXTNAME}.IsLoading} && !${${EXTNAME}.IsReady}
			{
				extension -unload ${EXTNAME}
				wait 20
				extension ${EXTNAME}
				wait 100 ${${EXTNAME}.IsReady}
			}

			Timer:Set[0]

			do
			{
				if (${${EXTNAME}.IsReady})
				{
					return
				}

				Timer:Inc
				wait 10
			}
			while (${Timer} < 20)
			UI:UpdateConsole["Login:LoadExtension: Loading extension ${EXTNAME} timed out, retrying"]
		}
		while (!${${EXTNAME}(exists)})
	 }

	method StartBot()
	{
		EVE:CloseAllMessageBoxes

		;UI:UpdateConsole["DEBUG: Current state: ${This.CurrentState}"]
		switch ${This.CurrentState}
		{
			case FINISHED
				run evebot/evebot
				This.CurrentState:Set["EVEBOT_STARTED"]
				break
			case EVEBOT_STARTED
				Script[EVEBot]:Resume
				break
			default
				UI:UpdateConsole["Login: StartBot called in unknown state!"]
				break
		}
	}

	method DoLogin()
	{
		EVE:CloseAllMessageBoxes

		UI:UpdateConsole["DEBUG: Current state: ${This.CurrentState}", LOG_DEBUG]
		switch ${This.CurrentState}
		{
			case POSSIBLE_ACCOUNT_EXPIRED
			case BANNED_HAHAHAHA
				{
					This.LoginTimer:Set[100]
					break
				}
			case START
				if ${Login(exists)}
				{
					This.CurrentState:Set["SERVERDOWN"]
					break
				}
				if ${CharSelect(exists)}
				{
					This.CurrentState:Set["CONNECTING"]
					This.LoginTimer:Set[1]
					break
				}
				if !${Login(exists)} && !${CharSelect(exists)}
				{
					This.CurrentState:Set["LOGGED_IN"]
					This.LoginTimer:Set[${This.inspaceWaitTime}]
					break
				}
			case SERVERDOWN
				UI:UpdateConsole["DEBUG: Server Status: ${Login.ServerStatus}", LOG_DEBUG]
				if ${Login.ServerStatus.Equal[LIVE]} || ${Login.ServerStatus.Equal[EVE-EVE-RELEASE]}
				{
					This.CurrentState:Set["SERVERUP"]
				}
				else
				{
					This.CurrentState:Set["SERVERDOWN"]
					This.LoginTimer:Set[${This.connectWaitTime}]
				}
				break
			case SERVERUP
				Login:SetUsername[${Config.Common.LoginName}]
				Login:SetPassword[${Config.Common.LoginPassword}]
				This.CurrentState:Set["LOGIN_ENTERED"]
				This.LoginTimer:Set[1]
				break
			case LOGIN_ENTERED
				Login:Connect
				This.CurrentState:Set["CONNECTING"]
				This.LoginTimer:Set[${This.connectWaitTime}]
				break
			case CONNECTING
				if ${EVEWindow[ByCaption,BANNED](exists)}
				{
					This.CurrentState:Set["BANNED_HAHAHAHA"]
					This.LoginTimer:Set[100]
					break
				}
				if ${EVEWindow[ByCaption,LOGIN DATA INCORRECT](exists)}
				{
					; TODO - add a retry count here so we don't spam.
					This.CurrentState:Set["SERVERUP"]
					This.LoginTimer:Set[50]
					break
				}
				/* this one causes false positives in overloaded systems
				if ${EVEWindow[ByCaption,INFORMATION](exists)}
				{
					This.CurrentState:Set["POSSIBLE_ACCOUNT_EXPIRED"]
					This.LoginTimer:Set[100]
					break
				}
				*/
				if ${EVEWindow[ByCaption,Connection in Progress](exists)} || \
					${EVEWindow[ByCaption,Connection Not Allowed](exists)} || \
					${EVEWindow[ByCaption,CONNECTION FAILED](exists)}
				{
					; Server is still coming up, or you are queued. Wait 10 seconds.
					Press Esc
					This.CurrentState:Set["PASS_ENTERED"]
					This.LoginTimer:Set[10]
					break
				}
				if ${EVEWindow[ByName,MessageBox](exists)} || \
					${EVEWindow[ByCaption,System Congested](exists)}
				{
					; This happens at character select, when the system is full
					Press Esc
					This.LoginTimer:Set[2]
					break
				}
				if ${Login(exists)}
				{
					; Reconnect if we're still at the login screen
					Login:Connect
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				if ${CharSelect(exists)}
				{
					;UI:UpdateConsole["DEBUG: AutoLoginCharID: ${Config.Common.AutoLoginCharID}", LOG_DEBUG]
					CharSelect:ClickCharacter[${Config.Common.AutoLoginCharID}]
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				else
				{
					; Now we're just waiting to get fully into the game. This can take a while, especially in systems like Jita.
					if ${EVEWindow[ByCaption,ENTERING STATION](exists)} || \
						${EVEWindow[ByCaption,PREPARE TO UNDOCK](exists)} || \
						${EVEWindow[ByCaption,ENTERING SPACE](exists)}
						${EVEWindow[ByCaption,CHARACTER SELECTION](exists)}
					{
						This.LoginTimer:Set[1]
						break
					}
					if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
					{
						This.CurrentState:Set["LOGGED_IN"]
						This.LoginTimer:Set[${This.inspaceWaitTime}]
						break
					}
					This.LoginTimer:Set[1]
					break
				}
			case LOGGED_IN
				{
					This.CurrentState:Set["FINISHED"]
					break
				}
				break
		}
	}
}
