function DefendAndDestroy()
{
	echo "Found ${Me.GetTargetedBy[EntitiesTargetingMe]} hostile ships"
		for (i:Set[1] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
		{
		Entity[ID,${EntitiesTargetingMe.Get[${i}].Id}]:Orbit
			while ${EntitiesTargetingMe.Get[${i}].Distance} > 1500
			{
			waitframe
			}
		Entity[ID,${EntitiesTargetingMe.Get[${i}].Id}]:LockTarget
		EVE:Execute[CmdActivateHighPowerSlot2]
			while ${Me.ActiveTarget} 
			;|| (${Me.Ship.HP} > 40)
			{
			waitframe
			}
		}
}