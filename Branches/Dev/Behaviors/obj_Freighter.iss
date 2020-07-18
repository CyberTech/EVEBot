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
	variable time NextPulse
	variable float PulseIntervalInSeconds = 2.0

	variable string CurrentState

	variable queue:bookmark SourceLocations
	variable int64 m_DestinationID

	variable obj_Courier 		Courier
	variable obj_StealthHauler 	StealthHauler
	variable obj_Scavenger 		Scavenger
	variable bool ExcessCargoAtSource = FALSE

	method Initialize()
	{
		This:SetupEvents[]
		EVEBot.BehaviorList:Insert["Freighter"]

		m_DestinationID:Set[0]

		/* I didn't want this here but it was the only way to
		 * get this to work properly.  When Bookmark:Remove
		 * works this can be moved into the state machine and
		 * PickupOrDropoff can delete the station bookmarks.
		 */
		This:BuildSourceList

		Logger:Log["obj_Freighter: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			switch ${Config.Freighter.FreighterMode}
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
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]

		/* override any events setup by the base class */
	}

	/* this function is called repeatedly by the main loop in EVEBot.iss */
	function ProcessState()
	{
		if !${Config.Common.Behavior.Equal[Freighter]}
		{
			return
		}

		switch ${Config.Freighter.FreighterMode}
		{
			;echo "Freighter: ProcessState: ${This.CurrentState}"
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
						Logger:Log["Aborting operation: Returning to base"]
						if ${EVE.Bookmark[${Config.Freighter.Destination}](exists)}
						{
							call Ship.WarpToBookMarkName "${Config.Freighter.Destination}"
						}
						break
					case BASE
						call This.DoBaseAction
						break
					case UNDOCK
						call Station.Undock
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
		if !${Config.Common.Behavior.Equal[Freighter]}
		{
			return
		}

		if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity(exists)} && ${m_DestinationID} == 0
		{
			m_DestinationID:Set[${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.ID}]
			Assets:IgnoreStation[${m_DestinationID}]
			This.ExcessCargoAtSource:Set[FALSE]
		}

		if ${EVEBot.ReturnToStation} && ${Me.InSpace}
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
		elseif ${Me.InSpace} && ${Ship.CargoFreeSpace} > ${Ship.CargoMinimumFreeSpace}
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
		switch ${Config.Freighter.FreighterMode}
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
			variable index:items HangarItems
			Me:GetHangarItems[HangarItems]
			Logger:Log["obj_Freighter: Ship has containers."]
			Logger:Log["obj_Freighter: Station contains ${HangarItems.Used} items."]
			if ${HangarItems.Used} > 0
			{	/* move from hangar to ship */
				call Cargo.TransferCargoToShip
			}
			else
			{	/* move from ship to hangar */
				call Cargo.TransferCargoToStationHangar
			}
		}
		else
		{
			Logger:Log["obj_Freighter: Ship doesn't have containers."]
		}

		wait 50
	}

	function Transport()
	{
		switch ${Config.Freighter.FreighterMode}
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
		{
			Logger:Log["DEBUG: No more source locations!"]
			EVEBot.ReturnToStation:Set[TRUE]
		}
		elseif ${SourceLocations.Peek(exists)}
		{
			call Ship.WarpToBookMark ${SourceLocations.Peek.ID}
		}
	}

	function MoveToNextStationWithAssets()
	{
		variable int64 nextStationID

		if !${EVEWindow[ByCaption, "Assets"](exists)}
		{
			EVE:Execute[OpenAssets]
		}

		nextStationID:Set[${Assets.NextStation}]
		if ${nextStationID}
		{
   			variable string tmp_string
			Logger:Log["DEBUG: StationID = ${nextStationID}"]
   			Logger:Log["DEBUG: Location = ${EVE.GetLocationNameByID[${nextStationID}]}"]
   			tmp_string:Set[${Assets.SolarSystem[${nextStationID}]}]
			Logger:Log["DEBUG: Solar System = ${tmp_string}"]
			Logger:Log["DEBUG: Region = ${Universe[${tmp_string}].Region}"]

		    if ${Config.Freighter.RegionName.Length} > 0
		    {   /* limit to the given region */
	   			Logger:Log["DEBUG: Config.Freighter.RegionName = ${Config.Freighter.RegionName}"]
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
	        	EVE:GetToDestinationPath[ap_path]
	        	variable iterator ap_path_iterator
	        	ap_path:GetIterator[ap_path_iterator]

				if ${ap_path_iterator:First(exists)}
				{
					do
					{
				        if ${Universe[${ap_path_iterator.Value}].Security} <= 0.45
				        {	/* avoid low-sec */
							Logger:Log["DEBUG: Avoiding low-sec routes."]
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
	    		Logger:Log["Freighter moving to ${EVE.GetLocationNameByID[${nextStationID}]}."]

				call Ship.ActivateAutoPilot
	    	}

	        if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity(exists)}
	        {	/* Unfortunately you cannot get the station ID cooresponding to the book- */
	        	/* mark until you are in the same system as the bookmark destination.     */
	        	if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.ID.Equal[${nextStationID}]}
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
			Logger:Log["No more work to do.  Freighter aborting."]
			EVEBot.ReturnToStation:Set[TRUE]
		}
	}

	/* If we are in a source station pick stuff up.
	 * If we are in the destination station drop our load.
	 */
	function PickupOrDropoff()
	{
		if ${Me.InStation}
		{	/* don't call this function if you are not in station */
			Logger:Log["DEBUG: \${EVE.Bookmark[${Config.Freighter.Destination}](exists)} = ${EVE.Bookmark[${Config.Freighter.Destination}](exists)}"]
			Logger:Log["DEBUG: \${m_DestinationID} = ${m_DestinationID}"]
			Logger:Log["DEBUG: \${Me.StationID} = ${Me.StationID}"]

			if ${Me.StationID} == ${EVE.Bookmark[${Config.Freighter.Destination}].ItemID}
			{	/* this is the destination station, drop off stuff */
				call Cargo.TransferCargoToStationHangar
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
				else
				{
					; We can't fit the rest of the cargo
					This.ExcessCargoAtSource:Set[TRUE]
				}
			}
		}
		else
		{
			if ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity(exists)}
			{
				switch ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.TypeID}
				{
					case TYPEID_LARGE_ASSEMBLY_ARRAY
						call Cargo.TransferOreToLargeShipAssemblyArray
						break
					case TYPEID_XLARGE_ASSEMBLY_ARRAY
						call Cargo.TransferOreToXLargeShipAssemblyArray
						break
				}
				switch ${EVE.Bookmark[${Config.Freighter.Destination}].ToEntity.GroupID}
				{
					case GROUP_CORPORATEHANGARARRAY
						call Cargo.TransferOreToCorpHangarArray
						break
				}
			}
		}
	}

	method BuildSourceList()
	{
		variable string bm_prefix
		bm_prefix:Set[${Config.Freighter.SourceBookmarkPrefix}]

		variable index:bookmark bm_index
		EVE:GetBookmarks[bm_index]

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
						Logger:Log["Label ${bm_iterator.Value.Label} exists more than once."]
						Logger:Log["Freighter will visit stations with the same bookmark label in a"]
						Logger:Log["random order.  Try to use unique bookmark labels in the future."]
						bm_collection:Set["${bm_iterator.Value.Label}_${Math.Rand[5000]:Inc[1000]}",${bm_iterator.Value.ID}]
					}
					else
					{
						bm_collection:Set[${bm_iterator.Value.Label},${bm_iterator.Value.ID}]
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
				SourceLocations:Queue[${bm_collection.CurrentValue.ID}]
			}
			while ${bm_collection.NextValue(exists)}
		}

		Logger:Log["BuildSourceList found ${SourceLocations.Used} source locations."]
	}
}
