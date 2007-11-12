/*
	The freighter object
	
	The obj_Freighter object is a bot module designed to be used with 
	EVEBOT.  The freighter bot will move cargo from one (or more) source
	locations to a destination.  The type of cargo moved is selectable.
	The source and destination locations are specified via bookmarks.
	
	-- GliderPro	
*/
objectdef obj_Freighter
{
	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable int FrameCounter
	
	variable queue:bookmark SourceLocations
	variable int m_DestinationID
	
	method Initialize(string player, string corp)
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
				call This.PickupOrDropoff
				call Station.Undock
				call Ship.OpenCargo
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
		elseif ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
		{
		 	This.CurrentState:Set["TRANSPORT"]
		}
		else
		{
			This.CurrentState:Set["Unknown"]
		}
	}

	/* Move the freighter to the next source station in the list */
	function Transport()
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

	/* If we are in a source station pick stuff up.
	 * If we are in the destination station drop our load.
	 */
	function PickupOrDropoff()
	{
		if ${Me.InStation}
		{	/* don't call this function if you are not in station */
			;echo "\${EVE.Bookmark[${Config.Freighter.Destination}](exists)} = ${EVE.Bookmark[${Config.Freighter.Destination}](exists)}"
			;echo "\${m_DestinationID} = ${m_DestinationID}"
			;echo "\${Me.StationID} = ${Me.StationID}"
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
