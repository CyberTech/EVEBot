 /* EveBots.iss - The purpose of this script is to automatically launch all accounts
 in an ISBoxer character set.
 WHAT YOU NEED TO DO:
 1) Set up the launcher for your characters.
 2) Make an ISBoxer character set for any characters you want started or regenerated.
 3) Configure the characters in the ISBoxer set to automatically start the launcher
 		with that slot's character.
 4) Set the variables appropriately in the main function under the line saying "Adjust these"
/* This will automatically close all sessions 5 minutes after downtime and start them back up ,
as well as regenerating any that crash. */
variable(global) obj_EveWatcher EVEWatcher

#define FIVE_MINUTES_MS 1000 * 60 * 5
#define ONE_MINUTE_MS 1000 * 60
#define DEBUG TRUE

/* main() - script entry point. */
function main()
{
	/* Make sure we're run in the uplink */
	if ${Session} != NULL
	{
		echo "EveBots.iss: This script may only be run from the uplink. Use \"uplink run EveBots\" or"
		echo "open the uplink console and run it from there."
		return
	}

	/* Adjust these */
	/* REMEMBER TO ADJUST THESE FOR DAYLIGHT SAVINGS TIME */
	variable int DowntimeHour = 6
	variable int UptimeHour = 7
	variable string CharacterSet = "SomeSet"	/* Name of the ISBoxer Character Set goes here */
	variable int CharactersInSet = 0					/* Number of characters in the ISBoxer Set */
	
	/* Don't touch below this line */	
	/* LS.RT uses time in ms */
	variable int Timer = ${LavishScript.RunningTime}
	variable int CrashedSessions = 0
	variable int TimesReportedLow = 0
	variable iterator CalledBackIterator
	variable iterator SessionIterator
	variable iterator LastUpdateIterator

	/* Loop every minute. */
	while 1==1
	{
		/* Broadcast callback and check for crashes every minute. Only regenerate sessions every five minutes. */

		/* Wait until a bit after the last launcher says it's in-game */
		if DEBUG
			echo "EveBots.iss: LS.RT: ${LavishScript.RunningTime}, EW.LauncherTimer: ${EVEWatcher.LauncherTimer}"
		if ${LavishScript.RunningTime} >= ${EVEWatcher.LauncherTimer}
		{
			/* Broadcast for our callback */
			if DEBUG
				echo "EveBots.iss: Broadcasting callback request to all other sessions then waiting 5 seconds."
			relay "all other" EVECallback:DoCallback
			wait 50
		}
		
		/* Get our iterators. */
		EVEWatcher.Characters_CalledBack:GetIterator[CalledBackIterator]
		EVEWatcher.Characters_Session:GetIterator[SessionIterator]
		EVEWatcher.Characters_LastUpdate:GetIterator[LastUpdateIterator]
		
		/* Close any crashed sessions. If we do have to close any, wait a few seconds after closing to
		give our system a bit of a break between closing sessions and immediately restarting them. */
		if ${CalledBackIterator:First(exists)} && ${SessionIterator:First(exists)} && ${LastUpdateIterator:First(exists)}
		{
			do
			{
				/* If a session hasn't called back for over 60 seconds it's probably crashed.  */
				if (${LavishScript.RunningTime} - ${LastUpdateIterator.Value}) > FIVE_MINUTES_MS && ${LastUpdateIterator.Value} != NULL
				{
					if DEBUG
						echo "EveBots.iss: Haven't heard from ${CalledBackIterator.Key} in over five minutes. Killing ${SessionIterator.Value}."
					kill ${SessionIterator.Value}
					CrashedSessions:Inc
					wait 10
				}
			}
			while ${CalledBackIterator:Next(exists)} && ${SessionIterator:Next(exists)} && ${LastUpdateIterator:Next(exists)}
		}
		
		/* The regeneration check will only run every five mintues. */
		if ${LavishScript.RunningTime} >= ${Timer}
		{
			if DEBUG
				echo "EveBots.iss: Regeneration check."
			/* Update the timer */
			Timer:Set[${Math.Calc[${LavishScript.RunningTime} + FIVE_MINUTES_MS]}]
	
			/* If we're between downtime and uptime and there are running sessions, kill them. */		
			if ${Time.Hour} >= ${DowntimeHour} && ${Time.Hour} < ${UptimeHour} && ${EVEWatcher.Characters_Session.Used} > 0
			{
				if DEBUG
					echo "EveBots.iss: Downtime started, killing all Watched sessions."
				EVEWatcher:CloseSessions[]
				EVEWatcher:ResetCalledBack[]
				EVEWatcher.Characters_CalledBack:Clear
				EVEWatcher.Characters_Session:Clear
			}
			
			/* If we're after uptime, make sure we have our sessions up. */
			/* Just use isboxer to launch the char set. Each char will have a different profile and therefore a different evebot,
				allowing for autologin to work. */
			if (${CrashedSessions} > 0 || ${EVEWatcher.Characters_CalledBack.Used} < ${CharactersInSet}) && (${Time.Hour} >= ${UptimeHour} || ${Time.Hour} < ${DowntimeHour}) 
			{
				/* We need to account for fuckups, i.e. bad login, account expired, account *shudder* closed. Lower CharactersInSet if we repeatedly
				have CalledBack report less than we're expecting so we don't spam launch. */
				if ${EVEWatcher.Characters_CalledBack.Used} < ${CharactersInSet}
				{
					if DEBUG
						echo "EveBots.iss: CallBacks reporting low, incrementing counter..."
					TimesReportedLow:Inc
					if ${TimesReportedLow} > 5
					{
						if DEBUG
							echo "EveBots.iss: Characters reported low five times, problems? Lowering CharactersInSet just in case."
						CharactersInSet:Set[${EVEWatcher.Characters_CalledBack.Used}]
						TimesReportedLow:Set[0]
					}
				}
				if DEBUG
					echo "EveBots.iss: Downtime passed and ${CrashedSessions} crashed sessions detected or no sessions running; regenerating bots."
				run isboxer -launch "${CharacterSet}"
				/* If this is our first run give at least five minutes for everything to start up. */
				if ${EVEWatcher.Characters_CalledBack.Used} == 0
				{
					if DEBUG
						echo "EveBots.iss: First launch, giving sessions some time to start so that Me.Name isn't null for callback..."
					TimesReportedLow:Dec
					/* Must change this wait into a real timer, maybe? */
					wait ${Math.Calc[10 * 60 * 4]}
					/* Wait 4 minutes here and the other minute down there. */
				}
			}
		}

		/* Sleep for 1 minute. */
		/* 10 deciseconds per second, 60 seconds per minute */
		if DEBUG
			echo "EveBots.iss: Sleeping 1 minute."
		wait ${Math.Calc[10 * 60]}
	}
}

