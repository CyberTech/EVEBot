/* 
  Provides proxy representation of EVEWindow[Inventory]... child windows via fallthru to the ISXEVE object
  -- CyberTech

		obj_EVEWindow_Proxy inherits all members and methods of the 'eveinvchildwindow' datatype
		Inherited members:

			Capacity
			UsedCapacity
			LocationFlag
			LocationFlagID
			IsInRange
			ItemID
			HasCapacity
			Name

		Inherited methods:
			MakeActive
			OpenAsNewWindow

		Note - You can't access the fallthroughobject members/methods via This; you must use the external name of this object.

*/

objectdef obj_EVEWindow_Proxy
{
	; Prefix variables here with Inv so they have lower chance to overload eveinvchildwindow members
	variable string InvName = ""
	variable int64 InvID = -1
	variable string InvLocation = ""
	variable string EVEWindowParams = ""
	variable index:item Items

	method Initialize()
	{

	}

	method SetFallThroughParams()
	{
		EVEWindowParams:Set[""]

		if ${This.InvID} != -1
		{
			EVEWindowParams:Concat["${This.InvID}"]
		}

		if ${This.InvName.NotNULLOrEmpty}
		{
			if ${EVEWindowParams.NotNULLOrEmpty}
			{
				EVEWindowParams:Concat["\,"]
			}
			EVEWindowParams:Concat["${This.InvName}"]
		}

		if ${This.InvLocation.NotNULLOrEmpty}
		{
			if ${EVEWindowParams.NotNULLOrEmpty}
			{
				EVEWindowParams:Concat["\,"]
			}
			EVEWindowParams:Concat["${This.InvLocation}"]
		}
	}

	member:string GetFallthroughObject()
	{
		echo "EVEWindow[Inventory].ChildWindow[${EVEWindowParams}]"
		return "EVEWindow[Inventory].ChildWindow[${EVEWindowParams}]"
	}	

/*
  ~ ChildWindow[ID#]                     :: the first child with the given ID#
  ~ ChildWindow["NAME"]                  :: the first child with the given "NAME"
  ~ ChildWindow["NAME","LOCATION"]       :: the child with the given "NAME" at the given "LOCATION"
  ~ ChildWindow[ID#,"NAME"]              :: the child with the given ID# and the given "NAME"
  ~ ChildWindow[ID#,"NAME","LOCATION"]   :: the child with the given ID# and "NAME", at the given "LOCATION"

	If ID is not specified, but Name is, MyShip.ID is assumed
	Note that some window types REQUIRE an ID. These will cause an error message to be printed instead of defaulting to MyShip.ID
*/
	method SetLocation(string _Name, int64 _ID=-1, string _Location="")
	{
		This.InvID:Set[${_ID}]
		This.InvName:Set[${_Name}]
		This.InvLocation:Set[${_Location}]
		This:SetFallThroughParams[]
	}

	function Activate(int64 _ID=-1, string _Location="")
	{
		if ${_Location.NotNULLOrEmpty}
		{
			This.InvLocation:Set[${_Location}]
		}

		if ${_ID} == -1 && ${This.InvID} == -1
		{
			if ${Inventory.IDRequired.Contains[${This.InvName}]} 
			{
				UI:UpdateConsole["Inventory.${This.ObjectName}: Station or Entity ID Required for this container type", LOG_CRITICAL]
				return FALSE
			}
			if ${This.InvName.Length} == 0
			{
				UI:UpdateConsole["Inventory.${This.ObjectName}: Neither Name nor ID were specified", LOG_CRITICAL]
				return FALSE
			}

			This.InvID:Set[${MyShip.ID}]
		}
		elseif ${_ID} != -1 
		{
			This.InvID:Set[${_ID}]
		}

		if ${This.InvID} == -1
		{
			UI:UpdateConsole["Inventory.${This.ObjectName}: Error: InvID still -1", LOG_CRITICAL]
			return FALSE
		}

		This:SetFallThroughParams[]

		if !${EVEWindow[Inventory](exists)}
		{
			UI:UpdateConsole["Opening Inventory..."]
			EVE:Execute[OpenInventory]
			wait 2
		}

		if (!${${This.GetFallthroughObject}(exists)})
		{
			;UI:UpdateConsole["Inventory.${This.ObjectName}: Error: ${This.GetFallthroughObject} doesn't exist", LOG_CRITICAL]
			return FALSE
		}

		UI:UpdateConsole["\arInventory.${This.ObjectName}: Attempting ${This.GetFallthroughObject}", LOG_CRITICAL]

		Inventory.${This.ObjectName}:MakeActive
		variable int Count = 0
		wait 8
		do
		{
			if ${This.IsCurrent}
			{
				UI:UpdateConsole["\ayInventory.${This.ObjectName}: MakeActive true after ${Count} waits", LOG_CRITICAL]
				Inventory.Current:SetReference[This]
				return TRUE
			}

			; Wait 5 seconds, a tenth at a time
			wait 1
			Count:Inc
		}
		while (${Count} < 50)

		UI:UpdateConsole["\arInventory.${This.ObjectName}: MakeActive timed out: ${This.GetFallthroughObject}", LOG_CRITICAL]
		return FALSE
	}

	member:bool IsCurrent()
	{
		variable weakref MyThis = This

		if !${EVEWindow[Inventory](exists)}
		{
			return FALSE
		}

		if ${MyThis.ItemID} == ${This.InvID} && ${MyThis.Name.Equal[${This.InvName}]}
		{
			return TRUE
		}
		return FALSE
	}

	method StackAll()
	{
		UI:UpdateConsole["\arInventory.${This.ObjectName}: StackAll not implemented", LOG_CRITICAL]
	}

	/* Can be called with no params, 1, or 2.
		GetItems[]                  - This.Items will be populated
		GetItems[NULL]              - This.Items will be populated
		GetItems[<index:items var>] - Passed var will be populated
	  GetItems[NULL, "CategoryID == CATEGORYID_CHARGE"]              - This.Item will be populated and filtered by the given query
		GetItems[<index:items var>, "CategoryID == CATEGORYID_CHARGE"] - Passed var will be populated and filtered by the given query
	*/
	method GetItems(weakref ItemIndex, string QueryFilter)
	{
		variable weakref indexref

		if ${ItemIndex.Reference(exists)}
		{
			indexref:SetReference[ItemIndex]
		}
		else
		{
			indexref:SetReference[This.Items]
		}

		${This.GetFallthroughObject}:GetItems[indexref]
		if ${QueryFilter.NotNULLOrEmpty}
		{
			; TODO - replace this with the querycache
			variable uint qid
			qid:Set[${LavishScript.CreateQuery[${QueryFilter}]}]
			indexref:RemoveByQuery[${qid}, FALSE]
			indexref:Collapse
			LavishScript:FreeQuery[${qid}]
		}
	}

	method DebugPrintInvData()
	{
		variable weakref MyThis = This

		echo "Object: Inventory.${This.ObjectName}"
		echo " MyID          : ${InvID}   MyName         : ${InvName}   Location: ${InvLocation}"
		echo " ItemID        : ${MyThis.ItemID}   Name          : ${MyThis.Name}"
		echo " IsInRange     : ${MyThis.IsInRange}"
		echo " HasCapacity   : ${MyThis.HasCapacity}"
		if (${MyThis.HasCapacity})
		{
			echo " Capacity      : ${MyThis.Capacity.Precision[2]}  UsedCapacity  : ${MyThis.UsedCapacity.Precision[2]}"
		}
		if (${Current.LocationFlagID} > 0)
		{
			echo " LocationFlag  : ${MyThis.LocationFlag} LocationFlagID: ${MyThis.LocationFlagID}"
		}
	}
}

