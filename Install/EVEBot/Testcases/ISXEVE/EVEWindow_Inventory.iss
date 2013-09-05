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
				echo "--| ${i}. Name: '${Iter.Value}'"
				echo "-----| HasCapacity: ${Iter.Value.HasCapacity}"
				if (${Iter.Value.HasCapacity})
				{
					echo "-----| Capacity: ${Iter.Value.Capacity.Precision[2]}"        
					echo "-----| UsedCapacity: ${Iter.Value.UsedCapacity.Precision[2]}"
				}
				if (${Iter.Value.LocationFlagID} > 0)
				{
					echo "-----| LocationFlag: ${Iter.Value.LocationFlag}"
					echo "-----| LocationFlagID: ${Iter.Value.LocationFlagID}"
				}
			  echo "-----| IsInRange: ${Iter.Value.IsInRange}"
				echo "-----| ItemID: ${Iter.Value.ItemID}"
				echo "--------------------------------"
				i:Inc
				echo Making Active:
				Iter.Value:MakeActive
				wait 10
			}
			while ${Iter:Next(exists)}
		}
	}
}