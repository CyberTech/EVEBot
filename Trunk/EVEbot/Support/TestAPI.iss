/*
	TestAPI 
	
	Copies (usually minimal) of EVEBot objects required to do standalone testing of various evebot objects
	
	-- CyberTech
*/

objectdef obj_UI
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

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

