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
		
	method Initialize()
	{			
		UI:UpdateConsole["obj_Hauler: Initialized"]
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
	/* This variable is set by a remote event.  When it is non-zero, */
	/* the bot will undock and seek out the gang memeber.  After the */
	/* member's cargo has been loaded the bot will zero this out.    */
	variable int m_gangMemberID
	variable int m_jetCanID

	/* the bot logic is currently based on a state machine */
	variable string CurrentState
	variable int FrameCounter
	
	variable bool m_CheckedCargo
	
	method Initialize(string player, string corp)
	{
		m_gangMemberID:Set[-1]
		m_jetCanID:Set[-1]
		m_CheckedCargo:Set[FALSE]
		UI:UpdateConsole["obj_OreHauler: Initialized"]
		Event[OnFrame]:AttachAtom[This:Pulse]
		This:SetupEvents[]
		BotModules:Insert["Hauler"]
	}

	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if !${Config.Common.BotModeName.Equal[Hauler]}
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
		Event[EVEBot_Miner_Full]:DetachAtom[This:MinerFull]
	}

	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		This[parent]:SetupEvents[]
		/* override any events setup by the base class */

		LavishScript:RegisterEvent[EVEBot_Miner_Full]
		Event[EVEBot_Miner_Full]:AttachAtom[This:MinerFull]
	}
	
	/* A miner's jetcan is full.  Let's go get the ore.  */
	method MinerFull(string haulParams)
	{
		echo "DEBUG: obj_OreHauler:MinerFull... ${haulParams}"
		
		variable int charID = -1
		variable int itemID = -1
		
		charID:Set[${haulParams.Token[1,","]}]
		itemID:Set[${haulParams.Token[2,","]}]
		
		echo "DEBUG: obj_OreHauler:MinerFull... ${charID} ${itemID}"

		m_gangMemberID:Set[${charID}]
		m_jetCanID:Set[${itemID}]		
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
				Call Dock
				break
			case BASE
				if !${m_CheckedCargo}
				{
					call Cargo.TransferOreToHangar
					m_CheckedCargo:Set[TRUE]
				}
				break
			case COMBAT
				UI:UpdateConsole["FIRE ZE MISSILES!!!"]
				call ShieldNotification
				break
			case HAUL
				UI:UpdateConsole["Hauling"]
				m_CheckedCargo:Set[FALSE]
				call Ship.Undock
				call This.Haul
				break
			case CARGOFULL
				call Dock
				break
			case RUNNING
				UI:UpdateConsole["Running Away"]
				call Dock
				EVEBot.ReturnToStation:Set[FALSE]
				break
		}	
	}
	
	method SetState()
	{
		if ${EVEBot.ReturnToStation} && !${Me.InStation}
		{
			This.CurrentState:Set["ABORT"]
			return
		}
	
		if ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
			return
		}
	
		if ${m_gangMemberID} > 0
		{
		 	This.CurrentState:Set["HAUL"]
			return
		}
		
		if ${Me.InStation} && ${m_gangMemberID} <= 0
		{
	  		This.CurrentState:Set["BASE"]
	  		return
		}
		
		if (${Me.ToEntity.ShieldPct} < ${MinShieldPct})
		{
			This.CurrentState:Set["COMBAT"]
			return
		}
					
		if ${Ship.CargoFreeSpace} < ${Ship.CargoMinimumFreeSpace} || ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["CARGOFULL"]
			m_gangMemberID:Set[-1]
			m_jetCanID:Set[-1]		
			return
		}
	
		This.CurrentState:Set["Unknown"]
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
		if ${Config.Hauler.HaulerMode.Equal["Service Gang Members"]}
		{
			UI:UpdateConsole["Hauler moving to gang member"]
		}		
	}

	function Haul()
	{		
		if ${m_gangMemberID} > 0 && ${m_jetCanID} > 0
		{
			UI:UpdateConsole["Warping to gang member."]
			Gang:WarpToGangMember[${m_gangMemberID}]
			call Ship.WarpWait

			call Ship.OpenCargo
			
			if ${Entity[${m_jetCanID}](exists)}
			{
				UI:UpdateConsole["Found can."]
				call This.ApproachEntity ${m_jetCanID}
				Entity[${m_jetCanID}]:OpenCargo
				wait 30	
				call This.LootEntity ${m_jetCanID}
				if ${Entity[${m_jetCanID}](exists)}
				{
					Entity[${m_jetCanID}]:CloseCargo
				}					
			}
			
			/* TODO: add code to loot and salvage any nearby wrecks */
		}
		
		UI:UpdateConsole["Done hauling."]
		
		EVEBot.ReturnToStation:Set[TRUE]
		m_gangMemberID:Set[-1]
		m_jetCanID:Set[-1]		
		call Ship.CloseCargo
	}	
}

