/*
	EVEBot Launcher
	
	Starts ISXEVE and Launches EVEBot. Handles Logging in.
	
	-- CyberTech
	
*/

#include core/defines.iss
#include core/obj_Login.iss
#include Support/obj_AutoPatcher.iss
variable obj_Login LoginHandler

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
