/*
	Station class

	Object to contain members related to in-station activities.

	-- CyberTech

*/

objectdef obj_EVEDB_StationID
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

#ifdef TESTCASE
	variable string CONFIG_FILE = "${Script.CurrentDirectory}/../Data/EVEDB_StationID.xml"
#else
	variable string CONFIG_FILE = "${BaseConfig.DATA_PATH}/EVEDB_StationID.xml"
#endif
	variable string SET_NAME = "EVEDB_StationID"

	method Initialize()
	{
		LavishSettings[${This.SET_NAME}]:Remove
		UI:UpdateConsole["${This.ObjectName}: Loading database from ${This.CONFIG_FILE}", LOG_MINOR]
		LavishSettings:Import[${This.CONFIG_FILE}]
		UI:UpdateConsole["obj_EVEDB_StationID: Initialized", LOG_MINOR]
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
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:item StationCargo
	variable index:item DronesInStation

	method Initialize()
	{
		UI:UpdateConsole["obj_Station: Initialized", LOG_MINOR]
	}

	member IsHangarOpen()
	{
		if ${EVEWindow[hangarFloor](exists)}
		{
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

	member:bool DockedAtStation(int StationID)
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
			UI:UpdateConsole["Opening Cargo Hangar"]
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsHangarOpen}
			{
				wait 1
			}
			wait 10
		}
	}

	function CloseHangar()
	{
		if !${This.Docked}
		{
			return
		}

		if ${This.IsHangarOpen}
		{
			UI:UpdateConsole["Closing Cargo Hangar"]
			EVEWindow[hangarFloor]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsHangarOpen}
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
			UI:UpdateConsole["obj_Cargo: Waiting for InStation..."]
			wait 10
		}

		Me:DoGetHangarItems[This.StationCargo]

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
						This.DronesInStation:Insert[${CargoIterator.Value}]
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

	function DockAtStation(int StationID)
	{
		variable int Counter = 0

		if ${Me.InStation}
		{
			UI:UpdateConsole["DockAtStation called, but we're already in station!"]
			return
		}

		UI:UpdateConsole["Docking at ${EVE.GetLocationNameByID[${StationID}]}"]

		Ship:SetType[${Entity[CategoryID,CATEGORYID_SHIP].Type}]
		Ship:SetTypeID[${Entity[CategoryID,CATEGORYID_SHIP].TypeID}]

		if ${Entity[${StationID}](exists)}
		{
			if ${Entity[${StationID}].Distance} > WARP_RANGE
			{
				UI:UpdateConsole["Warping to Station"]
				call Ship.WarpToID ${StationID}
				do
				{
				   wait 30
				}
				while ${Entity[${StationID}].Distance} > WARP_RANGE
			}

			do
			{
				Entity[${StationID}]:Approach
				UI:UpdateConsole["Approaching docking range..."]
				wait 30
			}
			while (${Entity[${StationID}].Distance} > DOCKING_RANGE)

			Counter:Set[0]
			UI:UpdateConsole["In Docking Range ... Docking"]
			;UI:UpdateConsole["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			do
			{
				Entity[${StationID}]:Dock
		   		wait 30
		   		Counter:Inc[1]
		   		if (${Counter} > 20)
		   		{
					UI:UpdateConsole["Warning: Docking incomplete after 60 seconds", LOG_CRITICAL]
					Entity[${StationID}]:Dock
		      		Counter:Set[0]
		   		}
				;UI:UpdateConsole["DEBUG: StationExists = ${Entity[${StationID}](exists)}"]
			}
			while !${This.DockedAtStation[${StationID}]}
			wait 75
			UI:UpdateConsoleIRC["Finished Docking"]
		}
		else
		{
			UI:UpdateConsole["Station Requested does not exist!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpToNext
		}
	}

	function Dock()
	{
		variable int Counter = 0
		variable int StationID = ${Entity[CategoryID,3,${Config.Common.HomeStation}].ID}

		if ${Me.InStation}
		{
			UI:UpdateConsole["Dock called, but we're already instation!"]
			return
		}

		UI:UpdateConsole["Docking at ${StationID}:${Config.Common.HomeStation}"]

		Ship:SetType[${Entity[CategoryID,CATEGORYID_SHIP].Type}]
		Ship:SetTypeID[${Entity[CategoryID,CATEGORYID_SHIP].TypeID}]

		if ${StationID} <= 0 || !${Entity[${StationID}](exists)}
		{
			UI:UpdateConsole["Warning: Home station not found, going to nearest base", LOG_CRITICAL]
			StationID:Set[${Entity[CategoryID,3].ID}]
		}

		if ${Entity[${StationID}](exists)}
		{
			call This.DockAtStation ${StationID}
		}
		else
		{
			UI:UpdateConsole["No stations in this system!  Trying Safespots...", LOG_CRITICAL]
			call Safespots.WarpToNext
		}
	}

	function Undock()
	{
		variable int Counter
		variable int StationID
		StationID:Set[${Me.StationID}]

		if !${Me.InStation}
		{
			UI:UpdateConsole["Undock called, but we're already undocking!"]
			return
		}

		UI:UpdateConsole["Undocking"]

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
			   UI:UpdateConsole["Undock: Unexpected failure, retrying...", LOG_CRITICAL]
			   UI:UpdateConsole["Undock: Debug: EVEWindow[Local]=${EVEWindow[Local](exists)}", LOG_CRITICAL]
			   UI:UpdateConsole["Undock: Debug: Me.InStation=${Me.InStation}", LOG_CRITICAL]
			   UI:UpdateConsole["Undock: Debug: Me.StationID=${Me.StationID}", LOG_CRITICAL]
			}
		}
		while ${This.Docked}

		wait 30
		Config.Common:HomeStation[${Entity[CategoryID,3].Name}]
		UI:UpdateConsole["Undock: Complete - Home Station set to ${Config.Common.HomeStation}"]


		Ship:UpdateModuleList[]
		Ship:SetType[${Entity[CategoryID,CATEGORYID_SHIP].Type}]
		Ship:SetTypeID[${Entity[CategoryID,CATEGORYID_SHIP].TypeID}]
	}

}
