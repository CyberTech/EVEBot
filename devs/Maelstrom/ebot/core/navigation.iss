
function warpto(int id, int d)
{
	if ${id} != 0 && ${Entity[ID,${id}].Distance} >= 100000 && ${Me.ToEntity.Mode} != 3
	{
		echo navigation,warpto: ${Entity[ID,${id}].Name} Distance: ${Entity[ID,${id}].Distance} meters
		echo navigation,warpto: Entity[ID,${id}]:WarpTo[${d}]
		Entity[ID,${id}]:WarpTo[${d}]
		wait 100
		while ${Me.ToEntity.Mode} == 3
			wait 20
		wait 20
	}
	else
		echo navigation,warpto: Failed: No ID Found
}

function approach(int id, int d)
{
	if ${id} != 0
	{
		if ${d} < 500
			d:Set[500]
		echo navigation,approach: EVE:Execute[CmdActivateMediumPowerSlot1]
		EVE:Execute[CmdActivateMediumPowerSlot1]
		echo navigation,approach: ${Entity[ID,${id}].Name} Distance: ${Entity[ID,${id}].Distance} meters
		echo navigation,approach: Entity[ID,${id}]:Approach[${d}]
		Entity[ID,${id}]:Approach[${i}]
		while ${Entity[ID,${id}].Distance} > 29000
			wait 20
		call locktarget ${id}
		while ${Entity[ID,${id}].Distance} > ${d}
			wait 20
		echo navigation,approach: Me:SetVelocity[0]
		Me:SetVelocity[0]
	}
	else
		echo navigation,approach: Failed: No ID Found
}

function orbit(int id, int d)
{
	if ${id(exists)}
	{
		if ${d} < 500
			d:Set[500]
		call approach ${id} ${d}
		echo navigation,approach: EVE:Execute[CmdActivateMediumPowerSlot1]
		EVE:Execute[CmdActivateMediumPowerSlot1]
		echo navigation,orbit: ${Entity[ID,${id}].Name} Distance: ${Entity[ID,${id}].Distance} meters
		echo navigation,orbit: Entity[ID,${id}]:Orbit[${d}]
		Entity[ID,${id}]:LockTarget
		while ${Me.GetTargets}
			wait 20
		Entity[ID,${id}]:Orbit[${d}]
	}
	else
		echo navigation,orbit: Failed: No ID Found
}
