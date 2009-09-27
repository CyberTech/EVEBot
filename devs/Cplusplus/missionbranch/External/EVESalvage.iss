;; Declare all script or global variables here
variable(script) int NumSalvageLocations
variable(script) index:bookmark MyBookmarks
variable(script) int MyBookmarksCount
variable(script) bool LeftStation
variable(script) bool SalvagerHomeBaseFound
variable(script) int Counter
variable(script) bool SalvageYardFound
variable(script) bool DoLoot
variable(script) index:string SalvageLocationLabels
variable(script) index:fleetmember MyFleet
variable(script) int MyFleetCount
variable(script) int FleetIterator
variable(script) bool FoundThem
variable(script) bool UsingAt
variable(script) bool StopAfterSalvaging


;; INCLUDE FUNCTION LIBRARY
#include "EVESalvageLibrary.iss"

function atexit()
{
 	echo "EVE Salvager Script -- Ended"
	return
}

function main(... Args)
{
  variable int i = 1
  variable int j = 1
  variable int k = 1
  variable int WaitCount = 0
  variable int Iterator = 1

  SalvageYardFound:Set[FALSE]
  LeftStation:Set[FALSE]
  DoLoot:Set[FALSE]
  UsingAt:Set[FALSE]
  StopAfterSalvaging:Set[FALSE]

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

  echo " \n \n \n** EVE Salvager 3.2 Script by Amadeus ** \n \n"

  ; 'Args' is an array ... arrays are static.  Copying to an index just in case we have a desire at some point to add/remove elements.
	if ${Args.Size} > 0
	{
		do
		{
			if (${Args[${Iterator}].Equal[-LOOT]} || ${Args[${Iterator}].Equal[-loot]})
				DoLoot:Set[TRUE]
			elseif (${Args[${Iterator}].Equal[-AT]} || ${Args[${Iterator}].Equal[-at]})
			{
				UsingAt:Set[TRUE]
				Iterator:Inc
				Me.Fleet:GetMembers[MyFleet]
				MyFleetCount:Set[${MyFleet.Used}]

				if ${MyFleetCount} <= 0
				{
				    echo "- Sorry -- you cannot clear a field 'at' someone that is not in your fleet."
				    echo "- Aborting script"
				    return
				}
				FoundThem:Set[FALSE]
				do
			    {
			        if (${MyFleet.Get[${FleetIterator}].ToPilot.Name.Find[${Args[${Iterator}]}]} > 0)
			        {
			           FoundThem:Set[TRUE]
			           break
			        }
			    }
			    while ${FleetIterator:Inc} <= ${MyFleetCount}

			    if !${FoundThem}
			    {
			        echo "- There does not seem to be a fleet member with the name '${Args[${Iterator}]}'..."
			        echo "- Aborting script"
			        return
			    }

			}
			elseif (${Args[${Iterator}].Equal[-STOP]} || ${Args[${Iterator}].Equal[-stop]})
    			StopAfterSalvaging:Set[TRUE]
			elseif ${EVE.Bookmark[${Args[${Iterator}]}](exists)}
				SalvageLocationLabels:Insert[${Args[${Iterator}]}]
			else
				echo "- '${Args[${Iterator}]}' is not a valid Bookmark label or command line argument:  Ignoring..."
		}
		while ${Iterator:Inc} <= ${Args.Size}
	}

  if (${Args.Size} <= 1)
  {
  	echo "* Syntax:  'run EVESalvage <bookmarklabel1> <bookmarklabel2> ...'"
  	echo "*          'run EVESalvage -at <FleetMemberName>"
  	echo "*"
  	echo "* Flags:   '-loot'  (the script will loot all cans that are found in space)"
  	echo "*          '-stop'  (the script will stop after the last wreck is handled and will not return to the base/location from which you started)"
  	return
  }

  if ${DoLoot}
  	echo "- The Salvager will loot cans as it goes."
  else
  	echo "- The Salvager will *NOT* loot cans as it goes."

  MyBookmarksCount:Set[${EVE.GetBookmarks[MyBookmarks]}]

  ;;; For use with the -at flag
  if ${UsingAt}
  {
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
		   Counter:Set[0]
		   if (${Me.InStation})
		   {
		   		do
		   		{
		   			wait 20
		   			Counter:Inc[20]
			   			if (${Counter} > 300)
			   			{
			   			  echo "- Undocking attempt failed ... trying again."
			   				EVE:Execute[CmdExitStation]
			   				Counter:Set[0]
			   			}
		   		}
		   		while (${Me.InStation} || !${EVEWindow[Local](exists)} || !${Me.InStation(exists)})
		   }
		   wait 5
		   LeftStation:Set[TRUE]
		}
		wait 1
	}

	echo "- Warping to '${MyFleet.Get[${FleetIterator}].ToPilot.Name}' for salvage operation..."
	MyFleet.Get[${FleetIterator}]:WarpTo
	do
	{
		wait 20
	}
	while (${Me.ToEntity.Mode} == 3)

    wait 10
	call DoSalvage ${DoLoot}

	; Remove bookmark now that we're done
	wait 2
	echo "- Salvage operation at '${MyFleet.Get[${FleetIterator}].ToPilot.Name}' complete..."
  }

  ; Checks required for using bookmarks...
  if (!${UsingAt})
  {
      if ${MyBookmarksCount} == 0
      {
        echo "- Sorry, you do not appear to have any bookmarks!"
        return
      }
  }


  ;;; Loop for use with bookmarks...we skip this if using -at ;;;;;;;
  if !${UsingAt}
  {
      NumSalvageLocations:Set[${SalvageLocationLabels.Used}]
      do
      {
      	j:Set[1]
        do
        {
    		if (${MyBookmarks.Get[${j}].Label.Find[${SalvageLocationLabels[${i}]}]} > 0)
    		{
    		  SalvageYardFound:Set[TRUE]
    	      if (!${SalvageYardFound})
    	      {
                 echo "- Sorry, no bookmarks were found that matched the arguments given."
                 return
    	      }
    	      else
    	      {
    	         echo "- Salvage location found in bookmarks: (${SalvageLocationLabels[${i}]})..."
    		  }


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
       			   Counter:Set[0]
       			   if (${Me.InStation})
       			   {
       			   		do
       			   		{
       			   			wait 20
       			   			Counter:Inc[20]
    				   			if (${Counter} > 300)
    				   			{
    				   			  echo "- Undocking atttempt failed ... trying again."
    				   				EVE:Execute[CmdExitStation]
    				   				Counter:Set[0]
    				   			}
       			   		}
       			   		while (${Me.InStation} || !${EVEWindow[Local](exists)} || !${Me.InStation(exists)})
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
    		MyBookmarks[${j}]:WarpTo
    		wait 120
    		do
    		{
    			wait 20
    		}
    		while (${Me.ToEntity.Mode} == 3)

            wait 10
    		call DoSalvage ${DoLoot}

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
  }
  ; Loop for use with bookmarks ENDS ;;;;;;;;;;;;;;;;;;;



  if (${StopAfterSalvaging})
    return

  ;;; Finished...returning home ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  echo "- Salvage operations completed .. returning to home base"
  if (${EVEWindow[MyShipCargo](exists)})
  	EVEWindow[MyShipCargo]:Close
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


 	;;; unload all "salvaged" items to hangar ;;;;;;;;;;;;;;
  wait 10
  echo "- Unloading Salvaged Items..."
 	call TransferSalvagedItemsToHangar
 	wait 2
 	if (${DoLoot})
 	{
 		echo "- Unloading Looted Items..."
 		call TransferLootToHangar
 	}
 	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 	; Remove the "Salvager Home Base" bookmark  (it's created each time the script is run)
 	EVE.Bookmark["Salvager Home Base"]:Remove

  return
}
