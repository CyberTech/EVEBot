/* 
	This is my stripped down version of the combat object 
	i'm writing to try to debug it, but however because people won't 
	give me strait fucking answers. 
	I hope someone else has better luck debugging this then I did.

   to.do
   Split Targeting and Fighting
    - Add next target selecting (Right now its set up to repeat itself, will change later)
    - Put Drone Engagement into seperate function
   Break down combat into offensive and defensive objects
    - Add Outside Fighter Support
   
   Hess   
*/


objectdef obj_Combat
{
	;Target that we will be fighting
	variable bool InCombat = FALSE
	variable bool Running = FALSE
	variable int FrameCounter
		
	method Initialize()
	{	
		Event[OnFrame]:AttachAtom[This:Pulse]
		call UpdateHudStatus "obj_Combat: Initialized"
	}
	
	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}
	
	method Pulse()
	{
		FrameCounter:Inc
						
		if ${FrameCounter} >= 350
		{
			if ${InCombat}== FALSE
		 	{		 		
				if (${Me.Ship.ShieldPct} < 99 && ${Me.GetTargetedBy} > 0)
				{
					InCombat:Set[TRUE]
					call UpdateHudStatus "Entered Combat"
					call This.Fight
				}
			}
			
			if ${Running}== FALSE
			{
				if ${Math.Calc[(${Me.Ship.ShieldPct} + ${Me.Ship.ArmorPct})/2]} < 20
				{
					Call This.SafeRun
				}
			}	
			
			FrameCounter:Set[0]
		}
	}
	
	method InCombatState()
	{
		Call UpdateHudStatus "Now In Combat"
		InCombat:Set[TRUE]
	}
			
	function Fight()
	{
		variable index:entity EntitiesTargetingMe
		variable int i
		variable int CombatTarget
		
		for (i:Set[1] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
		{	
			call UpdateHudStatus "DEBUG: ${EntitiesTargetingMe.Get[${i}].ID}"
		
			Entity[${EntitiesTargetingMe.Get[${i}].ID}]:LockTarget
			;Readd check here after debug
			
			wait 70
			call UpdateHudStatus "Combat Target is Locked"
			
			Entity[${EntitiesTargetingMe.Get[${i}].ID}]:MakeActiveTarget
			
			;Readd check here after debug
			call UpdateHudStatus "Target ${EntitiesTargetingMe.Get[${i}].ID} should be active and locked"
		
		
			;Defense if we have Drones
			wait 10
			if (${Drones.DronesInSpace} > 0)
			{
  		Eve:DronesEngageMyTarget[Drones.DroneList]
  		echo "DEBUG: Engaging Target"
  		}
  		
			;Defense if we have Laser 
			;Readd after Debuging
			;call LaserCombat
			
			do
			{
				wait 10
				echo "DEBUG: We're still in combat"
			}
			while ${Entity[ID,${EntitiesTargetingMe.Get[${i}].ID}].IsLockedTarget}== FALSE
			echo "Entity[ID,${EntitiesTargetingMe.Get[${i}].ID}] Has Been Destroyed"
			
			while (${Me.GetTargetedBy} == 0) && (${Me.Ship.ShieldPct} < 99%)
			{
				wait 10
			}
			
			InCombat:Set[FALSE]
		}
	}
	
	function SafeRun()
	{
		Running:Set[TRUE]
		Call UpdateHudStatus "Overall Precentage of ship is to low, We will run back to base to repair"
		Return REPAIR

	}
}