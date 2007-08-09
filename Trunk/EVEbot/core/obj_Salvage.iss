/*
	Wreck Salvaging (originally written by Amadeus)

BUGS:
	
			
*/

variable(script) int NumSalvageLocations
variable(script) index:bookmark MyBookmarks
variable(script) int MyBookmarksCount

variable(script) int AllModulesCount
variable(script) int TractorBeamCount
variable(script) int SalvagerCount
variable(script) int AfterburnerCount
variable(script) index:module AllModules
variable(script) index:module TractorBeams
variable(script) index:module Salvagers
variable(script) index:module Afterburners
variable(script) index:item MyCargo
variable(script) index:item CargoToTransfer
variable(script) int MaxSalvageRange
variable(script) int MaxTractorRange

variable(script) int WrecksCount
variable(script) index:entity Wrecks
variable(script) int MaxTargets
variable(script) int MaxTargetRange

variable(script) int TargetCount
variable(script) index:entity Targets

variable(script) bool LeftStation
variable(script) bool Continue
variable(script) bool SalvagerHomeBaseFound

variable(script) bool SalvageYardFound

function atexit()
{
 	echo "EVE Salvager Script -- Ended"
	return
}

function GetModulesInformation()
{
	variable int k = 1
	TractorBeams:Clear
	Salvagers:Clear
	Afterburners:Clear

	;; Determine the modules at our disposal
	echo "- Acquiring Information about your ship's modules..."
	AllModulesCount:Set[${Me.Ship.GetModules[AllModules]}]
	if (${AllModulesCount} <= 0)
	{
		echo ERROR -- Your ship does not appear to have any modules
		return
	}
	do
	{
   	if (${AllModules.Get[${k}].MaxTractorVelocity} > 0)
   	{
   	  ;echo "Adding ${AllModules.Get[${k}].ToItem.Name} to 'TractorBeams'"
			TractorBeams:Insert[${AllModules.Get[${k}]}]
			if ${MaxTractorRange} <= 0
			{
				MaxTractorRange:Set[${AllModules.Get[${k}].OptimalRange}]
				;echo "MaxTractorRange set to: ${MaxTractorRange}"
			}
   	}
   	elseif (${AllModules.Get[${k}].AccessDifficultyBonus} > 0)
   	{
   	  ;echo "Adding ${AllModules.Get[${k}].ToItem.Name} to 'Salvagers'"
   	  Salvagers:Insert[${AllModules.Get[${k}]}]
			if ${MaxSalvageRange} <= 0
			{
				MaxSalvageRange:Set[${AllModules.Get[${k}].OptimalRange}]
			}   	  
   	}
   	elseif (${AllModules.Get[${k}].MaxVelocityBonus} > 0)
   	{
   	  ;echo "Adding ${AllModules.Get[${k}].ToItem.Name} to 'Afterburners'"
   	  Afterburners:Insert[${AllModules.Get[${k}]}] 	  
   	}   	
	}
	while ${k:Inc} <= ${AllModulesCount}
	
	TractorBeamCount:Set[${TractorBeams.Used}]
	SalvagerCount:Set[${Salvagers.Used}]
	AfterburnerCount:Set[${Afterburners.Used}]
  echo "- Your ship has ${TractorBeamCount} Tractor Beams, ${SalvagerCount} Salvage Modules, and ${AfterburnerCount} Afterburner."

	return
}

