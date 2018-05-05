function main()
{
	echo "Ammo test case loaded, basing off HiSlot0"
	
	variable index:item idxAmmo
	variable iterator itrAmmo
	
	variable string sLoadedAmmo
	variable string sIteratedAmmo
	
	MyShip.Module[HiSlot0]:GetAvailableAmmo[idxAmmo]
	idxAmmo:GetIterator[itrAmmo]
	
	echo "itrAmmo:First(exists): ${itrAmmo:First(exists)}"
	if ${itrAmmo:First(exists)}
	{
		do
		{
			echo "Comparing currently loaded ammo (${MyShip.Module[HiSlot0].Charge.Name}) with current available ammo (${itrAmmo.Value.Name}). Strings equal? ${MyShip.Module[HiSlot0].Charge.Name.Find[${itrAmmo.Value.Name}]}"
			sLoadedAmmo:Set[${MyShip.Module[HiSlot0].Charge.Name}]
			sIteratedAmmo:Set[${itrAmmo.Value.Name}]
			echo "sLoadedAmmo: ${sLoadedAmmo}, sIteratedAmmo: ${sIteratedAmmo}, equal? ${sLoadedAmmo.Equal[${sIteratedAmmo}]}"
			echo "Module max charges: ${MyShip.Module[HiSlot0].MaxCharges}"
			if !${sLoadedAmmo.Equal[${sIteratedAmmo},${MyShip.Module[HiSlot0].MaxCharges}]}
			{
				echo "Changing ammo to currently iterated type at current number of charges and breaking."
				MyShip.Module[HiSlot0]:ChangeAmmo[${itrAmmo.Value.ID}]
				MyShip.Module[HiSlot1]:ChangeAmmo[${itrAmmo.Value.ID}]
				MyShip.Module[HiSlot2]:ChangeAmmo[${itrAmmo.Value.ID}]
				MyShip.Module[HiSlot3]:ChangeAmmo[${itrAmmo.Value.ID}]
				echo "IsReloading? ${MyShip.Module[HiSlot0].IsReloading}"
				break
			}
		}
		while ${itrAmmo:Next(exists)}
	}
}