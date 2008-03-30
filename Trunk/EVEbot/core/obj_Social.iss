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
	;Variables 
	variable index:pilot PilotIndex
	variable index:entity EntityIndex

	variable time NextPulse
	variable int PulseIntervalInSeconds = 5

	variable iterator WhiteListPilotIterator	
	variable iterator WhiteListCorpIterator	
	variable iterator WhiteListAllianceIterator	
	variable iterator BlackListPilotIterator	
	variable iterator BlackListCorpIterator	
	variable iterator BlackListAllianceIterator	
	variable bool SystemSafe	
	
	method Initialize()
	{
		Whitelist.PilotsRef:GetSettingIterator[This.WhiteListPilotIterator]
		Whitelist.CorporationsRef:GetSettingIterator[This.WhiteListCorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.WhiteListAllianceIterator]

		Blacklist.PilotsRef:GetSettingIterator[This.BlackListPilotIterator]
		Blacklist.CorporationsRef:GetSettingIterator[This.BlackListCorpIterator]
		Blacklist.AlliancesRef:GetSettingIterator[This.BlackListAllianceIterator]

		SystemSafe:Set[TRUE]
		
		Event[OnFrame]:AttachAtom[This:Pulse]
		
		Event[EVE_OnChannelMessage]:AttachAtom[This:OnChannelMessage]
		EVE:ActivateChannelMessageEvents
		
		UI:UpdateConsole["obj_Social: Initialized"]
	}
	
	method Shutdown()
	{
		EVE:ActivateChannelMessageEvents
		Event[EVE_OnChannelMessage]:DetachAtom[This:OnChannelMessage]
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}
		
	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
    		This:GetLists
			SystemSafe:Set[TRUE]
    		if ${Config.Combat.UseWhiteList}
    		{
    			This:CheckLocalWhiteList
    		}

    		if ${Config.Combat.UseBlackList}
    		{
    			This:CheckLocalBlackList
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
			call Sound.PlayTellSound
		}
	}
	
	member:bool IsSafe()
	{
		return ${This.SystemSafe}
	}
	
	/* This method is safe to call in station */
	method CheckLocalWhiteList()
	{
		variable index:pilot PilotIndex
		variable iterator PilotIterator
		variable bool pilotSafe
		variable int UnSafeCount
		variable set PilotWhiteList
		variable set CorpWhiteList
		variable set AllianceWhiteList
		
		EVE:DoGetPilots[PilotIndex]
		
		PilotWhiteList:Add[${Me.CharID}]
		if ${Me.CorporationID} > 0
		{
			AllianceWhiteList:Add[${Me.CorporationID}]
		}
		if ${Me.AllianceID} > 0
		{
			AllianceWhiteList:Add[${Me.AllianceID}]
		}

		if ${This.WhiteListPilotIterator:First(exists)}
		do
		{
			PilotWhiteList:Add[${This.WhiteListPilotIterator.Value}]
		}
		while ${This.WhiteListPilotIterator:Next(exists)}

		if ${This.WhiteListCorpIterator:First(exists)}
		do
		{
			CorpWhiteList:Add[${This.WhiteListCorpIterator.Value}]
		}
		while ${This.WhiteListCorpIterator:Next(exists)}

		if ${This.WhiteListAllianceIterator:First(exists)}
		do
		{
			AllianceWhiteList:Add[${This.WhiteListAllianceIterator.Value}]
		}
		while ${This.WhiteListAllianceIterator:Next(exists)}

		PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			pilotSafe:Set[FALSE]
			if ${AllianceWhiteList.Contains[${PilotIterator.Value.AllianceID}]} || \
				${CorpWhiteList.Contains[${PilotIterator.Value.CorporationID}]} || \
				${PilotWhiteList.Contains[${PilotIterator.Value.CharID}]}
			{
					pilotSafe:Set[TRUE]
			}
			
			if !${pilotSafe}
			{	
				/* pilot failed alliance and corporation check, get out of town!! */
				UI:UpdateConsole["obj_Social: Non-Whitelisted Pilot in local: ${PilotIterator.Value.Name}!"]
				UI:UpdateConsole["obj_Social: ALLIANCE:	<Setting Name="">${PilotIterator.Value.AllianceID}</Setting>"]
				UI:UpdateConsole["obj_Social: CORP:	<Setting Name="">${PilotIterator.Value.CorporationID}</Setting>"]
				SystemSafe:Set[${pilotSafe}]
				return
			}			
		}
		while ${PilotIterator:Next(exists)}	
	}
	
	/* This method is safe to call in station */
	method CheckLocalBlackList()
	{
		variable index:pilot PilotIndex
		variable iterator PilotIterator
		variable bool pilotSafe
		variable set PilotBlackList
		variable set CorpBlackList
		variable set AllianceBlackList
		
		EVE:DoGetPilots[PilotIndex]

		if ${This.BlackListPilotIterator:First(exists)}
		do
		{
			PilotBlackList:Add[${This.BlackListPilotIterator.Value}]
		}
		while ${This.BlackListPilotIterator:Next(exists)}

		if ${This.BlackListCorpIterator:First(exists)}
		do
		{
			CorpBlackList:Add[${This.BlackListCorpIterator.Value}]
		}
		while ${This.BlackListCorpIterator:Next(exists)}

		if ${This.BlackListAllianceIterator:First(exists)}
		do
		{
			AllianceBlackList:Add[${This.BlackListAllianceIterator.Value}]
		}
		while ${This.BlackListAllianceIterator:Next(exists)}

		PilotIndex:GetIterator[PilotIterator]
		if ${PilotIterator:First(exists)}
		do
		{
			pilotSafe:Set[TRUE]
			if ${PilotBlackList.Contains[${PilotIterator.Value.CharID}]} || \
				${AllianceBlackList.Contains[${PilotIterator.Value.AllianceID}]} || \
				${CorpBlackList.Contains[${PilotIterator.Value.CorporationID}]}
			{
					pilotSafe:Set[FALSE]
			}
			
			if !${pilotSafe}
			{	
				/* pilot failed alliance and corporation check, get out of town!! */
				UI:UpdateConsole["obj_Social: Blacklisted Pilot in local: ${PilotIterator.Value.Name}!"]
				SystemSafe:Set[${pilotSafe}]
				return
			}			
		}
		while ${PilotIterator:Next(exists)}
	}

	method GetLists()
	{
		if ( ${Me.InStation(exists)} && ${Me.InStation} )
			return

		if (${Me.ToEntity.Mode} == 3)
			return    

		EVE:DoGetEntities[PilotIndex,CategoryID,CATEGORYID_SHIP]
		EVE:DoGetEntities[EntityIndex,CategoryID,CATEGORYID_ENTITY]
	}
	
	member:bool PlayerDetection()
	{
		if !${This.PilotIndex.Used}
		{
			return FALSE
		}
		
		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]
		
		if ${PilotIterator:First(exists)}
		{
			do
			{
				if ${PilotIterator.Value.IsPC} && \
				 	${Me.ShipID} != ${PilotIterator.Value} && \
				 	${PilotIterator.Value.Distance} < ${Config.Miner.AvoidPlayerRange} && \
				 	!${PilotIterator.Value.ToFleetMember}
				{
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
		
		EVE:DoGetPilots[PilotIndex]
		echo ${PilotIndex.Used}

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

				if (${Me.CharID} == ${PilotIterator.Value.CharID}) 
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
				echo Corp -> Them ${EVE.Standing[${Me.CorporationID},${PilotIterator.Value.CharID}]}
				echo Alliance -> Them ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CharID}]}
				echo Me -> TheyCorp	${EVE.Standing[${Me.CharID},${PilotIterator.Value.CorporationID}]}
				echo MeCorp -> TheyCorp	${EVE.Standing[${Me.CorporationID},${PilotIterator.Value.CorporationID}]}
				echo MeAlliance -> TheyCorp ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CorporationID}]}
				echo Me -> TheyAlliance ${EVE.Standing[${Me.CharID},${PilotIterator.Value.AllianceID}]}
				echo MeCorp -> TheyAlliance ${EVE.Standing[${Me.CorporationID},${PilotIterator.Value.AllianceID}]}
				echo MeAlliance -> TheyAlliance ${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.AllianceID}]}

				echo They -> Me	${EVE.Standing[${PilotIterator.Value.CharID},${Me.CharID}]}
				echo TheyCorp -> Me ${EVE.Standing[${PilotIterator.Value.CorporationID},${Me.CharID}]}
				echo TheyAlliance -> Me ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CharID}]}
				echo They -> MeCorp ${EVE.Standing[${PilotIterator.Value.CharID},${Me.CorporationID}]}
				echo TheyCorp -> MeCorp ${EVE.Standing[${PilotIterator.Value.CorporationID},${Me.CorporationID}]}
				echo TheyAlliance -> MeCorp ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CorporationID}]}
				echo They -> MeAlliance ${EVE.Standing[${PilotIterator.Value.CharID},${Me.AllianceID}]}
				echo TheyCorp -> MeAlliance ${EVE.Standing[${PilotIterator.Value.CorporationID},${Me.AllianceID}]}
				echo TheyAlliance -> MeAlliance ${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.AllianceID}]}

				if	${EVE.Standing[${Me.CharID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.CorporationID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.CharID},${PilotIterator.Value.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${Me.CorporationID},${PilotIterator.Value.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${Me.CharID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${Me.CorporationID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotIterator.Value.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CorporationID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CorporationID},${Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CharID},${Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.CorporationID},${Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotIterator.Value.AllianceID},${Me.AllianceID}]} < ${Standing}
				{
					/* Yep, I'm laughing right now as well -- CyberTech */
					UI:UpdateConsole["obj_Social: StandingDetection in local: ${PilotIterator.Value.Name} - ${PilotIterator.Value.Standing}!"]
					return TRUE
				}
			}
			while ${PilotIterator:Next(exists)}
			
		}
		
		return FALSE
	}
	
	member:bool PilotsWithinDetection(int Dist)
	{
		if !${This.PilotIndex.Used}
		{
			return FALSE
		}
		
		variable iterator PilotIterator
		This.PilotIndex:GetIterator[PilotIterator]
		
		if ${PilotIterator:First(exists)}
		{
			do
			{
				if (${Me.ShipID} != ${PilotIterator.Value}) && \
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
		if !${This.EntityIndex.Used} && !${This.PilotIndex.Used}
		{
			return FALSE
		}
		
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
	
	