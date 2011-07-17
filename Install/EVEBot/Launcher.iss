/*
	EVEBot Launcher

	Starts ISXEVE and Launches EVEBot. Handles Logging in.

	-- CyberTech

	%CyberTechWork> they are separate scripts from evebot itself; it's intended that it'll store it's
	own config (config/launcher.xml) which stores name, charid, pass.  If desired char name is unknown
	 at launcher.iss call, then popup a dialog populated with the list of known characters and let the
	  user select.  Once logged in, evebot is called.  When evebot detects it's gotten logged out, it
	  recalls launcher with the character that evebot was running as.

	Modified by TruPoet to use a config file for login / password sets
	TODO: Setup a GUI to interface with the config file

*/

#include Support/TestAPI.iss
#include Support/obj_LoginHandler.iss
#include Support/obj_AutoPatcher.iss
#include Support/obj_Configuration.iss

variable obj_LoginHandler LoginHandler
variable obj_Configuration_BaseConfig BaseConfig
variable obj_Configuration Config

function main(string unchar="", string StartBot=FALSE)
{
	if !${LavishScript.Executable.Find["ExeFile.exe"](exists)}
	{
		Script:End
	}

	if !${ISXEVE(exists)}
	{
		call LoginHandler.LoadExtension
	}

	wait 200 ${ISXEVE.IsReady}

	if !${unchar.Equal[""]}
	{
		BaseConfig:ChangeConfig[${unchar}]
		wait 10
	}

	while !${Display.Window(exists)}
	{
		waitframe
	}
	windowtaskbar on "${unchar}"

	if ${Config.Common.LoginName.Equal["username1"]} || ${Config.Common.AutoLoginCharID} == 0
	{
		UI:UpdateConsole["Launcher: No character specified, or character not found in ${BaseConfig.CONFIG_FILE}"]
		UI:UpdateConsole["  Syntax: run EVEBot/Launcher ""CharName"" <Optional Botname>"]
		; do config gui here, the next line will save a blank template for a config if none exists
		return
	}

	wait 200 ${Login(exists)}

	if ${ISXEVE(exists)} && ${ISXEVE.IsReady}
	{
		LoginHandler:Start
		LoginHandler:DoLogin

		while ${LoginHandler.CurrentState.NotEqual["FINISHED"]}
		{
			waitframe
		}

		if ${StartBot.Upper.NotEqual[FALSE]}
		{
			switch ${StartBot.Upper}
			{
				; TRUE check is for backwards compat from when StartBot was a bool
				case TRUE
				case EVEBOT
				case EVEBOT_STABLE
					EVE:CloseAllMessageBoxes
					; TODO - get rid of this callback shit.
					runscript "${Script.CurrentDirectory}/EveCallback.iss"

					UI:UpdateConsole["Launcher: Starting EVEBot by CyberTech"]
					runscript EVEBot/EVEBot Stable
					wait 600 ${Script[EVEBot].Paused}
					while ${Script[EVEBot].Paused}
					{
						Script[EVEBot]:Resume
						wait 15
					}
					break
				case EVEBOT_DEV
					EVE:CloseAllMessageBoxes
					; TODO - get rid of this callback shit.
					UI:UpdateConsole["Launcher: Starting EveCallback"]
					runscript "${Script.CurrentDirectory}/EveCallback.iss"

					UI:UpdateConsole["Launcher: Starting EVEBot Dev by CyberTech"]
					runscript EVEBot/EVEBot Dev
					wait 600 ${EVEBot.Paused}
					while ${EVEBot.Paused}
					{
						Script[EVEBot]:Resume
						EVEBot:Resume["Resume called via Launcher"]
						wait 15
					}
					break
				case EVEBOT_DEV_TEST
					EVE:CloseAllMessageBoxes
					; TODO - get rid of this callback shit.
					UI:UpdateConsole["Launcher: Starting EveCallback"]
					runscript "${Script.CurrentDirectory}/EveCallback.iss"

					UI:UpdateConsole["Launcher: Starting EVEBot Test by CyberTech"]
					runscript EVEBot/EVEBot Test
					wait 600 ${Script[EVEBot].Paused}
					while ${Script[EVEBot].Paused}
					{
						Script[EVEBot]:Resume
						wait 15
					}
					break
				case STEALTHBOT
					UI:UpdateConsole["Launcher: Starting StealthBot by Stealthy"]
					wait 100
					EVE:CloseAllMessageBoxes
					dotnet sb${Session} stealthbot true
					break
				case QUESTOR
					UI:UpdateConsole["Launcher: Starting Questor by Da_Teach"]
					wait 100
					EVE:CloseAllMessageBoxes
					dotnet questor
					break
				default
					UI:UpdateConsole["Launcher: Unknown bot specified for launch, attempting to run as script name"]
					run ${StartBot}
					break
			}
		}
	}
	else
	{
		UI:UpdateConsole["Launcher: Error: Extension loading failed or was not recognized"]
	}

	UI:UpdateConsole["Launcher Finished"]
}
