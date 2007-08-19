function StackAll()
{
	call UpdateHudStatus "Stacking all..."
	Mouse:SetPosition[HangarDrop]
	wait 20
	Mouse:RightClick
	wait 20
	Mouse:SetPosition[StackAll]
	wait 20
	Mouse:LeftClick
	wait 20
	call UpdateHudStatus "Staking done"
	wait 20
}