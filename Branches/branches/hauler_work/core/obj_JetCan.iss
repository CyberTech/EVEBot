/*
	JetCan Class
	
	Interacting with jetcans in space
	All of this is also applicable to secure cargo containers in space
	Most of this will be applicable to wrecks as well, however some things, like window name, will need to change.
	
	-- CyberTech

BUGS:
			
*/

objectdef obj_JetCan
{
	variable int64 ActiveCan = -1
	
	method Initialize()
	{
		UI:UpdateConsole["obj_JetCan: Initialized"]
	}
	
	; Returns -1 for no can, or the entity ID
	member:int CurrentCan(bool CheckFreeSpace = FALSE)
	{
		if (${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)})
		{
			if ((${Entity[${This.ActiveCan}].Distance} >= LOOT_RANGE) || \
				(${CheckFreeSpace} && ${This.CargoFull[${This.ActiveCan}]}))
			{
				/* The can we WERE using is full, or has moved out of range; notify the hauler(s) */
				Miner:NotifyHaulers[]
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
		EVE:DoGetEntities[Cans, GroupID, GROUPID_CARGO_CONTAINER, Radius, LOOT_RANGE]
		
		Cans:GetIterator[Can]
		
		if ${Can:First(exists)}
		{
			do
			{
				if (${Can.Value.ID(exists)} && \
					${Can.Value.ID} > 0 && \
					${This.AccessAllowed[${Can.Value.ID}]} && \
					${Can.Value.ID} != ${This.ActiveCan} && \
					${Can.Value.Distance} <= LOOT_RANGE)
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

		if (${Entity[${ID}].HaveLootRights} || \
			${OwnerID} == ${Me.CharID} || \
			${Entity[${ID}].CorporationID} == ${Me.CorporationID} || \
			${Local[${OwnerID}].ToGangMember(exists)} ) 
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
				UI:UpdateConsole["JetCan:WaitForCan timed out waiting for a can to appear (30 seconds)"]
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
			UI:UpdateConsole["JetCan:Rename: Access to ${ID} is not allowed"]
			return
		}
		
		variable string NewName = "${Me.Name}"
		
		if (${Me.Corporation(exists)} && \
			${Me.Corporation.Length} > 0 )
		{
			NewName:Set["${Me.Corporation} ${EVE.Time[short]}"]
		}
		else
		{
			NewName:Set["${Me.Name} ${EVE.Time[short]}"]
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
			UI:UpdateConsole["JetCan:StackAllCargo: Access to ${ID} is not allowed"]
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

		return ${Math.Calc[${Entity[${ID}].CargoCapacity}*0.05]}
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
			return ${Entity[${ID}].CargoCapacity}
		}
		return ${Math.Calc[${Entity[${ID}].CargoCapacity}-${Entity[${ID}].UsedCargoCapacity}]}
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

		if ${This.CargoFreeSpace[${ID}]} <= ${Math.Calc[${Entity[${ID}].CargoCapacity}*0.50]}
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
			UI:UpdateConsole["JetCan:Open: Access to ${ID} is not allowed"]
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
					UI:UpdateConsole["JetCan.Open timed out (40 seconds)"]
					break
				}
				wait 0.5
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
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen[${ID}]}
			{
				wait 0.5
			}
			wait 10
		}
	}	
}
