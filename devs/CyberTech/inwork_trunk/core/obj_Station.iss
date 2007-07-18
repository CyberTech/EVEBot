objectdef obj_Station
{
	method Initialize()
	{
	}
	
	function OpenHangar()
	{
		call UpdateHudStatus "Opening Cargo Hangar"
		EVE:Execute[OpenHangarFloor]
		wait 25
	}	

	function CloseHangar()
	{
		call UpdateHudStatus "Closing Cargo Hangar"
		EVE:Execute[OpenHangarFloor]
		wait 25
	}	
}