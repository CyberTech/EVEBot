
#include core/mining.iss
#include core/navigation.iss
#include core/station.iss
#include core/targeting.iss

function main()
{
	while TRUE
	{
		if ${Me.InStation}
		{
			call unloadcargo
			call undock
		}
		elseif ${Me.Ship.UsedCargoCapacity} <= ${Math.Calc[${Me.Ship.CargoCapacity}-1]}
		{
			call mine
		}
		elseif ${Math.Calc[${Me.Ship.UsedCargoCapacity}+1]} >= ${Me.Ship.CargoCapacity}
		{
			call dock
		}
		else
			echo ebot,main: Error (is ISXEVE loaded?)
		wait 20
	}
}
