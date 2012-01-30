/*
	JetCan Class

	Interacting with jetcans in space
	All of this is also applicable to secure cargo containers in space
	Most of this will be applicable to wrecks as well, however some things, like window name, will need to change.

	-- CyberTech

		Jane (speaking): It is a game isn’t it Mary Poppins?

		Mary Poppins (speaking) : Well, it depends on your point of view. You see…

		(kinda, sing-speaking)In every job that must be done
		There is an element of fun
		You find the fun and snap!
		The job’s a game

		(now singing)
		And every task you undertake
		Becomes a piece of cake
		A lark! A spree! It’s very clear to see that…

		A Spoonful of sugar helps the medicine go down
		The medicine go down
		The medicine go down
		Just a spoonful of sugar helps the medicine go down
		In a most delightful way

		(Robin starts Whistling)

		A robin feathering his nest
		Has very little time to rest
		While gathering his bits of twine and twig
		Though quite intent in his pursuit
		He has a merry tune to toot
		He knows a song will move the job along

		(Robin whistles a bit with Mary)

		For a Spoonful of sugar helps the medicine go down
		The medicine go down
		Medicine go down
		Just a spoonful of sugar helps the medicine go down
		In a most delightful way

		[Interlude where all the toys go about putting themselves away as the children snap and the Robin whistles away. This is perhaps the longest part of the song and always makes me think the song is longer than it really is]

		The honey bees that fetch the nectar
		From the flowers to the comb
		Never tire of ever buzzing to and fro
		Because they take a little nip
		From every flower that they sip
		And hence (Mary’s reflection echoes: And hence),
		They find (Mary’s reflection echoes: They find)
		(together) Their task is not a grind.

		(the reflection alone) Aaaaaaaaaaaaaaaaaaaaaaaaaaah!
		(Mary spoken to the mirror) Cheeky! (now to the children) Don’t be all day about it please

		Michael (yelling from inside the closet): Let me out! Let me out!

		Mary (spoken to the toys): Well, that was very… Thank you now… Will you quite finish! Thank you.

BUGS:

*/

