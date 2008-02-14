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

	variable iterator CorpIterator	
	variable iterator AllianceIterator	
	variable bool SystemSafe	
	
	method Initialize()
	{
		Whitelist.CorporationsRef:GetSettingIterator[This.CorpIterator]
		Whitelist.AlliancesRef:GetSettingIterator[This.AllianceIterator]

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
			return
		}

		FrameCounter:Inc
		variable int IntervalInSeconds = 5
		
		
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
    		This:GetLists
    		This:CheckLocal
    		FrameCounter:Set[0]
		}
	}
	
	member:bool IsSafe()
	{
		return ${This.SystemSafe}
	}
	
	method CheckLocal()
	{
		variable index:pilot anIndex
		variable iterator    anIterator
		variable bool localSafe
		variable bool pilotSafe
		
		EVE:DoGetPilots[anIndex]
		anIndex:GetIterator[anIterator]
		
		localSafe:Set[TRUE]
		if ${anIterator:First(exists)}
		do
		{
			pilotSafe:Set[FALSE]
			
			if ${This.AllianceIterator:First(exists)}
			do
			{
				if ${This.AllianceIterator.Value.Int} == ${anIterator.Value.AllianceID}
				{
					pilotSafe:Set[TRUE]
				}
			}
			while ${This.AllianceIterator:Next(exists)}
			
			if !${pilotSafe}
			{	/* pilot failed alliance check, perform corporation check */
				if ${This.CorpIterator:First(exists)}
				do
				{
					if ${This.CorpIterator.Value.Int} == ${anIterator.Value.CorporationID}
					{
						pilotSafe:Set[TRUE]
					}
				}
				while ${This.CorpIterator:Next(exists)}
			}

			if !${pilotSafe}
			{	/* pilot failed alliance and corporation check, get out of town!! */
				UI:UpdateConsole["DEBUG: Hostile in local!!"]
				localSafe:Set[FALSE]
				break
			}
		}
		while ${anIterator:Next(exists)}
				
		SystemSafe:Set[${localSafe}]
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
	
	