/*
This contains all stuff dealing with other players around us. - Hessinger

	Methods
		- GetPlayers(): Updates our Pilot Index (Currently updated on pulse, do not use elsewhere)

	Members
		- (bool) PlayerDetection(): Returns TRUE if a Player is near us. (Notes: Ignores Fleet Members)
		- (bool) PilotsWithinDectection(int Distance): Returns True if there are pilots within the distance passed to the member. (Notes: Only works for players)
		- (bool) StandingDetection(): Returns True if there are pilots below the standing passed to the member. (Notes: Only works for players)
		- (bool) PossibleHostiles(): Returns True if there are ships targeting us.
*/

objectdef obj_Social
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable set ClearedPilots
	variable set ReportedPilotsSinceLastSafe
	variable int LastSolarSystemID
	variable int LastStationID

	variable index:pilot PilotIndex

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	variable bool Passed_LowStandingCheck = TRUE
	variable bool Passed_PilotCheck = TRUE

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
		EVE:RefreshStandings

		Whitelist.PilotsRef:GetSettingIterator[This.WhiteListPilotIterator]
		Whitelist.CorporationsRef:GetSettingIterator[This.WhiteListCorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.WhiteListAllianceIterator]

		Blacklist.PilotsRef:GetSettingIterator[This.BlackListPilotIterator]
		Blacklist.CorporationsRef:GetSettingIterator[This.BlackListCorpIterator]
		Blacklist.AlliancesRef:GetSettingIterator[This.BlackListAllianceIterator]

		UI:UpdateConsole["obj_Social: Initializing whitelist...", LOG_MINOR]
		PilotWhiteList:Add[${Me.CharID}]
		if ${Me.CorporationID} > 0
		{
			This.CorpWhiteList:Add[${Me.CorporationID}]
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

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Event[EVE_OnChannelMessage]:AttachAtom[This:OnChannelMessage]
		This.NextPulse:Set[${Time.Timestamp}]
		This.NextPulse.Second:Inc[10]
		This.NextPulse:Update

		EVE:ActivateChannelMessageEvents

		UI:UpdateConsole["obj_Social: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		EVE:ActivateChannelMessageEvents
		Event[EVE_OnChannelMessage]:DetachAtom[This:OnChannelMessage]
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
			if ${EVEBot.SessionValid}
			{
				This:CheckChatInvitation[]

				if ${Me.SolarSystemID} != ${This.LastSolarSystemID}
				{
					This.ClearedPilots:Clear
					This.ClearedPilots:Add[${Me.CharID}]
					This.LastSolarSystemID:Set[${Me.SolarSystemID}]
				}

				/* Not sure why I added this, no reason to clear pilot list on station entry/exit
				if ${Me.StationID} != ${This.LastStationID}
				{
					This.ClearedPilots:Clear
					This.ClearedPilots:Add[${Me.CharID}]
					This.LastStationID:Set[${Me.StationID}]
				}
				*/

				; DoGetPilots is relatively expensive vs just the pilotcount.  Check if we're alone before calling.
				if ${EVE.GetPilots} > 1
				{
					variable int i
					i:Set[${EVE.GetPilots[This.PilotIndex]}]

					for (i:Set[1]; ${i} <= ${This.PilotIndex.Used}; i:Inc)
					{
						if ${Me.CharID} == ${This.PilotIndex[${i}]}
						{
							;UI:UpdateConsole["Social: StandingDetection: Ignoring Self", LOG_DEBUG]
							This.PilotIndex:Remove[${i}]
							continue
						}

						if ${This.PilotIndex[${i}].ToFleetMember(exists)}
						{
							;UI:UpdateConsole["Social: StandingDetection Ignoring Fleet Member: ${PilotIterator.Value.Name}", LOG_DEBUG]
							This.PilotIndex:Remove[${i}]
							continue
						}
					}
					This.PiloteIndex:Collapse

					Passed_LowStandingCheck:Set[!${This.LowStandingDetected}]
					Passed_PilotCheck:Set[${This.CheckLocalPilots}]
					if ${Passed_LowStandingCheck} && ${Passed_PilotCheck}
					{
						This.ReportedPilotsSinceLastSafe:Clear
					}
				}
				else
				{
					Passed_LowStandingCheck:Set[TRUE]
					Passed_PilotCheck:Set[TRUE]
					This.PilotIndex:Clear
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
				if ${Config.Common.EnableChatLogging}
				{
					UI:UpdateConsoleIRC["Channel Local: ${sAuthor.Escape}: ${sMessageText.Escape}"]
				}
				else
				{
					UI:UpdateConsole["Channel Local: ${sAuthor.Escape}: ${sMessageText.Escape}", LOG_MINOR]
				}
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
		variable bool is_safe = TRUE

		if !${Passed_LowStandingCheck}
		{
			is_safe:Set[FALSE]
		}

		if !${Passed_PilotCheck}
		{
			is_safe:Set[FALSE]
		}

		return ${is_safe}
	}

	; Returns TRUE if the Check passes and there are no non-whitelisted and no blacklisted pilots in local
	member:bool CheckLocalPilots()
	{
		variable iterator PilotIterator
		variable int CorpID
		variable int AllianceID
		variable int PilotID
		variable string PilotName
		variable bool Result
		Result:Set[TRUE]

		if ${This.PilotIndex.Used} < 2
		{
			return TRUE
		}

		if !${Config.Combat.UseWhiteList} && !${Config.Combat.UseBlackList}
		{
			This.ReportedPilotsSinceLastSafe:Clear
		}


		This.PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			PilotID:Set[${PilotIterator.Value}]
			if ${This.ClearedPilots.Contains[${PilotID}]}
			{
				continue
			}
			if ${This.ReportedPilotsSinceLastSafe.Contains[${PilotID}]}
			{
				; We already reported this pilot, since the last time the system was safe. We'll go ahead and
				; declare the system still not safe, and not re-report.
				;UI:UpdateConsole["Note: Previously Reported PilotID: ${PilotID}", LOG_DEBUG]
				Result:Set[FALSE]
				continue
			}

			CorpID:Set[${PilotIterator.Value.CorporationID}]
			AllianceID:Set[${PilotIterator.Value.AllianceID}]
			PilotName:Set[${PilotIterator.Value.Name}]

			/*
				The whitelist OVERRIDES the blacklist, at all times.
				_IF_ UseWhiteList is checked, then pilots who are not whitelisted are implicitly blacklisted
			*/
			if ${This.CorpWhiteList.Contains[${CorpID}]} || \
				${This.AllianceWhiteList.Contains[${AllianceID}]} || \
				${This.PilotWhiteList.Contains[${PilotID}]}
			{
				UI:UpdateConsole["Note: Whitelisted Pilot: ${PilotName} ID: ${PilotID} CorpID: ${CorpID} AllianceID: ${AllianceID}", LOG_DEBUG]
			}
			elseif ${Config.Combat.UseBlackList}
			{
				if ${This.AllianceBlackList.Contains[${AllianceID}]}
				{
					UI:UpdateConsole["Alert: Blacklisted Alliance: Pilot: ${PilotName} AllianceID: ${AllianceID}", LOG_CRITICAL]
					Result:Set[FALSE]
					This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
				}
				if ${This.CorpBlackList.Contains[${CorpID}]}
				{
					UI:UpdateConsole["Alert: Blacklisted Corporation: Pilot: ${PilotName} CorpID: ${CorpID}", LOG_CRITICAL]
					Result:Set[FALSE]
					This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
				}
				if ${This.PilotBlackList.Contains[${PilotID}]}
				{
					UI:UpdateConsole["Alert: Blacklisted Pilot: ${PilotName}", LOG_CRITICAL]
					Result:Set[FALSE]
					This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
				}
			}
			elseif ${Config.Combat.UseWhiteList}
			{
				UI:UpdateConsole["Alert: Non-Whitelisted Pilot: ${PilotName} ID: ${PilotID} CorpID: ${CorpID} AllianceID: ${AllianceID}", LOG_CRITICAL]
				Result:Set[FALSE]
				This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
			}

			if ${Result}
			{
				; Result is still true, so the pilot has passed whitelist and blacklist checks
				This.ClearedPilots:Add[${PilotID}]
			}
		}
		while ${PilotIterator:Next(exists)}
		return ${Result}
	}

	member:bool PlayerInRange(float Range=0)
	{
		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]

		if ${PilotIterator:First(exists)}
		{
			do
			{
				if 	${PilotIterator.Value.ToEntity(exists)} && \
					${PilotIterator.Value.ToEntity.Distance} <= ${Config.Miner.AvoidPlayerRange}
				{
					UI:UpdateConsole["PlayerInRange: ${PilotIterator.Value.Name} (${EVEBot.MetersToKM_Str[${PilotIterator.Value.ToEntity.Distance}])"]
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}
		}
		return FALSE
	}

	member:bool LowStandingDetected()
	{
		variable bool HostilesPresent

		if !${Config.Defense.DetectLowStanding}
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
				;echo "DEBUG: ${PilotIterator.Value.Name} ID: ${PilotIterator.Value.CharID} CorpID: ${PilotIterator.Value.CorporationID} Corp: ${PilotIterator.Value.Corporation} AllianceID: ${PilotIterator.Value.AllianceID} Alliance: ${PilotIterator.Value.Alliance}"
				;echo "  DEBUG: ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToAlliance} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToCorp} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToPilot} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].MeToCorp} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].MeToPilot} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].AllianceToAlliance}"
				;echo "  DEBUG: ${PilotIterator.Value.Standing.CorpToAlliance} ${PilotIterator.Value.Standing.CorpToCorp} ${PilotIterator.Value.Standing.CorpToPilot} ${PilotIterator.Value.Standing.MeToCorp} ${PilotIterator.Value.Standing.MeToPilot} ${PilotIterator.Value.Standing.AllianceToAlliance}"

				if (${PilotIterator.Value.Standing.AllianceToAlliance} < ${Config.Defense.MinimumAllianceStanding} || \
					${PilotIterator.Value.Standing.CorpToAlliance} < ${Config.Defense.MinimumAllianceStanding})
				{
					UI:UpdateConsole["Social: Pilot Alliance Below Standing Threshold: ${PilotIterator.Value.Name} CorpID: ${PilotIterator.Value.CorporationID} AllianceID: ${PilotIterator.Value.AllianceID}", LOG_CRITICAL]
					HostilesPresent:Set[TRUE]
				}
				if (${PilotIterator.Value.Standing.CorpToCorp} < ${Config.Defense.MinimumCorpStanding} || \
					${PilotIterator.Value.Standing.MeToCorp} < ${Config.Defense.MinimumCorpStanding})
				{
					UI:UpdateConsole["Social: Pilot Corp Below Standing Threshold: ${PilotIterator.Value.Name} CorpID: ${PilotIterator.Value.CorporationID} AllianceID: ${PilotIterator.Value.AllianceID}", LOG_CRITICAL]
					HostilesPresent:Set[TRUE]
				}
				if (${PilotIterator.Value.Standing.CorpToPilot} < ${Config.Defense.MinimumPilotStanding} || \
					${PilotIterator.Value.Standing.MeToPilot} < ${Config.Defense.MinimumPilotStanding})
				{
					UI:UpdateConsole["Social: Pilot Below Standing Threshold: ${PilotIterator.Value.Name} CorpID: ${PilotIterator.Value.CorporationID} Alliance: ${PilotIterator.Value.AllianceID}", LOG_CRITICAL]
					HostilesPresent:Set[TRUE]
				}
			}
			while ${PilotIterator:Next(exists)}
		}

		return ${HostilesPresent}
	}
}

