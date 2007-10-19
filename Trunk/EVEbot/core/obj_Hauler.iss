/*
	The hauler object and subclasses
	
	The obj_Hauler object contains functions that a usefull in creating
	a hauler bot.  The obj_OreHauler object extends obj_Hauler and adds
	functions that are useful for bots the haul ore in conjunction with
	one or more miner bots.
	
	-- GliderPro	
*/
objectdef obj_Hauler
{
	/* The name of the player we are hauling for (null if using m_corpName) */
	variable string m_playerName
	
	/* The name of the corp we are hauling for (null if using m_playerName) */
	variable string m_corpName
		
	method Initialize()
	{			
		UI:UpdateConsole["obj_Hauler: Initialized"]
	}
	
	method Shutdown()
	{
		/* nothing needs cleanup AFAIK */
	}
		
	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		/* the base obj_Hauler class does not use events */
	}

	member:int NearestMatchingJetCan(int id)
	{
		variable index:int JetCan
		variable int JetCanCount
		variable int JetCanCounter
		variable string tempString
			
		JetCanCounter:Set[1]
		JetCanCount:Set[${EVE.GetEntityIDs[JetCan,GroupID,12]}]
		do
		{
			if ${Entity[${JetCan.Get[${JetCanCounter}]}](exists)}
			{
 				if ${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.CharID} == ${id}
 				{
 					echo "DEBUG: owner matched"
					echo "DEBUG: ${Entity[${JetCan.Get[${JetCanCounter}]}]}"
					echo "DEBUG: ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}"
					return ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}
 				}
			}
			else
			{
				echo "No jetcans found"
			}
		}
		while ${JetCanCounter:Inc} <= ${JetCanCount}
		
		return 0	/* no can found */
	}
	
	member:int OldNearestMatchingJetCan()
	{
		variable index:int JetCan
		variable int JetCanCount
		variable int JetCanCounter
		variable string tempString
			
		JetCanCounter:Set[1]
		JetCanCount:Set[${EVE.GetEntityIDs[JetCan,GroupID,12]}]
		do
		{
			if ${Entity[${JetCan.Get[${JetCanCounter}]}](exists)}
			{
 				if ${m_playerName.Length} 
 				{
 					tempString:Set[${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.Name}]
 					echo "DEBUG: owner ${tempString}"
 					if ${tempString.Equal[${m_playerName}]}
 					{
	 					echo "DEBUG: owner matched"
						echo "DEBUG: ${Entity[${JetCan.Get[${JetCanCounter}]}]}"
						echo "DEBUG: ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}"
						return ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}
 					}
 				}
 				elseif ${m_corpName.Length} 
 				{
 					tempString:Set[${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.Corporation}]
 					echo "DEBUG: corp ${tempString}"
 					if ${tempString.Equal[${m_corpName}]}
 					{
	 					echo "DEBUG: corp matched"
						return ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}
 					}
 				}
 				else
 				{
					echo "No matching jetcans found"
 				} 				
			}
			else
			{
				echo "No jetcans found"
			}
		}
		while ${JetCanCounter:Inc} <= ${JetCanCount}
		
		return 0	/* no can found */
	}
	
	function ApproachEntity(int id)
	{
		call Ship.Approach ${id} LOOT_RANGE
		EVE:Execute[CmdStopShip]
	}	
}