/*
	This is initialized in EVEBot as a global variable "Inventory"
	Cargos may be accessed as follows

	; Open inventory window and attempt to activate appropriate child
	; Set Inventory.Current to Inventory.Ship
	call Inventory.Ship.Activate

	; Check if Ship is current (meaning the above succeeded)
	if ${Inventory.Ship.IsCurrent} ; Note you can also test ${Return} from the Activate call
	{
		; From here you can access it as
		Inventory.Ship.Capacity
		OR
		Inventory.Current.Capacity
	}
*/
objectdef obj_Inventory
{
	variable weakref Current
	variable obj_EVEWindow_Proxy ShipCargo
	variable obj_EVEWindow_Proxy ShipFleetHangar
	variable obj_EVEWindow_Proxy ShipOreHold
	variable obj_EVEWindow_Proxy ShipDroneBay

	variable obj_EVEWindow_Proxy StationHangar
	variable obj_EVEWindow_Proxy StationCorpHangars
	variable obj_EVEWindow_Proxy CorporationDeliveries
	
	variable obj_EVEWindow_Proxy EntityContainer

	variable set IDRequired

	method Initialize()
	{
		ShipCargo:SetLocation[ShipCargo]
		ShipFleetHangar:SetLocation[ShipFleetHangar]
		ShipOreHold:SetLocation[ShipOreHold]
		ShipDroneBay:SetLocation[ShipDroneBay]
		StationHangar:SetLocation[StationItems]
		StationCorpHangars:SetLocation[StationCorpHangars]
		CorporationDeliveries:SetLocation[StationCorpDeliveries]
		;EntityContainer - Only uses ID

		IDRequired:Add["StationItems"]
		IDRequired:Add["StationCorpHangars"]
		IDRequired:Add["StationCorpDeliveries"]
	}

	method Shutdown()
	{
	}
}

/*

Notes: 
Corporation Hangars and Member Hangars are twisties only, not containers

Under Corp Member Hangar, each member
	StationCorpMember charid flagHangar 4

Ship Hangar:
	StationShips stationid flagHangar 4
Under Ship Hangar, each shiup
	ShipCargo shipid flagCargo 5

StationCorpDeliveries stationid flagCorpMarket 62


Note - each of the below also applies to the ships in the ship hangar, given the right id
ShipCargo itemid flagCargo 5
ShipOreHold itemid flagSpecializedOreHold 134
ShipFleetHangar itemid flagFleetHangar 155
ShipMaintenanceBay itemid flagShipHangar 90
ShipDroneBay itemid flagDroneBay 87


* The "container" entry within the eveinventorywindow with the label "Corporation hangars" is now accessible and must be
  made active before the individual corporation folders are available.  For example:
	if !${EVEWindow[Inventory].ChildWindowExists[StationCorpHangar]}
		EVEWindow[Inventory]:MakeChildActive[Corporation hangars]

TODO
 Find all :Open and :GetCargo or .*Cargo[..] calls for Entity-based work.

*/