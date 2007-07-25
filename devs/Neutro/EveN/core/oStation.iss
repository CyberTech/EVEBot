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

function TransferToCan()
{
	variable int j = 0
	; The name we want our container to have
	variable string ContainerName = "CopypasteCan${j}"
	variable index:item MyCargo
	variable int i = 0

	variable int MyCargoCount
	MyCargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
 
   ; Loop through my cargo -- I want to jettison the first thing that is of CategoryID 25 (Asteroid).
   ; Then, I want to add all of the other items that match that CategoryID to the container that was created.
   do
   {
      if (${MyCargo.Get[${i}].CategoryID} == 25)
      {
         if (!${Entity[${ContainerName}](exists)} || ${Entity[${ContainerName}].Distance} > 1500)
         {
            MyCargo.Get[${i}]:Jettison
			j:Inc
			ContainerName:Set["CopypasteCan${j}"]
            wait 2
            do
            {
              wait 15
            }
            while !${Entity["Cargo Container"](exists)}
            wait 5
            Entity["Cargo Container"]:SetName[${ContainerName}]
            wait 20            
            ; Always open the cargo container window
            Entity[${ContainerName}]:OpenCargo
            wait 30             
         }            
         else
         {
            ;echo Moving ${MyCargo.Get[${i}].Name} to ${Entity[${ContainerName}].ID}
            MyCargo.Get[${i}]:MoveTo[${Entity[${ContainerName}].ID}]
            wait 10
         }  
      } 
   }
   while ${i:Inc} <= ${MyCargoCount}
 
   ; After everything is done ...let's clean up the stacks.
   Entity[${ContainerName}]:StackAllCargo
   
   ;Broadcast the entityID to the transporter
   Triolet:AddCan[${Entity[${ContainerName}].ID}]
   ;,${Entity[${ContainerName}].Name},${LavishScript.RunningTime}
   
   ; Close the cargo container's cargo window if it's still open
   Entity[${ContainerName}]:CloseCargo
   wait 30    
}

function TransferToHauler(string ContainerName)
{
   variable index:item ContainerCargo
   variable int ContainerCargoCount
   variable int i = 1
 
   ; Make sure that there is actually a cargo container there that matches the name we set
   if (!${Entity[${ContainerName}](exists)})
   {
      echo No Entities in the area that match the name you provided.
      return
   }
 
   ; If it exists, get close enough to it!
   if (${Entity[${ContainerName}].Distance} > 1300)
   {
      Entity[${ContainerName}]:Approach
      do
      {
        wait 20
      }
      while ${Entity[${ContainerName}].Distance} > 1300
   }
 
   ; Always open the cargo container window
   Entity[${ContainerName}]:OpenCargo
   wait 30 
 
   ContainerCargoCount:Set[${Entity[${ContainerName}].GetCargo[ContainerCargo]}]
 
   do
   {
      ContainerCargo.Get[${i}]:MoveTo[MyShip]
      wait 15
   }
   while ${i:Inc} <= ${ContainerCargoCount}
   
   ;lets delete this can from the index
   Triolet.CanList:Remove[1]
   Triolet.CanList:Collapse
   
   ; After everything is looted...let's clean up our Cargo
   Me.Ship:StackAllCargo
   
   ; Now close the cargo window (if it's still open)
   Entity[${ContainerName}]:CloseCargo
   wait 5
}