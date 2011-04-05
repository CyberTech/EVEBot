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
#include core/obj_Skills.iss
#include core/obj_Asteroids.iss
#include core/obj_Drones.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss
#include core/obj_TempBookmarks.iss
#include core/obj_Jetcan.iss
#include core/obj_Social.iss
#include core/obj_Fleet.iss
#include core/obj_FleetManager.iss
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
#includeoptional Behaviors/Testcases/_includes.iss
#includeoptional Behaviors/_includes.iss

function atexit()
{
	;redirect profile.txt Script:DumpProfiling
}

function LoadBehaviors(string Label, string Path)
{
	variable int Position = 0
	variable filelist Files
	variable string NewObjectName
	variable string NewVarName
	variable string Log

	Files:GetFiles["${Path}"]
	while (${Position:Inc}<=${Files.Files})
	{
		if ${Files.File[${Position}].Filename.NotEqual["_includes.iss"]}
		{
			NewObjectName:Set[${Files.File[${Position}].Filename.Left[-4]}]
			NewVarName:Set[${NewObjectName.Right[-4]}]
			Logger:Log["Loading ${Label} behavior ${NewVarName}", LOG_DEBUG]
			declarevariable ${NewVarName} ${NewObjectName} global
		}
	}
	if ${Log.Length} > 0
	{
		Logger:Log["EVEBot:   ${Log}", LOG_ECHOTOO]
	}
}

function LoadThreads(string Label, string Path)
{
	variable int Position = 0
	variable filelist Files
	variable string Log

	Files:GetFiles["${Path}"]
	while (${Position:Inc}<=${Files.Files})
	{
		Log:Concat["${Files.File[${Position}]} "]
		TimedCommand 0 runscript \"${Files.File[${Position}].FullPath}\"
	}
	if ${Log.Length} > 0
	{
		Logger:Log["EVEBot:   ${Log}", LOG_ECHOTOO]
	}
}

function CreateVariable(string VarName, string VarType, string Scope, string DefaultValue)
{
	variable time StartTime
	variable time EndTime

	StartTime:Set[${Time.Timestamp}]
	declarevariable ${VarName} ${VarType} ${Scope} ${DefaultValue}
	EndTime:Set[${Time.Timestamp}]

#if EVEBOT_DEBUG_TIMING
	Logger:Log["DEBUG: Declared ${VarName} in ${Math.Calc[${EndTime.Timestamp} - ${StartTime.Timestamp}]}", LOG_ECHOTOO]
#endif
}

