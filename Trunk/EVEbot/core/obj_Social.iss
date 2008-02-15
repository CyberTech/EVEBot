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
	variable index:entity PilotIndex
	variable index:entity EntityIndex
	variable int FrameCounter

	variable iterator WhiteListPilotIterator	
	variable iterator WhiteListCorpIterator	
	variable iterator WhiteListAllianceIterator	
	variable iterator BlackListPilotIterator	
	variable iterator BlackListCorpIterator	
	variable iterator BlackListAllianceIterator	
	variable bool SystemSafe	
	
	method Initialize()
	{
		Whitelist.PilotsRef:GetSettingIterator[This.PilotIterator]
		Whitelist.CorporationsRef:GetSettingIterator[This.CorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.AllianceIterator]

		Blacklist.PilotsRef:GetSettingIterator[This.PilotIterator]
		Blacklist.CorporationsRef:GetSettingIterator[This.CorpIterator]
		Blacklist.AlliancesRef:GetSettingIterator[This.AllianceIterator]

		SystemSafe:Set[TRUE]
		
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Social: Initialized"]
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			;return
		}

		FrameCounter:Inc
		variable int IntervalInSeconds = 5
				
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
    		This:GetLists
    		if ${Config.Combat.UseWhiteList}
    		{
    			This:CheckLocalWhiteList
    		}
    		if ${Config.Combat.UseBlackList}
    		{
    			This:CheckLocalBlackList
    		}
    		FrameCounter:Set[0]
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
			AllianceWhiteList:Add[${This.WhiteListCorpIterator.Value}]
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
				SystemSafe:Set[${pilotSafe}]
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

		if ${This.WhiteListPilotIterator:First(exists)}
		do
		{
			PilotWhiteList:Add[${This.WhiteListPilotIterator.Value}]
		}
		while ${This.WhiteListPilotIterator:Next(exists)}

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
				 	!${PilotIterator.Value.Owner.ToFleetMember}
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
				if (${Me.ShipID} == ${PilotIterator.Value}) && \
					${PilotIterator.Value.Owner.ToFleetMember(exists)}
				{
					return FALSE
				}

				/* Check Standing */
				if	${EVE.Standing[${Me.CharID},${PilotITerator.Value.Owner.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.CorporationID},${PilotITerator.Value.Owner.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotITerator.Value.Owner.CharID}]} < ${Standing} || \
					${EVE.Standing[${Me.CharID},${PilotITerator.Value.Owner.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${Me.CorporationID},${PilotITerator.Value.Owner.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotITerator.Value.Owner.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${Me.CharID},${PilotITerator.Value.Owner.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${Me.CorporationID},${PilotITerator.Value.Owner.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${Me.AllianceID},${PilotITerator.Value.Owner.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.CharID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.CorporationID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.AllianceID},${Me.CharID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.CharID},${Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.CorporationID},${Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.AllianceID},${Me.CorporationID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.CharID},${Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.CorporationID},${Me.AllianceID}]} < ${Standing} || \
					${EVE.Standing[${PilotITerator.Value.Owner.AllianceID},${Me.AllianceID}]} < ${Standing}
				{
					/* Yep, I'm laughing right now as well -- CyberTech */
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
					!${PilotIterator.Value.Owner.ToFleetMember} && \
					${PilotITerator.Value.Distance} < ${Dist}
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
	
	