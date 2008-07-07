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

	method Initialize()
	{
		UI:UpdateConsole["obj_Scavenger: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}
	
	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${EVEBot.ReturnToStation} && !${_Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${_Me.Ship.UsedCargoCapacity} <= ${Config.Miner.CargoThreshold}
		{
		 	This.CurrentState:Set["SCAVENGE"]
			return
		}		
	    elseif ${_Me.Ship.UsedCargoCapacity} > ${Config.Miner.CargoThreshold}
		{
			This.CurrentState:Set["DROPOFF"]
			return
		}
		else
		{
			UI:UpdateConsole["obj_Scavenger: ERROR!  Unknown State."]
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
			case SCAVENGE
				if ${Station.Docked}
				{
					call Station.Undock
				}
				wait 10
				call Asteroids.MoveToRandomBeltBookMark
				wait 10
				call This.WarpToFirstNonEmptyWreck
				wait 10
				call This.LootClosestWreck
				break
			case DROPOFF
				call Station.Dock
				wait 100
				call Cargo.TransferCargoToHangar
				wait 100
				break
			case IDLE
				break
		}	
	}
	
	function WarpToFirstNonEmptyWreck()
	{
		variable index:entity Wrecks
		variable iterator     Wreck

		EVE:DoGetEntities[Wrecks,GroupID,GROUPID_WRECK]
		UI:UpdateConsole["obj_Scavenger: DEBUG: Found ${Wrecks.Used} wrecks."]

		Wrecks:GetIterator[Wreck]
		if ${Wreck:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Scavenger: DEBUG: ${Wreck.Value.ID} ${Wreck.Value.Distance} ${Wreck.Value.IsWreckEmpty}"]
				if ${Wreck.Value(exists)} && ${Wreck.Value.Distance} > WARP_RANGE && ${Wreck.Value.IsWreckEmpty} == FALSE
				{
					call Ship.WarpToID ${Wreck.Value.ID}
					return
				}
			}
			while ${Wreck:Next(exists)}
		}
	}

	function LootClosestWreck()
	{
		variable index:entity Wrecks
		variable iterator     Wreck
		variable index:item   Items
		variable iterator     Item
		variable index:int    ItemsToMove
		variable float        TotalVolume = 0
		variable float        ItemVolume = 0

		/* only look for wrecks within 3000 meters */
		EVE:DoGetEntities[Wrecks,GroupID,GROUPID_WRECK,Radius,3000]
		Wrecks:GetIterator[Wreck]
		if ${Wreck:First(exists)}
		{
			do
			{
				if ${Wreck.Value(exists)} && ${Wreck.Value.IsWreckEmpty} == FALSE
				{
					call Ship.Approach ${Wreck.Value.ID} LOOT_RANGE
					Wreck.Value:OpenCargo
					wait 10				
					call Ship.OpenCargo
					wait 10				
					Wreck.Value:DoGetCargo[Items]
					UI:UpdateConsole["obj_Scavenger: DEBUG:  Wreck contains ${Items.Used} items."]
					
					Items:GetIterator[Item]
					if ${Item:First(exists)}
					{
						do
						{
							ItemVolume:Set[${Item.Value.Quantity} * ${Item.Value.Volume}]
							if ${Math.Calc[${ItemVolume} + ${TotalVolume}]} < ${Ship.CargoFreeSpace}				
							{
								ItemsToMove:Insert[${Item.Value.ID}]
								TotalVolume:Set[${Math.Calc[${ItemVolume} + ${TotalVolume}]}]
							}
						}
						while ${Item:Next(exists)}
					}
					
					if ${ItemsToMove.Used} > 0
					{
						EVE:MoveItemsTo[ItemsToMove, MyShip]
						wait 10
					}

					return
				}
			}
			while ${Wreck:Next(exists)}
		}
	}
}

