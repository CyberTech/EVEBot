function DefendAndDestroy()
{
variable index:entity EntitiesTargetingMe
variable int i

echo "Declaring EntitiesTargetingMe"
	echo "Found ${Me.GetTargetedBy[EntitiesTargetingMe]} hostile ships"
		for (i:Set[1] ; ${i} <= ${Me.GetTargetedBy[EntitiesTargetingMe]} ; i:Inc)
		{
		echo "i is set to ${i}"
		Call Orbit ${EntitiesTargetingMe.Get[${i}].ID} 1500
		echo "Locking target ${EntitiesTargetingMe.Get[${i}].Name}"
		Entity[ID,${EntitiesTargetingMe.Get[${i}].ID}]:LockTarget
		echo "Activating Railrun..."
		EVE:Execute[CmdActivateHighPowerSlot2]
			;while ${Me.ActiveTarget(exists)} 
			;|| (${Me.Ship.HP} > 40)
			;{
			;wait 20
			;}
		echo "Waiting 30 sec..."
		wait 300
		echo "Waiting stop."
		}
}