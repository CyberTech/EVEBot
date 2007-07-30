objectdef obj_Station
{
	method Initialize()
	{
		call UpdateHudStatus "obj_Station: Initialized"
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
	
	function OpenHangar()
	{
		if !${This.IsHangarOpen}
		{
			call UpdateHudStatus "Opening Cargo Hangar"
			EVE:Execute[OpenHangarFloor]
			wait WAIT_CARGO_WINDOW
			while !${This.IsHangarOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}	

	function CloseHangar()
	{
		if ${This.IsHangarOpen}
		{
			call UpdateHudStatus "Closing Cargo Hangar"
			EVEWindow[hangarFloor]:Close
			wait WAIT_CARGO_WINDOW
			while ${This.IsHangarOpen}
			{
				wait 0.5
			}
			wait 10
		}
	}
	
	function Repair()
	{
		;This will need to be updated when ISXEve is capable of repairing!
		;For now it will log out to prevent us from loosing ships.
			if ${Math.Calc[(${Me.Ship.ShieldPct} + ${Me.Ship.ArmorPct})/2]} < 100
			{
			call UpdateHudStatus "We need to repair but can't at the moment, Because ISXEve needs to support it first"
			Running:Set[FALSE]
			}
	}
}