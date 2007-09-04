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
	variable int ActiveCan = -1
	
	method Initialize()
	{
		UI:UpdateConsole["obj_JetCan: Initialized"]
	}
	
	; Returns -1 for no can, or the entity ID
	member:int CurrentCan()
	{
		if ${This.ActiveCan} > 0 && \
			${Entity[${This.ActiveCan}](exists)} && \
			${Entity[${This.ActiveCan}].Distance} <= LOOT_RANGE)
		{
			return ${This.ActiveCan}
		}

		variable int CanID = ${Entity[GroupID, GROUPID_CARGO_CONTAINER, Radius, LOOT_RANGE].ID}
		if (${CanID(exists)} && \
			${CanID} > 0 && \
			${This.AccessAllowed[${CanID}]})
		{
			This.ActiveCan:Set[${CanID}]
			return ${CanID}
		}
		
		This.ActiveCan:Set[-1]
		return ${This.ActiveCan}
	}
	
	member:bool IsReady()
	{
		if ${This.CurrentCan} > 0
		{
			return TRUE
		}

		return FALSE
	}
	
	member:bool AccessAllowed(int ID)
	{
		if ${ID} == 0 && \
			${This.ActiveCan} > 0
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
	
	method Rename(int ID)
	{
		if ${ID} == 0 && \
			${This.ActiveCan} > 0
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
	
	method StackAllCargo(int ID)
	{
		if !${This.IsCargoOpen}
		{
			return
		}
		
		if ${ID} == 0 && \
			${This.ActiveCan} > 0
		{
			ID:Set[${This.ActiveCan}]
		}
		
		if !${This.AccessAllowed[${ID}]}
		{
			UI:UpdateConsole["JetCan:StackAllCargo: Access to ${ID} is not allowed"]
			return
		}
		
		Entity[${ID}]:StackAllCargo
	}

	member IsCargoOpen(int ID)
	{
		if ${ID} == 0 && \
			${This.ActiveCan} > 0
		{
			ID:Set[${This.ActiveCan}]
		}
		
		/* if ${EVEWindow[ByCaption, WINDOW_CONTAINER](exists)} */
		if ${Entity[${ID}].LootWindow(exists)}
		{
			return TRUE
		}
		else
		{
			return FALSE
		}		
	}
	
	function Open(int ID=0)
	{
		if ${This.IsCargoOpen}
		{
			return
		}
		
		if ${ID} == 0 && \
			${This.ActiveCan} > 0
		{
			ID:Set[${This.ActiveCan}]
		}
		
		if !${This.AccessAllowed[${ID}]}
		{
			UI:UpdateConsole["JetCan:Open: Access to ${ID} is not allowed"]
			return
		}

		if !${This.IsCargoOpen}
		{
			UI:UpdateConsole["Opening JetCan"]
			Entity[${ID}]:OpenCargo
			wait WAIT_CARGO_WINDOW
			while !${This.IsCargoOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}	

	function Close(int ID=0)
	{
		if ${This.IsCargoOpen}
		{
			return
		}
		
		if ${ID} == 0 && \
			${This.ActiveCan} > 0
		{
			ID:Set[${This.ActiveCan}]
		}

		if ${This.IsCargoOpen}
		{
			UI:UpdateConsole["Closing JetCan"]
			Entity[${ID}]:CloseCargo
			wait WAIT_CARGO_WINDOW
			while ${This.IsCargoOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}	
}
