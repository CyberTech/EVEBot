function main()
{
	echo "Ammo test case loaded, basing off HiSlot0"
	
	variable index:item idxAmmo
	variable iterator itrAmmo
	
	MyShip.Module[HiSlot0]:DoGetAvailableAmmo[idxAmmo]
	idxAmmo:GetIterator[itrAmmo]
	
	echo "itrAmmo:First(exists): ${itrAmmo:First(exists)}"
	if ${itrAmmo:First(exists)}
	{
		do
		{
			echo "Comparing currently loaded ammo (${MyShip.Module[HiSlot0].Charge.Name}) with current available ammo (${itrAmmo.Value.Name}). Strings equal? ${MyShip.Module[HiSlot0].Charge.Name.Equal[${itrAmmo.Value.Name}]}"
			if !${MyShip.Module[HiSlot0].Charge.Name.Equal[${itrAmmo.Value.Name}]}
			{
				echo "Changing ammo to currently iterated type at current number of charges and breaking."
				MyShip.Module[HiSlot0]:ChangeAmmo[${itrAmmo.Value.ID}]
				break
			}
		}
		while ${itrAmmo:Next(exists)}
	}
}