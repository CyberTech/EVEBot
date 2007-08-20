
#include ./core/functions.iss


function LoadEvebotGUI()
{
	ui -load "./interface/evebotgui.xml"
}
function atexit()
{
	ui -unload "./interface/evebotgui.xml"
}
function DeclareState()
{
	if ${Me.ToEntity.Mode}==3
	{
		Return "WARP"
	}
	if ${Me.InStation}
	{
		Return "UNDOCK"
	}
	if !(${Me.Ship.UsedCargoCapacity}==0) && ${Entity[ID,${station}].Distance}<10000
	{
		Return "DOCK"
	}
	if !(${Me.Ship.UsedCargoCapacity}==0) && ${Entity[ID,${station}].Distance}>=10000
	{
		Return "STATIONWARP"
	}
	if ${Entity[ID,${belt}].Distance}>50000
	{
		Return "BELTWARP"
	}
	if (${Me.Ship.UsedCargoCapacity}==0) && ${Entity[ID,${belt}].Distance}<=50000 && ${roid}==0
	{
		Return "SELECTROID"
	}
	if (${Me.Ship.UsedCargoCapacity}==0) && ${Entity[ID,${belt}].Distance}<=50000 && !${roid}==0 && ${Entity[ID,${roid}].Distance}>9000
	{
		Return "APPROACHROID"
	}
	if (${Me.Ship.UsedCargoCapacity}==0) && ${Entity[ID,${belt}].Distance}<=50000 && !${roid}==0 && ${Entity[ID,${roid}].Distance}<=9000
	{
		Return "MINEROID"
	}
	
	Return "NONE"
}

function main()
{
	declare station int script ${Entity[CategoryID,3].ID}
	declare belt int script ${Entity[GroupID,9].ID}
	declare roid int script
	declare botstate string
	
	call LoadCoordinates
	call LoadEvebotGUI
	
	While ${botstate.NotEqual[END]}
	{
		call DeclareState
		botstate:Set[${Return}]
		echo ${botstate}

		
		Switch ${botstate}
		{
			case WARP
				waitframe
				break
			case UNDOCK
				call DragToHangar
				call StackAll
				call UnDock
				wait 300
				belt:Set[${Entity[GroupID,9].ID}]
				echo ${belt}
				break
			case DOCK
				call DockAtStation ${station}
				wait 200
				break
			case STATIONWARP
				Entity[ID,${station}]:WarpTo
				wait 700 ${Me.ToEntity.Mode}==3
				break
			case BELTWARP
				Entity[ID,${belt}]:WarpTo
				wait 700 ${Me.ToEntity.Mode}==3
				break
			case SELECTROID
				roid:Set[${Entity[CategoryID,25].ID}]
				echo ${roid} selected
				break
			case APPROACHROID
				Entity[ID,${roid}]:Orbit
				wait 500 ${Entity[ID,${roid}].Distance}<=9000
				break
			case MINEROID
				call MineRoid ${roid}
				roid:Set[0]
				break
			case NONE
				waitframe
				break
		}
	}
}