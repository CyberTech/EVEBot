/*
	The scavenger object

	The obj_Scavenger object is a bot mode designed to be used with
	obj_Freighter bot module in EVEBOT.  It warp to asteroid belts
	snag some loot and warp off.

	-- GliderPro
*/

/* obj_Scavenger is a "bot-mode" which is similar to a bot-module.
 * obj_Scavenger runs within the obj_Freighter bot-module.  It would
 * be very straightforward to turn obj_Scavenger into a independent
 * bot-module in the future if it outgrows its place in obj_Freighter.
 */
objectdef obj_Scavenger
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable bool bHaveCargo = FALSE
	variable bool bGoHome = FALSE
	variable bool bFocusSalvagers = FALSE
	variable index:entity LockedTargets
	variable int Destination
	variable int CharacterName
	variable index:bookmark MyBookmarks
	variable index:bookmark BookmarkListToSalvage
	variable iterator Target
	variable index:fleetmember MyFleet
	variable int MyFleetCount
	variable int SolarID = NULL
	variable int FleetIterator
	;variable index:bookmark 
	variable bool FoundThem
	variable int j
	variable index:int64  ItemsToMove
  	variable int WaitCount = 0
  	variable int Iterator = 1
  	variable index:bookmark BookmarksForMeToPissOn
  	variable int RoomTimer
  	variable index:int64 BookmarkIDs
	method Initialize()
	{
		UI:UpdateConsole["obj_Scavenger: Initialized", LOG_MINOR]
		LavishScript:RegisterEvent[TOSALVAGE]
		Event[TOSALVAGE]:AttachAtom[This:ToSalvage]
		CurrentState:Set["IDLE"]
		LavishScript:RegisterEvent[HERE]
		Event[HERE]:AttachAtom[This:HERE]
	}

	method Shutdown()
	{
	}
	method ToSalvage()
	{	
		if ${Config.Common.BotModeName.Equal[Freighter]}
		{
				EVEWindow[ByCaption,"People & Places"]:Close
				;PULL A LIST OF OUR CORP BMS NOW
				CurrentState:Set["SCAVENGE"]
				UI:UpdateConsole["Request received from salvager, starting operation."]
		}
	}
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
	}

	function ProcessState()
	{
		if !${Config.Common.BotModeName.Equal[Freighter]}
			return
			
		switch ${CurrentState}
		{
			case ABORT
				call Station.Dock
				break
			case SCAVENGE
				echo "SCAVENGE"
				RoomCounter:Set[0]
				call This.Scavenger
				break
			case DROPOFFTOSTATION
				call This.GoHome
				wait 100
				call Cargo.TransferCargoToHangar
				wait 20
				CurrentState:Set["SCAVENGE"]
				break
			case FLEE
				call This.Flee
				break	
			case IDLE
				break
		}
	}
	
	method Setting()
	{

	}

	method HERE(... Params)
	{
		BookmarkListToSalvage:Clear
		if ${Config.Common.BotModeName.Equal[Freighter]}
		{
			variable int i
			for (i:Set[1] ; ${i} <= ${Params.Size} ; i:Inc)
			{
				BookmarkListToSalvage:Insert[${Params[${i}]}]
			}
		}
	}

	function Scavenger()
	{
		EVEWindow[ByCaption,"People & Places"]:Close
		while ${EVEWindow[ByCaption,"People & Places"](exists)}
		{
			UI:UpdateConsole["Waiting for People & Places window to close."]
			wait 100
		}
		EVE:Execute[OpenPeopleAndPlaces]
		wait 50
		BookmarksForMeToPissOn:Clear
		EVE:GetBookmarks[BookmarksForMeToPissOn]
		BookmarksForMeToPissOn:RemoveByQuery[${LavishScript.CreateQuery[OwnerID != "${Me.Corp.ID}"]}]
		BookmarksForMeToPissOn:Collapse
		if ${BookmarksForMeToPissOn.Used} == 0
		{
			UI:UpdateConsole["No corp bookmarks found, returning."]
			CurrentState:Set["IDLE"]
			return
		}
		variable iterator itty
		BookmarksForMeToPissOn:GetIterator[itty]
		variable iterator ittyCreators
		variable index:int64 intCreators
		variable bool found
		variable iterator BookmarkID
		intCreators:GetIterator[ittyCreators]
		if ${itty:First(exists)}
		{
			cache:Set[${intCreators.Used}]
			do
			{
				if ${ittyCreators:First(exists)}
				{
					do
					{ 
						found:Set[FALSE]
						if ${ittyCreators.Value.Equal[${itty.Value.CreatorID}]}
						{
							found:Set[TRUE]
							break
						}
					}
					while ${ittyCreators:Next(exists)}
					if !${found}
					{
						intCreators:Insert[${itty.Value.CreatorID}]
					}
				}
				else
				{
					intCreators:Insert[${itty.Value.CreatorID}]
				}
			}
			while ${itty:Next(exists)}
		}
		UI:UpdateConsole["Getting list of bookmarks now."]
		if ${ittyCreators:First(exists)}
		{
			do
			{
				BookmarkIDs:Clear
				BookmarkIDs:Set[NULL]
				UI:UpdateConsole["Clearing list of bookmarks now."]
				relay all Event[WHERE]:Execute[${ittyCreators.Value}]
				UI:UpdateConsole["Just relayed request for bm."]
				wait 50
				UI:UpdateConsole["received a list of ${BookmarkListToSalvage.Used} bookmarks from missioner."]
				if ${BookmarkListToSalvage.Used} > 0
				{
					break
				}

			}
			while ${ittyCreators:Next(exists)}
		}
		BookmarkListToSalvage:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID != "${BookmarkListToSalvage[1].SolarSystemID}"]}]
		if ${BookmarkListToSalvage.Used} > 0
		{
			Destination:Set[${BookmarkListToSalvage[1].SolarSystemID}]
			UI:UpdateConsole["Heading to ${Destination}"]
			call ChatIRC.Say "Starting salvage run now."
			if !${Me.InSpace}
			{
				call Station.Undock
			}
			while !${Me.InSpace}
			{
				wait 100
			}
		}
		else
		{
			;relay all Event[QUERY]:Execute[]
			UI:UpdateConsole["No bookmarks found"]
			This.CurrentState:Set["IDLE"]
			return
		}
		;UI:UpdateConsole["${Destination "]
		if ${Me.SolarSystemID} != ${Destination}
			{
				Universe[${Destination}]:SetDestination
				while ${Me.SolarSystemID} != ${Destination}
				{
					if !${Me.AutoPilotOn}
					{
						EVE:Execute[CmdToggleAutopilot]
					}
					wait 5
				}
			}
		wait 100
		;THIS HAS TO WARP TO FIRST BM
		UI:UpdateConsole["Warping to first bookmark"]
		BookmarkListToSalvage[1]:WarpTo 
		wait 100
		while ${Me.ToEntity.Mode} == 3
		{
			wait 10
		}	
		do
		{
			while ${Me.ToEntity.Mode} == 3
			{
				wait 10
				UI:UpdateConsole["Warping, do nothing"]
			}
			UI:UpdateConsole["Starting salvage of a room now"]
			call This.SalvageSite

		}
		while ${BookmarkListToSalvage.Used} > 0
		Destinaton:Set[0]
		This.CurrentState:Set["DROPOFFTOSTATION"]
		UI:UpdateConsole["Going home!"]

	}

	function DropAtCHA()
	{
		variable index:item ContainerItems
		variable iterator CargoIterator

		; TODO - This will find the first bookmark matching this name, even if it's out of the system. This would be bad. Need to iterate and find the right one.
		if !${EVE.Bookmark[${Config.Combat.AmmoBookmark}](exists)}
		{
			UI:UpdateConsole["DroppingOffLoot: Fleeing: No ammo bookmark"]
			call This.Flee
			return
		}
		else
		{
			call Ship.WarpToBookMarkName ${Config.Combat.AmmoBookmark}
			UI:UpdateConsole["Dropping off Loot"]
			call Ship.OpenCargo
			; If a corp hangar array is on grid - drop loot
			if ${Entity["TypeID = 17621"].ID} != NULL
			{
				UI:UpdateConsole["Dropping off Loot at ${Entity["TypeID = 17621"]} (${Entity["TypeID = 17621"].ID})"]
				call Ship.Approach ${Entity[TypeID,17621].ID} 1500
				call Ship.OpenCargo
				Entity[${Entity["TypeID = 17621"].ID}]:OpenCargo

				call Cargo.TransferCargoToCorpHangarArray
				return
			}
		}
		This.CurrentState:Set["SCAVENGE"]
	}
	
	function SalvageSite()
	{
		if (${Config.Miner.StandingDetection} && \
			${Social.StandingDetection[${Config.Miner.LowestStanding}]}) || \
			!${Social.IsSafe}
		{
			call This.Flee
			return
		}
		RoomTimer:Set[${Script.RunningTime}]
		run evesalvage -here -stop -waittimevar 5
		while ${Script[Evesalvage](exists)}
		{
			wait 100
		}
		RoomTimer:Set[${Math.Calc[${Script.RunningTime}-${RoomTimer}]}]
		RoomTimer:Set[${Math.Calc[${RoomTimer}/60000]}]
		call ChatIRC.Say "Finished room, it took ${RoomTimer} minutes and ${Math.Calc[${RoomTimer}%60]} seconds. :O"
		RoomTimer:Set[0]
		UI:UpdateConsole["Deleting current old bookmark, warping to new one"]
		BookmarkListToSalvage[1]:Remove
		BookmarkListToSalvage:Remove[1]
		wait 50
		if ${BookmarkListToSalvage[2](exists)}
		{
			BookmarkListToSalvage[2]:WarpTo
		}
		else
		{
			UI:UpdateConsole["No bookmarks left. ${BookmarkListToSalvage.Used}"]
			return
		}
		while ${Me.ToEntity.Mode} != 3
		{
			wait 10
		}
		while ${Me.ToEntity.Mode} == 3
		{
			wait 100
			UI:UpdateConsole["Warping, do nothing"]
		}
		BookmarkListToSalvage:Collapse	
		
	}
	
	function Flee()
	{
		Ship:Deactivate_SensorBoost
		This.CurrentState:Set["FLEE"]
		This.Fled:Set[TRUE]

		if ${Config.Combat.RunToStation}
		{
			call This.FleeToStation
		}
		else
		{
			call This.FleeToSafespot
		}
	}

	function FleeToStation()
	{
		if !${Station.Docked}
		{
			call Station.Dock
		}
	}
	function GoHome()
	{
		variable index:item Items
		variable iterator Item
		MyShip:GetCargo[Items]
		Items:GetIterator[Item]
		variable index:string Contraband
		variable iterator ittyContraband
		Contraband:Insert["Crystal Egg"]
		Contraband:Insert["X-Instinct"]
		Contraband:Insert["Exile"]
		Contraband:Insert["Vitoc"]
		Contraband:Insert["Blue Pill"]
		Contraband:Insert["Drop"]
		Contraband:Insert["Mindflood"]
		Contraband:Insert["Sooth Sayer"]

		wait 1
		Contraband:GetIterator[ittyContraband]
		if ${Item:First(exists)}
		do
		{
			if ${ittyContraband:First(exists)}
			{
				do 
				{
					if ${Item.Value.Name.Equal[${ittyContraband.Value}]}
						{
							echo "Contraband found"
							if !${Entity[Name =- "Cargo Container"](exists)}
								{
									Item.Value:Jettison
									echo "Jettisoning Contraband"
									wait 50
								}
							else	
							{
								Entity[Name =- "Cargo Container"]:OpenCargo
								Item.Value:MoveTo[${Entity[Name =- "Cargo Container"].ID}]
								wait 20
							}
						}
				}
				while ${ittyContraband:Next(exists)}
			}
		}
		while ${Item:Next(exists)}
		EVEWindow[ByName,${MyShip.ID}]:StackAll
		EVE:GetBookmarks[MyBookmarks]
		j:Set[1]
		do
		{
			if (${MyBookmarks.Get[${j}].Label.Find["SHB"]} > 0)
			{
				if (!${MyBookmarks[${j}].SolarSystemID.Equal[${Me.SolarSystemID}]})
				{
					echo "- Setting destination and activating auto pilot for return to home base"
					MyBookmarks[${j}]:SetDestination
					wait 5
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
				}
				else
				{
					;;; Warp to location
					echo "- Warping to home base location"
					MyBookmarks[${j}]:WarpTo
					wait 120
					do
					{
						wait 20
					}
					while (${Me.ToEntity.Mode} == 3)
					wait 20
		
					;;; Dock, if applicable
					if ${MyBookmarks[${j}].ToEntity(exists)}
					{
						if (${MyBookmarks[${j}].ToEntity.CategoryID} == 3)
						{
							MyBookmarks[${j}].ToEntity:Approach
							do
							{
								wait 20
							}
							while (${MyBookmarks[${j}].ToEntity.Distance} > 50)
		
							MyBookmarks[${j}].ToEntity:Dock
							Counter:Set[0]
							do
							{
							   wait 20
							   Counter:Inc[20]
							   if (${Counter} > 200)
							   {
							      echo " - Docking atttempt failed ... trying again."
							      ;EVE.Bookmark[${Destination}].ToEntity:Dock
							      Entity[CategoryID = 3]:Dock
							      Counter:Set[0]
							   }
							}
							while (!${Me.InStation})
						}
					}
				}
			}
	}
	while ${j:Inc} <= ${MyBookmarks.Used}
 	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


 	;;; unload all "salvaged" items to hangar ;;;;;;;;;;;;;;
	}

	function FleeToSafespot()
	{
		if ${Safespots.IsAtSafespot}
		{
			if !${Ship.IsCloaked}
			{
				Ship:Activate_Cloak[]
			}
		}
		else
		{
			if ${Me.ToEntity.Mode} != 3
			{
				call Safespots.WarpTo
				wait 30
			}
		}
	}
}

