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

variable obj_UI UI
variable obj_LoginHandler LoginHandler
variable obj_Configuration_BaseConfig BaseConfig
variable obj_Configuration Config

function main(string unchar="", bool StartBot=FALSE)
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
	wait 200 ${Login(exists)}

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

	if (${Config.Common.LoginName.Equal[""]} || \
		${Config.Common.LoginPassword.Equal[""]} || \
		${Config.Common.LoginName.Equal[NULL]} || \
		${Config.Common.LoginPassword.Equal[NULL]} || \
		${Config.Common.AutoLoginCharID} == 0 || )
	{
		UI:UpdateConsole["No login, pw, or CharID found in Launcher config"]
		; do config gui here, the next line will save a blank template for a config if none exists
		Config:Save
		return
	}

	if ${ISXEVE(exists)} && ${ISXEVE.IsReady}
	{
		LoginHandler:Start
		LoginHandler:DoLogin

		while ${LoginHandler.CurrentState.NotEqual["FINISHED"]}
		{
			waitframe
		}

		if ${StartBot}
		{
			LoginHandler:StartBot

			while !${Script[EVEBot](exists)}
			{
				wait 10
			}

			wait 600 ${Script[EVEBot].Paused}

			while ${Script[EVEBot].Paused}
			{
				LoginHandler:StartBot
				wait 15
			}
		}
	}
	else
	{
		UI:UpdateConsole["Launcher: Error: Extension loading failed or was not recognized"]
	}

	UI:UpdateConsole["Launcher Finished"]
}
