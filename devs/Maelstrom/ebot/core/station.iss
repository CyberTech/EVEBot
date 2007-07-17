#define CargoHoldItem1	440,440	/* Location on Screen of First Item in Cargo Hold */
#define CargoHoldItem2	520,440	/* Location on Screen of Second Item in Cargo Hold */
#define CargoHoldItem3	600,440	/* Location on Screen of Third Item in Cargo Hold */
#define HangarDrop		120,480	/* Location on Screen To Drop Items in Hanger */
#define StackAll		158,536	/* If you Right Click HangerDrop location and choose Stack All */

function dock(int id)
{
	if !${Me.InStation}
	{
		if !${id}
			id:Set[${Entity[CategoryID,3].ID}]
		if ${id} != 0
		{
			call warpto ${id}
			echo station,dock: Entity[ID,${id}]:Dock
			Entity[ID,${id}]:Dock
			wait 150
		}
		else
			echo station,dock: Failed: No ID Found
	}
	else
		echo Dock Failed: InStation
}

function unloadcargo()
{
	while !${Display.GetPixel[CargoHoldItem1].Hex.Equal[29221c]}
	{
		echo station,unloadcargo: Item1
		Mouse:SetPosition[CargoHoldItem1]
		wait 20
		Mouse:HoldLeft
		wait 10
		Mouse:SetPosition[HangarDrop]
		wait 10
		Mouse:ReleaseLeft
		Break
	}
	while !${Display.GetPixel[CargoHoldItem2].Hex.Equal[27211a]}
	{
		echo station,unloadcargo: Item2
		Mouse:SetPosition[CargoHoldItem2]
		wait 20
		Mouse:HoldLeft
		wait 10
		Mouse:SetPosition[HangarDrop]
		wait 10
		Mouse:ReleaseLeft
		Break
	}
	while !${Display.GetPixel[CargoHoldItem3].Hex.Equal[262019]}
	{
		echo station,unloadcargo: Item3
		Mouse:SetPosition[CargoHoldItem3]
		wait 20
		Mouse:HoldLeft
		wait 10
		Mouse:SetPosition[HangarDrop]
		wait 10
		Mouse:ReleaseLeft
		Break
	}
	echo station,unloadcargo: Done
}

function undock()
{
	wait 20
	if ${Me.InStation}
	{
		echo station,undock: Me:Undock
		Me:Undock
		wait 150
	}
	else
		echo station,undock: Failed: Not InStation
}
