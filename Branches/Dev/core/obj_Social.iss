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

objectdef obj_Social inherits obj_BaseClass
{
	variable set ClearedPilots
	variable set ClearedPilotsStanding
	variable set ReportedPilotsSinceLastSafe
	variable int LastSolarSystemID
	variable int LastStationID

	variable index:pilot PilotIndex

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
		LogPrefix:Set["${This.ObjectName}"]

		EVE:RefreshStandings

		Whitelist.PilotsRef:GetSettingIterator[This.WhiteListPilotIterator]
		Whitelist.CorporationsRef:GetSettingIterator[This.WhiteListCorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.WhiteListAllianceIterator]

		Blacklist.PilotsRef:GetSettingIterator[This.BlackListPilotIterator]
		Blacklist.CorporationsRef:GetSettingIterator[This.BlackListCorpIterator]
		Blacklist.AlliancesRef:GetSettingIterator[This.BlackListAllianceIterator]

		Logger:Log["${LogPrefix}: Initializing whitelist...", LOG_MINOR]
		PilotWhiteList:Add[${EVEBot.CharID}]
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

		Logger:Log["${LogPrefix}: Initializing blacklist...", LOG_MINOR]
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

		PulseTimer:SetIntervals[2.0,2.5]
		PulseTimer:Increase[2.0]

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Event[EVE_OnChannelMessage]:AttachAtom[This:OnChannelMessage]

		;EVE:ActivateChannelMessageEvents

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		;EVE:ActivateChannelMessageEvents
		Event[EVE_OnChannelMessage]:DetachAtom[This:OnChannelMessage]
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if !${EVEBot.Loaded} || ${EVEBot.Disabled}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			if ${EVEBot.SessionValid}
			{
				This:CheckChatInvitation[]

				if ${Me.SolarSystemID} != ${This.LastSolarSystemID}
				{
					; TODO - I need to clear this when blacklist or whitelist are updated during bot operation, if that is ever possible.
					This.ClearedPilots:Clear
					This.ClearedPilots:Add[${EVEBot.CharID}]

					; TODO - I should find a way to reset this if we find out that standings have updated (events?)
					This.ClearedPilotsStanding:Clear
					This.ClearedPilotsStanding:Add[${EVEBot.CharID}]

					This.LastSolarSystemID:Set[${Me.SolarSystemID}]
				}

				/* Not sure why I added this, no reason to clear pilot list on station entry/exit
				if ${Me.StationID} != ${This.LastStationID}
				{
					This.ClearedPilots:Clear
					This.ClearedPilots:Add[${EVEBot.CharID}]
					This.LastStationID:Set[${Me.StationID}]
				}
				*/

				EVE:GetLocalPilots[This.PilotIndex]
				if ${This.PilotIndex.Used} > 1
				{
					variable int i
					variable int FleetID
					FleetID:Set[${Me.Fleet.ID}]

					for (i:Set[1]; ${i} <= ${This.PilotIndex.Used}; i:Inc)
					{
						if ${EVEBot.CharID} == ${This.PilotIndex[${i}]}
						{
							;Logger:Log["Social: StandingDetection: Ignoring Self", LOG_DEBUG]
							This.PilotIndex:Remove[${i}]
							continue
						}

						if ${FleetID} > 0 && ${This.PilotIndex[${i}].ToFleetMember(exists)}
						{
							;Logger:Log["Social: StandingDetection Ignoring Fleet Member: ${PilotIterator.Value.Name}", LOG_DEBUG]
							This.PilotIndex:Remove[${i}]
							continue
						}
					}
					This.PilotIndex:Collapse

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

			This.PulseTimer:Update
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
					Logger:LogIRC["Channel Local: ${sAuthor.Escape}: ${sMessageText.Escape}"]
				}
				else
				{
					Logger:Log["Channel Local: ${sAuthor.Escape}: ${sMessageText.Escape}", LOG_MINOR]
				}
			}
		}
	}

	method CheckChatInvitation()
	{
		if ${EVEWindow[ByCaption, "Chat Invite"](exists)}
		{
			Sound:PlayTellSound
			Logger:Log["Notice: ${EVEWindow[ByCaption, Chat Invite].Name}", LOG_CRITICAL]
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
				;Logger:Log["Note: Previously Reported PilotID: ${PilotID}", LOG_DEBUG]
				Result:Set[FALSE]
				continue
			}

			CorpID:Set[${PilotIterator.Value.Corp.ID}]
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
				Logger:Log["Note: Whitelisted Pilot: ${PilotName} ID: ${PilotID} CorpID: ${CorpID} AllianceID: ${AllianceID}", LOG_DEBUG]
			}
			elseif ${Config.Combat.UseBlackList}
			{
				if ${This.AllianceBlackList.Contains[${AllianceID}]}
				{
					Logger:Log["Alert: Blacklisted Alliance: Pilot: ${PilotName} AllianceID: ${AllianceID}", LOG_CRITICAL]
					Result:Set[FALSE]
					This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
				}
				if ${This.CorpBlackList.Contains[${CorpID}]}
				{
					Logger:Log["Alert: Blacklisted Corporation: Pilot: ${PilotName} CorpID: ${CorpID}", LOG_CRITICAL]
					Result:Set[FALSE]
					This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
				}
				if ${This.PilotBlackList.Contains[${PilotID}]}
				{
					Logger:Log["Alert: Blacklisted Pilot: ${PilotName}", LOG_CRITICAL]
					Result:Set[FALSE]
					This.ReportedPilotsSinceLastSafe:Add[${PilotID}]
				}
			}
			elseif ${Config.Combat.UseWhiteList}
			{
				Logger:Log["Alert: Non-Whitelisted Pilot: ${PilotName} ID: ${PilotID} CorpID: ${CorpID} AllianceID: ${AllianceID}", LOG_CRITICAL]
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
					Logger:Log["PlayerInRange: ${PilotIterator.Value.Name} (${EVEBot.MetersToKM_Str[${PilotIterator.Value.ToEntity.Distance}])"]
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}
		}
		return FALSE
	}

	member:int LowStandingDetected()
	{
		variable int HostilesPresent
		variable bool HostilePilot
		variable string LogMsg

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
				;echo "DEBUG: ${PilotIterator.Value.Name} ID: ${PilotIterator.Value.CharID} CorpID: ${PilotIterator.Value.Corp.ID} Corp: ${PilotIterator.Value.Corporation} AllianceID: ${PilotIterator.Value.AllianceID} Alliance: ${PilotIterator.Value.Alliance}"
				;echo "  DEBUG: ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.Corp.ID},${PilotIterator.Value.AllianceID}].CorpToAlliance} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToCorp} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].CorpToPilot} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].MeToCorp} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].MeToPilot} ${Me.StandingTo[${PilotIterator.Value.CharID},${PilotIterator.Value.CorporationID},${PilotIterator.Value.AllianceID}].AllianceToAlliance}"
				;echo "  DEBUG: ${PilotIterator.Value.Standing.CorpToAlliance} ${PilotIterator.Value.Standing.CorpToCorp} ${PilotIterator.Value.Standing.CorpToPilot} ${PilotIterator.Value.Standing.MeToCorp} ${PilotIterator.Value.Standing.MeToPilot} ${PilotIterator.Value.Standing.AllianceToAlliance}"

				if ${This.ClearedPilotsStanding.Contains[${PilotIterator.Value}]}
				{
					continue
				}

				if ${This.ReportedPilotsSinceLastSafe.Contains[${PilotID}]}
				{
					; We already reported this pilot, since the last time the system was safe. We'll go ahead and
					; declare the system still not safe, and not re-report.
					;Logger:Log["Note: Previously Reported PilotID: ${PilotID}", LOG_DEBUG]
					Result:Set[FALSE]
					continue
				}
				LogMsg:Set["Social: "]
				if (${PilotIterator.Value.Standing.AllianceToAlliance} < ${Config.Defense.MinimumAllianceStanding} || \
					${PilotIterator.Value.Standing.CorpToAlliance} < ${Config.Defense.MinimumAllianceStanding})
				{
					LogMsg:Concat[" Alliance"]
					HostilePilot:Set[TRUE]
				}
				if (${PilotIterator.Value.Standing.CorpToCorp} < ${Config.Defense.MinimumCorpStanding} || \
					${PilotIterator.Value.Standing.MeToCorp} < ${Config.Defense.MinimumCorpStanding})
				{
					LogMsg:Concat[" Corp"]
					HostilePilot:Set[TRUE]
				}
				if (${PilotIterator.Value.Standing.CorpToPilot} < ${Config.Defense.MinimumPilotStanding} || \
					${PilotIterator.Value.Standing.MeToPilot} < ${Config.Defense.MinimumPilotStanding})
				{
					LogMsg:Concat[" Pilot"]
					HostilePilot:Set[TRUE]
				}

				if ${HostilePilot}
				{
					LogMsg:Concat[" Below Standing Threshold: ${PilotIterator.Value.Name} CorpID: ${PilotIterator.Value.Corp.ID} AllianceID: ${PilotIterator.Value.AllianceID}"]
					Logger:Log[${LogMsg}, LOG_CRITICAL]
					HostilesPresent:Inc
					This.ReportedPilotsSinceLastSafe:Add[${PilotIterator.Value}]
				}
				else
				{
					This.ClearedPilotsStanding:Add[${PilotIterator.Value}]
				}
			}
			while ${PilotIterator:Next(exists)}
		}

		return ${HostilesPresent}
	}
}

