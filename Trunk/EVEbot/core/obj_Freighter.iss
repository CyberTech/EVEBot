/*
	The freighter object
	
	The obj_Freighter object is a bot module designed to be used with 
	EVEBOT.  The freighter bot will move cargo from one (or more) source
	locations to a destination.  The type of cargo moved is selectable.
	The source and destination locations are specified via bookmarks.
	
	-- GliderPro	
*/

/* obj_Courier is a "bot-mode" which is similar to a bot-module.
 * obj_Courier runs within the obj_Freighter bot-module.  It would 
 * be very straightforward to turn obj_Courier into a independent 
 * bot-module in the future if it outgrows its place in obj_Freighter.
 */
objectdef obj_Courier
{
	/* the bot logic is currently based on a state machine */
	variable string CurrentState

	method Initialize()
	{
		UI:UpdateConsole["obj_Courier: Initialized"]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]		
	}
	
	/* NOTE: The order of these if statements is important!! */
	/* obj_Courier tasks:
	 *	MOVING_TO_AGENT
	 *	GETTING_MISSION
	 *	MOVING_TO_PICKUP
	 *	LOADING_CARGO
	 *	MOVING_TO_DROPOFF
	 *	UNLOADING_CARGO
	 *	TURNING_IN_MISSION
	 *  (repeat)
	 */
	method SetState()
	{
		if ${Agents.ActiveAgent.NotEqual[${Config.Freighter.AgentName}]}
		{
			Agents:SetActiveAgent[${Config.Freighter.AgentName}]
		}
		
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${Agents.HaveMission}
		{
			This.CurrentState:Set["START_MISSION"]
		}
		elseif !${Agents.HaveMission}
		{
			This.CurrentState:Set["GET_MISSION"]
		}
		else
		{
			This.CurrentState:Set["Unknown"]
		}
	}

	function ProcessState()
	{
		switch ${This.CurrentState}
		{
			case ABORT
				call Station.Dock
				break
			case IDLE
				break
		}	
	}
}

