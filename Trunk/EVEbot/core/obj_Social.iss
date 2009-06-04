/*
This contains all stuff dealing with other players around us. - Hessinger

	Methods
		- GetPlayers(): Updates our Pilot Index (Currently updated on pulse, do not use elsewhere)

	Members
		- (bool) PlayerDetection(): Returns TRUE if a Player is near us. (Notes: Ignores Fleet Members)
		- (bool) NPCDetection(): Returns TRUE if an NPC is near us.
		- (bool) PilotsWithinDectection(int Distance): Returns True if there are pilots within the distance passed to the member. (Notes: Only works for players)
		- (bool) StandingDetection(): Returns True if there are pilots below the standing passed to the member. (Notes: Only works for players)
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
	variable int PulseIntervalInSeconds = 2

	variable bool Passed_LowStandingCheck = TRUE
	variable bool Passed_WhiteListCheck = TRUE
	variable bool Passed_BlackListCheck = TRUE

	variable iterator WhiteListPilotIterator
	variable iterator WhiteListCorpIterator
	variable iterator WhiteListAllianceIterator
	variable iterator BlackListPilotIterator
	variable iterator BlackListCorpIterator
	variable iterator BlackListAllianceIterator

	variable set PilotBlackList
	variable set CorpBlackList
	variable set AllianceBlackList
	variable set PilotWhiteList
	variable set CorpWhiteList
	variable set AllianceWhiteList

	method Initialize()
	{
		Whitelist.PilotsRef:GetSettingIterator[This.WhiteListPilotIterator]
		Whitelist.CorporationsRef:GetSettingIterator[This.WhiteListCorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.WhiteListAllianceIterator]

		Blacklist.PilotsRef:GetSettingIterator[This.BlackListPilotIterator]
		Blacklist.CorporationsRef:GetSettingIterator[This.BlackListCorpIterator]
		Blacklist.AlliancesRef:GetSettingIterator[This.BlackListAllianceIterator]

		UI:UpdateConsole["obj_Social: Initializing whitelist...", LOG_MINOR]
		PilotWhiteList:Add[${_Me.CharID}]
		if ${_Me.CorporationID} > 0
		{
			This.CorpWhiteList:Add[${_Me.CorporationID}]
		}
		if ${_Me.AllianceID} > 0
		{
			This.AllianceWhiteList:Add[${_Me.AllianceID}]
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

		Event[OnFrame]:AttachAtom[This:Pulse]
		Event[EVE_OnChannelMessage]:AttachAtom[This:OnChannelMessage]
		EVE:ActivateChannelMessageEvents

		UI:UpdateConsole["obj_Social: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		EVE:ActivateChannelMessageEvents
		Event[EVE_OnChannelMessage]:DetachAtom[This:OnChannelMessage]
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
			if ${EVEBot.SessionValid}
			{
				This:CheckChatInvitation[]

				if ${EVE.GetPilots} > 1
				{
					; DoGetPilots is relatively expensive vs just the pilotcount.  Check if we're alone before calling.
					EVE:DoGetPilots[This.PilotIndex]
					if ${Config.Defense.DetectLowStanding}
					{
						Passed_LowStandingCheck:Set[!${This.LowStandingDetected}]
					}
				}
				else
				{
					This.PilotIndex:Clear
				}

				if (${Config.Combat.UseBlackList} && ( ${PilotBlackList.Used} > 1 || ${CorpBlackList.Used} > 1 || ${AllianceBlackList.Used} > 1)) || \
					(${Config.Combat.UseWhiteList} && ( ${PilotWhiteList.Used} > 2 || ${CorpWhiteList.Used} > 2 || ${AllianceWhiteList.Used} > 2))
				{
					if ${Me.InSpace}
					{
						EVE:DoGetEntities[This.EntityIndex,CategoryID,CATEGORYID_ENTITY]
					}
					else
					{
						This.EntityIndex:Clear
					}

    				Passed_WhiteListCheck:Set[${This.CheckLocalWhiteList}]
    				Passed_BlackListCheck:Set[${This.CheckLocalBlackList}]
    			}
    			else
    			{
    				Passed_WhiteListCheck:Set[TRUE]
    				Passed_BlackListCheck:Set[TRUE]
    			}
			}

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

	method OnChannelMessage(int64 iTimeStamp, string sDate, string sTime, string sChannel, string sAuthor, int iAuthorID, string sMessageText)
	{
		if ${sChannel.Equal["Local"]}
		{
			if ${sAuthor.NotEqual["EVE System"]}
			{
				Sound:PlayTellSound
				UI:UpdateConsole["Channel Local: ${sAuthor.Escape}: ${sMessageText.Escape}", LOG_CRITICAL]
			}
		}
	}

	method CheckChatInvitation()
	{
		if ${EVEWindow[ByCaption, "Chat Invite"](exists)}
		{
			Sound:PlayTellSound
			UI:UpdateConsole["Notice: ${EVEWindow[ByCaption, Chat Invite].Name}", LOG_CRITICAL]
		}
	}

	member:bool IsSafe()
	{
		if !${Passed_LowStandingCheck}
		{
			return FALSE
		}
		if !${Passed_WhiteListCheck}
		{
			return FALSE
		}
		if !${Passed_BlackListCheck}
		{
			return FALSE
		}
		return TRUE
	}

	; Returns TRUE if the Check passes and there are no non-whitelisted pilots in local
	member:bool CheckLocalWhiteList()
	{
		variable iterator PilotIterator
		variable int CorpID
		variable int AllianceID
		variable int PilotID
		variable string PilotName
		variable bool Result

		Result:Set[TRUE]

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
			CorpID:Set[${PilotIterator.Value.CorporationID}]
			AllianceID:Set[${PilotIterator.Value.AllianceID}]
			PilotID:Set[${PilotIterator.Value.CharID}]
			PilotName:Set[${PilotIterator.Value.Name}]

			if !${This.AllianceWhiteList.Contains[${AllianceID}]} && \
				!${This.CorpWhiteList.Contains[${CorpID}]} && \
				!${This.PilotWhiteList.Contains[${PilotID}]}
			{
				if ${PilotIterator.Value.Alliance(exists)}
				{
					UI:UpdateConsole["Alert: Non-Whitelisted Pilot: ${PilotName} (${PilotID}) ${PilotIterator.Value.Corporation} (${CorpID}) ${PilotIterator.Value.Alliance} (${AllianceID})", LOG_CRITICAL]
				}
				else
				{
					UI:UpdateConsole["Alert: Non-Whitelisted Pilot: ${PilotName} (${PilotID}) ${PilotIterator.Value.Corporation} (${CorpID})", LOG_CRITICAL]
				}
				Result:Set[FALSE]
			}
		}
		while ${PilotIterator:Next(exists)}
		return ${Result}
	}

	; Returns TRUE if the Check passes and there are no blacklisted pilots in local
	member:bool CheckLocalBlackList()
	{
		variable iterator PilotIterator
		variable bool Result

		Result:Set[TRUE]

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
			if ${This.AllianceBlackList.Contains[${PilotIterator.Value.AllianceID}]}
			{
				UI:UpdateConsole["Alert: Blacklisted Alliance: Pilot: ${PilotIterator.Value.Name} Alliance: ${PilotIterator.Value.Alliance}", LOG_CRITICAL]
				Result:Set[FALSE]
			}
			if ${This.CorpBlackList.Contains[${PilotIterator.Value.CorporationID}]}
			{
				UI:UpdateConsole["Alert: Blacklisted Corporation: Pilot: ${PilotIterator.Value.Name} Corp: ${PilotIterator.Value.Corporation}", LOG_CRITICAL]
				Result:Set[FALSE]
			}
			if ${This.PilotBlackList.Contains[${PilotIterator.Value.CharID}]}
			{
				UI:UpdateConsole["Alert: Blacklisted Pilot: ${PilotIterator.Value.Name}!", LOG_CRITICAL]
				Result:Set[FALSE]
			}
		}
		while ${PilotIterator:Next(exists)}
		return ${Result}
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
				if 	${_Me.CharID} != ${PilotIterator.Value.CharID} && \
					${PilotIterator.Value.ToEntity(exists)} && \
					${PilotIterator.Value.ToEntity.IsPC} && \
					${PilotIterator.Value.ToEntity.Distance} < ${Config.Miner.AvoidPlayerRange} && \
					!${PilotIterator.Value.ToFleetMember}
				{
					UI:UpdateConsole["PlayerInRange: ${PilotIterator.Value.Name} (${EVEBot.MetersToKM_Str[${PilotIterator.Value.ToEntity.Distance}])"]
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

	member:bool LowStandingDetected()
	{
		variable bool HostilesPresent

   		if ${This.PilotIndex.Used} < 2
   		{
   			return FALSE
   		}

		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]

		HostilesPresent:Set[FALSE]
		if ${PilotIterator:First(exists)}
		{
			do
			{
				;echo "DEBUG: ${PilotIterator.Value.Name} ${PilotIterator.Value.CharID} ${PilotIterator.Value.CorporationID} ${PilotIterator.Value.Corporation} ${PilotIterator.Value.AllianceID} ${PilotIterator.Value.Alliance}"

				if ${_Me.CharID} == ${PilotIterator.Value.CharID}
				{
					;UI:UpdateConsole["Social: StandingDetection: Ignoring Self", LOG_DEBUG]
					continue
				}

				if ${PilotIterator.Value.ToFleetMember(exists)}
				{
					;UI:UpdateConsole["Social: StandingDetection Ignoring Fleet Member: ${PilotIterator.Value.Name}", LOG_DEBUG]
					continue
				}

				;echo "  DEBUG: ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToAlliance} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToCorp} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToPilot} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].MeToCorp} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].MeToPilot} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].AllianceToAlliance}"
				;echo "  DEBUG: ${PilotIterator.Value.Standing.CorpToAlliance} ${PilotIterator.Value.Standing.CorpToCorp} ${PilotIterator.Value.Standing.CorpToPilot} ${PilotIterator.Value.Standing.MeToCorp} ${PilotIterator.Value.Standing.MeToPilot} ${PilotIterator.Value.Standing.AllianceToAlliance}"
				if (${PilotIterator.Value.Standing.AllianceToAlliance} < ${Config.Defense.MinimumAllianceStanding} || \
					${PilotIterator.Value.Standing.CorpToAlliance} < ${Config.Defense.MinimumAllianceStanding})
				{
					UI:UpdateConsole["Social: Pilot Alliance Below Standing Threshold: ${PilotIterator.Value.Name} ${PilotIterator.Value.Corporation} Alliance: ${PilotIterator.Value.Alliance}", LOG_CRITICAL]
					HostilesPresent:Set[TRUE]
				}
				if (${PilotIterator.Value.Standing.CorpToCorp} < ${Config.Defense.MinimumCorpStanding} || \
					${PilotIterator.Value.Standing.MeToCorp} < ${Config.Defense.MinimumCorpStanding})
				{
					UI:UpdateConsole["Social: Pilot Corp Below Standing Threshold: ${PilotIterator.Value.Name} ${PilotIterator.Value.Corporation} Alliance: ${PilotIterator.Value.Alliance}", LOG_CRITICAL]
					HostilesPresent:Set[TRUE]
				}
				if (${PilotIterator.Value.Standing.CorpToPilot} < ${Config.Defense.MinimumPilotStanding} || \
					${PilotIterator.Value.Standing.MeToPilot} < ${Config.Defense.MinimumPilotStanding})
				{
					UI:UpdateConsole["Social: Pilot Below Standing Threshold: ${PilotIterator.Value.Name} ${PilotIterator.Value.Corporation} Alliance: ${PilotIterator.Value.Alliance}", LOG_CRITICAL]
					HostilesPresent:Set[TRUE]
				}
			}
			while ${PilotIterator:Next(exists)}
		}

		return ${HostilesPresent}
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
				if (${_Me.ShipID} != ${PilotIterator.Value}) && \
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
		variable iterator EntityIterator
		This.EntityIndex:GetIterator[EntityIterator]

		if ${EntityIterator:First(exists)}
		{
			do
			{
				if ${EntityIterator.Value.IsTargetingMe}
				{
					return TRUE
				}
			}
			while ${EntityIterator:Next(exists)}
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
				if ${PilotIterator.Value.IsTargetingMe}
				{
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}
		}

		return FALSE
	}

}

