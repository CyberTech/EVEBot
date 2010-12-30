#if ${ISXEVE(exists)}
#else
	#error EVEBot requires ISXEVE to be loaded before running
#endif

#include core/defines.iss

#if !${ISXEVE.IsBeta}
	#echo 
	#echo 
	#echo Trunk EVEBot requires ISXEVE _BETA_, which is not public 
	#echo at the moment. It will not operate properly with ISXEVE 
	#echo Live. Please use Stable or Tagged Trunk.  See IRC for 
	#echo more information.
	#echo 
	#echo -- CyberTech
	#echo 
	#echo 
	#error Aborting
#endif

/* Base Requirements  */
#include core/obj_Logger.iss
#include core/obj_Configuration.iss
#include core/obj_EVEBot.iss

/* Core Library (Non-EVE Related code) */
;#include core/Lib/obj_BaseClass.iss
;#include core/Lib/obj_Vector.iss
;#include core/Lib/obj_Mutex.iss
;#include core/Lib/obj_Sound.iss
;#include core/Lib/obj_LSGUI.iss

/* Core EVEBot API Includes */
#include core/obj_EntityCache.iss
#include core/obj_Bookmark.iss
#include core/obj_BeltBookmarks.iss
#include core/obj_EVEDB.iss
#include core/obj_Skills.iss
#include core/obj_Asteroids.iss
#include core/obj_Drones.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss
#include core/obj_Bookmarks.iss
#include core/obj_Jetcan.iss
#include core/obj_Social.iss
#include core/obj_Fleet.iss
#include core/obj_Assets.iss
#include core/obj_IRC.iss
#include core/obj_Safespots.iss
#include core/obj_Belts.iss
#include core/obj_Targets.iss
#include core/obj_Agents.iss
#include core/obj_Missions.iss
#include core/obj_Market.iss
#include core/obj_Autopilot.iss
#include core/obj_MissionParser.iss
#include core/obj_MissionCombat.iss
#include core/obj_MissionCombatConfig.iss
#include core/obj_MissionCommands.iss
;#include core/obj_Callback.iss

/* Behavior/Mode Includes */
#includeoptional Behaviors/_includes.iss
#includeoptional Modes/_includes.iss

function atexit()
{
	;redirect profile.txt Script:DumpProfiling
}

