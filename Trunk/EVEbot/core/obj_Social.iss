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
			This.AllianceWhiteList:Add[${_Me.CorporationID}]
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

		SystemSafe:Set[TRUE]

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
			EVE:DoGetPilots[This.PilotIndex]

			if !${_Me.InStation}
			{
				EVE:DoGetEntities[This.EntityIndex,CategoryID,CATEGORYID_ENTITY]
			}

    		SystemSafe:Set[${Math.Calc[${This.CheckLocalWhiteList} & ${This.CheckLocalBlackList}](bool)}]

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
				call Sound.PlayTellSound
				UI:UpdateConsole["Channel Local: ${sAuthor.Escape}: ${sMessageText.Escape}", LOG_CRITICAL]
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

		if !${Config.Combat.UseWhiteList}
		{
			return TRUE
		}

		if ${This.PilotIndex.Used} == 1
		{
			return TRUE
		}

		This.PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			if !${This.AllianceWhiteList.Contains[${PilotIterator.Value.AllianceID}]} && \
				!${This.CorpWhiteList.Contains[${PilotIterator.Value.CorporationID}]} && \
				!${This.PilotWhiteList.Contains[${PilotIterator.Value.CharID}]}
			{
				UI:UpdateConsole["Alert: Non-Whitelisted Pilot: ${PilotIterator.Value.Name}: CharID: ${PilotIterator.Value.CharID} CorpID: ${PilotIterator.Value.CorporationID} AllianceID: ${PilotIterator.Value.AllianceID}", LOG_CRITICAL]
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

   		if ${This.PilotIndex.Used} == 1
   		{
   			return TRUE
   		}

		This.PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			if ${This.PilotBlackList.Contains[${PilotIterator.Value.CharID}]} || \
				${This.AllianceBlackList.Contains[${PilotIterator.Value.AllianceID}]} || \
				${This.CorpBlackList.Contains[${PilotIterator.Value.CorporationID}]}
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
		if !${This.PilotIndex.Used}
		{
			return FALSE
		}

		if ${Range} == 0
		{
			return FALSE
		}

   		if ${This.PilotIndex.Used} == 1
   		{
   			return TRUE
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

   		if ${This.PilotIndex.Used} == 1
   		{
   			return FALSE
   		}

		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]


		if ${PilotIterator:First(exists)}
		{
			do
			{
				echo ${PilotIterator.Value.Name} ${PilotIterator.Value.CharID} ${PilotIterator.Value.CorporationID} ${PilotIterator.Value.AllianceID}
				echo ${Me.Standing[${PilotIterator.Value.CharID}]}
				echo ${Me.Standing[${PilotIterator.Value.CorporationID}]}
				echo ${Me.Standing[${PilotIterator.Value.AllianceID}]}

				if ${_Me.CharID} == ${PilotIterator.Value.CharID}
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
				echo Me -> Them ${EVE.Standing[${_Me.CharID},${PilotIterator.Value.CharID}]}
				echo Corp -> Them ${EVE.Standing[${_Me.CorporationID},${PilotIterator.Value.CharID}]}
				echo Alliance -> Them ${EVE.Standing[${_Me.AllianceID},${PilotIterator.Value.CharID}]}
				echo Me -> TheyCorp	${EVE.Standing[${_Me.CharID},${PilotIterator.Value.CorporationID}]}
				echo MeCorp -> TheyCorp	${EVE.Standing[${_Me.CorporationID},${PilotIterator.Value.CorporationID}]}
				echo MeAlliance -> TheyCorp ${EVE.Standing[${_Me.AllianceID},${PilotIterator.Value.CorporationID}]}
				echo Me -> TheyAlliance ${EVE.Standing[${_Me.CharID},${PilotIterator.Value.AllianceID}]}
				echo MeCorp -> TheyAlliance ${EVE.Standing[${_Me.CorporationID},${PilotIterator.Value.AllianceID}]}
				echo MeAlliance -> TheyAlliance ${EVE.Standing[${_Me.AllianceID},${PilotIterator.Value.AllianceID}]}

				echo They -> Me	${EVE.Standing[${PilotIterator.Value.CharID},${_Me.CharID}]}
				echo TheyCorp -> Me ${EVE.Standing[${PilotIterator.Value.CorporationID},${_Me.CharID}]}
				echo TheyAlliance -> Me ${EVE.Standing[${PilotIterator.Value.AllianceID},${_Me.CharID}]}
				echo They -> MeCorp ${EVE.Standing[${PilotIterator.Value.CharID},${_Me.CorporationID}]}
				echo TheyCorp -> MeCorp ${EVE.Standing[${PilotIterator.Value.CorporationID},${_Me.CorporationID}]}
				echo TheyAlliance -> MeCorp ${EVE.Standing[${PilotIterator.Value.AllianceID},${_Me.CorporationID}]}
				echo They -> MeAlliance ${EVE.Standing[${PilotIterator.Value.CharID},${_Me.AllianceID}]}
				echo TheyCorp -> MeAlliance ${EVE.Standing[${PilotIterator.Value.CorporationID},${_Me.AllianceID}]}
				echo TheyAlliance -> MeAlliance ${EVE.Standing[${PilotIterator.Value.AllianceID},${_Me.AllianceID}]}

				if	${EVE.Standing[${_Me.CharID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${_Me.CorporationID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${_Me.AllianceID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${_Me.CharID},${PilotIterator.Value.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${_Me.CorporationID},${PilotIterator.Value.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${_Me.AllianceID},${PilotIterator.Value.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${_Me.CharID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${_Me.CorporationID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${_Me.AllianceID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${_Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CorporationID},${_Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${_Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${_Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CorporationID},${_Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${_Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${_Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CorporationID},${_Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${_Me.AllianceID}]} < ${Standing}
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
   		if ${This.PilotIndex.Used} == 1
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

		if ${This.PilotIndex.Used} == 1
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

