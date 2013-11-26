/*
	LoginHandler class

	Object to contain autologin code

	-- CyberTech

	Referenced code from Altered during object creation.

	TODO: Solve invalid config loaded at fresh startup b/c me.name is null during obj_config.

	Modified by TruPoet in such a way that it will work no matter if you're at the login screen,
	charselect, or in the game itself.

*/

objectdef obj_LoginHandler inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"

	variable int LoginTimer = 0
	variable string CurrentState

	variable bool ServerWasDown = FALSE

	; Added these in so no magic numbers are used
	variable float loginWaitTime = 2.0
	variable float connectWaitTime = 7.0
	variable float inspaceWaitTime = 15.0
	variable float CharSelectWaitTime = 15.0
	variable float ServerUpWaitTime = 600.0
	variable float TooManyLoginWaitTime = 1200.0

	variable int CurrentLoggingAttempts = 0
	variable int MaxLoginAttemptsBeforeDelay = 5
	variable obj_PulseTimer LastLoginTimer
	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		This.CurrentState:Set["START"]

		PulseTimer:SetIntervals[1.0,1.5]
		LastLoginTimer:SetIntervals[6.0,15.0]

		UI:UpdateConsole["${LogPrefix}: Initialized", LOG_DEBUG]
	}

	method Start()
	{
		This.PulseTimer:Expire
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${This.LoginTimer} > 0
		{
			UI:UpdateConsole["DEBUG: Pulse: Setting Timer: ${This.LoginTimer}s - ${This.CurrentState}", LOG_DEBUG]
			This.PulseTimer:SetMinInterval[${This.LoginTimer}]
			This.PulseTimer:Update[FALSE]
			This.LoginTimer:Set[0]
		}

		if ${This.PulseTimer.Ready}
		{
			This:DoLogin
			This.PulseTimer:SetMinInterval[1.0]
			This.PulseTimer:Update[FALSE]
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

		if ${${EXTNAME}(exists)}
		{
			UI:UpdateConsole["Login: Waiting for Extension ${EXTNAME}", LOG_DEBUG]
			wait 300 ${${EXTNAME}.IsReady}
			if ${${EXTNAME}.IsReady}
			{
				return
			}
		}

		UI:UpdateConsole["Login: Loading Extension ${EXTNAME}", LOG_DEBUG]
		do
		{
			if !${${EXTNAME}.IsLoading} && !${${EXTNAME}.IsReady}
			{
				if !${${EXTNAME}(exists)}
				{
					extension -unload ${EXTNAME}
					wait 20
				}
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
			UI:UpdateConsole["Login:LoadExtension: Loading extension ${EXTNAME} timed out, retrying", LOG_STANDARD]
		}
		while (!${${EXTNAME}(exists)})
	}

	function Load_isxStealth()
	{
		variable int Timer = 0
		variable string EXTNAME = "ISXSTEALTH"
		extension -unload ${EXTNAME}
		wait 20
		extension ${EXTNAME}
		wait 100
		BlockMiniDump true;
		StealthModule isxstealth.dll
		StealthModule isxeve.dll
		StealthModule innerspace.dll
		StealthModule lavish.dll
		StealthModule is-kernel.dll
		StealthModule isui.dll
		StealthModule is-d3d9.dll
		StealthModule is-d3d8.dll
		StealthModule is-d3d11.dll
		StealthModule is-virtualinput.dll
		StealthModule lavish.lavishvmruntime.dll
		StealthModule lavish.innerspace.dll
	}

	method DoLogin()
	{
		if ${EVEWindow[ByName,modal](exists)}
		{
			if ${EVEWindow[ByName,modal].Text.Find["There is a new build available"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonYes
				This.CurrentState:Set["START"]
				This.LoginTimer:Set[5.0]
				return
			}
			elseif ${EVEWindow[ByName,modal].Text.Find["A client update is available"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonOK
				This.CurrentState:Set["START"]
				This.LoginTimer:Set[5.0]
				return
			}
			elseif ${EVEWindow[ByName,modal].Text.Find["The client update has been installed."](exists)} || \
				${EVEWindow[ByName,modal].Text.Find["The update has been downloaded."](exists)}
			{
				UI:UpdateConsole["Restarting client due to patch...", LOG_STANDARD]
				timedcommand 5 EVEWindow[ByName,modal]:ClickButtonOK
				Script:End
			}
			elseif ${EVEWindow[ByName,modal].Text.Find["The daily downtime will begin in"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonOK
			}
			elseif ${EVEWindow[ByName,modal].Text.Find["The connection to the server was closed"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonOK
			}
			elseif ${EVEWindow[ByName,modal].Text.Find["At any time you can log in to the account management page"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonOK
			}
			elseif ${EVEWindow[ByName,modal].Text.Find["wants you to join their fleet, do you accept?"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonNo
			}
			else
			{
				UI:UpdateConsole["Error: Unexpected Modal dialog with text:", LOG_STANDARD]
				UI:UpdateConsole["${EVEWindow[ByName,modal].Text}", LOG_STANDARD]
				UI:UpdateConsole["--- Launcher Ended ---", LOG_STANDARD]
				Display.Window:Flash
				Script:End
			}
		}

		switch ${This.CurrentState}
		{
			case START
				if ${EVE.IsProgressWindowOpen}
				{
					break
				}

				if ${Login(exists)}
				{
					This.CurrentState:Set["SERVERDOWN"]
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				if ${CharSelect(exists)}
				{
					This.CurrentState:Set["CONNECTING"]
					break
				}
				if !${Login(exists)} && !${CharSelect(exists)} && ${Me(exists)}
				{
					This.CurrentState:Set["LOGGED_IN"]
					This.LoginTimer:Set[${This.inspaceWaitTime}]
					break
				}
			case SERVERDOWN
				UI:UpdateConsole["DEBUG: Server Status: ${Login.ServerStatus}", LOG_DEBUG]
				/*
					Known States:
						"OK"
						"Starting up (1 minute and 17 seconds)"
						"Not accepting connections"
				*/
				if ${Login.ServerStatus.Equal["OK"]} || ${Login.ServerStatus.Equal[" OK"]}
				{
					This.CurrentState:Set["SERVERUP"]
				}
				else
				{
					if !${This.ServerWasDown}
					{
						UI:UpdateConsole["Launcher: Server down", LOG_DEBUG]
					}
					This.CurrentState:Set["SERVERDOWN"]
					This.ServerWasDown:Set[TRUE]
					This.LoginTimer:Set[${This.connectWaitTime}]
				}
				break
			case SERVERUP
				if ${This.ServerWasDown}
				{
					UI:UpdateConsole["Launcher: Server Up After Downtime - Delaying login ${Math.Calc[${This.ServerUpWaitTime}/60]} minutes", LOG_STANDARD]
					This.LoginTimer:Set[${This.ServerUpWaitTime}]
					This.ServerWasDown:Set[FALSE]
					break
				}
				variable int YPos
				variable int XPos

				YPos:Set[${Math.Calc[${Display.Height} / ${Math.Rand[4]:Inc[2]}]}]
				XPos:Set[${Math.Calc[${Display.Width} / ${Math.Rand[4]:Inc[1]}]}]
				Mouse:SetPosition[${XPos}, ${YPos}]
				Mouse:LeftClick

				Login:SetUsername[${Config.Common.LoginName}]
				Login:SetPassword[${Config.Common.LoginPassword}]
				This.CurrentState:Set["LOGIN_ENTERED"]
				break
			case LOGIN_ENTERED
				if ${CurrentLoggingAttempts} > ${MaxLoginAttemptsBeforeDelay}
				{
					UI:UpdateConsole["Warning: ${CurrentLoggingAttempts} login attempts in a row. Delaying next attempt by ${Math.Calc[${This.TooManyLoginWaitTime}/60]} minutes", LOG_STANDARD]
					This.LoginTimer:Set[${This.TooManyLoginWaitTime}]
					CurrentLoggingAttempts:Set[0]
					break
				}
				if ${This.LastLoginTimer.Ready}
				{
					Login:Connect
					This.CurrentState:Set["CONNECTING"]
					This.LastLoginTimer:Update[TRUE]
					CurrentLoggingAttempts:Inc
				}
				This.LoginTimer:Set[${This.connectWaitTime}]
				break
			case CONNECTING
				if ${Login(exists)}
				{
					if ${EVEWindow[ByCaption,LOGIN DATA INCORRECT](exists)}
					{
						; TODO - add a retry count here so we don't spam.
						This.CurrentState:Set["SERVERUP"]
						This.LoginTimer:Set[50.0]
						break
					}

					if ${EVEWindow[ByName,modal].Text.Find["Account subscription expired"](exists)}
					{
						UI:UpdateConsole[" ", LOG_STANDARD]
						UI:UpdateConsole["Launcher: Account Expired, ending script", LOG_STANDARD]
						UI:UpdateConsole["${EVEWindow[ByName,modal].Text}", LOG_STANDARD]
						UI:UpdateConsole[" ", LOG_STANDARD]
						Display.Window:Flash
						Script:End
						break
					}

					if ${EVEWindow[ByName,modal].Text.Find["has been disabled"](exists)}
					{
						UI:UpdateConsole[" ", LOG_STANDARD]
						UI:UpdateConsole["Launcher: Account banned?", LOG_STANDARD]
						UI:UpdateConsole["${EVEWindow[ByName,modal].Text}", LOG_STANDARD]
						UI:UpdateConsole[" ", LOG_STANDARD]
						Display.Window:Flash
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
						This.LoginTimer:Set[10.0]
						break
					}
					; Reconnect if we're still at the login screen
					Login:Connect
					This.LoginTimer:Set[${This.connectWaitTime}]
					break
				}
				if ${CharSelect(exists)} && !${EVE.IsProgressWindowOpen}
				{
					This.CurrentState:Set["CHARSELECT"]
					This.LoginTimer:Set[${This.CharSelectWaitTime}]
					break
				}
			case CHARSELECT
				{
					if !${CharSelect(exists)}
					{
						if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
						{
							This.CurrentState:Set["LOGGED_IN"]
							This.LoginTimer:Set[${This.inspaceWaitTime}]
							break
						}
						break
					}

					if ${EVE.IsProgressWindowOpen}
					{
						;echo {EVE.ProgressWindowTitle} == ${EVE.ProgressWindowTitle}
						This.LoginTimer:Set[2]
						break
					}

					if ${EVEWindow[ByName,MessageBox](exists)} || ${EVEWindow[ByCaption,System Congested](exists)}
					{
						; This happens at character select, when the system is full
						Press Esc
						This.LoginTimer:Set[2]
						break
					}

					if ${EVEWindow[ByName,modal].Text.Find["The daily downtime will begin in"](exists)}
					{
						EVEWindow[ByName,modal]:ClickButtonOK
						break
					}

					if ${EVEWindow[ByName,modal].Text.Find["has been flagged for recustomization."](exists)}
					{
						EVEWindow[ByName,modal]:ClickButtonNo
						break
					}

					if !${CharSelect.CharExists[${Config.Common.AutoLoginCharID}]}
					{
						UI:UpdateConsole["DEBUG: Waiting for ${Config.Common.AutoLoginCharID} to be ready", LOG_DEBUG]
						break
					}
					; Do the actual login, if the rest has been gotten thru
					UI:UpdateConsole["DEBUG: Logging in with CharID: ${Config.Common.AutoLoginCharID}", LOG_DEBUG]
					CharSelect:ClickCharacter[${Config.Common.AutoLoginCharID}]
					This.LoginTimer:Set[${This.inspaceWaitTime}]
					break
				}
			case LOGGED_IN
				{
					if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
					{
						This.CurrentState:Set["FINISHED"]
					}
					break
				}
				break
		}
	}
}
