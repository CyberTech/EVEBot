/*
*/

function main(string unchar="", bool StartBot=FALSE)
{
	if !${LavishScript.Executable.Find["ExeFile.exe"](exists)}
	{
		Script:End
	}

	Display.Window:Flash
	echo "*******************************************"
	echo "\arYou are using a branch of EVEBot that has been deprecated - your launcher and support scripts are not being updated"
	echo "\ayPlease see http://eve.isxgames.com/wiki/index.php?title=EVEBot_for_Dummies#How_to_get_EVEBot\ax"
	echo "\ayfor instructions on installing the 'Install' branch of EVEBot, which has a vastly updated launcher\ax"
	echo "*******************************************"
	Console:Open
	return
}