function DoSalvage()
{
  variable int i = 1
  variable int j
  variable int k

  
	call GetModulesInformation
	MaxTargets:Set[${Me.Ship.MaxLockedTargets}]
	wait 5
	MaxTargetRange:Set[${Me.Ship.MaxTargetRange}]

	WrecksCount:Set[${EVE.GetEntities[Wrecks,wreck]}]
	echo "- Salvager initialized ... ${WrecksCount} wrecks found in this area."
	
	if ${WrecksCount} == 0
	{
	   return
	}
	
	do
	{
	  echo "- Processing Wrecks: ${WrecksCount} wrecks remaining"
	
		if (${Me.GetTargets} == ${MaxTargets})
		{
		  echo "-- Max Targets reached (${MaxTargets}): holding..."
			do
			{
				wait 30
			}
			while (${Me.GetTargets} == ${MaxTargets})
		}	
		
		; Make sure we're not already targetting this wreck...
		TargetCount:Set[${Me.GetTargets[Targets]}]
		k:Set[1]
		if ${TargetCount} > 0
		{
		 	do
		 	{
		 		if ${Targets.Get[${k}].ID} == ${Wrecks.Get[${i}].ID}
		 		{
		 		   i:Inc
		 		   continue
		 		}		
		 		wait 2
		 	}
		 	while ${k:Inc} <= ${TargetCount}
		}
	
	  
		echo "-- Processing: ${Wrecks.Get[${i}].Name}"
		;;; Target
		if (${Wrecks.Get[${i}].Distance} > ${MaxTargetRange})
		{
		  echo "--- Wreck too far away to target :: Approaching..."
			Wrecks.Get[${i}]:Approach
			if (${AfterburnerCount} > 0)
			{
		   		if (${Afterburners.Get[1].IsDeactivating})
		   		{
		      	do
		      	{
		      		wait 5
		      	}
		      	while ${Afterburners.Get[1].IsDeactivating}
		   		}			
			    if (!${Afterburners.Get[1].IsActive})
				   	Afterburners.Get[1]:Click
				 	wait 5
			}			
			do
			{
				wait 20
			}
			while (${Wrecks.Get[${i}].Distance} > ${MaxTargetRange})
			; EVE:Execute[CmdStopShip]
			; wait 2
		}
		

		Wrecks.Get[${i}]:LockTarget
		
		do
		{
		 	wait 15
		}
		while ${GetTargeting} > 0
		
		wait 15
		Wrecks.Get[${i}]:MakeActiveTarget
		wait 7
		
		;;; Tractor...or else approach and wait for wreck to be in distance ;;;;;;;;
		if ${Wrecks.Get[${i}].Distance} > ${Math.Calc[${MaxSalvageRange} - 250]}
		{
		  echo "--- Wreck too far away to salvage -- Tractoring..."
			if ${Wrecks.Get[${i}].Distance} > ${MaxTractorRange}
			{
			  echo "--- Wreck too far away to tractor -- Approaching..."
				Wrecks.Get[${i}]:Approach
				if (${AfterburnerCount} > 0)
				{
			    if (${Wrecks.Get[${i}].Distance} > ${Math.Calc[${MaxSalvageRange} * 2]})
			    {
				   	if (${Afterburners.Get[1].IsDeactivating})
				   	{
				      do
				      {
				      	wait 5
				      }
				      while ${Afterburners.Get[1].IsDeactivating}
				   	}
				   	if (!${Afterburners.Get[1].IsActive})
					   	Afterburners.Get[1]:Click
					 	wait 5
				 	}
			 	}
				do
				{
					wait 20
				}
				while (${Wrecks.Get[${i}].Distance} > ${MaxTractorRange})
				wait 2
				echo "--- Wreck is now within tractor range -- Tractoring..."
			}
	  }
	  
	  ;; Activate Tractor Beam...
		Continue:Set[FALSE]
		do
		{
			j:Set[1]
			do
			{
				if (!${TractorBeams.Get[${j}].IsActive} && !${TractorBeams.Get[${j}].IsDeactivating} && !${Continue})
				{
				  echo "---- Activating: ${TractorBeams.Get[${j}].ToItem.Name}"
					TractorBeams.Get[${j}]:Click
					
					if ${Wrecks.Get[${i}].Distance} > ${MaxSalvageRange}
					{
						if (${AfterburnerCount} > 0)
						{
						   Wrecks.Get[${i}]:Approach
						   if (${Wrecks.Get[${i}].Distance} > ${Math.Calc[${MaxSalvageRange} * 2]})
						   {
							   if (${Afterburners.Get[1].IsDeactivating})
							   {
							      do
							      {
							      	wait 5
							      }
							      while ${Afterburners.Get[1].IsDeactivating}
							   }
							   if (!${Afterburners.Get[1].IsActive})
								   Afterburners.Get[1]:Click
								 wait 2
							 }
						}							
					}
					Continue:Set[TRUE]
					wait 5
				}	
				wait 2
			}
			while (${j:Inc} <= ${TractorBeamCount})
		}
		while !${Continue}
		
		do 
		{
			wait 20
		}
		while ${Wrecks.Get[${i}].Distance} > ${MaxSalvageRange}
		
		echo "--- Wreck is now within salvage range -- Salvaging..."
		if (${AfterburnerCount} > 0)
		{
		   if (${Afterburners.Get[1].IsActive})
			   Afterburners.Get[1]:Click
			 wait 2
		}				
		EVE:Execute[CmdStopShip]

		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		;; Salvage ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		Continue:Set[FALSE]
		do
		{
			j:Set[1]
			do
			{
				if (!${Salvagers.Get[${j}].IsActive} && !${Salvagers.Get[${j}].IsDeactivating} && !${Continue})
				{
				  echo "---- Activating: ${Salvagers.Get[${j}].ToItem.Name}"
					Salvagers.Get[${j}]:Click
					Continue:Set[TRUE]
					wait 5
				}
				wait 5
			}
			while ${j:Inc} <= ${SalvagerCount}
		}
		while !${Continue}
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		wait 10

		i:Set[1]
		WrecksCount:Set[${EVE.GetEntities[Wrecks,wreck]}]
		if (${WrecksCount} == 1)
		{
		   if (${Me.GetTargets} == 1)
			 {
			    break
			 }
	  }
	  
	  ;; Make sure we're not running low on capacitor
	  if (${Me.Ship.CapacitorPct} <= 22)
	  {
	  	echo "- Running low on Capacitor:  Pausing...
	  	do
	  	{
	  	   wait 30
	  	}
	  	while (${Me.Ship.CapacitorPct} <= 22)
	  }
		
	}
	while ${WrecksCount} > 1
	
	
	;; Wait until the last wreck is finished
	if (${EVE.GetEntities[Wrecks,wreck]} > 0)
	{
	  do
	  {
	     wait 30
	  }
	  while (${EVE.GetEntities[Wrecks,wreck]} > 0)
  }
}

