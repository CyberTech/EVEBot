;; Declare all script or global variables here
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
variable(script) index:int  NewCargoToTransfer
variable(script) int MaxSalvageRange
variable(script) int MaxTractorRange
variable(script) int WrecksCount
variable(script) index:entity Wrecks
variable(script) int MaxTargets
variable(script) int MaxTargetRange
variable(script) int TargetCount
variable(script) index:entity Targets
variable(script) bool ContinueOn
variable(script) index:entity Cans
variable(script) int CanCount
variable(script) int EntityCargoCount
variable(script) index:item EntityCargo
variable(script) collection:int ProcessedEntities
variable(script) collection:int CargoholdLoot
variable(script) bool LibraryInitialized

variable(script) string EVELootingFileName
variable(script) bool CheckLootItemDB
variable(script) settingsetref LootItemsDB
variable(script) filepath EVELootingFilePath

function InitializeLibrary(bool LootCans)
{
	if (${LootCans})
	{
		EVELootingFilePath:Set["${Script.CurrentDirectory}/../config/"]
		EVELootingFileName:Set[${EVELootingFilePath}EVEIgnoreLootingItems.xml]
	 
		LavishSettings:AddSet[Loot Items Database]
		LavishSettings[Loot Items Database]:Clear
		LavishSettings[Loot Items Database]:AddComment["This is your 'ignore' list while looting.  Items set to TRUE will be ignored and therefore NOT looted."]
		LavishSettings[Loot Items Database]:AddSet[${Me.Name}]
		LavishSettings[Loot Items Database]:Import[${EVELootingFileName}]
		
		LootItemsDB:Set[${LavishSettings[Loot Items Database].FindSet[${Me.Name}]}]		
	}
	
	LibraryInitialized:Set[TRUE]
	return
}