objectdef obj_Freighter
{
	/* the bot logic is currently based on a state machine */
	variable string CurrentState

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	
	variable queue:bookmark SourceLocations
	variable int m_DestinationID
	variable obj_Courier Courier
	
	method Initialize()
	{
		This:SetupEvents[]
		BotModules:Insert["Freighter"]
		
		/* I didn't want this here but it was the only way to
		 * get this to work properly.  When Bookmark:Remove 
		 * works this can be moved into the state machine and
		 * PickupOrDropoff can delete the station bookmarks.
		 */
		This:BuildSourceList
		
		UI:UpdateConsole["obj_Freighter: Initialized"]
	}
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Freighter]}
		{
			return
		}
		
	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
			switch ${Config.Freighter.FreighterModeName}
			{
				case Move Minerals to Buyer
					/* not implemented yet */
					break
				case Mission Runner
					This.Courier:SetState
					break
				default
					This:SetState[]
					break
			}


    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}
		
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]		
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]

		/* override any events setup by the base class */
		Event[OnFrame]:AttachAtom[This:Pulse]
	}
	
	/* this function is called repeatedly by the main loop in EveBot.iss */
	function ProcessState()
	{				
		switch ${Config.Freighter.FreighterModeName}
		{
			case Move Minerals to Buyer
				/* not implemented yet */
				break
			case Mission Runner
				call This.Courier.ProcessState
				break
			default
				switch ${This.CurrentState}
				{
					case IDLE
						break
					case ABORT
						UI:UpdateConsole["Aborting operation: Returning to base"]
						if ${EVE.Bookmark[${Config.Freighter.Destination}](exists)}
						{
							call Ship.WarpToBookMarkName "${Config.Freighter.Destination}"
						}
						break
					case BASE
						call This.DoBaseAction
						break
					case TRANSPORT
						call This.Transport
						break
					case CARGOFULL
						if ${EVE.Bookmark[${Config.Freighter.Destination}](exists)}
						{
							call Ship.WarpToBookMarkName "${Config.Freighter.Destination}"
						}
						break
				}	
				break
		}
	}
	
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity(exists)}
		{
			m_DestinationID:Set[${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.ID}]
		}										

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
		elseif ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
		{
			This.CurrentState:Set["CARGOFULL"]
		}
		elseif !${Me.InStation} && ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	This.CurrentState:Set["TRANSPORT"]
		}
		else
		{
			This.CurrentState:Set["Unknown"]
		}
	}

	function DoBaseAction()
	{
		switch ${Config.Freighter.FreighterModeName}
		{
			case Move Minerals to Buyer
				/* not implemented yet */
				break
			case Container Test
				call This.ContainerTest
				break
			default
				call This.PickupOrDropoff
				call Station.Undock
				call Ship.OpenCargo
				break
		}
	}
	
	function ContainerTest()
	{
		call Cargo.OpenHolds
		
		if ${Cargo.ShipHasContainers}
		{
			UI:UpdateConsole["obj_Freighter: Ship has containers."]
			UI:UpdateConsole["obj_Freighter: Station contains ${Me.GetHangarItems} items."]
			if ${Me.GetHangarItems} > 0
			{	/* move from hangar to ship */
				call Cargo.TransferCargoToShip
			}
			else
			{	/* move from ship to hangar */
				call Cargo.TransferCargoToHangar
			}			
		}
		else
		{
			UI:UpdateConsole["obj_Freighter: Ship doesn't have containers."]
		}
			
		wait 50
	}

	function Transport()
	{
		switch ${Config.Freighter.FreighterModeName}
		{
			case Source and Destination
				call This.MoveToSourceStation
				break
			case Asset Gather
				call This.MoveToNextStationWithAssets
				break
			case Move Minerals to Buyer
				/* not implemented yet */
				break
		}
	}
	
	/* Move the freighter to the next source station in the list */
	function MoveToSourceStation()
	{
		if ${SourceLocations.Used} == 0 
		{	/* sources emptied, abort */
			EVEBot.ReturnToStation:Set[TRUE]
		}
		elseif ${SourceLocations.Peek(exists)}
		{
			call Ship.WarpToBookMark ${SourceLocations.Peek}
		}
	}
	
	function MoveToNextStationWithAssets()
	{
		variable int nextStationID
		
		nextStationID:Set[${Assets.NextStation}]
		if ${nextStationID}
		{
		    if ${Config.Freighter.SystemName(exists)}
		    {   /* limit to the given system */
    			UI:UpdateConsole["DEBUG: StationID = ${nextStationID}"]
    			UI:UpdateConsole["DEBUG: Region = ${EVE.Station[${nextStationID}].Region}"]
    			/* TODO: EVE.Station[] IS BROKEN!!!! */
		        ;if ${Config.Freighter.SystemName.NotEqual[${EVE.Station[${nextStationID}].Region}]}
		        ;{
        		;	Assets:IgnoreStation[${nextStationID}]
               	;	nextStationID:Set[0]
		        ;}
		    }
		}
		else
		{	/* no more assets, abort */
			UI:UpdateConsole["No more work to do.  Freighter aborting."]
			EVEBot.ReturnToStation:Set[TRUE]
		}
		
		if ${nextStationID}
		{
    		UI:UpdateConsole["Freighter moving to ${EVE.GetLocationNameByID[${nextStationID}]}."]
    	}
	}

	/* If we are in a source station pick stuff up.
	 * If we are in the destination station drop our load.
	 */
	function PickupOrDropoff()
	{
		if ${Me.InStation(exists)} && ${Me.InStation}
		{	/* don't call this function if you are not in station */
			UI:UpdateConsole["DEBUG: /${EVE.Bookmark[${Config.Freighter.Destination}](exists)} = ${EVE.Bookmark[${Config.Freighter.Destination}](exists)}"]
			UI:UpdateConsole["DEBUG: /${m_DestinationID} = ${m_DestinationID}"]
			UI:UpdateConsole["DEBUG: /${Me.StationID} = ${Me.StationID}"]
			if ${EVE.Bookmark[${Config.Freighter.Destination}](exists)} && \
			   ${m_DestinationID} == ${Me.StationID}
			{	/* this is the destination station, drop off stuff */
				call Cargo.TransferCargoToHangar
			}
			else
			{	/* this must be a source station, pickup stuff */
				call Cargo.TransferCargoToShip
				if ${Cargo.LastTransferComplete}
				{
					if ${SourceLocations.Peek(exists)}
					{
						SourceLocations:Dequeue					
					}
				}
			}
		}
	}

	method BuildSourceList()
	{
		variable string bm_prefix
		bm_prefix:Set[${Config.Freighter.SourcePrefix}]

		variable index:bookmark bm_index		
		EVE:DoGetBookmarks[bm_index]
	
		variable int idx
		idx:Set[${bm_index.Used}]
		
		SourceLocations:Clear
		while ${idx} > 0
		{
			variable string bm_name
			bm_name:Set["${bm_index.Get[${idx}].Label}"]			
			if ${bm_name.Left[${bm_prefix.Length}].Equal[${bm_prefix}]}
			{
				SourceLocations:Queue[${bm_index.Get[${idx}]}]	
			}
			idx:Dec
		}		
		
		UI:UpdateConsole["BuildSourceList found ${SourceLocations.Used} source locations."]
	}
}