function TransferSalvagedItemsToHangar()
{	
    wait 20
		if ${EVEWindow[MyShipCargo](exists)}
		{
			EVEWindow[MyShipCargo]:Close
			wait 20
		}
		EVE:Execute[OpenCargoHoldOfActiveShip]
		wait 20
		
		Me.Ship:DoGetCargo[MyCargo]
		
		variable iterator ThisCargo
		
		MyCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			variable int GroupID
			variable string Name

			GroupID:Set[${ThisCargo.Value.GroupID}]
			Name:Set[${ThisCargo.Value.Name}]

			;echo "DEBUG: obj_Cargo:TransferToHangar: GroupID: ${GroupID} ${Name} - ${ThisCargo.Value.Quantity}"			
			switch ${GroupID}
			{
				case 754
					CargoToTransfer:Insert[${ThisCargo.Value}]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}

		if ${CargoToTransfer.Used} > 0
		{
			EVE:Execute[OpenHangarFloor]
			wait 30
			
			variable iterator CargoIterator
			CargoToTransfer:GetIterator[CargoIterator]
			
			if ${CargoIterator:First(exists)}
			do
			{
				;echo "obj_Cargo:TransferToHangar: Unloading Cargo: ${CargoIterator.Value.Name}"
				CargoIterator.Value:MoveTo[Hangar]
				wait 30
			}
			while ${CargoIterator:Next(exists)}
			wait 10
		}

		CargoToTransfer:Clear[]
 
    ; After everything is done ...let's clean up the stacks.
    Me.Station:StackAllHangarItems
    wait 5
}