objectdef obj_JetCan
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable int64 ActiveCan = -1
	variable set FullCans

	method Initialize()
	{
		UI:UpdateConsole["obj_JetCan: Initialized", LOG_MINOR]
	}

	; Returns -1 for no can, or the entity ID
	member:int64 CurrentCan(bool CheckFreeSpace = FALSE)
	{
		if (${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)})
		{
			if ((${Entity[${This.ActiveCan}].Distance} >= LOOT_RANGE) || \
				(${CheckFreeSpace} && ${This.CargoFull[${This.ActiveCan}]}))
			{
				/* The can we WERE using is full, or has moved out of range; notify the hauler(s) */
				Miner:NotifyHaulers[]
				This.FullCans:Add[${This.ActiveCan}]
			}
			else
			{
				return ${This.ActiveCan}
			}
		}

		if ${This.ActiveCan} > 0
		{
			/* The can no longer exists, since we passed above checks, so try to compensate for an Eve bug and close the loot window for it. */
			EVEWindow[loot_${This.ActiveCan}]:Close
		}

		variable index:entity Cans
		variable iterator Can
		EVE:QueryEntities[Cans, "GroupID = GROUPID_CARGO_CONTAINER && Distance <= LOOT_RANGE"]

		Cans:GetIterator[Can]

		if ${Can:First(exists)}
		{
			do
			{
				if (${Can.Value.ID(exists)} && \
					${Can.Value.ID} > 0 && \
					${This.AccessAllowed[${Can.Value.ID}]} && \
					${Can.Value.ID} != ${This.ActiveCan} && \
					${Can.Value.Distance} <= LOOT_RANGE) && \
					!${This.FullCans.Contains[${Can.Value.ID}]}
				{
					This.ActiveCan:Set[${Can.Value.ID}]
					return ${This.ActiveCan}
				}
			}
			while ${Can:Next(exists)}
		}
		else
		{
			This.FullCans:Clear
		}

		This.ActiveCan:Set[-1]
		return ${This.ActiveCan}
	}

	member:bool IsReady(bool CheckFreeSpace = FALSE)
	{
		if ${This.CurrentCan[${CheckFreeSpace}]} > 0
		{
			return TRUE
		}

		return FALSE
	}

	member:bool AccessAllowed(int64 ID)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${Entity[${ID}](exists)}
		{
			return FALSE
		}

		variable int OwnerID = ${Entity[${ID}].OwnerID}

		if ${Entity[${ID}].HaveLootRights}
		{
			return TRUE
		}

		return FALSE
	}

	function WaitForCan()
	{
		variable int Counter
		while !${This.IsReady}
		{
			echo "JetCan:WaitForCan Waiting"
			wait 20
			Counter:Inc[2]
			if ${Counter} > 30
			{
				UI:UpdateConsole["JetCan:WaitForCan timed out waiting for a can to appear (30 seconds)", LOG_CRITICAL]
				return
			}
		}

	}

	method Rename(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.AccessAllowed[${ID}]}
		{
			UI:UpdateConsole["JetCan:Rename: Access to ${ID} is not allowed", LOG_CRITICAL]
			return
		}

		variable string NewName

		switch ${Config.Miner.JetCanNaming}
		{
			case 1
				NewName:Set[${Me.Corp.Ticker} ${EVE.Time[short]}]
				break
			case 2
				NewName:Set[${Me.Corp.Ticker}:${EVE.Time[short]}]
				break
			case 3
				NewName:Set[${Me.Corp.Ticker}_${EVE.Time[short]}]
				break
			case 4
				NewName:Set[${Me.Corp.Ticker}.${EVE.Time[short]}]
				break
			case 5
				NewName:Set[${Me.Corp.Ticker}]
				break
			case 6
				NewName:Set[${EVE.Time[short]}]
				break
			case 7
				NewName:Set[${Me.Name.Token[1, " "]} ${EVE.Time[short]}]
				break
			case 8
				NewName:Set[${Me.Name.Token[1, " "]}]
				break
			case 9
				NewName:Set[${Me.Name}]
				break
			default
				NewName:Set[${Me.Name}]
				break
		}

		UI:UpdateConsole["JetCan:Rename: Renaming can to ${NewName}"]
		Entity[${ID}]:SetName[${NewName}]
	}

	method StackAllCargo(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return
		}

		if !${This.AccessAllowed[${ID}]}
		{
			UI:UpdateConsole["JetCan:StackAllCargo: Access to ${ID} is not allowed", LOG_CRITICAL]
			return
		}

		Entity[${ID}]:StackAllCargo
	}

	member IsCargoOpen(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if ${Entity[${ID}].LootWindow(exists)}
		{
			return TRUE
		}
		else
		{
			return FALSE
		}
	}

	member:float CargoCapacity(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		/* TODO: hard coded capacity b/c of isxeve cargocapcity breakage */
		;return ${Entity[${ID}].CargoCapacity}
		return 27500
	}

	member:float CargoMinimumFreeSpace(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		return ${Math.Calc[${This.CargoCapacity}*0.05]}
	}

	member:float CargoFreeSpace(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		if ${Entity[${ID}].UsedCargoCapacity} < 0
		{
			return ${This.CargoCapacity}
		}
		return ${Math.Calc[${This.CargoCapacity}-${Entity[${ID}].UsedCargoCapacity}]}
	}

	member:bool CargoFull(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		if ${This.CargoFreeSpace[${ID}]} <= ${This.CargoMinimumFreeSpace[${ID}]}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool CargoHalfFull(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		if ${This.CargoFreeSpace[${ID}]} <= ${Math.Calc[${This.CargoCapacity}*0.50]}
		{
			return TRUE
		}
		return FALSE
	}

	function Open(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if ${This.IsCargoOpen[${ID}]}
		{
			return
		}

		if !${This.AccessAllowed[${ID}]}
		{
			UI:UpdateConsole["JetCan:Open: Access to ${ID} is not allowed", LOG_CRITICAL]
			return
		}

		if !${This.IsCargoOpen} && \
			${Entity[${ID}](exists)}
		{
			UI:UpdateConsole["Opening JetCan"]
			Entity[${ID}]:OpenCargo
			wait WAIT_CARGO_WINDOW

			variable float TimeOut = 0
			while !${This.IsCargoOpen[${ID}]}
			{
				TimeOut:Inc[0.5]
				if ${TimeOut} > 20
				{
					UI:UpdateConsole["JetCan.Open timed out (40 seconds)", LOG_CRITICAL]
					break
				}
				wait 5
			}
			wait 10
		}
	}

	function Close(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if ${This.IsCargoOpen[${ID}]}
		{
			UI:UpdateConsole["Closing JetCan"]
			Entity[${ID}]:CloseCargo
			Entity[${ID}]:CloseStorage
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen[${ID}]}
			{
				wait 1
			}
			wait 10
		}
	}
}

