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

	variable time NextPulse
	variable int PulseIntervalInSeconds = 2
	
	variable queue:bookmark SourceLocations
	variable int m_DestinationID
	
	variable obj_Courier 		Courier
	variable obj_StealthHauler 	StealthHauler
	variable obj_Scavenger 		Scavenger
	
	method Initialize()
	{
		This:SetupEvents[]
		BotModules:Insert["Freighter"]
		
		m_DestinationID:Set[0]
		
		/* I didn't want this here but it was the only way to
		 * get this to work properly.  When Bookmark:Remove 
		 * works this can be moved into the state machine and
		 * PickupOrDropoff can delete the station bookmarks.
		 */
		if ${Config.Common.BotModeName.Equal[Freighter]}
		{
			This:BuildSourceList
		}

		UI:UpdateConsole["obj_Freighter: Initialized", LOG_MINOR]
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
				case Stealth Hauler
					This.StealthHauler:SetState
					break
				case Scavenger
					This.Scavenger:SetState
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
			case Stealth Hauler
				call This.StealthHauler.ProcessState
				break
			case Scavenger
				call This.Scavenger.ProcessState
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
		if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity(exists)} && ${m_DestinationID} == 0
		{
			m_DestinationID:Set[${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.ID}]
			Assets:IgnoreStation[${m_DestinationID}]
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

		if !${EVEWindow[ByCaption,"ASSETS"](exists)}
		{
			EVE:Execute[OpenAssets]
		}
		
		nextStationID:Set[${Assets.NextStation}]
		if ${nextStationID}
		{
   			variable string tmp_string
			UI:UpdateConsole["DEBUG: StationID = ${nextStationID}"]
   			UI:UpdateConsole["DEBUG: Location = ${EVE.GetLocationNameByID[${nextStationID}]}"]
   			tmp_string:Set[${Assets.SolarSystem[${nextStationID}]}]
			UI:UpdateConsole["DEBUG: Solar System = ${tmp_string}"]
			UI:UpdateConsole["DEBUG: Region = ${Universe[${tmp_string}].Region}"]

		    if ${Config.Freighter.RegionName.Length} > 0
		    {   /* limit to the given region */
	   			UI:UpdateConsole["DEBUG: Config.Freighter.RegionName = ${Config.Freighter.RegionName}"]
		        if ${Config.Freighter.RegionName.NotEqual[${Universe[${tmp_string}].Region}]}
		        {
        			Assets:IgnoreStation[${nextStationID}]
               		nextStationID:Set[0]
		        }
		    }
	        
	        if ${nextStationID} && (${Me.SolarSystemID} != ${Universe[${tmp_string}].ID})
	        {	/* check for low-sec jumps */
	        	Universe[${tmp_string}]:SetDestination
	        	wait 5
	        	variable index:int ap_path
	        	EVE:DoGetToDestinationPath[ap_path]
	        	variable iterator ap_path_iterator
	        	ap_path:GetIterator[ap_path_iterator]
	        	
				if ${ap_path_iterator:First(exists)}
				{
					do
					{
				        if ${Universe[${ap_path_iterator.Value}].Security} <= 0.45
				        {	/* avoid low-sec */
							UI:UpdateConsole["DEBUG: Avoiding low-sec routes."]					        	
		        			Assets:IgnoreStation[${nextStationID}]
		               		nextStationID:Set[0]
		               		break
				        }
					}
					while ${ap_path_iterator:Next(exists)}
				}		
	        }
	        
			if ${nextStationID} && (${Me.SolarSystemID} != ${Universe[${tmp_string}].ID})
			{
	    		UI:UpdateConsole["Freighter moving to ${EVE.GetLocationNameByID[${nextStationID}]}."]
	    		
				wait 5
				UI:UpdateConsole["Activating autopilot and waiting until arrival..."]
				EVE:Execute[CmdToggleAutopilot]
				do
				{
					wait 50
					if !${Me.AutoPilotOn(exists)}
					{
						do
						{
							wait 5
						}
						while !${Me.AutoPilotOn(exists)}
					}
				}
				while ${Me.AutoPilotOn}
				wait 20
				do
				{
				   wait 10
				}
				while !${Me.ToEntity.IsCloaked}
				wait 5
	    	}
	    	
	        if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity(exists)}
	        {	/* Unfortunately you cannot get the station ID cooresponding to the book- */
	        	/* mark until you are in the same system as the bookmark destination.     */
	        	if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.ID} == ${nextStationID}
	        	{
               		nextStationID:Set[0]	        		
	        	}
			}										

			if ${nextStationID}
			{
				call Station.DockAtStation ${nextStationID}    		
			}	    	
		}
		else
		{	/* no more assets, abort */
			UI:UpdateConsole["No more work to do.  Freighter aborting."]
			EVEBot.ReturnToStation:Set[TRUE]
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
	
		variable iterator bm_iterator
		bm_index:GetIterator[bm_iterator]
		
		variable collection:bookmark bm_collection
		if ${bm_iterator:First(exists)}
		{
			do
			{
				variable string bm_name
				bm_name:Set["${bm_iterator.Value.Label}"]			
				if ${bm_name.Left[${bm_prefix.Length}].Equal[${bm_prefix}]}
				{
					if ${bm_collection.Element[${bm_iterator.Value.Label}](exists)}
					{
						UI:UpdateConsole["Label ${bm_iterator.Value.Label} exists more than once."]
						UI:UpdateConsole["Freighter will visit stations with the same bookmark label in a"]
						UI:UpdateConsole["random order.  Try to use unique bookmark labels in the future."]
						bm_collection:Set["${bm_iterator.Value.Label}_${Math.Rand[5000]:Inc[1000]}",${bm_iterator.Value}]
					}
					else
					{
						bm_collection:Set[${bm_iterator.Value.Label},${bm_iterator.Value}]	
					}
				}
			}
			while ${bm_iterator:Next(exists)}
		}		
		
		SourceLocations:Clear
		if ${bm_collection.FirstValue(exists)}
		{
			do
			{
				SourceLocations:Queue[${bm_collection.CurrentValue}]	
			}
			while ${bm_collection.NextValue(exists)}
		}		
		
		UI:UpdateConsole["BuildSourceList found ${SourceLocations.Used} source locations."]
	}
}