function main(... SalvageLocationLabels)
{
  variable int i = 1
  variable int j = 1
  variable int k = 1
  variable int WaitCount = 0
  
  SalvageYardFound:Set[FALSE]
  LeftStation:Set[FALSE]

  if !${ISXEVE(exists)}
  {
     echo "- ISXEVE must be loaded to use this script."
     return
  }
  do
  {
     waitframe
  }
  while !${ISXEVE.IsReady}
  
  if (${SalvageLocationLabels.Size} <= 0)
  {
     echo "- Bad Syntax"
     return
  }
  
  echo " \n \n \n** EVE Salvager Script by Amadeus ** \n \n"
 
	MyBookmarksCount:Set[${EVE.GetBookmarks[MyBookmarks]}]
	if ${MyBookmarksCount} == 0
	{
		echo "- Sorry, you do not appear to have any bookmarks!"
		return
	}  
  


  ;;; Main Loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  NumSalvageLocations:Set[${SalvageLocationLabels.Size}]
  do
  {
  	j:Set[1]
    do
    {
			if (${MyBookmarks.Get[${j}].Label.Find[${SalvageLocationLabels[${i}]}]} > 0)
			{  
			  SalvageYardFound:Set[TRUE]
				echo "- Salvage location found in bookmarks: (${SalvageLocationLabels[${i}]})..."
    		
    		;;; Leave station 
    		if !${LeftStation}
    		{
	   			if ${Me.InStation}
	   			{
					   ;; First, make sure we have a bookmark labeled "Salvager Home Base" -- otherwise, create it ;;;;;;;;;;;;;
					   SalvagerHomeBaseFound:Set[FALSE]
					   do
					   {
					    	if (${MyBookmarks.Get[${k}].Label.Find["Salvager Home Base"]} > 0)
					  		{
					  			SalvagerHomeBaseFound:Set[TRUE]
					  		}
					   }
					   while ${k:Inc} <= ${MyBookmarksCount}
					
					   if !${SalvagerHomeBaseFound}
					   {
					   		echo "- Creating 'Salvager Home Base' bookmark..."
					  		EVE:CreateBookmark["Salvager Home Base"]
					  		wait 10
					 	 } 
					 	   			
	   			   echo "- Undocking from station..."
	   			   EVE:Execute[CmdExitStation]	
	   			   wait 150
	   			   if (${Me.InStation})
	   			   {
	   			   		do
	   			   		{
	   			   			wait 20
	   			   		}
	   			   		while (${Me.InStation} || !${EVEWindow[Local](exists)})
	   			   }
	   			   wait 5
	   			   LeftStation:Set[TRUE]
	   			}
	   			else
	   			   echo "- WARNING: You must be in a station to properly utilize this script."
	   			wait 1
   			}
   			
   			;;; Set destination and then activate autopilot (if we're not in that system to begin with)
   			if (${MyBookmarks[${j}].SolarSystemID} != ${Me.SolarSystemID})
   			{
   			  echo "- Setting Destination and activating auto pilot for salvage operation ${i} (${MyBookmarks.Get[${j}].Label})."
   			  wait 5
   				MyBookmarks[${j}]:SetDestination
   				wait 5
   				EVE:Execute[CmdToggleAutopilot]
					do
					{
					   wait 50
					   if !${Me.AutoPilotOn(exists)}
					   {
					     do
					     {
					        wait 5
					     }
					     while !${Me.AutoPilotOn(exists)}
					   }
					}
   					while !${Me.AutoPilotOn}
   				wait 20
   				do
   				{
   				   wait 10
   				}
   				while !${Me.ToEntity.IsCloaked}
   				wait 5
   			}
   			
   			;;; Warp to location
   			echo "- Warping to salvage location..."
    		MyBookmarks[${j}]:WarpTo
    		wait 120
    		do
    		{
    			wait 20
    		}
    		while (${Me.ToEntity.Mode} == 3)	
        
        wait 10
    		call DoSalvage
    		
    		; Remove bookmark now that we're done
    		wait 2
    		echo "- Salvage operation at '${SalvageLocationLabels[${i}]}' complete ... removing bookmark."
    		EVE.Bookmark[${SalvageLocationLabels[${i}]}]:Remove
    		wait 10
      }
    }
   	while ${j:Inc} <= ${MyBookmarksCount}
  }
  while ${i:Inc} <= ${NumSalvageLocations}
  
  
  ; No salvage locations were found..so just end the script
  if !${SalvageYardFound}
  { 
    echo "- Sorry, no bookmarks were found that matched the arguments given."
    return
  }

  
  ;;; Finished...returning home ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  echo "- Salvage operations completed .. returning to home base"	
  MyBookmarksCount:Set[${EVE.GetBookmarks[MyBookmarks]}]
	j:Set[1]
	do
	{
		if (${MyBookmarks.Get[${j}].Label.Find["Salvager Home Base"]} > 0)
		{
			if (${MyBookmarks[${j}].SolarSystemID} != ${Me.SolarSystemID})
			{
				echo "- Setting destination and activating auto pilot for return to home base"
				MyBookmarks[${j}]:SetDestination
				wait 5
				EVE:Execute[CmdToggleAutopilot]
				do
				{
				   wait 50
				   if !${Me.AutoPilotOn(exists)}
				   {
				     do
				     {
				        wait 5
				     }
				     while !${Me.AutoPilotOn(exists)}
				   }
				}
 				
 				wait 20
 				do
 				{
 				   wait 10
 				}
 				while !${Me.ToEntity.IsCloaked}
			}
   			
			;;; Warp to location
			echo "- Warping to home base location"
			MyBookmarks[${j}]:WarpTo
			wait 120
			do
			{
				wait 20
			}
			while (${Me.ToEntity.Mode} == 3)	
			wait 20
			
			;;; Dock, if applicable
			if ${MyBookmarks[${j}].ToEntity(exists)}
			{
				if (${MyBookmarks[${j}].ToEntity.CategoryID} == 3)
				{
					MyBookmarks[${j}].ToEntity:Approach
					do
					{
						wait 20
					}
					while (${MyBookmarks[${j}].ToEntity.Distance} > 50)
					
					MyBookmarks[${j}].ToEntity:Dock			
					do
					{
					   wait 20
					   WaitCount:Inc[20]
					}
					while (!${Me.InStation} && ${WaitCount} < 200)
					WaitCount:Set[0]
					if (!${Me.InStation})
					{
					  echo "- First Attempt at docking with failed...trying again."
					  Entity[CategoryID,3]:Dock
						do
						{
					  	 wait 20
					  	 WaitCount:Inc[20]
						}
						while (!${Me.InStation} && ${WaitCount} < 200)
						WaitCount:Set[0]
					}							
				}
			}
		}
	}
	while ${j:Inc} <= ${MyBookmarksCount}
 	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 	
 	
 	;;; If we're in a station, unload all "salvaged" items to hangar ;;;;;;;;;;;;;;
  if ${Me.InStation}
  {
 		call TransferSalvagedItemsToHangar
	}
 	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 	
 	; Remove the "Salvager Home Base" bookmark  (it's created each time the script is run)
 	EVE.Bookmark["Salvager Home Base"]:Remove

  return
}