objectdef obj_OreHauler inherits obj_Hauler
{
	/* This variable is set by a remote event.  When it is non-zero, */
	/* the bot will undock and seek out the gang memeber.  After the */
	/* member's cargo has been loaded the bot will zero this out.    */
	variable int m_gangMemberID
	variable int m_SystemID
	variable int m_BeltID

	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable int FrameCounter
	
	variable index:bookmark SafeSpots
	variable iterator SafeSpotIterator
	
	variable queue:gangmember GangMembers
	
	method Initialize(string player, string corp)
	{
		m_gangMemberID:Set[-1]
		m_SystemID:Set[-1]
		m_BeltID:Set[-1]
		m_CheckedCargo:Set[FALSE]
		UI:UpdateConsole["obj_OreHauler: Initialized"]
		Event[OnFrame]:AttachAtom[This:Pulse]
		This:SetupEvents[]
		BotModules:Insert["Hauler"]
	}

	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Hauler]}
		{
			return
		}
		FrameCounter:Inc

		variable int IntervalInSeconds = 2
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			This:SetState[]
			FrameCounter:Set[0]
		}
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]		
		Event[EVEBot_Miner_Full]:DetachAtom[This:MinerFull]
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]
		/* override any events setup by the base class */

		LavishScript:RegisterEvent[EVEBot_Miner_Full]
		Event[EVEBot_Miner_Full]:AttachAtom[This:MinerFull]
	}
	
	/* A miner's jetcan is full.  Let's go get the ore.  */
	method MinerFull(string haulParams)
	{
		echo "DEBUG: obj_OreHauler:MinerFull... ${haulParams}"
		
		variable int charID = -1
		variable int systemID = -1
		variable int beltID = -1
		
		charID:Set[${haulParams.Token[1,","]}]
		systemID:Set[${haulParams.Token[2,","]}]
		beltID:Set[${haulParams.Token[3,","]}]
		
		echo "DEBUG: obj_OreHauler:MinerFull... ${charID} ${systemID} ${beltID}"

		m_gangMemberID:Set[${charID}]
		m_SystemID:Set[${systemID}]		
		m_BeltID:Set[${beltID}]				
	}	
	
	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{				
		switch ${This.CurrentState}
		{
			case IDLE
				break
			case ABORT
				UI:UpdateConsole["Aborting operation: Returning to base"]
				Call Dock
				break
			case BASE
				call Cargo.TransferOreToHangar
				call Ship.Undock
				break
			case HAUL
				call This.Haul
				break
			case CARGOFULL
				call Dock
				m_gangMemberID:Set[-1]
				m_SystemID:Set[-1]		
				m_BeltID:Set[-1]		
				break
		}	
	}
	
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${Me.InStation}
		{
	  		This.CurrentState:Set["BASE"]
		}
		elseif ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	This.CurrentState:Set["HAUL"]
		}
		elseif ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{
			This.CurrentState:Set["CARGOFULL"]
		}
		else
		{
			This.CurrentState:Set["Unknown"]
		}
	}

	function LootEntity(int id)
	{
		variable index:item ContainerCargo
		variable iterator Cargo
		variable int QuantityToMove

		UI:ConsoleUpdate["DEBUG: obj_OreHauler.LootEntity ${id}"]
		
		Entity[${id}]:DoGetCargo[ContainerCargo]
		ContainerCargo:GetIterator[Cargo]
		if ${Cargo:First(exists)}
		{
			do
			{
				UI:ConsoleUpdate["Hauler: Found ${Cargo.Value.Quantity} x ${Cargo.Value.Name} - ${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}m3"]
				if (${Cargo.Value.Quantity} * ${Cargo.Value.Volume}) > ${Ship.CargoFreeSpace}
				{
					/* Move only what will fit, minus 1 to account for CCP rounding errors. */
					QuantityToMove:Set[${Ship.CargoFreeSpace} / ${Cargo.Value.Volume} - 1]
				}
				else
				{
					QuantityToMove:Set[${Cargo.Value.Quantity}]
				}

				UI:ConsoleUpdate["Hauler: Moving ${QuantityToMove} units: ${Math.Calc[${QuantityToMove} * ${Cargo.Value.Volume}]}m3"]
				if ${QuantityToMove} > 0
				{
					Cargo.Value:MoveTo[MyShip,${QuantityToMove}]
					wait 30
				}
								
				if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
				{
					/* TODO - this needs to keep a queue of bookmarks, named for the can ie, "Can CORP hh:mm", of partially looted cans */
					/* Be sure its names, and not ID.  We shouldn't store anything in a bookmark name that we shouldnt know */
					
					UI:UpdateConsole["DEBUG: obj_Hauler.LootEntity: Ship Cargo: ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}"
					break
				}
			} 
			while ${Cargo:Next(exists)}
		}

		Me.Ship:StackAllCargo
		wait 10
	}


	function Haul()
	{
		switch ${Config.Hauler.HaulerModeName}
		{
			case Service On-Demand
				call This.HaulOnDemand
				break
			case Service Gang Members
				call This.HaulForGang
				break
			case Service All Belts
				call This.HaulAllBelts
				break
		}
	}

	/* The HaulOnDemand function will be called repeatedly   */
	/* until we leave the HAUL state due to downtime,        */
	/* agression, or a full cargo hold.  The Haul function   */
	/* should do one (and only one) of the following actions */
	/* each it is called.									 */
	/*                                                       */ 
	/* 1) Warp to gang member and loot nearby cans           */ 
	/* 2) Warp to next safespot                              */ 
	/* 3) Travel to new system (if required)                 */ 
	/*                                                       */ 
	function HaulOnDemand()
	{		
		if ${m_gangMemberID} > 0 && ${m_SystemID} == ${Me.SolarSystemID}
		{
			call This.WarpToGangMemberAndLoot ${m_gangMemberID}
		}
		else
		{
			call This.WarpToNextSafeSpot
		}
	}

	/* 1) Warp to gang member and loot nearby cans           */ 
	/* 2) Repeat until cargo hold is full                    */ 
	/*                                                       */ 
	function HaulForGang()
	{		
		if ${GangMembers.Used} == 0 
		{
			This:BuildGangMemberList
			call This.WarpToNextSafeSpot
		}		
		else
		{
			if ${GangMembers.Peek(exists)} && \
				${Local[${GangMembers.Peek.CharID}](exists)}
			{
				call This.WarpToGangMemberAndLoot ${GangMembers.Peek.CharID}
				GangMembers:Dequeue
			}
		}
	}
	
	function HaulAllBelts()
	{		
    	UI:UpdateConsole["Service All Belts mode not implemented!"]
		EVEBot.ReturnToStation:Set[TRUE]
	}

	function WarpToGangMemberAndLoot(int charID)
	{
		variable int id = 0
		
		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{	/* if we are already full ignore this request */
			return
		}
		
		UI:UpdateConsole["Warping to gang member."]
		Gang:WarpToGangMember[${charID}]
		call Ship.WarpWait

		call Ship.OpenCargo
	
		do
		{
			id:Set[${This.NearestMatchingJetCan[${charID}]}]

			echo "DEBUG: can ID = ${id}"
			if ${Entity[${id}](exists)}

			{
				call This.ApproachEntity ${id}
				Entity[${id}]:OpenCargo

				wait 30	
				call This.LootEntity ${id}
				if ${Entity[${id}](exists)}
				{
					Entity[${id}]:CloseCargo
				}

				if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
				{
					break
				}
			}
		} 
		while ${Entity[${id}](exists)}
		
		/* TODO: add code to loot and salvage any nearby wrecks */

		m_gangMemberID:Set[-1]
		m_SystemID:Set[-1]		
		m_BeltID:Set[-1]		
		call Ship.CloseCargo
	}

	method BuildGangMemberList()
	{
		variable index:gangmember gang
		GangMembers:Clear
		Me:DoGetGang[gang]
	
		variable int idx
		idx:Set[${gang.Used}]
		
		while ${idx} > 0
		{
			if ${gang.Get[${idx}].CharID} != ${Me.CharID}
			{
				GangMembers:Queue[${gang.Get[${idx}]}]	
			}
			idx:Dec
		}		
		
		UI:UpdateConsole["BuildGangMemberList found ${GangMembers.Used} other gang members."]
	}
	

	method BuildSafeSpotList()
	{
		SafeSpots:Clear
		EVE:DoGetBookmarks[SafeSpots]
	
		variable int idx
		idx:Set[${SafeSpots.Used}]
		
		while ${idx} > 0
		{
			variable string Prefix
			Prefix:Set[${Config.Labels.SafeSpotPrefix}]
			
			variable string Label
			Label:Set[${SafeSpots.Get[${idx}].Label}]			
			if ${Label.Left[${Prefix.Length}].NotEqual[${Prefix}]}
			{
				SafeSpots:Remove[${idx}]
			}
			elseif ${SafeSpots.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
			{
				SafeSpots:Remove[${idx}]
			}
			
			idx:Dec
		}		
		SafeSpots:Collapse
		SafeSpots:GetIterator[SafeSpotIterator]
		
		UI:UpdateConsole["BuildSafeSpotList found ${SafeSpots.Used} safespots in this system."]
	}
	
	function WarpToNextSafeSpot()
	{
		if ${SafeSpots.Used} == 0 
		{
			This:BuildSafeSpotList
		}		
		
		if ${SafeSpots.Get[1](exists)} && ${SafeSpots.Get[1].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:BuildSafeSpotList
		}
		
		if !${SafeSpotIterator:Next(exists)}
		{
			SafeSpotIterator:First
		}
		
		if ${SafeSpotIterator.Value(exists)}
		{
			call Ship.WarpToBookMark ${SafeSpotIterator.Value.ID}
		}
	}
}