/* The object for the eve callbacks. */
objectdef obj_EveWatcher
{
	/* Parallel collections to hold our characters paired with a bool designating
	whether or not we got the callback and a string to hold the session. We will
	use this to kill a crashed session so we can regenerate them. */
	variable collection:bool Characters_CalledBack
	variable collection:string Characters_Session
	variable collection:int Characters_LastUpdate
	
	/* Timer Launcher will update. */
	variable int LauncherTimer = ${Math.Calc[${LavishScript.RunningTime} + 60 * 1000]}
	
	/* Another emtpy initialize function. */
	method Initialize()
	{
		/* This code did not work because of a UTF-8 vs ASCII conflict.
		 Had to make some hackish modifications to insert names based on callbacks. */
	}
	
	/* Reset the CalledBack collection to false. */
	method ResetCalledBack()
	{
		variable iterator itrCalledBack
		Characters_CalledBack:GetIterator[itrCalledBack]
		if DEBUG
			echo "EveBots.iss: Resetting CalledBack list."
		if ${itrCalledBack:First(exists)}
		{
			do
			{
				itrCalledBack:SetValue[FALSE]
			}
			while ${itrCalledBack:Next(exists)}
		}
	}
	
	/* Set the variables from callbacks.
	session: The session that's calling back.
	characterName: The name of the character in the session calling back. */
	method Update(string newSession, string characterName)
	{
		if !${characterName.Equal[NULL]}
	  {
			Characters_CalledBack:Set[${characterName},TRUE]
			Characters_LastUpdate:Set[${characterName},${LavishScript.RunningTime}]
			Characters_Session:Set[${characterName},${newSession}]
		}
	}
	
	/* Close all of our saved sessions. */
	method CloseSessions()
	{
		variable iterator itrSession
		Characters_Session:GetIterator[itrSession]
		if ${itrSession:First(exists)}
		{
			do
			{
				if DEBUG
				{
					echo "EveBots.iss: Closing session ${itrSession.Value}"
				}
				kill ${itrSession.Value}
			}
			while ${itrSession:Next(exists)}
		}
	}
	
	/* Debug methods to dump the collections */
	method DumpSession()
	{
		echo "EveBots: Dumping sessions:"
		variable iterator itrSession
		Characters_Session:GetIterator[itrSession]
		
		if ${itrSession:First(exists)}
		{
			do
			{
				echo "EveBots: ${itrSession.Key} ${itrSession.Value}"
			}
			while ${itrSession:Next(exists)}
		}
	}
	
	method DumpCalledBack()
	{
		echo "EveBots: Dumping CalledBack:"
		variable iterator itrCalledBack
		Characters_CalledBack:GetIterator[itrCalledBack]
		
		if ${itrCalledBack:First(exists)}
		{
			do
			{
				echo "EveBots: ${itrCalledBack.Key} ${itrCalledBack.Value}"
			}
			while ${itrCalledBack:Next(exists)}
		}
	}
	
	method DumpLastUpdate()
	{
		echo "EveBots: Dumping LastUpdate:"
		variable iterator itrLastUpdate
		Characters_LastUpdate:GetIterator[itrLastUpdate]
		
		if ${itrLastUpdate:First(exists)}
		{
			do
			{
				echo "EveBots: ${itrLastUpdate.Key} ${itrLastUpdate.Value}"
			}
			while ${itrLastUpdate:Next(exists)}
		}
	}
}