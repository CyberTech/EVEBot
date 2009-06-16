#if ${ISXEVE(exists)}
#else
	#error This script requires ISXEVE to be loaded before running
#endif

#include core/defines.iss

/* Base Requirements  */
#include core/obj_EVEBot.iss
#include core/obj_Configuration.iss

/* Cache Objects */
#include core/obj_Cache.iss

/* Core Library (Non-EVE Related code) */
#include core/Lib/obj_BaseClass.iss
#include core/Lib/obj_Vector.iss
;#include core/Lib/obj_Mutex.iss
#include core/Lib/obj_Sound.iss

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
#include core/obj_Items.iss
#include core/obj_Autopilot.iss
#include core/obj_MissionCombat.iss
#include core/obj_MissionCombatConfig.iss
#include core/obj_MissionCommands.iss
#include core/obj_Callback.iss

/* Behavior/Mode Includes */
#includeoptional Behaviors/includes.iss

/* Custom Includes */
#includeoptional Behaviors/UserDefined/includes.iss

/* Custom Includes  - Custom directory is assumed to be an external SVN repository */
#includeoptional Behaviors/Custom/includes.iss

/* Cache Objects */
variable(global) obj_Cache_Me _Me
variable(global) obj_Cache_MyShip _MyShip
variable(global) obj_Cache_EVETime _EVETime

function atexit()
{
	;redirect profile.txt Script:DumpProfiling
}

function main()
{
	echo "${Time} EVEBot: Starting"

#if EVEBOT_PROFILING
	Script:Unsquelch
	Script:EnableDebugLogging[evebot_profile.txt]
	Script[EVEBot]:EnableProfiling
#endif

	while !${_Me.Name(exists)} || ${_Me.Name.Equal[NULL]} || ${_Me.Name.Length} == 0
	{
		echo " ${Time} EVEBot: Waiting for cache to initialize - ${_Me.Name} != ${Me.Name}"
		wait 10
		obj_Cache_Me:Initialize
		obj_Cache_MyShip:Initialize
		obj_Cache_EVETime:Initialize
	}


	echo "${Time} EVEBot: Loading Base & Config..."

	/* All variables that would normally be defined script scope should be defined global scope to simplify threads */

	/* Script-Defined Support Objects */
	declarevariable EVEBot obj_EVEBot global
	declarevariable UI obj_EVEBotUI global
	declarevariable BaseConfig obj_Configuration_BaseConfig global
	declarevariable Config obj_Configuration global
	declarevariable Whitelist obj_Config_Whitelist global
	declarevariable Blacklist obj_Config_Blacklist global

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
	declarevariable Skills obj_Skills global
	declarevariable Bookmarks obj_Bookmarks global
	declarevariable JetCan obj_JetCan global
	declarevariable CorpHangarArray obj_CorpHangerArray global
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

	declarevariable BotModules index:string global
	declarevariable GlobalVariableIterator iterator global

	echo "${Time} EVEBot: Loading Behavior Modules..."

	/* Script-Defined Behavior Objects */
	variable int count = 0
	variable filelist file_list
	variable string obj_name
	variable string var_name
	variable filepath script_dir = ${Script.CurrentDirectory}
	file_list:GetFiles[${script_dir}/\behaviors/\*.iss]
	while (${count:Inc}<=${file_list.Files})
	{
		if ${file_list.File[${count}].Filename.NotEqual["includes.iss"]}
		{	/* skip the includes.iss file */
			obj_name:Set[${file_list.File[${count}].Filename.Left[-4]}]
			var_name:Set[${obj_name.Right[-4]}]
			echo "${Time} EVEBot: Loading behavior ${obj_name}..."
			declarevariable ${var_name} ${obj_name} global
		}
	}

	/* Custom Behavior Objects */
	file_list:GetFiles[${script_dir}/\behaviors/\custom/\*.iss]
	while (${count:Inc}<=${file_list.Files})
	{
		if ${file_list.File[${count}].Filename.NotEqual["includes.iss"]}
		{	/* skip the includes.iss file */
			obj_name:Set[${file_list.File[${count}].Filename.Left[-4]}]
			var_name:Set[${obj_name.Right[-4]}]
			echo "${Time} EVEBot: Loading custom behavior ${obj_name}..."
			declarevariable ${var_name} ${obj_name} global
		}
	}

	variable iterator BotModule
	BotModules:GetIterator[BotModule]

	echo "${Time} EVEBot: Starting Threaded Modules..."

	runscript Threads/Targeting.iss
	runscript Threads/Defense.iss
	runscript Threads/Offense.iss

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

	if ${BotModule:First(exists)}
	{
		UIElement[EveBot].FindUsableChild["EVEBotMode","combobox"]:ClearItems
		do
		{
			UIElement[EveBot].FindUsableChild["EVEBotMode","combobox"]:AddItem["${BotModule.Value}"]
		}
		while ${BotModule:Next(exists)}
		UIElement[EveBot].FindUsableChild["EVEBotMode","combobox"].ItemByText[${Config.Common.BotMode}]:Select

	}

#if USE_ISXIRC
	call ChatIRC.Connect
#endif

	UI:UpdateConsole["-=Paused: Press Run-="]
	Script:Pause

	while ${EVEBot.Paused}
	{
		wait 10
	}

	while TRUE
	{
		if ${BotModule:First(exists)}
		do
		{
			while ${EVEBot.Paused}
			{
				wait 10
			}
			call ${BotModule.Value}.ProcessState
			waitframe
		}
		while ${BotModule:Next(exists)}
	}
}
