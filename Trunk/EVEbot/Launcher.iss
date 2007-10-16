/*
	EVEBot Launcher
	
	Starts ISXEVE and Launches EVEBot. Handles Logging in.
	
	-- CyberTech
	
	%CyberTechWork> they are separate scripts from evebot itself; it's intended that it'll store it's 
	own config (config/launcher.xml) which stores name, charid, pass.  If desired char name is unknown
	 at launcher.iss call, then popup a dialog populated with the list of known characters and let the
	  user select.  Once logged in, evebot is called.  When evebot detects it's gotten logged out, it 
	  recalls launcher with the character that evebot was running as.

*/

#include core/defines.iss
#include Support/obj_LoginHandler.iss
#include Support/obj_AutoPatcher.iss
variable obj_LoginHandler LoginHandler

/* Defined here for obj_Login to use temporarily */
objectdef obj_UI
{
	method UpdateConsole(string StatusMessage)
	{
		variable string msg
		
		if ${StatusMessage(exists)}
		{
			msg:Set["${Time.Time24}: ${StatusMessage}"]
			echo ${msg}
		}
	}
}
variable obj_UI UI

function main()
{
	if !${ISXEVE(exists)}
	{
		call LoginHandler.LoadExtension
	}

	if ${ISXEVE(exists)}
	{
		;Login:DoLogin
	}
}
