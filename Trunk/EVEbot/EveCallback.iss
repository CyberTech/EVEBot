/* EveCallback.iss - Contain the callback for the eve sessions for detecting a crash. */

/* Global instance of obj_EveCallback for the callback. */
variable(global) obj_EveCallback EVECallback
#define DEBUG TRUE

/* Main entry point. */
function main(... Params)
{
	if DEBUG
		echo "EveCallback.iss: Loaded. Beginning infinite loop."
	while 1==1
	{
		
	}
}

objectdef obj_EveCallback
{
	/* Do nothing to initialize. */
	method Initialize()
	{
	
	}

	/* Do the callback. Relay the function call to the uplink, which will have a global atom
	for the check. */
	method DoCallback()
	{
		if ${ISXEVE.Version} > 0
		{
			if DEBUG
				echo "EveCallback.iss: Relaying \"uplink EVEWatcher:Update[${Session},${Me.Name}]\""
			uplink EVEWatcher:Update[${Session},${Me.Name}]
		}
		else
		{
			echo "EveCallback.iss: EVE not detected."
		}
	}
}