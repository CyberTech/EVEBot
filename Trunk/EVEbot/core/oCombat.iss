function DefendAndDestroy()
{
variable index:entity EntitiesTargetingMe
variable int i
variable int ModulenCount = 0
variable index:module Modulen
ModulenCount:Set[${Me.Ship.GetModules[Modulen]}]
   if (${ModulenCount} < 1)
   {
       UI:UpdateConsole["ERROR:  You appear to have no modules on this ship!"]
       call Dock
       wait 60
	  	 return      
   }

		UI:UpdateConsole["But I am le tired"]
		for (i:Set[1] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
		{
		UI:UpdateConsole["Well go take a nap"]
		call DeactivateLasers
		Call Orbit ${EntitiesTargetingMe.Get[${i}].ID} 1500
		Entity[${EntitiesTargetingMe.Get[${i}].ID}]:LockTarget
		wait 60
		call CombatLasers
		}
}

function CombatLasers()
{

	UI:UpdateConsole["THEN FIRE ZE MISSILES"]
	variable int ModulexCount = 0
   variable index:module Modulex
   variable int i = 1
   variable int u = 1
   declare CombatMissile int ${Me.Ship.Module[${i}].RateOfFire}
   variable index:int MyDrones
   variable int DronesInSpaceCount
   DronesInSpaceCount:Set[${EVE.GetEntityIDs[MyDrones,OwnerID,${Me.CharID},CategoryID,18]}]
   UI:UpdateConsole["THEM CHINESE SONS OF A BITCHES ARE GOING DOWN!"]
   ModulexCount:Set[${Me.Ship.GetModules[Modulex]}]
   wait 20
      
   do
   {
      if (${Me.Ship.Module[${i}].RateOfFire} > 0)
      {
          if !${Modulex.Get[${i}].IsActive}
          {	
						UI:UpdateConsole["Now we've got like Missiles flying everywhere"]
          }
          else
          {
           	UI:UpdateConsole["Firing: ${Modules.Get[${i}].ToItem.Name}"]
          	Me.Ship.Module[${i}]:Click
          	wait 5
          }
      }
      else
      {
				UI:UpdateConsole["${i} Not a combat module"]
				wait 2
      }
      wait 20
   }
   while ${i:Inc} <= ${ModulexCount}
   
 	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Small Check to see if any of our lasers actually combat types  ;
   ;; and drones in space newbs :P                                   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   do
   {
   		if (${Me.Ship.Module[${u}].RateOfFire} > 0)
      	{
      		UI:UpdateConsole["We've just comfirmed we are in combat...]
      		call InCombat
      		wait 10
      		break
      	}
      	else
      	{
      	wait 2
      	}
   	}
   	while ${u:Inc} <= ${ModulexCount}
   	
   if (${DronesInSpaceCount} > 0)
   {
    UI:UpdateConsole["We've just comfirmed we are in combat...]
   	call InCombat
   }
   else
   {			   			
   UI:UpdateConsole["Guess we don't have any combat lasers or drones"]
	 call Dock
   wait 60
   return
   }
}

function InCombat()
{
UI:UpdateConsole["So we're fighting it looks like.. now we gotta wait till this all over!"]

do
{
  wait 50
  if (${Me.Ship.StructurePct} < ${MinStructurePct})
   {
    UI:UpdateConsole["This is too risky now, we've got under ${MinStructurePct}% Structure HP"]
   	UI:UpdateConsole["Lets get out of here"]
    call Dock
    wait 50
    return
   }
}
while (${Me.GetTargets} > 0)

if (${Me.GetTargetedBy} > 0)
 {
 	UI:UpdateConsole["Something else is targeting us, lets check it out"]
 	call ShieldNotification
 }
 else
 {
 UI:UpdateConsole["Looks like we pwned some newbs.. PEW PEW!!"]
 return
 }
 
}
  
  

function ShieldNotification()
{	

	if ${Entity.Owner.Name(exists)}
	{
		UI:UpdateConsole["SHIT! We're getting owned by a player! RUN!"]
		call Dock
		wait 3000
		UI:UpdateConsole["Ok, 5 Minutes Up"]
		return
	}
	else
	{
		if (${Me.GetTargetedBy} > 0)
		{ 
			wait 10
			UI:UpdateConsole["Lets own this sucker"]
			call DefendAndDestroy
		}
		else
		{
			UI:UpdateConsole["Theres nothing targeting us!"]
			UI:UpdateConsole["Lets wait and see if our Shield Regens"]
			EVE:Execute[CmdStopShip]
		  do
		  {
			wait 20
			}
			while (${Me.Ship.ShieldPct} < 70)
			wait 10
			return
		}
	}
}

function ActivateDefense()
{
variable int i
	for (i:Set[0] ; ${i} <= 1 ; i:Inc)
	{
		if ${Me.Ship.Module[MedSlot${i}].IsActivatable}
		{
			if ${Me.Ship.Module[MedSlot${i}].IsActive}
			{
			UI:UpdateConsole["Med power slot ${i} is already active"]
			}
			else
			{
			Me.Ship.Module[MedSlot${i}]:Click
			UI:UpdateConsole["Powering up Med power slot ${i}"]
			}
		}
		
		if ${Me.Ship.Module[LoSlot${i}].IsActivatable}
		{
			if ${Me.Ship.Module[LoSlot${i}].IsActive}
			{
			UI:UpdateConsole["Low power slot ${i} is already active"]
			}
			else
			{
			Me.Ship.Module[LoSlot${i}]:Click
			UI:UpdateConsole["Powering up Low power slot ${i}"]
			}
		}
	wait 10
	}
}

function DeactivateLasers()
{
   variable int ModulesCount = 0
   variable index:module Modules
   variable int i = 1
   
   ;Already checked if we had lasers! (Hessinger)
   ModulesCount:Set[${Me.Ship.GetModules[Modules]}]

   do
   {
     if !${Modules.Get[${i}].IsActive}
      {
      wait 2
      }
      else
      {
 			UI:UpdateConsole["Deactivating Old Laser because of the way that idiot hessinger wrote our combat routine"]
      Modules.Get[${i}]:Click
      wait 5
      }
   }
   while ${i:Inc} <= ${ModulesCount}
   
}
