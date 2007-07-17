function StackAll()
{
	call UpdateHudStatus "Stacking all..."
	Mouse:SetPosition[HangarDrop]
	wait 4
	Mouse:RightClick
	wait 4
	Mouse:SetPosition[StackAll]
	wait 4
	Mouse:LeftClick
	wait 4
	call UpdateHudStatus "Staking done"
}