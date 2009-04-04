/* SuperLauncher.iss - serve as a multi-script launcher for my bots.
Launch my callback script, test crash logging script, and the evebot launcher. */

#define DEBUG TRUE

/* Main entry point. Params[1] = EVEBot Launcher character profile. */
function main(... Params)
{
	variable string LauncherCharacter = ${Params[1]}
	if DEBUG
		echo "SuperLauncher.iss: LauncherCharacter: ${LauncherCharacter}; Params[1]: ${Params[1]}"
	
	/* Make sure ISXEVE is loaded. No point to doing anything else if it isn't loaded, and EVECallback
	could potentially be fucked up by ISXEVE not being loaded. */
	if ${ISXEVE.Version.Equal[NULL]}
	{
		do
		{
			echo "SuperLauncher.iss: ISXEVE not detected. Waiting 10 seconds and checking again..."
			wait 100
		}
		while ${ISXEVE.Version.Equal[NULL]}	
	}
	
	/* Run the Callback script */
	if DEBUG
		echo "SuperLauncher.iss: Starting the EveCallback script"
	run EveCallback
	
	/* TODO: Make the test crash logging script. */
	if DEBUG
		echo "SuperLauncher.iss: Starting the EVEBot Launcher using profile ${LauncherCharacter}"
	run evebot/launcher ${LauncherCharacter}
}