function LoadCoordinates()
{

#define CargoHoldItem1 113,274                /* Location on Screen of First Item in Cargo Hold */
#define CargoHoldItem2 186,274               /* Location on Screen of Second Item in Cargo Hold */
#define CargoHoldItem3 264,274               /* Location on Screen of Third Item in Cargo Hold */

#define HangarDrop 487,696                    /* Location on Screen To Drop Items in Hanger */
;------------------------------------------------------------;
;If you Right Click HangerDrop location and choose Stack All ;
;That is the location entered below                          ;
;------------------------------------------------------------;
#define StackAll 525,751                     /* Right Click HangerDrop location and choose Stack All */

}

function DragToHangar()
{
   while !${Display.GetPixel[CargoHoldItem1].Hex.Equal[211810]}
   	{
   	Mouse:SetPosition[CargoHoldItem1]
   	wait 20
   	Mouse:HoldLeft
   	wait 10
   	Mouse:SetPosition[HangarDrop]
   	wait 10
   	Mouse:ReleaseLeft
   	}
   
  While !${Display.GetPixel[CargoHoldItem2].Hex.Equal[211810]}
   	{
   	Mouse:SetPosition[CargoHoldItem2]
   	wait 20
   	Mouse:HoldLeft
   	wait 10
   	Mouse:SetPosition[HangarDrop]
   	wait 10
   	Mouse:ReleaseLeft
	}
	
  While !${Display.GetPixel[CargoHoldItem3].Hex.Equal[211810]}
   	{
   	Mouse:SetPosition[CargoHoldItem3]
   	wait 20
   	Mouse:HoldLeft
   	wait 10
   	Mouse:SetPosition[HangarDrop]
   	wait 10
   	Mouse:ReleaseLeft
	} 
}

function StackAll()   
   
{
  Mouse:SetPosition[HangarDrop]
  wait 10
  Mouse:RightClick
  wait 10
  Mouse:SetPosition[StackAll]
  wait 10
  Mouse:LeftClick
}


function DockAtStation(int ID)
{
	Entity[ID,${ID}]:Dock
}

function UnDock()
{
	Me:Undock
}

function MineRoid(int ID)
{
	Entity[ID,${ID}]:Orbit
	Entity[ID,${ID}]:LockTarget
	waitframe
	wait 100 ${Entity[ID,${ID}].BeingTargeted}
	EVE:Execute[CmdActivateHighPowerSlot1]
	wait 1800
	Entity[ID,${ID}]:UnlockTarget
}