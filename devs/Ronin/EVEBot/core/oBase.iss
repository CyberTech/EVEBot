function TransferToHangar()
{
if !${Me.InStation}
      return
      
   if !${Me.Ship.IsCargoAccessible}
   {
      EVE:Execute[OpenCargoHoldOfActiveShip]
      wait 30
      EVE:Execute[OpenCargoHoldOfActiveShip]
      wait 10
    }   
    
    ; Open Hangar
    EVE:Execute[OpenHangarFloor]
    wait 25

    variable index:item MyCargo
    variable int i = 1
    variable int MyCargoCount
    MyCargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]

    ; Loop through my cargo -- Move EVERYTHING to my hangar
    do
    {
	if ${Me.Ship.Cargo[${i}](exists)}
	{
		call UpdateHudStatus "Unloading Cargo[${i}]: ${Me.Ship.Cargo[${i}].Name}"
		MyCargo.Get[${i}]:MoveTo[Hangar]
		wait 15
	}
    }  
    while ${i:Inc} <= ${MyCargoCount}
    wait 20
 
    ; After everything is done ...let's clean up the stacks.
    Me.Station:StackAllHangarItems
    wait 25
}