function main()
{
	; Set turbo to 4000 per frame for startup.
	Turbo 4000
	echo "${Time}: EVEBot: Starting"

#if EVEBOT_PROFILING
	Script:Unsquelch
	Script[EVEBot]:EnableProfiling
	Script:EnableDebugLogging[evebot_profile.txt]
#endif

	echo "${Time}: EVEBot: Loading Base & Config..."

	/* All variables that would normally be defined script scope should be defined global scope to simplify threads */

	/* NON-EVE Related Objects */
	call CreateVariable LSQueryCache obj_LSQueryCache global

	/* Script-Defined Support Objects */
	call CreateVariable LSGUI obj_LSGUI global "Tabs@EVEBot"
	call CreateVariable Logger obj_Logger global
	call CreateVariable BaseConfig obj_Configuration_BaseConfig global
	call CreateVariable Config obj_Configuration global
	call CreateVariable EVEBot obj_EVEBot global
	call CreateVariable UI obj_EVEBotUI global
	call CreateVariable UplinkManager obj_UplinkManager global
	call CreateVariable Whitelist obj_Config_Whitelist global
	call CreateVariable Blacklist obj_Config_Blacklist global
	call CreateVariable EntityCache obj_EntityCache global

	Logger:Log["EVEBot: Loading Core Objects...", LOG_ECHOTOO]

	/* Core Objects */
	call CreateVariable Asteroids obj_Asteroids global
	call CreateVariable Ship obj_Ship global
	call CreateVariable Station obj_Station global
	call CreateVariable Cargo obj_Cargo global
	;call CreateVariable Skills obj_Skills global
	call CreateVariable TempBookmarks obj_TempBookmarks global
	call CreateVariable JetCan obj_JetCan global
	call CreateVariable CorpHangarArray obj_CorpHangarArray global
	call CreateVariable AssemblyArray obj_AssemblyArray global
	call CreateVariable Social obj_Social global
	call CreateVariable Fleet obj_Fleet global
	call CreateVariable FleetManager obj_FleetManager global
	call CreateVariable Assets obj_Assets global
	call CreateVariable ChatIRC obj_IRC global
	call CreateVariable Safespots obj_Safespots global
	call CreateVariable Belts obj_Belts global
	call CreateVariable BeltBookmarks obj_BeltBookmarks global
	call CreateVariable Targets obj_Targets global
	call CreateVariable Sound obj_Sound global
	call CreateVariable Agents obj_Agents global
	call CreateVariable Missions obj_Missions global
	call CreateVariable Market obj_Market global
	call CreateVariable Autopilot obj_Autopilot global
	call CreateVariable Callback obj_Callback global

	call CreateVariable  GlobalVariableIterator iterator global

	wait 0.5
	; Threads need to load after globals but before behaviors.
	Logger:Log["EVEBot: Starting EVEBot Threads...", LOG_ECHOTOO]
	call LoadThreads "Thread" "${Script.CurrentDirectory}/\Threads/\*.iss"

	Logger:Log["EVEBot: Loading behaviors...", LOG_ECHOTOO]
	#includeoptional Behaviors/_variables.iss
	#includeoptional Behaviors/Testcases/_variables.iss

	; Script-Defined Behavior Objects
	;call LoadBehaviors "Stock" "${Script.CurrentDirectory}/\Behaviors/\*.iss"
	; Custom Behavior Objects (External directory is assumed to be from an external repository, it's not part of EVEBot)
	;call LoadBehaviors "External" "${Script.CurrentDirectory}/\Behaviors/\External/\*.iss"

	if !${EVEBot.BehaviorList.Used}
	{
		Logger:Log["ERROR: No Behavioral modules loaded, exiting", LOG_ECHOTOO]
		EVEBot:EndBot[]
	}

	Logger:Log["EVEBot: Parsing object versions...", LOG_ECHOTOO]

	; This is a TimedCommand so that it executes in global scope, so we can get the list of global vars.
	TimedCommand 0 VariableScope:GetIterator[GlobalVariableIterator]
	wait 10 ${GlobalVariableIterator:First(exists)}

	/* 	This code iterates thru the variables list, looking for classes that have been
		defined with an SVN_REVISION variable.  It then converts that to a numeric
		Version(int), which is then used to calculate the highest version (VersionNum),
		for display on the UI. -- CyberTech
	*/
	;Logger:Log["DEBUG: Dumping EVEBot Class Versions:". LOG_ECHOTOO]
	if ${GlobalVariableIterator:First(exists)}
	do
	{
		if ${GlobalVariableIterator.Value(exists)} && \
			${GlobalVariableIterator.Value(type).Name.Left[4].Equal["obj_"]} && \
			${GlobalVariableIterator.Value.SVN_REVISION(exists)} && \
			${GlobalVariableIterator.Value.Version(exists)}
		{
			GlobalVariableIterator.Value.Version:Set[${GlobalVariableIterator.Value.SVN_REVISION.Token[2, " "]}]
			;Logger:Log["DEBUG: ${GlobalVariableIterator.Value.ObjectName} Revision ${GlobalVariableIterator.Value.Version}", LOG_ECHOTOO]
			if ${VersionNum} < ${GlobalVariableIterator.Value.Version}
			{
				VersionNum:Set[${GlobalVariableIterator.Value.Version}]
			}
		}
	}
	while ${GlobalVariableIterator:Next(exists)}
	EVEBot:SetVersion[${VersionNum}]

	Logger:Log["EVEBot: Completing startup...", LOG_ECHOTOO]
	UI:Reload

	call ChatIRC.Connect

	Turbo 125

	; Clear the EVEBotBehaviors globalkeep now that we're done with it
	TimedCommand 0 VariableScope:DeleteVariable["EVEBotBehaviors"]
	EVEBot.Loaded:Set[TRUE]
	EVEBot:Pause["EVEBot: Loaded ${AppVersion}: Paused - Press Run"]

	while TRUE
	{
		if !${EVEBot.Paused} && \
			!${EVEBot.Disabled} && \
			${${Config.Common.Behavior}(exists)}
		{
			call ${Config.Common.Behavior}.ProcessState
		}
		wait 5
	}
}
