/*
	AutoPatcher Class
	
	Handles calling ISXGamesPatcher for EVEBot
	
	-- CyberTech
*/

objectdef obj_AutoPatcher
{
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
	member EVEBot_onUpdatedFile(string FilePath)
	{
		echo "obj_AutoUpdater: Updated file ${FilePath}"
		This.UpdatePerformed:Set[TRUE]
	}

	member EVEBot_onUpdateError(string Error)
	{
		echo "obj_AutoUpdater:Error: ${Error}"
	}

	member EVEBot_onUpdateComplete()
	{
		echo "obj_AutoUpdater: Updated of ${APP_NAME} complete"
		This.UpdaterFinished:Set[TRUE]
	}

}