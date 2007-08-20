function TransferToHangar()
{
    if !${Me.InStation}
      return
      
    call UpdateHudStatus "Opening Cargo Hold for hangar interaction"
    EVE:Execute[OpenCargoHoldOfActiveShip]
    wait 20
    
    ; Open Hangar
    EVE:Execute[OpenHangarFloor]
    wait 25
    variable index:item MyCargo
    variable int i = 1
    variable int MyCargoCount
    MyCargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
    call UpdateHudStatus "MyCargo Populated, Size: ${MyCargoCount}"
    do
   	{
   	  call UpdateHudStatus "CargoItem: ${i} is CategoryID: ${MyCargo.Get[${i}].CategoryID}"
			if (${MyCargo.Get[${i}].CategoryID} == 25 || ${MyCargo.Get[${i}].CategoryID} == 4)
			{
				call UpdateHudStatus "Unloading Cargo ${i}: ${MyCargo.Get[${i}].Name}"
				MyCargo.Get[${i}]:MoveTo[Hangar]
				wait 25
			}
    }  
    while ${i:Inc} <= ${MyCargoCount}
    EVEBOT_TotalRuns:Inc
    wait 20
 
    ; After everything is done ...let's clean up the stacks.
    Me.Station:StackAllHangarItems
    wait 25
    
    call UpdateHudStatus "Hangar Interaction Completed..."
    call UpdateHudStatus "Closing ship cargo hold."
  	EVE:Execute[OpenCargoHoldOfActiveShip] 
  	wait 5
}
