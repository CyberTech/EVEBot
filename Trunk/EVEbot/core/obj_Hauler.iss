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
	
	method Initialize(string player, string corp)
	{	
		if (${player.Length} && ${corp.Length})
		{
			echo "ERROR: obj_Hauler:Initialize -- cannot use a player and a corp name.  One must be blank"
		}
		else
		{			
			if ${player.Length}
			{
				m_playerName:Set[${player}]
			}
			
			if ${corp.Length}
			{
				m_corpName:Set[${corp}]
			}
			
			if (!${player.Length} && !${corp.Length})
			{
				echo "WARNING: obj_Hauler:Initialize -- player and corp name are blank.  Defaulting to Me.Corporation"
				m_corpName:Set[${Me.Corporation}]
			} 
		}
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
}

objectdef obj_OreHauler inherits obj_Hauler
{
	method Initialize(string player, string corp)
	{
		This[parent]:Initialize[${player},${corp}]		
	}

	method Shutdown()
	{
		Event[Docked]:DetachAtom[This:ShipDocked]
		Event[Undocked]:DetachAtom[This:ShipUndocked]				
		Event[Warping]:DetachAtom[This:ShipWarping]	
		Event[Stopped]:DetachAtom[This:ShipStopped]	
		Event[UnderAttack]:DetachAtom[This:ShipUnderAttack]	
		Event[TestEvent]:DetachAtom[This:TestEventHandler]	
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]
		
		/* override any events setup by the base class */
		Event[Docked]:AttachAtom[This:ShipDocked]
		Event[Undocked]:AttachAtom[This:ShipUndocked]	
		Event[Warping]:AttachAtom[This:ShipWarping]	
		Event[Stopped]:AttachAtom[This:ShipStopped]	
		Event[UnderAttack]:AttachAtom[This:ShipUnderAttack]	
		Event[TestEvent]:AttachAtom[This:TestEventHandler]	
	}
	
	/* The ship docked event handler is called when the  */
	/* ship transitions from a undocked to docked state. */
	method ShipDocked()
	{
		echo "DEBUG: obj_OreHauler:ShipDocked..."
	}
	
	/* The ship docked event handler is called when the  */
	/* ship transitions from a docked to undocked state. */
	method ShipUndocked()
	{
		echo "DEBUG: obj_OreHauler:ShipUndocked..."
	}

	/* The ship docked event handler is called when the  */
	/* ship transitions from a stopped to a warping state. */
	method ShipWarping()
	{
		echo "DEBUG: obj_OreHauler:ShipWarping..."
	}

	/* The ship docked event handler is called when the  */
	/* ship transitions from a warping to a stopped state. */
	method ShipStopped()
	{
		echo "DEBUG: obj_OreHauler:ShipStopped..."
	}

	/* The ship docked event handler is called when the  */
	/* ship comes under attack. */
	method ShipUnderAttack()
	{
		echo "DEBUG: obj_OreHauler:ShipUnderAttack..."
	}

	method TestEventHandler()
	{
		echo "DEBUG: obj_OreHauler:TestEventHandler..."
	}
	
	method ApproachEntity(int id)
	{
		if ${Entity[${id}](exists)}
		{
			while ${Entity[${id}].Distance} > 1200
			{
				call Ship.Approach ${id}			
			}
		}
		EVE:Execute[CmdStopShip]
		wait 50		
	}
	
	method LootEntity(int id)
	{
	}

	method GoPickupOre()
	{
		variable index:item ContainerCargo
		variable int ContainerCargoCount
		variable int i = 1
		variable string tempString
		
		variable index:int JetCan
		variable int JetCanCount
		variable int JetCanCounter = 1
			
		Asteroids:CheckBeltBookMarks[]
		call Asteroids.MoveToField FALSE
	
		call Ship.OpenCargo
		
		while ${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
		{				
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
	 					if ${tempString} != ${m_playerName}
	 					{
		 					continue
	 					}
	 				}
	 				elseif ${m_corpName.Length} 
	 				{
	 					tempString:Set[${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.Corporation}]
	 					echo "DEBUG: corp ${tempString}"
	 					if ${tempString} != ${m_corpName}
	 					{
		 					continue
	 					}
	 				}
	 				else
	 				{
	 					continue
	 				}
	 				
	 				/* if we get here we found a match */
	 				This:ApproachEntity[${JetCan.Get[${JetCanCounter}]}]
					Entity[${JetCan.Get[${JetCanCounter}]:OpenCargo
					wait 30	
					This:LootEntity[${JetCan.Get[${JetCanCounter}]}]
					if ${Entity[${JetCan.Get[${JetCanCounter}](exists)}
					{
						Entity[${JetCan.Get[${JetCanCounter}]:CloseCargo
					}					
					if ${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
					{
						break
					}
				}
				else
				{
					echo "No jetcans found"
				}
			}
			while ${JetCanCounter:Inc} <= ${JetCanCount}
		}		
		
		call UpdateHudStatus "Cargo Hold has reached threshold"
	
		call Ship.CloseCargo
	}
}