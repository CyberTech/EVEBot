function StackAll()
{
	echo "Stacking all..."
	Mouse:SetPosition[HangarDrop]
	wait 4
	Mouse:RightClick
	wait 4
	Mouse:SetPosition[StackAll]
	wait 4
	Mouse:LeftClick
	wait 4
	echo "Staking done"
}