function GetModulesInformation(bool LootCans)
{
	variable int k = 1
	TractorBeams:Clear
	Salvagers:Clear
	Afterburners:Clear
	
	;; This function is always called when using the EVESalvageLibrary, so initialize it the first time it's called
	if !${LibraryInitialized}
		call InitializeLibrary ${LootCans}

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

function OpenCargo()
{
	if !${EVEWindow[MyShipCargo](exists)}
	{
		echo "Opening Ship Cargohold"
		EVE:Execute[OpenCargoHoldOfActiveShip]
		wait 15
		while !${EVEWindow[MyShipCargo](exists)}
		{
			wait 0.5
		}
		wait 10
	}
}

function CloseCargo()
{
	if ${EVEWindow[MyShipCargo](exists)}
	{
		echo "Closing Ship Cargohold"
		EVEWindow[MyShipCargo]:Close
		wait 15
		while ${EVEWindow[MyShipCargo](exists)}
		{
			wait 0.5
		}
		wait 10
	}
}

function CheckForLoot()
{
	variable int i = 1
	variable int k
	variable int j
	
  CanCount:Set[${EVE.GetEntities[Cans,Cargo Container]}]
  
  if ${CanCount} > 0
  {
  	echo "- Looting: ${CanCount} cargo containers found, processing..."
	 	
	 	do
	 	{
			if (${Me.GetTargets} == ${MaxTargets})
				{
				  echo "-- Max Targets reached (${MaxTargets}): holding..."
					do
					{
						wait 30
					}
					while (${Me.GetTargets} == ${MaxTargets})
				}	
				
				; Make sure we're not already targetting this can...
				TargetCount:Set[${Me.GetTargets[Targets]}]
				k:Set[1]
				if ${TargetCount} > 0
				{
				 	do
				 	{
				 		if ${Targets.Get[${k}].ID} == ${Cans.Get[${i}].ID}
				 		{
				 		   i:Inc
				 		   continue
				 		}		
				 		wait 2
				 	}
				 	while ${k:Inc} <= ${TargetCount}
				}
				
				; Make sure we own this can
				if (!${Cans.Get[${i}].HaveLootRights})
				{
					i:Inc
					continue
				}	 	
				
				; If we've already processed this can, then we want to ignore it.
				if (${ProcessedEntities.Element[${Cans.Get[${i}].ID}](exists)})
				{
					i:Inc
					continue
				}
	 	
	 			ProcessedEntities:Set[${Cans.Get[${i}].ID},1]
				echo "-- Processing: ${Cans.Get[${i}].Name}"
				;;; Target
				if (${Cans.Get[${i}].Distance} > ${MaxTargetRange})
				{
				  echo "--- Can too far away to target -- Approaching..."
					Cans.Get[${i}]:Approach
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
					while (${Cans.Get[${i}].Distance} > ${MaxTargetRange})
				}
				Cans.Get[${i}]:LockTarget
				do
				{
				 	wait 15
				}
				while ${Me.GetTargeting} > 0
				
				wait 15
				Cans.Get[${i}]:MakeActiveTarget
				wait 7
				
				;;; Tractor...or else approach and wait for can to be in distance ;;;;;;;;
				if ${Cans.Get[${i}].Distance} > 1300
				{
				  echo "--- Can too far away to loot -- Tractoring..."
					if ${Cans.Get[${i}].Distance} > ${MaxTractorRange}
					{
					  echo "--- Can too far away to tractor -- Approaching..."
						Cans.Get[${i}]:Approach
						if (${AfterburnerCount} > 0)
						{
					    if (${Cans.Get[${i}].Distance} > 10000)
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
						while (${Cans.Get[${i}].Distance} > ${MaxTractorRange})
						wait 2
						echo "--- Can is now within tractor range -- Tractoring..."
					}

				  ;; Activate Tractor Beam...
					ContinueOn:Set[FALSE]
					do
					{
						j:Set[1]
						do
						{
							if (!${TractorBeams.Get[${j}].IsActive} && !${TractorBeams.Get[${j}].IsDeactivating} && !${ContinueOn})
							{
							  echo "---- Activating: ${TractorBeams.Get[${j}].ToItem.Name}"
								TractorBeams.Get[${j}]:Click
								
								if ${Cans.Get[${i}].Distance} > 1300
								{
									if (${AfterburnerCount} > 0)
									{
									   Cans.Get[${i}]:Approach
									   if (${Cans.Get[${i}].Distance} > 10000)
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
								ContinueOn:Set[TRUE]
								wait 5
							}	
							wait 2
						}
						while (${j:Inc} <= ${TractorBeamCount})
					}
					while !${ContinueOn}
				
					do 
					{
						wait 20
					}
					while ${Cans.Get[${i}].Distance} > 1300
				}
				
				echo "--- Can is now within loot range -- Looting..."
				if (${AfterburnerCount} > 0)
				{
				   if (${Afterburners.Get[1].IsActive})
					   Afterburners.Get[1]:Click
					 wait 2
				}				
				EVE:Execute[CmdStopShip]
		
				
				;; Loot! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				Cans.Get[${i}]:OpenCargo
				wait 30
				call OpenCargo
				call LootEntity ${Cans.Get[${i}].ID}
				echo "--- Stacking cargo..."
				Me.Ship:StackAllCargo
				if ${Cans.Get[${i}](exists)}
				{
			  	Cans.Get[${i}]:CloseCargo
			  	wait 2
			  	TargetCount:Set[${Me.GetTargets[Targets]}]
					k:Set[1]
					if ${TargetCount} > 0
					{
					 	do
					 	{
					 		if ${Targets.Get[${k}].ID} == ${Cans.Get[${i}].ID}
					 		{
					 		   Cans.Get[${i}]:UnlockTarget
					 		   break
					 		}		
					 		wait 2
					 	}
					 	while ${k:Inc} <= ${TargetCount}
					}
				}
				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				
				i:Inc
		}
	 	while ${i} <= ${CanCount}
	}
	 	
}

function DoSalvage(bool LootCans)
{
  variable int i = 1
  variable int j
  variable int k

  
	call GetModulesInformation ${LootCans}
	MaxTargets:Set[${Me.Ship.MaxLockedTargets}]
	wait 5
	MaxTargetRange:Set[${Me.Ship.MaxTargetRange}]

	WrecksCount:Set[${EVE.GetEntities[Wrecks,wreck]}]
	echo "- Salvager initialized ... ${WrecksCount} wrecks found in this area."
	
	if ${WrecksCount} == 0
	{
	   if ${LootCans}
	   		call CheckForLoot		
	   return
	}
	
	do
	{
		if (${i} <= ${WrecksCount})
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
			
			; Make sure we own this wreck
			if (${Wrecks.Get[${i}](exists)})
			{
				if (!${Wrecks.Get[${i}].HaveLootRights})
				{
					i:Inc
					continue
				}
			}
		  
		  ProcessedEntities:Set[${Wrecks.Get[${i}].ID},1]
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
			while ${Me.GetTargeting} > 0
			
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
			ContinueOn:Set[FALSE]
			do
			{
				j:Set[1]
				do
				{
					if (!${TractorBeams.Get[${j}].IsActive} && !${TractorBeams.Get[${j}].IsDeactivating} && !${ContinueOn})
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
						ContinueOn:Set[TRUE]
						wait 5
					}	
					wait 2
				}
				while (${j:Inc} <= ${TractorBeamCount})
			}
			while !${ContinueOn}
			
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
			ContinueOn:Set[FALSE]
			do
			{
				j:Set[1]
				do
				{
					if (!${Salvagers.Get[${j}].IsActive} && !${Salvagers.Get[${j}].IsDeactivating} && !${ContinueOn})
					{
					  echo "---- Activating: ${Salvagers.Get[${j}].ToItem.Name}"
						Salvagers.Get[${j}]:Click
						ContinueOn:Set[TRUE]
						wait 5
					}
					wait 5
				}
				while ${j:Inc} <= ${SalvagerCount}
			}
			while !${ContinueOn}
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			wait 10
		}
		;; END of: if ${i} <= ${WrecksCount}
		
		
		; Do any looting
		if (${LootCans})
			call CheckForLoot

		i:Set[1]
		WrecksCount:Set[${EVE.GetEntities[Wrecks,wreck]}]
		
		; Break out if there is but one wreck left and it's your target
		if (${WrecksCount} == 1)
		{
		   if (${Me.ActiveTarget.Name.Find[wreck]} > 0)
			 {
			    break
			 }
	  }
	  
	  ; Break out if there are no wrecks at all
	  if ${WrecksCount} == 0
	  	break
	  
	  ; Break out if you do not own any of the wrecks that are left
	  ContinueOnOn:Set[FALSE]
	  k:Set[1]
	  do
	  {
	  	if ${Wrecks.Get[${k}].HaveLootRights}
	  	{
	  		ContinueOn:Set[TRUE]
	  		break
	  	}
	  }
	  while ${k:Inc} <= ${WrecksCount}
	  if !${ContinueOn}
	  	break
	  
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
		
		; Make sure we aren't out of cargo space
		call CheckShipIsFull ${LootCans} 0
		
	}
	while ${WrecksCount} > 1
	
	
	;; Wait until the last wreck is finished
	if (${Me.GetTargets} > 0)
	{
	  do
	  {
	     wait 30
	  }
	  while (${Me.GetTargets} > 0)
  }
  wait 2
  
  ; Do any looting 
  if ${LootCans}
		call CheckForLoot
}

function TransferSalvagedItemsToHangar()
{	
		variable int CargoCount
	
    wait 10
		if (!${EVEWindow[MyShipCargo](exists)})
		{
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 30
		}
		if !${EVEWindow[hangarFloor](exists)}
		{
			EVE:Execute[OpenHangarFloor]
			wait 30
		}
					
		CargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
		if (${CargoCount} == 0)
		{
			EVEWindow[MyShipCargo]:Close
			wait 10
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 20
			CargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
		}					
						
		
		variable iterator ThisCargo
		
		NewCargoToTransfer:Clear[]
		MyCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			variable int GroupID
			variable string Name

			GroupID:Set[${ThisCargo.Value.GroupID}]
			Name:Set[${ThisCargo.Value.Name}]

			;echo "DEBUG: TransferSalvagedItemsToHangar: GroupID: ${GroupID} ${Name} - ${ThisCargo.Value.Quantity}"			
			switch ${GroupID}
			{
				case 754
					NewCargoToTransfer:Insert[${ThisCargo.Value}]
					break
				default
					break
			}
		}
		while ${ThisCargo:Next(exists)}

		if ${NewCargoToTransfer.Used} > 0
		{
			EVE:MoveItemsTo[NewCargoToTransfer,Hangar]
		}

		NewCargoToTransfer:Clear[]
 
    ; After everything is done ...let's clean up the stacks.
    Me:StackAllHangarItems
    wait 5
}

function TransferLootToHangar()
{	
		variable int CargoCount
	
    wait 10
		if !${EVEWindow[MyShipCargo](exists)}
		{
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 30
		}
		
		if !${EVEWindow[hangarFloor](exists)}
		{
			EVE:Execute[OpenHangarFloor]
			wait 30
		}
						
		echo "DEBUG: TransferLootToHangar: ${CargoholdLoot.Used}"		
		CargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
		if (${CargoCount} == 0)
		{
			EVEWindow[MyShipCargo]:Close
			wait 10
			EVE:Execute[OpenCargoHoldOfActiveShip]
			wait 20
			CargoCount:Set[${Me.Ship.GetCargo[MyCargo]}]
		}
		
		variable iterator ThisCargo
		
		NewCargoToTransfer:Clear
		MyCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			NewCargoToTransfer:Insert[${ThisCargo.Value}]
		}
		while ${ThisCargo:Next(exists)}

		if ${NewCargoToTransfer.Used} > 0
		{
                EVE:MoveItemsTo[NewCargoToTransfer,Hangar]
		}

		NewCargoToTransfer:Clear
 
    ; After everything is done ...let's clean up the stacks.
    Me:StackAllHangarItems
    wait 5
}

