/*
	Station class

	Object to contain members related to in-station activities.

	-- CyberTech

*/

objectdef obj_EVEDB_StationID
{
#ifdef TESTCASE
	variable string CONFIG_FILE = "${Script.CurrentDirectory}/../Data/EVEDB_StationID.xml"
#else
	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_StationID.xml"
#endif
	variable string SET_NAME = "EVEDB_StationID"

	method Initialize()
	{
		LavishSettings[${This.SET_NAME}]:Remove
		Logger:Log["${This.ObjectName}: Loading database from ${This.CONFIG_FILE}", LOG_MINOR]
		LavishSettings:Import[${This.CONFIG_FILE}]
		Logger:Log["obj_EVEDB_StationID: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[${This.SET_NAME}]:Remove
	}

	member:int StationID(string stationName)
	{
		return ${LavishSettings[${This.SET_NAME}].FindSet[${stationName}].FindSetting[stationID, NOTSET]}
	}
}

objectdef obj_Station
{
	variable index:item StationCargo
	variable index:item DronesInStation

	method Initialize()
	{
		Logger:Log["obj_Station: Initialized", LOG_MINOR]
	}

	member IsHangarOpen()
	{
		if ${EVEWindow[Inventory].ChildWindow[StationItems](exists)}
		{
			EVEWindow[Inventory].ChildWindow[StationItems]:MakeActive
			return TRUE
		}
		else
		{
			return FALSE
		}
	}
	member IsCorpHangarOpen()
	{
		if ${EVEWindow[Inventory].ChildWindow[StationCorpHangars](exists)}
		{
			EVEWindow[Inventory].ChildWindow[StationCorpHangars]:MakeActive
			return TRUE
		}
		else
		{
			return FALSE
		}
	}

	member:bool Docked()
	{
		if ${EVEBot.SessionValid} && \
			!${Me.InSpace} && \
			${Me.InStation} && \
			${Me.StationID} > 0
		{
			return TRUE
		}
		return FALSE
	}

	member:bool DockedAtStation(int64 StationID)
	{
		if ${EVEBot.SessionValid} && \
			!${Me.InSpace} && \
			${Me.InStation} && \
			${Me.StationID} == ${StationID}

		{
			return TRUE
		}

		return FALSE
	}

	function OpenHangar()
	{
		if !${This.Docked}
		{
			return
		}

		if !${This.IsHangarOpen}
		{
			Logger:Log["Opening Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}

	function OpenCorpHangar()
	{
		if ${This.Docked} == FALSE
		{
			return
		}
		if !${This.IsCorpHangarOpen}
		{
			UI:UpdateConsole["Opening Corp Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsCorpHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}


	function GetStationItems()
	{
		while (${Me.InSpace} || !${Me.InStation})
		{
			Logger:Log["obj_Cargo: Waiting for InStation..."]
			wait 10
		}

		Me:GetHangarItems[This.StationCargo]

		variable iterator CargoIterator
		This.StationCargo:GetIterator[CargoIterator]

			if ${CargoIterator:First(exists)}
			do
			{
				variable int CategoryID
				variable string Name

				CategoryID:Set[${CargoIterator.Value.CategoryID}]
				;echo "${CargoIterator.Value.Name}: ${CargoIterator.Value.CategoryID}"
				Name:Set[${CargoIterator.Value.Name}]

				;echo "DEBUG: obj_Cargo:TransferToHangar: CategoryID: ${CategoryID} ${Name} - ${ThisCargo.Value.Quantity}"
				switch ${CategoryID}
				{
					default
						break
					case 18
						This.DronesInStation:Insert[${CargoIterator.Value.ID}]
				}
			}
			while ${CargoIterator:Next(exists)}
	}

	function CheckList()
	{
		;BotType Checks

		;General Checks
		;ToDo Needs to be moved, into correct classes.

		;Awaiting ISXEVE Drone Bay Support
		/*
		echo "${Config.Common.MinimumDronesInBay} > ${Ship.Drones.DronesInBay}"
		if ${Config.Common.MinimumDronesInBay} > ${Ship.Drones.DronesInBay}
		{
		call Station.OpenHangar
		call This.GetStationItems
		wait 10

			echo "${Ship.Drones.DronesInStation}"
			if ${Ship.Drones.DronesInStation} > 0
			{
			echo "${Ship.Drones.DronesInStation}"
			call Ship.Drones.StationToBay
			}

		call Cargo.CloseHolds
		}
		*/

	}

	function DockAtStation(int64 StationID)
	{
		variable int Counter = 0

		if ${Me.InStation}
		{
			Logger:Log["DockAtStation called, but we're already in station!"]
			return
		}

		Logger:Log["Docking at ${EVE.GetLocationNameByID[${StationID}]}"]

		if ${Entity[${StationID}](exists)}
		{
			if ${Entity[${StationID}].Distance} > WARP_RANGE
			{
				Logger:Log["Warping to Station"]
				call Ship.WarpToID ${StationID}
				do
				{
				   wait 30
				}
				while ${Entity[${StationID}].Distance} > WARP_RANGE
			}

			do
			{
				Entity[${StationID}]:Dock
				Logger:Log["Approaching docking range..."]
				wait 200 ${This.DockedAtStation[${StationID}]}
			}
			while (${Entity[${StationID}].Distance} > DOCKING_RANGE)

			Counter:Set[0]
			Logger:Log["In Docking Range ... Docking"]
			;Logger:Log["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			do
			{
				Entity[${StationID}]:Dock
		   		wait 30
		   		Counter:Inc[1]
		   		if (${Counter} > 20)
		   		{
					Logger:Log["Warning: Docking incomplete after 60 seconds", LOG_CRITICAL]
					Entity[${StationID}]:Dock
		      		Counter:Set[0]
		   		}
				;Logger:Log["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			}
			while !${This.DockedAtStation[${StationID}]}
			wait 75
			Logger:LogIRC["Finished Docking"]
		}
		else
		{
			Logger:Log["Station Requested does not exist!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpToNext
		}
	}

	function Dock()
	{
		variable int Counter = 0
		variable int64 StationID = ${Entity[CategoryID = CATEGORYID_STATION && Name = ${Config.Common.HomeStation}].ID}

		if ${Me.InStation}
		{
			Logger:Log["Dock called, but we're already instation!"]
			return
		}

		Logger:Log["Docking at ${StationID}:${Config.Common.HomeStation}"]

		if ${StationID} <= 0 || !${Entity[${StationID}](exists)}
		{
			Logger:Log["Warning: Home station not found, going to nearest base", LOG_CRITICAL]
			StationID:Set[${Entity[CategoryID = CATEGORYID_STATION].ID}]
		}

		if ${Entity[${StationID}](exists)}
		{
			Logger:Log["Docking at ${StationID}:${Entity[${StationID}].Name}"]
			call This.DockAtStation ${StationID}
		}
		else
		{
			Logger:Log["No stations in this system!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpToNext
		}
	}

	function Undock()
	{
		variable int Counter
		variable int64 StationID
		StationID:Set[${Me.StationID}]

		if !${Me.InStation}
		{
			Logger:Log["Undock called, but we're already undocking!"]
			return
		}

		Logger:Log["Undocking"]

		EVE:Execute[CmdExitStation]
		wait WAIT_UNDOCK
		Counter:Set[0]
		do
		{
			wait 10
			Counter:Inc[1]
			if ${Counter} > 20
			{
			   Counter:Set[0]
			   EVE:Execute[CmdExitStation]
			   Logger:Log["Undock: Unexpected failure, retrying...", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: EVEWindow[Local]=${EVEWindow[Local](exists)}", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: Me.InStation=${Me.InStation}", LOG_CRITICAL]
			   Logger:Log["Undock: Debug: Me.StationID=${Me.StationID}", LOG_CRITICAL]
			}
		}
		while ${This.Docked}

		wait 30
		Config.Common:HomeStation[${Entity[CategoryID = CATEGORYID_STATION].Name}]
		Logger:Log["Undock: Complete - Home Station set to ${Config.Common.HomeStation}"]

		Ship.RetryUpdateModuleList:Set[1]
	}

}
