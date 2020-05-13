#if ${ISXEVE(exists)}
#else
	#error EVEBot requires ISXEVE to be loaded before running
#endif

#include core/defines.iss

/* Base Requirements */
#include core/obj_EVEBot.iss
#include core/obj_Configuration.iss

/* Support File Includes */
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

/* Behavior/Mode Includes */
#include Behaviors/obj_Courier.iss
#include Behaviors/obj_StealthHauler.iss
#include Behaviors/obj_Hauler.iss
#include Behaviors/obj_Miner.iss
#include Behaviors/obj_Freighter.iss
#include Behaviors/obj_Ratter.iss
#include Behaviors/obj_Scavenger.iss
#include Behaviors/obj_Missioneer.iss
#include Behaviors/obj_Guardian.iss

function atexit()
{
	;Redirect EVEBot_Profiling.txt Script[EVEBot]:DumpProfiling
}

function main()
{
	echo "${Time} EVEBot: Starting"
	;Script:Unsquelch
	;Script[EVEBot]:EnableDebugLogging[EVEBot_Debug.txt]
	;Script[EVEBot]:EnableProfiling
	;;Redirect EVEBot_Profiling.txt Script[EVEBot]:DumpProfiling

	turbo 4000

	echo "${Time} EVEBot: Loading Base Objects & Config..."

	/* Script-Defined Support Objects */
	declarevariable EVEBot obj_EVEBot script
	declarevariable UI obj_EVEBotUI script
	declarevariable BaseConfig obj_Configuration_BaseConfig script

	declarevariable Config obj_Configuration script
	declarevariable Whitelist obj_Config_Whitelist script
	declarevariable Blacklist obj_Config_Blacklist script

	turbo 8000
	echo "${Time} EVEBot: Loading EVEDBs..."
	declarevariable EVEDB_Stations obj_EVEDB_Stations script
	declarevariable EVEDB_Items obj_EVEDB_Items script
	turbo 4000

	echo "${Time} EVEBot: Loading Core Objects..."
	declarevariable Sound obj_Sound script
	declarevariable ChatIRC obj_IRC script
	declarevariable Asteroids obj_Asteroids script
	declarevariable Ship obj_Ship script
	declarevariable Station obj_Station script
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

	/* Script-Defined Behavior Objects */
	declarevariable BotModules index:string script
	declarevariable Miner obj_Miner script
	declarevariable Hauler obj_Hauler script
	declarevariable Freighter obj_Freighter script
	declarevariable Ratter obj_Ratter script
	declarevariable Missioneer obj_Missioneer script
	declarevariable Guardian obj_Guardian script

	echo "${Time} EVEBot: Loaded"

	variable iterator BotModule
	BotModules:GetIterator[BotModule]

	variable iterator VariableIterator
	Script[EVEBot].VariableScope:GetIterator[VariableIterator]

	/* 	This code iterates thru the variables list, looking for classes that have been
		defined with an SVN_REVISION variable.  It then converts that to a numeric
		Version(int), which is then used to calculate the highest version (VersionNum),
		for display on the UI.
	*/
	;echo "Listing EVEBot Class Versions:"
	;if ${VariableIterator:First(exists)}
	;do
	;{
	;	if ${VariableIterator.Value(exists)} && \
;		${VariableIterator.Value(type).Name.Left[4].Equal["obj_"]} && \
;;		${VariableIterator.Value.SVN_REVISION(exists)} && \
;		${VariableIterator.Value.Version(exists)}
;		{
;			VariableIterator.Value.Version:Set[${VariableIterator.Value.SVN_REVISION.Token[2, " "]}]
;			;echo " ${VariableIterator.Value.ObjectName} Revision ${VariableIterator.Value.Version}"
;			if ${VersionNum} < ${VariableIterator.Value.Version}
;			{
;				VersionNum:Set[${VariableIterator.Value.Version}]
;			}
;		}
;	}
;	while ${VariableIterator:Next(exists)}

;	EVEBot:SetVersion[${VersionNum}]

	UI:Reload


#if USE_ISXIM
	call ChatIRC.Connect
#endif
	turbo 100

	if ${Ship.InWarp}
	{
		UI:UpdateConsole["Waiting for warp to complete"]
		while ${Ship.InWarp}
		{
			wait 10
		}
	}

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
			call RandomDelay 500
		}
		while ${BotModule:Next(exists)}
		call RandomDelay 100

		#if USE_ISXIM
			;	Join IRC
			if !${ChatIRC.IsConnected}
			{
				call ChatIRC.Connect
			}
		#endif
	}
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