function LoadBehaviors(string Label, string Path)
{
	variable int count = 0
	variable filelist file_list
	variable string obj_name
	variable string var_name

	file_list:GetFiles["${Path}"]
	while (${count:Inc}<=${file_list.Files})
	{
		if ${file_list.File[${count}].Filename.NotEqual["_includes.iss"]}
		{
			obj_name:Set[${file_list.File[${count}].Filename.Left[-4]}]
			var_name:Set[${obj_name.Right[-4]}]
			Logger:Log["Loading ${Label} behavior ${var_name}", LOG_DEBUG]
			declarevariable ${var_name} ${obj_name} global
		}
	}
}
function main()
{
	; Set turbo to 4000 per frame for startup.
	Turbo 4000
	echo "${Time} EVEBot: Starting"

#if EVEBOT_PROFILING
	Script:Unsquelch
	Script[EVEBot]:EnableProfiling
	Script:EnableDebugLogging[evebot_profile.txt]
#endif

	echo "${Time} EVEBot: Loading Base & Config..."

	/* All variables that would normally be defined script scope should be defined global scope to simplify threads */

	/* Script-Defined Support Objects */
	declarevariable LSGUI obj_LSGUI global
	declarevariable Logger obj_Logger global
	declarevariable BaseConfig obj_Configuration_BaseConfig global
	declarevariable Config obj_Configuration global
	declarevariable EVEBot obj_EVEBot global
	declarevariable UI obj_EVEBotUI global

	declarevariable Whitelist obj_Config_Whitelist global
	declarevariable Blacklist obj_Config_Blacklist global
	declarevariable EntityCache obj_EntityCache global

	echo "${Time} EVEBot: Loading Databases..."

	/* EVE Database Exports */
	declarevariable EVEDB_Stations obj_EVEDB_Stations global
	declarevariable EVEDB_StationID obj_EVEDB_StationID global
	declarevariable EVEDB_Spawns obj_EVEDB_Spawns global
	declarevariable EVEDB_Items obj_EVEDB_Items global

	echo "${Time} EVEBot: Loading Core Objects..."

	/* Core Objects */
	declarevariable Asteroids obj_Asteroids global
	declarevariable Ship obj_Ship global
	declarevariable Station obj_Station global
	declarevariable Cargo obj_Cargo global
	;declarevariable Skills obj_Skills global
	declarevariable Bookmarks obj_Bookmarks global
	declarevariable JetCan obj_JetCan global
	declarevariable CorpHangarArray obj_CorpHangerArray global
	declarevariable AssemblyArray obj_AssemblyArray global
	declarevariable Social obj_Social global
	declarevariable Fleet obj_Fleet global
	declarevariable Assets obj_Assets global
	declarevariable ChatIRC obj_IRC global
	declarevariable Safespots obj_Safespots global
	declarevariable Belts obj_Belts global
	declarevariable BeltBookmarks obj_BeltBookmarks global
	declarevariable Targets obj_Targets global
	declarevariable Sound obj_Sound global
	declarevariable Agents obj_Agents global
	declarevariable Missions obj_Missions global
	declarevariable Market obj_Market global
	declarevariable Autopilot obj_Autopilot global
	declarevariable Callback obj_Callback global
	
	declarevariable GlobalVariableIterator iterator global

	echo "${Time} EVEBot: Loading Behaviors..."
	#includeoptional Behaviors/_variables.iss
	#includeoptional Modes/_variables.iss

	; Script-Defined Behavior Objects
	;call LoadBehaviors "Stock" "${Script.CurrentDirectory}/\Behaviors/\*.iss"
	; Custom Behavior Objects (External directory is assumed to be from an external repository, it's not part of EVEBot)
	;call LoadBehaviors "External" "${Script.CurrentDirectory}/\Behaviors/\External/\*.iss"
	echo "${Time} EVEBot: Starting Threaded Modules..."

	runscript Threads/Targeting.iss
	runscript Threads/Defense.iss
	runscript Threads/Offense.iss
	;runscript Threads/Navigator.iss
	echo "${Time} EVEBot: Loaded"

	; This is a TimedCommand so that it executes in global scope, so we can get the list of global vars.
	TimedCommand 1 VariableScope:GetIterator[GlobalVariableIterator]
	wait 10

	/* 	This code iterates thru the variables list, looking for classes that have been
		defined with an SVN_REVISION variable.  It then converts that to a numeric
		Version(int), which is then used to calculate the highest version (VersionNum),
		for display on the UI. -- CyberTech
	*/
	;echo "Listing EVEBot Class Versions:"
	if ${GlobalVariableIterator:First(exists)}
	do
	{
		if ${GlobalVariableIterator.Value(exists)} && \
			${GlobalVariableIterator.Value(type).Name.Left[4].Equal["obj_"]} && \
			${GlobalVariableIterator.Value.SVN_REVISION(exists)} && \
			${GlobalVariableIterator.Value.Version(exists)}
		{
			GlobalVariableIterator.Value.Version:Set[${GlobalVariableIterator.Value.SVN_REVISION.Token[2, " "]}]
			;echo " ${GlobalVariableIterator.Value.ObjectName} Revision ${GlobalVariableIterator.Value.Version}"
			if ${VersionNum} < ${GlobalVariableIterator.Value.Version}
			{
				VersionNum:Set[${GlobalVariableIterator.Value.Version}]
			}
		}
	}
	while ${GlobalVariableIterator:Next(exists)}

	EVEBot:SetVersion[${VersionNum}]

	UI:Reload

#if USE_ISXIM
	call ChatIRC.Connect
#endif

	Logger:Log["-=Paused: Press Run-="]
	Turbo 100
	Script:Pause

	while ${EVEBot.Paused}
	{
		wait 10
	}

	while TRUE
	{
		call ${Config.Common.Behavior}.ProcessState
		wait 1
	}
}
