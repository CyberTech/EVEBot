function TransferToHangar()
{
	while !${Display.GetPixel[CargoHoldItem1].Hex.Equal[29221c]}
	{
	echo "Transfering item1 to hangar"
	Mouse:SetPosition[CargoHoldItem1]
	wait 4
	Mouse:HoldLeft
	wait 4
	Mouse:SetPosition[HangarDrop]
	wait 4
	Mouse:ReleaseLeft
	Break
	}
		
	while !${Display.GetPixel[CargoHoldItem2].Hex.Equal[27211a]}
	{
	echo "Transfering item2 to hangar"
	Mouse:SetPosition[CargoHoldItem2]
	wait 4
	Mouse:HoldLeft
	wait 4
	Mouse:SetPosition[HangarDrop]
	wait 4
	Mouse:ReleaseLeft
	Break
	}
		
	while !${Display.GetPixel[CargoHoldItem3].Hex.Equal[262019]}
	{
	echo "Transfering item3 to hangar"
	Mouse:SetPosition[CargoHoldItem3]
	wait 4
	Mouse:HoldLeft
	wait 4
	Mouse:SetPosition[HangarDrop]
	wait 4
	Mouse:ReleaseLeft
	Break
	} 
}