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
	
	/* When this flag is set to TRUE the hauler should return to base */
	variable bool m_abort
	
	method Initialize(string player, string corp)
	{	
		m_abort:Set[FALSE]
		
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

	member:int NearestMatchingJetCan()
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
	method Initialize(string player, string corp)
	{
		This[parent]:Initialize[${player},${corp}]		
		
		if ${m_playerName.Length} 
		{
			call UpdateHudStatus "obj_OreHauler: Initialized. Hauling for ${m_playerName}."	
		}
		elseif ${m_corpName.Length} 
		{
			call UpdateHudStatus "obj_OreHauler: Initialized. Hauling for ${m_corpName}."	
		}
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
	
	function LootEntity(int id)
	{
		variable index:item ContainerCargo
		variable int ContainerCargoCount
		variable int i = 1
		variable int quantity
		variable float volume

		echo "DEBUG: obj_OreHauler.LootEntity ${id}"
		
		i:Set[1]
		ContainerCargoCount:Set[${Entity[${id}].GetCargo[ContainerCargo]}]
		do
		{
			quantity:Set[${ContainerCargo.Get[${i}].Quantity}]
			volume:Set[${ContainerCargo.Get[${i}].Volume}]
			echo "DEBUG: ${quantity}"
			echo "DEBUG: ${volume}"
			if (${quantity} * ${volume}) > ${Ship.CargoFreeSpace}
			{
				quantity:Set[${Ship.CargoFreeSpace} / ${volume}]
				echo "DEBUG: ${quantity}"
			}
			ContainerCargo.Get[${i}]:MoveTo[MyShip,${quantity}]
			wait 30
			
			echo "DEBUG: ${Ship.CargoFreeSpace} ... ${Ship.CargoMinimumFreeSpace}"
			if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace}
			{
				break
			}
		}
		while ${i:Inc} <= ${ContainerCargoCount}

		Me.Ship:StackAllCargo
		wait 50
		
	}

	/* The MoveToField function is being used in place of */
	/* a WarpToGang function.  The target belt is hard-   */
	/* coded for now.                                     */
	function MoveToField(bool ForceMove)
	{
		variable int curBelt
		variable index:entity Belts
		variable iterator BeltIterator
	
		EVE:DoGetEntities[Belts,GroupID,9]
		Belts:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			if ${ForceMove} || ${BeltIterator.Value.Distance} > 25000
			{
				; We're not at a field already, so find one
				curBelt:Set[1]
				call UpdateHudStatus "Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"
				call Ship.WarpToID ${Belts[${curBelt}]}
				This.UsingMookMarks:Set[TRUE]
				This.LastBeltIndex:Set[${curBelt}]
			}
			else
			{
				call UpdateHudStatus "Staying at Asteroid Belt: ${BeltIterator.Value.Name}"
			}		
		}
		else
		{
			echo "ERROR: oMining:Mine --> No asteroid belts in the area..."
			play:Set[FALSE]
			return
		}
	}

	function Haul()
	{
		variable int id
		variable int count
		
		m_abort:Set[FALSE]
		
		call This.MoveToField FALSE
	
		call Ship.OpenCargo
		
		/* wait in belt until cargo full or agressed */
		while !${This.m_abort} && \
				${Ship.CargoFreeSpace} >= ${Ship.CargoMinimumFreeSpace}
		{				
			id:Set[${This.NearestMatchingJetCan}]

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
			
			/* only loot cans every 10 minutes */
			count:Set[0]
			while ${count} < 60		/* 60 * 10 seconds = 10 minutes */
			{
				wait 100
				count:Inc
				
				if ${Me.GetTargetedBy} > 0
				{
					call UpdateHudStatus "Hauler is under attack!  Bug out."
					m_abort:Set[TRUE]
					forcedreturn	/* cause the state machine to return us to base */
					break
				}
			}			
		}		
		
		call UpdateHudStatus "Done hauling."
	
		call Ship.CloseCargo
	}
}