function CheckShipIsFull(bool LootCans, bool IgnoreCapacity)
{
		variable int j
		variable int k
		variable int UndockCounter
		
		;echo "DEBUG: Math.Calc[Me.Ship.CargoCapacity-Me.Ship.UsedCargoCapacity: ${Math.Calc[${Me.Ship.CargoCapacity}-${Me.Ship.UsedCargoCapacity}]}"
		;echo "DEBUG: Math.Calc[Me.Ship.CargoCapacity*0.01: ${Math.Calc[${Me.Ship.CargoCapacity}*0.01]}"
		
		if !${IgnoreCapacity}
		{
			/* salvage operation requires a minimum of 40 m^3 free */
	 		if (${Math.Calc[${Me.Ship.CargoCapacity}-${Me.Ship.UsedCargoCapacity}]} > 40)
			{
				return
			}
	 	}
	 	
	 	; else, make a temp bookmark, return us to our salvage home, unload, and go back for more
	 	echo "- Cargo Hold Full:  Returning to station to unload...
		EVE:CreateBookmark["tmp-looting"]
	  MyBookmarksCount:Set[${EVE.GetBookmarks[MyBookmarks]}]
	  
	  ; Close cargo hold!
	  if (${EVEWindow[MyShipCargo](exists)})
	  	EVEWindow[MyShipCargo]:Close
	  
		j:Set[1]
		do
		{
			if (${MyBookmarks.Get[${j}].Label.Find["Salvager Home Base"]} > 0)
			{
				if (${MyBookmarks[${j}].SolarSystemID} != ${Me.SolarSystemID})
				{
					echo "- Setting destination and activating auto pilot for return to home station"
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
	 				while ${Me.AutoPilotOn}
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
						Counter:Set[0]			
						do
						{
						   wait 20
						   Counter:Inc[20]
						   if (${Counter} > 200)
						   {
						      echo " - Docking atttempt failed ... trying again."
						      ;EVE.Bookmark[${Destination}].ToEntity:Dock
						      Entity[CategoryID,3]:Dock
						      Counter:Set[0]
						   }
						}
						while (!${Me.InStation})					
					}
				}
			}
		}
		while ${j:Inc} <= ${MyBookmarksCount}
	 	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 	
	 	
	 	;;; If we're in a station, unload all "salvaged" items and Loot ;;;;;;;;;;;;;;
	 	wait 10
	 	echo "- Unloading Salvaged Items..."
	  call TransferSalvagedItemsToHangar
	 	wait 2
	 	if ${LootCans}
	 	{
	 		echo "- Unloading Looted Items..."
	 		call TransferLootToHangar
	 	}
	 	Me.ToEntity:CloseCargo
	 	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	 
	 
		;;; Now it's time to head back out to the site
		if ${Me.InStation}
		{
		   echo "- Undocking from station..."
		   EVE:Execute[CmdExitStation]	
		   wait 150
		   UndockCounter:Set[0]
		   if (${Me.InStation})
		   {
		   		do
		   		{
		   			wait 20
		   			UndockCounter:Inc[20]
		   			if (${UndockCounter} > 300)
		   			{
		   			  echo "- Undocking atttempt failed ... trying again." 
		   				EVE:Execute[CmdExitStation]
		   				UndockCounter:Set[0]
		   			}	   			   			
		   		}
		   		while (${Me.InStation} || !${EVEWindow[Local](exists)} || !${Me.InStation(exists)})
		   }
		   wait 5
		   LeftStation:Set[TRUE]
		}
		
		if (!${EVE.Bookmark["tmp-looting"](exists)})
		{
			do
			{
				wait 10
			}
			while !${EVE.Bookmark["tmp-looting"](exists)}
		}
		
		;;; Set destination and then activate autopilot (if we're not in that system to begin with)    			
		if (${EVE.Bookmark["tmp-looting"].SolarSystemID} != ${Me.SolarSystemID})
		{
		  echo "- Setting Destination and activating auto pilot to resume salvage operation"
		  wait 5
			EVE.Bookmark["tmp-looting"]:SetDestination
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
			while ${Me.AutoPilotOn}
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
		EVE.Bookmark["tmp-looting"]:WarpTo
		wait 120
		do
		{
			wait 20
		}
		while (${Me.ToEntity.Mode} == 3)			
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	  ; delete tmp bookmark, and then we're ready to continue!
	  EVE.Bookmark["tmp-looting"]:Remove
	  
	  echo "- Cargo Hold Empty: Resuming Operations..."
	
}

function LootEntity(int EntityID)
{	

		Entity[${EntityID}]:DoGetCargo[EntityCargo]
		
		variable iterator ThisCargo
		
		EntityCargo:GetIterator[ThisCargo]
		if ${ThisCargo:First(exists)}
		do
		{
			variable string Name
			Name:Set[${ThisCargo.Value.Name}]			
			
			CheckLootItemDB:Set[${LootItemsDB.FindSetting["${Name}",FALSE]}]
			LavishSettings[Loot Items Database]:Export[${EVELootingFileName}]
			
			; If the entry in the xml is FALSE, then we want to loot it.
			if (!${CheckLootItemDB})
			{
				CargoToTransfer:Insert[${ThisCargo.Value}]
				;echo "DEBUG: CargoToTransfer.Used == ${CargoToTransfer.Used}
			}
			else
				echo "DEBUG: Ignoring ${Name}"
				
			
			;variable int TypeID
			;TypeID:Set[${ThisCargo.Value.TypeID}]
			
			;switch ${TypeID}
			;{
				; We don't want to loot metal scraps
			;	case 15331
			;		break
			;	default
			;	  CargoToTransfer:Insert[${ThisCargo.Value}]
			;		break
			;}			
		}
		while ${ThisCargo:Next(exists)}

		if ${CargoToTransfer.Used} > 0
		{
			variable iterator CargoIterator
			CargoToTransfer:GetIterator[CargoIterator]
			
			if ${CargoIterator:First(exists)}
			do
			{
			  echo "- Processing: ${CargoIterator.Value.Name}"
			  if (${CargoIterator.Value.Volume} > ${Math.Calc[${Me.Ship.CargoCapacity} - ${Me.Ship.UsedCargoCapacity}]})
			  {
			  	call CheckShipIsFull 1 1	
			  	continue
				}
			
			  if (${Math.Calc[${CargoIterator.Value.Quantity} * ${CargoIterator.Value.Volume}]} > ${Math.Calc[${Me.Ship.CargoCapacity} - ${Me.Ship.UsedCargoCapacity}]})
			  {
				  CargoIterator.Value:MoveTo[MyShip,${Math.Calc[${Math.Calc[${Me.Ship.CargoCapacity} - ${Me.Ship.UsedCargoCapacity}]} / ${CargoIterator.Value.Volume}]}]
					CargoholdLoot:Set[${CargoIterator.Value.ID},1]
					;echo "DEBUG: Added ${CargoIterator.Value.ID} to CargoholdLoot (CargoholdLoot Used now: ${CargoholdLoot.Used})"
				  wait 20
				}
				else
				{
				  CargoIterator.Value:MoveTo[MyShip]
				  CargoholdLoot:Set[${CargoIterator.Value.ID},1]
				  ;echo "DEBUG: Added ${CargoIterator.Value.ID} to CargoholdLoot (CargoholdLoot Used now: ${CargoholdLoot.Used})"
				  wait 20
				}	
				
				call CheckShipIsFull 1 0			
			}
			while ((${CargoIterator:Next(exists)}) && (${Me.Ship.UsedCargoCapacity} < ${Me.Ship.CargoCapacity}))
			wait 10
		}

		CargoToTransfer:Clear[]
    wait 5
}