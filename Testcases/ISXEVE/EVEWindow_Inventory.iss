function main()
{
	variable index:eveinvchildwindow InvWindowChildren
	variable iterator Iter
	variable int i = 1
	
	variable eveinvwindow InventoryWindow = "${EVEWindow["Inventory"]}"
	if (${InventoryWindow(exists)})
	{
		echo "- Name: ${InventoryWindow.Name}"
		echo "-- Type: ${InventoryWindow(type)}"
		echo "-- Caption: ${InventoryWindow.Caption}"
		
		InventoryWindow:GetChildren[InvWindowChildren]
		InvWindowChildren:GetIterator[Iter]
		if ${Iter:First(exists)}
		{
			echo "------- Inventory Window Children:"
			do
			{
				echo "Making Active: ${i}. Name: '${Iter.Value.Name}'"
				Iter.Value:MakeActive
				wait 8
				echo "-----| ActiveChild:    ${InventoryWindow.ActiveChild.Name} ${InventoryWindow.ActiveChild.ItemID} ${InventoryWindow.ActiveChild.LocationFlag} ${InventoryWindow.ActiveChild.LocationFlagID}"
				echo "-----| HasCapacity:    ${Iter.Value.HasCapacity}"
				if (${Iter.Value.HasCapacity})
				{
					echo "------| Capacity:      ${Iter.Value.Capacity.Precision[2]}"        
					echo "------| UsedCapacity:  ${Iter.Value.UsedCapacity.Precision[2]}"
				}
				echo "-----| LocationFlag:   ${Iter.Value.LocationFlag}"
				echo "-----| LocationFlagID: ${Iter.Value.LocationFlagID}"
			  echo "-----| IsInRange:      ${Iter.Value.IsInRange}"
				echo "-----| ItemID:         ${Iter.Value.ItemID}"
				echo "--------------------------------"
				i:Inc
			}
			while ${Iter:Next(exists)}
		}
	}
}