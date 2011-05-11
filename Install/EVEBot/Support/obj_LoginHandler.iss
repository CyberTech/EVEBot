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
	variable int connectWaitTime = 5
	variable int inspaceWaitTime = 60
	variable int evebotWaitTime = 30

	method Initialize()
	{
		UI:UpdateConsole["${This.ObjectName}: Initialized", LOG_MINOR]
		This.CurrentState:Set["START"]
	}

	method Start()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This.NextPulse:Set[${Time.Timestamp}]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
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

	method DoLogin()
	{
		UI:UpdateConsole["DEBUG: Current state: ${This.CurrentState}", LOG_DEBUG]

		switch ${This.CurrentState}
		{
			case START
				if ${ISXEVE.IsBeta} && ${EVEWindow[ByName,modal](exists)}
				{
					if ${EVEWindow[ByName,modal].Text.Find["A client update is available."](exists)}
					{
						EVEWindow[ByName,modal]:ClickButtonNo
					}
				}

				EVE:CloseAllMessageBoxes
		
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
				if ${Login.ServerStatus.Equal["OK"]}
				{
					This.CurrentState:Set["SERVERUP"]
				}
				else
				{
					This.CurrentState:Set["SERVERDOWN"]
					This.LoginTimer:Set[${This.connectWaitTime}]
				}
				EVE:CloseAllMessageBoxes
				break
			case SERVERUP
				Login:SetUsername[${Config.Common.LoginName}]
				Login:SetPassword[${Config.Common.LoginPassword}]
				This.CurrentState:Set["LOGIN_ENTERED"]
				This.LoginTimer:Set[1]
				EVE:CloseAllMessageBoxes
				break
			case LOGIN_ENTERED
				Login:Connect
				This.CurrentState:Set["CONNECTING"]
				This.LoginTimer:Set[${This.connectWaitTime}]
				break
			case CONNECTING
				if ${Login(exists)}
				{
					if ${EVEWindow[ByCaption,LOGIN DATA INCORRECT](exists)}
					{
						; TODO - add a retry count here so we don't spam.
						This.CurrentState:Set["SERVERUP"]
						This.LoginTimer:Set[50]
						break
					}
				
					if ${EVEWindow[ByName,modal].Text.Find["Account subscription expired"](exists)}
					{
						echo "Launcher: Account Expired, ending script"
						Script:End
						break
					}

					if ${EVEWindow[ByName,modal].Text.Find["has been disabled"](exists)}
					{
						echo "Launcher: Account banned?"
						Script:End
						break
					}

					if ${EVEWindow[ByCaption,Connection in Progress](exists)} || \
						${EVEWindow[ByCaption,CONNECTION IN PROGRESS](exists)} || \
						${EVEWindow[ByCaption,Connection Not Allowed](exists)} || \
						${EVEWindow[ByCaption,CONNECTION FAILED](exists)}
					{
						; Server is still coming up, or you are queued. Wait 10 seconds.
						Press Esc
						This.CurrentState:Set["PASS_ENTERED"]
						This.LoginTimer:Set[10]
						break
					}
					; Reconnect if we're still at the login screen
					Login:Connect
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				if ${CharSelect(exists)}
				{
					if ${ISXEVE.IsBeta} && ${EVEWindow[ByName,modal].Text.Find["has been flagged for recustomization."](exists)}
					{
						EVEWindow[ByName,modal]:ClickButtonNo
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
						${EVEWindow[ByCaption,ENTERING SPACE](exists)} || \
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