objectdef obj_CorpHangarArray inherits obj_JetCan
{
	; Returns -1 for no can, or the entity ID
	member:int CurrentCan(bool CheckFreeSpace = FALSE)
	{
		if (${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)})
		{
			if ${CheckFreeSpace} && ${This.CargoFull[${This.ActiveCan}]}
			{
				;UI:UpdateConsole["oops... Corporate Hangar Array is full. I have no solution for this!", LOG_CRITICAL]

				/* TODO - when we can properly check the cargo full state of pos hangers, remove this */
				return ${This.ActiveCan}
			}
			else
			{
				return ${This.ActiveCan}
			}
		}

		if ${This.ActiveCan} > 0
		{
			/* The can no longer exists, since we passed above checks, so try to compensate for an Eve bug and close the loot window for it. */
			/* We don't worry about it for corp hangar arrays, it'll close when we warp away */
			/* TODO - get name in case we do want to ever close it */
			;EVEWindow[loot_${This.ActiveCan}]:Close
		}

		variable index:entity Cans
		variable iterator Can
		EVE:QueryEntities[Cans, "GroupID = GROUP_CORPORATEHANGARARRAY"]

		Cans:GetIterator[Can]

		if ${Can:First(exists)}
		{
			do
			{
				if (${Can.Value.ID(exists)} && \
					${Can.Value.ID} > 0 && \
					${This.AccessAllowed[${Can.Value.ID}]} && \
					${Can.Value.ID} != ${This.ActiveCan})
				{
					This.ActiveCan:Set[${Can.Value.ID}]
					return ${This.ActiveCan}
				}
			}
			while ${Can:Next(exists)}
		}


		This.ActiveCan:Set[-1]
		return ${This.ActiveCan}
	}

	member IsCargoOpen(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if ${Entity[${ID}].StorageWindow(exists)}
		{
			return TRUE
		}
		else
		{
			return FALSE
		}
	}

	member:float CargoCapacity(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		/* TODO: hard coded capacity b/c of isxeve cargocapcity breakage */
		;return ${Entity[${ID}].CargoCapacity}
		return 1400000
	}

	member:bool AccessAllowed(int64 ID)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${Entity[${ID}](exists)}
		{
			return FALSE
		}

		if ${Entity[${ID}].Corp.ID} == ${Me.Corp.ID}
		{
			return TRUE
		}

		return FALSE
	}
}

objectdef obj_SpawnContainer inherits obj_JetCan
{
	; Returns -1 for no can, or the entity ID
	member:int64 CurrentCan(bool CheckFreeSpace = FALSE)
	{
		if (${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)})
		{
			return ${This.ActiveCan}
		}

		if ${This.ActiveCan} > 0
		{
			/* The can no longer exists, since we passed above checks, so try to compensate for an Eve bug and close the loot window for it. */
			EVEWindow[loot_${This.ActiveCan}]:Close
		}

		variable index:entity Cans
		variable iterator Can
		EVE:QueryEntities[Cans, "GroupID = GROUPID_SPAWN_CONTAINER"]

		Cans:GetIterator[Can]

		if ${Can:First(exists)}
		{
			do
			{
				if (${Can.Value.ID(exists)} && \
					${Can.Value.ID} > 0 && \
					${Can.Value.ID} != ${This.ActiveCan})
				{
					This.ActiveCan:Set[${Can.Value.ID}]
					return ${This.ActiveCan}
				}
			}
			while ${Can:Next(exists)}
		}


		This.ActiveCan:Set[-1]
		return ${This.ActiveCan}
	}

	member:float CargoCapacity(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		/* TODO: hard coded capacity b/c of isxeve cargocapcity breakage */
		;return ${Entity[${ID}].CargoCapacity}
		return 1400000
	}

}

