
function locktarget(int id)
{
	if ${id} != 0
	{
		echo targeting,locktarget: ${Entity[ID,${id}].Name} Distance: ${Entity[ID,${id}].Distance} meters
		echo targeting,locktarget: Entity[ID,${id}]:LockTarget
		if ${Entity[ID,${id}].Distance} <= 30000
		{
			Entity[ID,${id}]:LockTarget
			wait 40
		}
		else
			call approach ${id} 30000
	}
	else
		echo targeting,locktarget: Failed: No ID Found
}
