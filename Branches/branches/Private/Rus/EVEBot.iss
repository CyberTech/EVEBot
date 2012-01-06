#if ${ISXEVE(exists)}
#else
	#error EVEBot requires ISXEVE to be loaded before running
#endif

#include core/defines.iss

#if ${Type[isxeve].Member[IsBeta]} && ${ISXEVE.IsBeta}
	#echo
	#echo
	#echo Stable EVEBot does not support ISXEVE Beta.
	#echo Reinstall isxeve.dll from https://www.isxGames.com/isxeve/Extensions/ISXEVE.dll
	#echo
	#echo -- CyberTech
	#echo
	#echo
	#error Aborting
#endif

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
#include core/obj_Gang.iss
#include core/obj_Assets.iss
#include core/obj_IRC.iss
#include core/obj_Safespots.iss
#include core/obj_Belts.iss
#include core/obj_Targets.iss
#include core/obj_Sound.iss
#include core/obj_Agents.iss
#include core/obj_Combat.iss
#include core/obj_Missions.iss
#include core/obj_Market.iss
#include core/obj_Items.iss
#include core/obj_Autopilot.iss

/* Behavior/Mode Includes */
#include Behaviors/obj_Courier.iss
#include Behaviors/obj_StealthHauler.iss
#include Behaviors/obj_Hauler.iss
#include Behaviors/obj_Miner.iss
#include Behaviors/obj_Freighter.iss
#include Behaviors/obj_Ratter.iss
#include Behaviors/obj_Scavenger.iss
#include Behaviors/obj_Missioneer.iss

function atexit()
{
	;Redirect EVEBot_Profiling.txt Script[EVEBot]:DumpProfiling
}

function main()
{
	echo "${Time} EVEBot: Starting"

	echo "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
	echo " "
	echo "ATTENTION - ISXEVE Beta (long term revamp) is now in public testing. If you wish to test, please"
	echo "            go to http://eve.isxGames.com/wiki/index.php?title=ISXEVE_Beta"
	echo " "
	echo "            NOTE: Support for ISXEVE Beta is ONLY on irc at irc.lavishsoft.com #ISXEVE, if you"
	echo "                  can not or will not use IRC, then stick with ISXEVE Live until the transition"
	echo " -- CyberTech"
	echo " "
	echo "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
	echo "Resuming in 5 seconds "
	wait 50
	;Script:Unsquelch
	;Script[EVEBot]:EnableDebugLogging[EVEBot_Debug.txt]
	;Script[EVEBot]:EnableProfiling
	;;Redirect EVEBot_Profiling.txt Script[EVEBot]:DumpProfiling

	turbo 4000

	echo "${Time} EVEBot: Loading Objects..."

	/* Script-Defined Support Objects */
	declarevariable EVEBot obj_EVEBot script
	declarevariable UI obj_EVEBotUI script
	declarevariable BaseConfig obj_Configuration_BaseConfig script

	declarevariable Config obj_Configuration script
	declarevariable Whitelist obj_Config_Whitelist script
	declarevariable Blacklist obj_Config_Blacklist script
	declarevariable EVEDB_Stations obj_EVEDB_Stations script
	declarevariable EVEDB_StationID obj_EVEDB_StationID script
	declarevariable EVEDB_Spawns obj_EVEDB_Spawns script
	declarevariable EVEDB_Items obj_EVEDB_Items script

	/* Core Objects */
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
	declarevariable Social obj_Social script
	declarevariable Fleet obj_Fleet script
	declarevariable Assets obj_Assets script
	declarevariable ChatIRC obj_IRC script
	declarevariable Safespots obj_Safespots script
	declarevariable Belts obj_Belts script
	declarevariable Targets obj_Targets script
	declarevariable Sound obj_Sound script
	declarevariable Agents obj_Agents script
	declarevariable Missions obj_Missions script
	declarevariable Market obj_Market script
	declarevariable Autopilot obj_Autopilot script

	/* Script-Defined Behavior Objects */
	declarevariable BotModules index:string script
	declarevariable Miner obj_Miner script
	declarevariable Hauler obj_OreHauler script
	declarevariable Freighter obj_Freighter script
	declarevariable Ratter obj_Ratter script
	declarevariable Missioneer obj_Missioneer script

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
	if ${VariableIterator:First(exists)}
	do
	{

		if ${VariableIterator.Value(exists)} && \
			${VariableIterator.Value(type).Name.Left[4].Equal["obj_"]} && \
			${VariableIterator.Value.SVN_REVISION(exists)} && \
			${VariableIterator.Value.Version(exists)}
		{
			VariableIterator.Value.Version:Set[${VariableIterator.Value.SVN_REVISION.Token[2, " "]}]
			;echo " ${VariableIterator.Value.ObjectName} Revision ${VariableIterator.Value.Version}"
			if ${VersionNum} < ${VariableIterator.Value.Version}
			{
				VersionNum:Set[${VariableIterator.Value.Version}]
			}
		}
	}
	while ${VariableIterator:Next(exists)}

	EVEBot:SetVersion[${VersionNum}]

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
			wait 5
		}
		while ${BotModule:Next(exists)}
		wait 1
	}
}
