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
}