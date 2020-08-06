#if ${ISXEVE(exists)}
#else
	#error EVEBot requires ISXEVE to be loaded before running
#endif

#include core/defines.iss

/* Base Requirements */
#include core/obj_Logger.iss
#include core/obj_Configuration.iss
#include core/obj_EVEBot.iss

/* Support File Includes */
#include core/obj_Skills.iss
#include core/obj_Asteroids.iss
#include core/obj_Drones.iss
#include core/obj_Ship.iss
#include core/obj_Station.iss
#include core/obj_Inventory.iss
#include core/obj_Cargo.iss
#include core/obj_EVEBotUI.iss
#include core/obj_Bookmarks.iss
#include core/obj_Jetcan.iss
#include core/obj_Social.iss
#include core/obj_Assets.iss
#include core/obj_IRC.iss
#include core/obj_Safespots.iss
#include core/obj_Ammospots.iss
#include core/obj_Belts.iss
#include core/obj_Targets.iss
#include core/obj_Sound.iss
#include core/obj_Agents.iss
#include core/obj_Combat.iss
#include core/obj_Missions.iss
#include core/obj_Market.iss
#include core/obj_Items.iss
#include core/obj_Autopilot.iss
#include core/obj_Fleet.iss

objectdef obj_Behaviors
{
		variable set Loaded
}
; Holds the loaded behaviors
variable(global) obj_Behaviors Behaviors

/* Behavior/Mode Includes */
#includeoptional Behaviors/Testcases/_includes.iss
#includeoptional Behaviors/_includes.iss

