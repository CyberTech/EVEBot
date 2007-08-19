function DefendAndDestroy()
{
variable index:entity EntitiesTargetingMe
variable int i

call UpdateHudStatus "Declaring EntitiesTargetingMe"
	call UpdateHudStatus "Found ${Me.GetTargetedBy[EntitiesTargetingMe]} hostile ships"
		for (i:Set[1] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
		{
		call UpdateHudStatus "i is set to ${i}"
		Call Orbit ${EntitiesTargetingMe.Get[${i}].ID} 1500
		call UpdateHudStatus "Locking target ${EntitiesTargetingMe.Get[${i}].Name}"
		Entity[ID,${EntitiesTargetingMe.Get[${i}].ID}]:LockTarget
		call UpdateHudStatus "Activating Railrun..."
		EVE:Execute[CmdActivateHighPowerSlot2]
			;while ${Me.ActiveTarget(exists)} 
			;|| (${Me.Ship.HP} > 40)
			;{
			;wait 20
			;}
		call UpdateHudStatus "Waiting 30 sec..."
		wait 300
		call UpdateHudStatus "Waiting stop."
		}
}