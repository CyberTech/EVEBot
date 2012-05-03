/*
This contains all stuff dealing with other players around us. - Hessinger

	Methods
		- GetPlayers(): Updates our Pilot Index (Currently updated on pulse, do not use elsewhere)

	Members
		- (bool) PlayerDetection(): Returns TRUE if a Player is near us. (Notes: Ignores Fleet Members)
		- (bool) NPCDetection(): Returns TRUE if an NPC is near us.
		- (bool) PilotsWithinDectection(int Distance): Returns True if there are pilots within the distance passed to the member. (Notes: Only works for players)
		- (bool) StandingDetection(int Standing): Returns True if there are pilots below the standing passed to the member. (Notes: Only works for players)
		- (bool) PossibleHostiles(): Returns True if there are ships targeting us.
*/

objectdef obj_Social
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:pilot PilotIndex
	variable index:entity EntityIndex
	variable collection:time WhiteListPilotLog
	variable collection:time BlackListPilotLog

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable iterator WhiteListPilotIterator
	variable iterator WhiteListCorpIterator
	variable iterator WhiteListAllianceIterator
	variable iterator BlackListPilotIterator
	variable iterator BlackListCorpIterator
	variable iterator BlackListAllianceIterator
	variable bool SystemSafe

	variable set PilotBlackList
	variable set CorpBlackList
	variable set AllianceBlackList
	variable set PilotWhiteList
	variable set CorpWhiteList
	variable set AllianceWhiteList
	
	variable int NextBreak=0
	variable int NextRestart=0
	variable bool OnBreak=FALSE
	variable time CurrentTime
	variable time NextBreakTime
	variable time RestartTime
	
	variable int IsSafeCooldown=0

	method Initialize()
	{
		Whitelist.PilotsRef:GetSettingIterator[This.WhiteListPilotIterator]
		Whitelist.CorporationsRef:GetSettingIterator[This.WhiteListCorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.WhiteListAllianceIterator]

		Blacklist.PilotsRef:GetSettingIterator[This.BlackListPilotIterator]
		Blacklist.CorporationsRef:GetSettingIterator[This.BlackListCorpIterator]
		Blacklist.AlliancesRef:GetSettingIterator[This.BlackListAllianceIterator]

		UI:UpdateConsole["obj_Social: Initializing whitelist...", LOG_MINOR]
		PilotWhiteList:Add[${Me.CharID}]
		if ${Me.Corp.ID} > 0
		{
			This.CorpWhiteList:Add[${Me.Corp.ID}]
		}
		if ${Me.AllianceID} > 0
		{
			This.AllianceWhiteList:Add[${Me.AllianceID}]
		}

		if ${This.WhiteListPilotIterator:First(exists)}
		do
		{
			This.PilotWhiteList:Add[${This.WhiteListPilotIterator.Value}]
		}
		while ${This.WhiteListPilotIterator:Next(exists)}

		if ${This.WhiteListCorpIterator:First(exists)}
		do
		{
			This.CorpWhiteList:Add[${This.WhiteListCorpIterator.Value}]
		}
		while ${This.WhiteListCorpIterator:Next(exists)}

		if ${This.WhiteListAllianceIterator:First(exists)}
		do
		{
			This.AllianceWhiteList:Add[${This.WhiteListAllianceIterator.Value}]
		}
		while ${This.WhiteListAllianceIterator:Next(exists)}

		UI:UpdateConsole["obj_Social: Initializing blacklist...", LOG_MINOR]
		if ${This.BlackListPilotIterator:First(exists)}
		do
		{
			This.PilotBlackList:Add[${This.BlackListPilotIterator.Value}]
		}
		while ${This.BlackListPilotIterator:Next(exists)}

		if ${This.BlackListCorpIterator:First(exists)}
		do
		{
			This.CorpBlackList:Add[${This.BlackListCorpIterator.Value}]
		}
		while ${This.BlackListCorpIterator:Next(exists)}

		if ${This.BlackListAllianceIterator:First(exists)}
		do
		{
			This.AllianceBlackList:Add[${This.BlackListAllianceIterator.Value}]
		}
		while ${This.BlackListAllianceIterator:Next(exists)}

		SystemSafe:Set[TRUE]

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Event[EVE_OnChannelMessage]:AttachAtom[This:OnChannelMessage]
		LavishScript:RegisterEvent[EVEBot_HARDSTOP]
		Event[EVEBot_HARDSTOP]:AttachAtom[This:TriggerHARDSTOP]
		LavishScript:RegisterEvent[EVEBot_ABORTHARDSTOP]
		Event[EVEBot_ABORTHARDSTOP]:AttachAtom[This:AbortHARDSTOP]

		UI:UpdateConsole["obj_Social: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVE_OnChannelMessage]:DetachAtom[This:OnChannelMessage]
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		Event[EVEBot_HARDSTOP]:DetachAtom[This:TriggerHARDSTOP]
		Event[EVEBot_ABORTHARDSTOP]:DetachAtom[This:AbortHARDSTOP]
	}

	method Pulse()
	{
		if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
			EVE:GetLocalPilots[This.PilotIndex]
			if ${This.PilotIndex.Used} == 1
			{
				This.PilotIndex:Clear
			}

			if !${Me.InStation}
			{
				EVE:QueryEntities[This.EntityIndex,"CategoryID = CATEGORYID_ENTITY"]
			}
			else
			{
				This.EntityIndex:Clear
			}

			SystemSafe:Set[${Math.Calc[${This.CheckLocalWhiteList} & ${This.CheckLocalBlackList} & ${This.CheckStanding}].Int(bool)}]

			if ${IsSafeCooldown} == 0 && !${SystemSafe} && ${Config.Combat.UseSafeCooldown}
			{
				IsSafeCooldown:Set[${Math.Calc[${Time.Timestamp} + (${Config.Combat.SafeCooldown} * 60)]}]
			}

			if ${IsSafeCooldown} != 0 && ${Config.Combat.UseSafeCooldown}
			{
				if ${Time.Timestamp} >= ${IsSafeCooldown}
				{
					IsSafeCooldown:Set[0]
				}
				else
				{ 
					if !${SystemSafe}
					{
						IsSafeCooldown:Set[${Math.Calc[${Time.Timestamp} + (${Config.Combat.SafeCooldown} * 60)]}]
						echo Unsafe pilot still in system - Reset timer to ${IsSafeCooldown}
					}
					else
					{
						echo No unsafe pilots in system but still on cooldown
					}
					SystemSafe:Set[FALSE]
				}
			}
			
			
			
			This:ProcessBreak
			
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

	method OnChannelMessage(int ChannelID, int64 CharID, int64 CorpID, int64 AllianceID, string CharName, string MessageText)
	{
		if ${ChannelID} == ${Me.SolarSystemID}
		{
			if ${CharName.NotEqual["EVE System"]}
			{
				call Sound.PlayTellSound
				UI:UpdateConsole["Channel Local: ${CharName.Escape}: ${MessageText.Escape}", LOG_CRITICAL]
			}
		}
	}

	member:bool IsSafe()
	{
		return ${This.SystemSafe}
	}

	member:bool CheckLocalWhiteList()
	{
		variable iterator PilotIterator
		variable int64 CorpID
		variable int64 AllianceID
		variable int64 PilotID
		variable string PilotName

		if !${Config.Combat.UseWhiteList}
		{
			return TRUE
		}

		if ${This.PilotIndex.Used} < 2
		{
			return TRUE
		}

		This.PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			CorpID:Set[${PilotIterator.Value.Corp.ID}]
			AllianceID:Set[${PilotIterator.Value.AllianceID}]
			PilotID:Set[${PilotIterator.Value.CharID}]
			PilotName:Set[${PilotIterator.Value.Name}]

			if !${This.AllianceWhiteList.Contains[${AllianceID}]} && \
				!${This.CorpWhiteList.Contains[${CorpID}]} && \
				!${This.PilotWhiteList.Contains[${PilotID}]} && \
				!${Me.Fleet.IsMember[${PilotID}]}
			{
				UI:UpdateConsole["Alert: Non-Whitelisted Pilot: ${PilotName}: CharID: ${PilotID} CorpID: ${CorpID} AllianceID: ${AllianceID}", LOG_CRITICAL]
				return FALSE
			}
		}
		while ${PilotIterator:Next(exists)}
		return TRUE
	}


	; Returns false if pilots with failed standing are in system
	member:bool CheckStanding()
	{
		variable iterator PilotIterator
		variable int64 CorpID
		variable int64 AllianceID
		variable int64 PilotID
		variable int MyAllianceID = 0
		variable float MeToPilot
		variable float MeToCorp
		variable float MeToAlliance
		variable float CorpToPilot
		variable float CorpToCorp
		variable float CorpToAlliance
		variable float AllianceToCorp
		variable float AllianceToAlliance

		if ${Config.Combat.LowestStanding} < -10
			return TRUE

		if ${This.PilotIndex.Used} < 2
		{
			return TRUE
		}

		if !${Me.AllianceID(exists)}
		{
			return TRUE
		}

		if ${Me.AllianceID} > 0
		{
			MyAllianceID:Set[${Me.AllianceID}]
		}

		This.PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			MeToPilot:Set[${PilotIterator.Value.Standing.MeToPilot}]
			MeToCorp:Set[${PilotIterator.Value.Standing.MeToCorp}]
			MeToAlliance:Set[${PilotIterator.Value.Standing.MeToAlliance}]
			CorpToPilot:Set[${PilotIterator.Value.Standing.CorpToPilot}]
			CorpToCorp:Set[${PilotIterator.Value.Standing.CorpToCorp}]
			CorpToAlliance:Set[${PilotIterator.Value.Standing.CorpToAlliance}]
			AllianceToCorp:Set[${PilotIterator.Value.Standing.AllianceToCorp}]
			AllianceToAlliance:Set[${PilotIterator.Value.Standing.AllianceToAlliance}]

			CorpID:Set[${PilotIterator.Value.Corp.ID}]
			AllianceID:Set[${PilotIterator.Value.AllianceID}]
			PilotID:Set[${PilotIterator.Value.CharID}]

			if !${PilotID.Equal[-1]} && \
				!${PilotID.Equal[${Me.CharID}]} && \
				(!${Me.Fleet(exists)} || !${Me.Fleet.IsMember[${PilotID}]}) && \
				!${MyAllianceID.Equal[${AllianceID}]} && \
				( \
					(${MeToPilot} != 0 && ${MeToPilot} < ${Config.Combat.LowestStanding}) || \
					(${MeToCorp} != 0 && ${MeToCorp} < ${Config.Combat.LowestStanding}) || \
					(${MeToAlliance} != 0 && ${MeToAlliance} < ${Config.Combat.LowestStanding}) || \
					(${CorpToPilot} != 0 && ${CorpToPilot} < ${Config.Combat.LowestStanding}) || \
					(${CorpToCorp} != 0 && ${CorpToCorp} < ${Config.Combat.LowestStanding}) || \
					(${CorpToAlliance} != 0 && ${CorpToAlliance} < ${Config.Combat.LowestStanding}) || \
					(${AllianceToCorp} != 0 && ${AllianceToCorp} < ${Config.Combat.LowestStanding}) || \
					(${AllianceToAlliance} < ${Config.Combat.LowestStanding}) || \
					( \
						${Config.Combat.IncludeNeutralInCalc} && \
						( \
							${AllianceToAlliance} < ${Config.Combat.LowestStanding} || \
							${AllianceToCorp} < ${Config.Combat.LowestStanding} || \
							${MeToPilot} < ${Config.Combat.LowestStanding} || \
							${MeToCorp} < ${Config.Combat.LowestStanding} || \
							${MeToAlliance} < ${Config.Combat.LowestStanding} || \
							${CorpToPilot} < ${Config.Combat.LowestStanding} || \
							${CorpToCorp} < ${Config.Combat.LowestStanding} || \
							${CorpToAlliance} < ${Config.Combat.LowestStanding} \
						) \
					) \
				)
			{
				UI:UpdateConsole["if !${PilotID.Equal[-1]} && ", LOG_DEBUG]
				UI:UpdateConsole["	!${PilotID.Equal[${Me.CharID}]} &&  ", LOG_DEBUG]
				UI:UpdateConsole["	(!${Me.Fleet(exists)} || !${Me.Fleet.IsMember[${PilotID}]}) &&  ", LOG_DEBUG]
				UI:UpdateConsole["	!${MyAllianceID.Equal[${AllianceID}]} &&  ", LOG_DEBUG]
				UI:UpdateConsole["	(  ", LOG_DEBUG]
				UI:UpdateConsole["		(${MeToPilot} != 0 && ${MeToPilot} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${MeToCorp} != 0 && ${MeToCorp} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${MeToAlliance} != 0 && ${MeToAlliance} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${CorpToPilot} != 0 && ${CorpToPilot} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${CorpToCorp} != 0 && ${CorpToCorp} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${CorpToAlliance} != 0 && ${CorpToAlliance} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${AllianceToCorp} != 0 && ${AllianceToCorp} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		(${AllianceToAlliance} < ${Config.Combat.LowestStanding}) ||  ", LOG_DEBUG]
				UI:UpdateConsole["		${Config.Combat.IncludeNeutralInCalc} && ", LOG_DEBUG]
				UI:UpdateConsole["		( ", LOG_DEBUG]
				UI:UpdateConsole["			${AllianceToAlliance} < ${Config.Combat.LowestStanding} || ", LOG_DEBUG]
				UI:UpdateConsole["			${AllianceToCorp} < ${Config.Combat.LowestStanding} ||  ", LOG_DEBUG]
				UI:UpdateConsole["			${MeToPilot} < ${Config.Combat.LowestStanding} ||  ", LOG_DEBUG]
				UI:UpdateConsole["			${MeToCorp} < ${Config.Combat.LowestStanding} ||  ", LOG_DEBUG]
				UI:UpdateConsole["			${MeToAlliance} < ${Config.Combat.LowestStanding} ||  ", LOG_DEBUG]
				UI:UpdateConsole["			${CorpToPilot} < ${Config.Combat.LowestStanding} ||  ", LOG_DEBUG]
				UI:UpdateConsole["			${CorpToCorp} < ${Config.Combat.LowestStanding} ||  ", LOG_DEBUG]
				UI:UpdateConsole["			${CorpToAlliance} < ${Config.Combat.LowestStanding}  ", LOG_DEBUG]
				UI:UpdateConsole["		) ", LOG_DEBUG]
				UI:UpdateConsole["	) ", LOG_DEBUG]
				UI:UpdateConsole["Alert: Low Standing Pilot: ${PilotIterator.Value.Name}: CharID: ${PilotID} CorpID: ${CorpID} AllianceID: ${AllianceID}", LOG_DEBUG]
				UI:UpdateConsole["Standings: ${MeToPilot} ${MeToCorp} ${MeToAlliance} ${CorpToPilot} ${CorpToCorp} ${CorpToAlliance} ${AllianceToCorp} ${AllianceToAlliance}", LOG_DEBUG]

				return FALSE
			}

		}
		while ${PilotIterator:Next(exists)}
		return TRUE
	}

	member:bool CheckLocalBlackList()
	{
		variable iterator PilotIterator

   		if !${Config.Combat.UseBlackList}
   		{
   			return TRUE
   		}

   		if ${This.PilotIndex.Used} < 2
   		{
   			return TRUE
   		}

		This.PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			if !${Me.Fleet.IsMember[${PilotID}]} && \
				${Me.CharID} != ${PilotIterator.Value.CharID} && \
				(	${This.PilotBlackList.Contains[${PilotIterator.Value.CharID}]} || \
					${This.AllianceBlackList.Contains[${PilotIterator.Value.AllianceID}]} || \
					${This.CorpBlackList.Contains[${PilotIterator.Value.Corp.ID}]} \
				)
			{
				UI:UpdateConsole["Alert: Blacklisted Pilot: ${PilotIterator.Value.Name}!", LOG_CRITICAL]
				return FALSE
			}
		}
		while ${PilotIterator:Next(exists)}
		return TRUE
	}

	member:bool PlayerInRange(float Range=0)
	{
		if ${Range} == 0
		{
			return FALSE
		}

   		if ${This.PilotIndex.Used} < 2
   		{
   			return FALSE
   		}

		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]

		if ${PilotIterator:First(exists)}
		{
			do
			{
				if 	${Me.CharID} != ${PilotIterator.Value.CharID} && \
					${PilotIterator.Value.ToEntity(exists)} && \
					${PilotIterator.Value.ToEntity.IsPC} && \
					${PilotIterator.Value.ToEntity.Distance} < ${Config.Miner.AvoidPlayerRange} && \
					!${PilotIterator.Value.ToFleetMember}
				{
					UI:UpdateConsole["PlayerInRange: ${PilotIterator.Value.Name} - ${EVEBot.MetersToKM_Str[${PilotIterator.Value.ToEntity.Distance}]"]
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}
		}
		return FALSE
	}

	member:bool NPCDetection()
	{
		if !${This.EntityIndex.Used}
		{
			return FALSE
		}

		variable iterator EntityIterator
		This.EntityIndex:GetIterator[EntityIterator]

		if ${EntityIterator:First(exists)}
		{
			do
			{
				if ${EntityIterator.Value.IsNPC}
				{
					return TRUE
				}
			}
			while ${EntityIterator:Next(exists)}
		}

		return FALSE
	}

	member:bool StandingDetection(int Standing)
	{
		return FALSE
		; TODO - this is broken, isxeve standing check doesn't work atm.

		echo ${This.PilotIndex.Used}

   		if ${This.PilotIndex.Used} < 2
   		{
   			return FALSE
   		}

		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]


		if ${PilotIterator:First(exists)}
		{
			do
			{
				echo ${PilotIterator.Value.Name} ${PilotIterator.Value.CharID} ${PilotIterator.Value.Corp.ID} ${PilotIterator.Value.AllianceID}
				echo ${Me.Standing[${PilotIterator.Value.CharID}]}
				echo ${Me.Standing[${PilotIterator.Value.Corp.ID}]}
				echo ${Me.Standing[${PilotIterator.Value.AllianceID}]}

				if ${Me.CharID} == ${PilotIterator.Value.CharID}
				{
					echo "StandingDetection: Ignoring Self"
					continue
				}

				if ${PilotIterator.Value.ToFleetMember(exists)}
				{
					echo "StandingDetection Ignoring Fleet Member: ${PilotIterator.Value.Name}"
					continue
				}

				/* Check Standing */
				echo Me -> Them ${EVE.Standing[${Me.CharID},${PilotIterator.Value.CharID}]}
				echo Corp -> Them ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.CharID}]}
				echo Alliance -> Them ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CharID}]}
				echo Me -> TheyCorp	${EVE.Standing[${Me.CharID},${PilotIterator.Value.Corp.ID}]}
				echo MeCorp -> TheyCorp	${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.Corp.ID}]}
				echo MeAlliance -> TheyCorp ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.Corp.ID}]}
				echo Me -> TheyAlliance ${EVE.Standing[${Me.CharID},${PilotIterator.Value.AllianceID}]}
				echo MeCorp -> TheyAlliance ${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.AllianceID}]}
				echo MeAlliance -> TheyAlliance ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.AllianceID}]}

				echo They -> Me	${EVE.Standing[${PilotIterator.Value.CharID},${Me.CharID}]}
				echo TheyCorp -> Me ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.CharID}]}
				echo TheyAlliance -> Me ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CharID}]}
				echo They -> MeCorp ${EVE.Standing[${PilotIterator.Value.CharID},${Me.Corp.ID}]}
				echo TheyCorp -> MeCorp ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.Corp.ID}]}
				echo TheyAlliance -> MeCorp ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.Corp.ID}]}
				echo They -> MeAlliance ${EVE.Standing[${PilotIterator.Value.CharID},${Me.AllianceID}]}
				echo TheyCorp -> MeAlliance ${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.AllianceID}]}
				echo TheyAlliance -> MeAlliance ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.AllianceID}]}

				if	${EVE.Standing[${Me.CharID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.CharID},${PilotIterator.Value.Corp.ID}]} < ${Standing} || \
					${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.Corp.ID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.Corp.ID}]} < ${Standing} || \
					${EVE.Standing[${Me.CharID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${Me.Corp.ID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${Me.Corp.ID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.Corp.ID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.Corp.ID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.Corp.ID},${Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.AllianceID}]} < ${Standing}
				{
					/* Yep, I'm laughing right now as well -- CyberTech */
					UI:UpdateConsole["obj_Social: StandingDetection in local: ${PilotIterator.Value.Name} - ${PilotIterator.Value.Standing}!", LOG_CRITICAL]
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}

		}

		return FALSE
	}

	member:bool PilotsWithinDetection(int Dist)
	{
   		if ${This.PilotIndex.Used} < 2
   		{
   			return FALSE
   		}

		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]

		if ${PilotIterator:First(exists)}
		{
			do
			{
				if (${Me.ShipID} != ${PilotIterator.Value.ID}) && \
					!${PilotIterator.Value.ToFleetMember} && \
					${PilotIterator.Value.Distance} < ${Dist}
				{
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}
		}

		return FALSE
	}

	member:bool PossibleHostiles()
	{
		if ${This.PilotIndex.Used} < 2
		{
			return FALSE
		}

		if ${Me.InStation}
		{
			return FALSE
		}
		variable bool bReturn = FALSE
		variable iterator PilotIterator
		variable float PilotSecurityStatus

		This.PilotIndex:GetIterator[PilotIterator]

		if ${PilotIterator:First(exists)}
		{
			do
			{
				if 	${Me.CharID} == ${PilotIterator.Value.CharID} || \
					!${PilotIterator.Value.ToEntity(exists)} || \
					${PilotIterator.Value.ToFleetMember(exists)}
				{
					continue
				}

				if ${PilotIterator.Value.ToEntity.IsTargetingMe}
				{
					UI:UpdateConsole["obj_Social: Hostile on grid: ${PilotIterator.Value.Name} is targeting me", LOG_CRITICAL]
					bReturn:Set[TRUE]
				}

				; Entity.Security returns -9999.00 if it fails, so we need to check for that
				PilotSecurityStatus:Set[${PilotIterator.Value.ToEntity.Security}]
				if ${PilotSecurityStatus} > -11.0 && \
					${PilotSecurityStatus} < ${Config.Miner.MinimumSecurityStatus}
				{
					UI:UpdateConsole["obj_Social: Possible hostile: ${PilotIterator.Value.Name} Sec Status: ${PilotSecurityStatus.Centi}", LOG_CRITICAL]
					bReturn:Set[TRUE]
				}
			}
			while ${PilotIterator:Next(exists)}
		}

		return ${bReturn}
	}
	
	method ProcessBreak()
	{
		if ${Config.Combat.TakeBreaks}
		{
			if ${NextBreak} == 0 && !${OnBreak}
			{
				NextBreak:Set[${Math.Calc[${Time.Timestamp} + ${Config.Combat.TimeBetweenBreaks} * 3600 - 1200 + ${Math.Rand[2400]}]}]
			}
			
			if ${NextBreak} <= ${Time.Timestamp} && !${OnBreak} && !${EVEBot.ReturnToStation}
			{
				UI:UpdateConsole["Taking a break!", LOG_CRITICAL]
				if ${Config.Combat.BroadcastBreaks}
				{
					relay all -event EVEBot_HARDSTOP
				}
				else
				{
					EVEBot.ReturnToStation:Set[TRUE]
				}
				OnBreak:Set[TRUE]
				NextBreak:Set[0]
			}
			
			if ${NextRestart} == 0 && ${OnBreak}
			{
				NextRestart:Set[${Math.Calc[${Time.Timestamp} + ${Config.Combat.BreakDuration} * 3600 - 1200 + ${Math.Rand[2400]}]}]
			}
			
			if ${NextRestart} <= ${Time.Timestamp} && ${OnBreak}
			{
				UI:UpdateConsole["Break over, back to work!", LOG_CRITICAL]
				if ${Config.Combat.BroadcastBreaks}
				{
					relay all -event EVEBot_ABORTHARDSTOP
				}
				else
				{
					EVEBot.ReturnToStation:Set[FALSE]
				}
				OnBreak:Set[FALSE]
				NextRestart:Set[0]
			}
		}
		
		CurrentTime:Set[${Time.Timestamp}]
		NextBreakTime:Set[${NextBreak}]
		RestartTime:Set[${NextRestart}]
		
	}

	
	;This method is triggered by an event.  If triggered, it tells us one of our fellow miners has entered the HARDSTOP state, and we should also run
	method TriggerHARDSTOP()
	{
		EVEBot.ReturnToStation:Set[TRUE]
	}
	;This method is triggered by an event.  If triggered, it tells us one of our fellow miners has entered the HARDSTOP state, and we should also run
	method AbortHARDSTOP()
	{
		EVEBot.ReturnToStation:Set[FALSE]
	}

}