function atexit()
{
	;Redirect EVEBot_Profiling.txt Script[EVEBot]:DumpProfiling
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
		if ${Files.File[${Position}].Filename.NotEqual["_includes.iss"]} && \
			${Files.File[${Position}].Filename.NotEqual["_variables.iss"]}
		{
			NewObjectName:Set[${Files.File[${Position}].Filename.Left[-4]}]
			NewVarName:Set[${NewObjectName.Right[-4]}]
			Logger:Log["   ${NewVarName}", LOG_ECHOTOO]
			call CreateVariable ${NewVarName} ${NewObjectName} script
			Behaviors.Loaded:Add[${NewVarName}]
		}
	}
	if ${Log.Length} > 0
	{
		Logger:Log["   ${Log}", LOG_ECHOTOO]
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
		if ${Files.File[${Position}].Size} > 0
		{
			if ${Log.NotNULLOrEmpty}
			{
				Log:Concat[", "]
			}

			Log:Concat["${Files.File[${Position}].Filename.Left[-4]} "]
			TimedCommand 0 runscript \"${Files.File[${Position}].FullPath}\"
		}
	}
	if ${Log.Length} > 0
	{
		Logger:Log["   ${Log}", LOG_ECHOTOO]
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

#ifdef EVEBOT_TESTCASE
function evebot_main()
{
#else
function main()
{
#endif
	; Set turbo to 4000 per frame for startup.
	Turbo 4000
	echo "${Time}: ${APP_NAME} \atstarting\ax"

#if EVEBOT_PROFILING
	Script:Unsquelch
	Script[EVEBot]:EnableProfiling
	Script:EnableDebugLogging[evebot_profile.txt]
#endif

	call CreateVariable Logger obj_Logger global

	Logger:Log[" Loading Base & Config...", LOG_ECHOTOO]

	/* NON-EVE Related Objects */
	call CreateVariable LSQueryCache obj_LSQueryCache global

	/* Script-Defined Support Objects */
	declarevariable BaseConfig obj_Configuration_BaseConfig script

	declarevariable Config obj_Configuration script
	call CreateVariable EVEBot obj_EVEBot global
	declarevariable UI obj_EVEBotUI script
	declarevariable Whitelist obj_Config_Whitelist script
	declarevariable Blacklist obj_Config_Blacklist script

	turbo 8000
	Logger:Log[" Loading EVEDBs...", LOG_ECHOTOO]
	declarevariable EVEDB_Stations obj_EVEDB_Stations script
	declarevariable EVEDB_Items obj_EVEDB_Items script
	turbo 4000

	Logger:Log[" Loading Core Objects...", LOG_ECHOTOO]
	declarevariable Sound obj_Sound script
	declarevariable ChatIRC obj_IRC script
	declarevariable Asteroids obj_Asteroids script
	declarevariable Ship obj_Ship script
	declarevariable Station obj_Station script
	declarevariable Inventory obj_Inventory script
	declarevariable Cargo obj_Cargo script
	declarevariable Skills obj_Skills script
	declarevariable Bookmarks obj_Bookmarks script
	declarevariable JetCan obj_JetCan script
	declarevariable CorpHangarArray obj_CorpHangarArray script
	declarevariable LargeShipAssemblyArray obj_LargeShipAssemblyArray script
	declarevariable XLargeShipAssemblyArray obj_XLargeShipAssemblyArray script
	declarevariable CompressionArray obj_CompressionArray script
	declarevariable Social obj_Social script
	declarevariable Fleet obj_Fleet script
	declarevariable Assets obj_Assets script
	declarevariable Safespots obj_Safespots script
	declarevariable Ammospots obj_Ammospots script
	declarevariable Belts obj_Belts script
	declarevariable Targets obj_Targets script
	declarevariable Agents obj_Agents script
	declarevariable Missions obj_Missions script
	declarevariable Market obj_Market script
	declarevariable Autopilot obj_Autopilot script

	wait 0.5
	; Threads need to load after globals but before behaviors.
	Logger:Log[" Starting threads...", LOG_ECHOTOO]
	call LoadThreads "Thread" "${Script.CurrentDirectory}/\Threads/\*.iss"

	Logger:Log[" Loading behaviors...", LOG_ECHOTOO]
	#includeoptional Behaviors/_variables.iss
	#includeoptional Behaviors/Testcases/_variables.iss

	; Script-Defined Behavior Objects
	;Logger:Log[" Loading stock behaviors...", LOG_ECHOTOO]
	;call LoadBehaviors "Stock" "${Script.CurrentDirectory}/\Behaviors/\*.iss"
	;Logger:Log[" Loading testcase behaviors...", LOG_ECHOTOO]
	;call LoadBehaviors "Testcases" "${Script.CurrentDirectory}/\Behaviors/\Testcases/\*.iss"

	; Custom Behavior Objects (External directory is assumed to be from an external repository, it's not part of EVEBot)
	;Logger:Log[" Loading 3rd Party behaviors...", LOG_ECHOTOO]
	;call LoadBehaviors "External" "${Script.CurrentDirectory}/\Behaviors/\External/\*.iss"

	if ${Behaviors.Loaded.Used} == 0
	{
		Logger:Log["WARNING: No Behavioral modules loaded, background tasks only", LOG_ECHOTOO]
	}

	Logger:Log[" Reloading UI...", LOG_ECHOTOO]
	UI:Reload

#if USE_ISXIM
	call ChatIRC.Connect
#endif
	Turbo 125

	; Clear the EVEBotBehaviors globalkeep now that we're done with it
	TimedCommand 0 VariableScope:DeleteVariable["EVEBotBehaviors"]

	if ${Ship.InWarp}
	{
		Logger:Log[" Waiting for warp to complete"]
		while ${Ship.InWarp}
		{
			wait 10
		}
	}

	EVEBot.Loaded:Set[TRUE]
	Logger:Log["${APP_NAME} loaded", LOG_ECHOTOO]
#ifndef EVEBOT_TESTCASE
	EVEBot:Pause["Press Run to start"]

	while TRUE
	{
		if !${EVEBot.Paused} && \
			!${EVEBot.Disabled} && \
			${${Config.Common.CurrentBehavior}(exists)}
		{
			call ${Config.Common.CurrentBehavior}.ProcessState
		}

		call RandomDelay 100
	}
#endif
}

;	This function introduces a random delay to make evebot look more organic to data tracking.
;	The delay should be minor and un-noticeable, unless you're a machine
;	Range = Value plus or minus 50 milliseconds
function RandomDelay(int base)
{
	variable int WaitTime
	WaitTime:Set[${Math.Calc[${base} - 50 + ${Math.Rand[100]}]}]
	variable int FinishTime=${LavishScript.RunningTime}
	FinishTime:Inc[${WaitTime}]
	do
	{
		wait 1
	}
	while ${LavishScript.RunningTime}<${FinishTime}
}