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

#include core/defines.iss
#include Support/TestAPI.iss
#include Support/obj_LoginHandler.iss
#include Support/obj_AutoPatcher.iss
#include Support/obj_Configuration.iss

variable obj_LoginHandler LoginHandler
variable obj_Configuration_BaseConfig BaseConfig
variable obj_Configuration Config
variable obj_UI UI

function main(string unchar="")
{
	if !${ISXEVE(exists)}
	{
		;echo DEBUG: ISXEVE not loaded, loading it now
		call LoginHandler.LoadExtension
		wait 200
	}
	if !${unchar.Equal[""]}
	{
	       	;echo DEBUG: Changing config to ${unchar}
	       	BaseConfig:ChangeConfig[${unchar}]
	       	wait 10
	}


	if (${Config.Common.LoginName.Equal[""]} || \ 
		${Config.Common.LoginPassword.Equal[""]} || \ 
		${Config.Common.LoginName.Equal[NULL]} || \ 
		${Config.Common.LoginPassword.Equal[NULL]} || \
		${Config.Common.AutoLoginCharID} == 0 || )
	{
		echo No login, pw, or CharID found in config
		; do config gui here, the next line will save a blank template for a config if none exists
		Config:Save
		return
	}
	;echo DEBUG: ${Config.Common.LoginName} / ${Config.Common.LoginPassword} / ${Config.Common.AutoLoginCharID}

	if ${ISXEVE(exists)}
	{
		LoginHandler:Start
		LoginHandler:DoLogin
	}
	while !${LoginHandler.Finished}
	{
		waitframe
	}
}
