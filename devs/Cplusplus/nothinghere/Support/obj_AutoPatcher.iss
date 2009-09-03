/*
	AutoPatcher Class
	
	Handles calling ISXGamesPatcher for EVEBot
	
	-- CyberTech
*/

objectdef obj_AutoPatcher
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool UpdatePerformed = FALSE
	variable bool UpdaterFinished = FALSE
	
	method Initialize()
	{
		UI:UpdateConsole["obj_AutoPatcher: Running"]
		if ${currentPath.FileExists[${APP_PATH}.nopatch]}
		{
			echo "${APP_NAME}: Development setup, no auto-update"
			return
		}

		echo "${APP_NAME}: Running patch checker for Updates"
		if ${Config.Common.UseDevelopmentBuild}
		{
			dotnet ${APP_NAME} isxGamesPatcher ${APP_NAME} ${APP_VERSION} ${APP_MANIFEST_TRUNK}
		}
		else
		{
			dotnet ${APP_NAME} isxGamesPatcher ${APP_NAME} ${APP_VERSION} ${APP_MANIFEST}
		}

		TimedCommand 60 Script[EVEBot].VariableScope.AutoPatcher:EVEBot_ForceComplete
		while !${This.UpdaterFinished}
		{
			wait 10
		}

		; Check to see if we have updated, if so restart
		if ${This.UpdatePerformed}
		{
			echo "${APP_NAME} updated, restarting in 5 seconds"
			TimedCommand 50 run evebot/evebot
			Script:EndScript
		}		
	}

	/* Detect Script auto-updated files */
	method EVEBot_onUpdatedFile(string FilePath)
	{
		echo "obj_AutoUpdater: Updated file ${FilePath}"
		This.UpdatePerformed:Set[TRUE]
	}

	method EVEBot_onUpdateError(string Error)
	{
		echo "obj_AutoUpdater:Error: ${Error}"
	}

	method EVEBot_onUpdateComplete()
	{
		echo "obj_AutoUpdater: Updated of ${APP_NAME} complete"
		This.UpdaterFinished:Set[TRUE]
	}

	method EVEBot_ForceComplete()
	{
		echo "obj_AutoUpdater: Updated of ${APP_NAME} aborted, timed out after 60 seconds"
		This.UpdaterFinished:Set[TRUE]
	}

}