objectdef obj_LargeShipAssemblyArray inherits obj_JetCan
{
	; Returns -1 for no can, or the entity ID
	member:int64 CurrentCan(bool CheckFreeSpace = FALSE)
	{
		if (${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)})
		{
			if ${CheckFreeSpace} && ${This.CargoFull[${This.ActiveCan}]}
			{
				;UI:UpdateConsole["oops... Corporate Hangar Array is full. I have no solution for this!", LOG_CRITICAL]

				/* TODO - when we can properly check the cargo full state of pos hangers, remove this */
				return ${This.ActiveCan}
			}
			else
			{
				return ${This.ActiveCan}
			}
		}

		if ${This.ActiveCan} > 0
		{
			/* The can no longer exists, since we passed above checks, so try to compensate for an Eve bug and close the loot window for it. */
			/* We don't worry about it for corp hangar arrays, it'll close when we warp away */
			/* TODO - get name in case we do want to ever close it */
			;EVEWindow[loot_${This.ActiveCan}]:Close
		}

		variable index:entity Cans
		variable iterator Can
		EVE:QueryEntities[Cans, "TypeID = TYPEID_LARGE_ASSEMBLY_ARRAY"]

		Cans:GetIterator[Can]

		if ${Can:First(exists)}
		{
			do
			{
				if (${Can.Value.ID(exists)} && \
					${Can.Value.ID} > 0 && \
					${This.AccessAllowed[${Can.Value.ID}]} && \
					${Can.Value.ID} != ${This.ActiveCan})
				{
					This.ActiveCan:Set[${Can.Value.ID}]
					return ${This.ActiveCan}
				}
			}
			while ${Can:Next(exists)}
		}


		This.ActiveCan:Set[-1]
		return ${This.ActiveCan}
	}

	member:float CargoCapacity(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		/* TODO: hard coded capacity b/c of isxeve cargocapcity breakage */
		;return ${Entity[${ID}].CargoCapacity}
		return 18500500
	}

	member:bool AccessAllowed(int64 ID)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${Entity[${ID}](exists)}
		{
			return FALSE
		}

		if ${Entity[${ID}].Corp.ID} == ${Me.Corp.ID}
		{
			return TRUE
		}

		return FALSE
	}
}

objectdef obj_XLargeShipAssemblyArray inherits obj_JetCan
{
	; Returns -1 for no can, or the entity ID
	member:int64 CurrentCan(bool CheckFreeSpace = FALSE)
	{
		if (${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)})
		{
			if ${CheckFreeSpace} && ${This.CargoFull[${This.ActiveCan}]}
			{
				;UI:UpdateConsole["oops... Corporate Hangar Array is full. I have no solution for this!", LOG_CRITICAL]

				/* TODO - when we can properly check the cargo full state of pos hangers, remove this */
				return ${This.ActiveCan}
			}
			else
			{
				return ${This.ActiveCan}
			}
		}

		if ${This.ActiveCan} > 0
		{
			/* The can no longer exists, since we passed above checks, so try to compensate for an Eve bug and close the loot window for it. */
			/* We don't worry about it for corp hangar arrays, it'll close when we warp away */
			/* TODO - get name in case we do want to ever close it */
			;EVEWindow[loot_${This.ActiveCan}]:Close
		}

		variable index:entity Cans
		variable iterator Can
		EVE:QueryEntities[Cans, "TypeID = TYPEID_XLARGE_ASSEMBLY_ARRAY"]

		Cans:GetIterator[Can]

		if ${Can:First(exists)}
		{
			do
			{
				if (${Can.Value.ID(exists)} && \
					${Can.Value.ID} > 0 && \
					${This.AccessAllowed[${Can.Value.ID}]} && \
					${Can.Value.ID} != ${This.ActiveCan})
				{
					This.ActiveCan:Set[${Can.Value.ID}]
					return ${This.ActiveCan}
				}
			}
			while ${Can:Next(exists)}
		}


		This.ActiveCan:Set[-1]
		return ${This.ActiveCan}
	}

	member:float CargoCapacity(int64 ID=0)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${This.IsCargoOpen[${ID}]}
		{
			return FALSE
		}

		/* TODO: hard coded capacity b/c of isxeve cargocapcity breakage */
		;return ${Entity[${ID}].CargoCapacity}
		return 18500500
	}

	member:bool AccessAllowed(int64 ID)
	{
		if (${ID} == 0 && ${This.ActiveCan} > 0)
		{
			ID:Set[${This.ActiveCan}]
		}

		if !${Entity[${ID}](exists)}
		{
			return FALSE
		}

		if ${Entity[${ID}].Corp.ID} == ${Me.Corp.ID}
		{
			return TRUE
		}

		return FALSE
	}
}
