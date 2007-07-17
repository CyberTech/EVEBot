function TransferToHangar()
{
	if !${Me.InStation}
      		return
      
   	while !${Me.Ship.IsCargoAccessible}
   	{
		call UpdateHudStatus "Opening Cargo"
      		EVE:Execute[OpenCargoHoldOfActiveShip]
      		wait 20
    	}   
    
	call UpdateHudStatus "Opening Hangar"
    	EVE:Execute[OpenHangarFloor]
	waitframe
    	wait 15
  
    	variable index:item MyCargo
    	variable int i = 1
    	variable int MyCargoCount
    	MyCargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
   
	call UpdateHudStatus "Cargo Count: ${MyCargoCount}"

	do
    	{
 		while ${Me.Ship.Cargo[${i}](exists)}
		{
			call UpdateHudStatus "Moving ${i}: ${Me.Ship.Cargo[${i}].Name}"
			wait 15
			Me.Ship.Cargo[${i}]:MoveTo[Hangar]
		}
       		wait 15
    	}  
    	while ${i:Inc} <= ${MyCargoCount}

   	wait 20
	call UpdateHudStatus "Stacking All in Hangar"
	Me.Station:StackAllHangarItems
	waitframe
	wait 30
}