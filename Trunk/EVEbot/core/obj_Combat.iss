/* 
	Progress
	Combat: 5%
	Defensive: 10%
	Offensive: 0%
	Fighter: 0%

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
			
			;Not Ready
			;if ${Running}== FALSE
			;{
			;	if ${Math.Calc[(${Me.Ship.ShieldPct} + ${Me.Ship.ArmorPct})/2]} < 60
			;	{
			;		This:InCombatState
			;		Call This.SafeRun
			;		Call UpdateHudStatus "Debug: Our combined health is lower then 50"
			;	}
			;}	
			
			FrameCounter:Set[0]
		}
	}
	
	method InCombatState()
	{
		Call UpdateHudStatus "Now In Combat"
		InCombat:Set[TRUE]
	}
	
	method ExitCombatState()
	{
		Call UpdateHudStatus "Debug: ExitCombatState"
		InCombat:Set[FALSE]
	}
	
	function UpdateList()
	{
		variable index:entity Targets
		
				
	function Fight()
	{
		variable index:entity EntitiesTargetingMe
		variable int i
		variable int CombatTarget
		
		for (i:Set[0] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
		{	
			call UpdateHudStatus "DEBUG: ${EntitiesTargetingMe.Get[${i}].ID}"
			CombatTarget:Set[Entity[${EntitiesTargetingMe.Get[${i}].ID}]]
		}
		
			call UpdateHudStatus "DEBUG: #2 ${EntitiesTargetingMe.Get[${i}].ID}"
			do
			{
			Entity[${CombatTarget}]:LockTarget
			call UpdateHudStatus "Trying to lock target ${CombatTarget}, Locked: ${Entity[${CombatTarget}].IsLockedTarget}"
			wait 50
			}
			while ${Entity[${CombatTarget}].IsLockedTarget}== TRUE
			call UpdateHudStatus "Combat Target is Locked"
			
			do
			{
			Entity[${CombatTarget}]:MakeActiveTarget
			call UpdateHudStatus "Trying to make target active, Active: ${Entity[${CombatTarget}].IsActiveTarget}"
			wait 50
			}
			while ${Entity[${CombatTarget}].IsActiveTarget}== TRUE

			call UpdateHudStatus "Target ${EntitiesTargetingMe.Get[${i}].ID} should be active and locked"
		
		
			;Defense if we have Drones
			;wait 10
			;if (${Ship.Drones.DronesInSpace} > 0)
			;{
  		;Eve:DronesEngageMyTarget[Drones.DroneList]
  		;echo "DEBUG: Engaging Target"
  		;}
  		
			;Defense if we have Laser 
			;Readd after Debuging
			;call LaserCombat
			
			;do
			;{
			;	wait 10
			;	echo "DEBUG: We're still in combat"
			;}
			;while ${Entity[ID,${EntitiesTargetingMe.Get[${i}].ID}].IsLockedTarget}== FALSE
			;echo "Entity[ID,${EntitiesTargetingMe.Get[${i}].ID}] Has Been Destroyed"
			
			while (${Me.GetTargetedBy} == 0) && (${Me.Ship.ShieldPct} < 99)
			{
				echo "Low Health within Combat Function"
				wait 10
			}
			
			This:ExitCombatState
	}
	
	;Not Ready
	function SafeRun()
	{
		Call UpdateHudStatus "Overall Precentage of ship is to low, We will run back to base to repair"
		Running:Set[TRUE]
		return
	}
	
	function ResetRun()
	{
		Running:Set[FALSE]
	}
}