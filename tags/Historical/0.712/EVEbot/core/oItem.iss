function StackAll()
{
	echo "Stacking all..."
	Mouse:SetPosition[HangarDrop]
	wait 10
	Mouse:RightClick
	wait 10
	Mouse:SetPosition[StackAll]
	wait 20
	Mouse:LeftClick
	wait 30
	echo "Staking done"
}