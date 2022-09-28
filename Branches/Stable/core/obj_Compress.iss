/*
	Compression Class

	Interacting with ore in space

BUGS:

*/

objectdef obj_Compress inherits obj_BaseClass
{
	variable index:item MyOre
	variable iterator OreIterator
	variable index:int64 IDList

	method Initialize()
	{
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	function CheckForCompression()
	{
		
		while ${Me.InSpace}
		{
			if !${EVEWindow[Inventory](exists)}
			{
				echo "Opening Inventory..."
		        EVE:Execute[OpenInventory]
		        wait 2
			}

            EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold]:MakeActive
	        Wait 10

            EVEWindow[Inventory].ActiveChild:GetItems[MyOre]
	        echo "Compiling Ore In Hold"

            MyOre:GetIterator[OreIterator]
            if ${OreIterator:First(exists)}
	        {
		        do
		        {
			        if (${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold](exists)} && ${Ship.OreHoldHalfFull})
                    {
                        echo "Open compression window"    
                        OreIterator.Value:Compress
                    }
		        }
		    while ${OreIterator:Next(exists)}
	        }
		}

	}

	function Close(int64 ID=0)
	{
		; The current code didn't do anything and there is no actual way to close the JetCan right now
		;(you can only close the main inv window), which IMO should be handled separately from the JetCan's window. So I commented it out. D
		; -- wco12

		; TODO - should be able to close via envinvchildwindow:close now - CT
	}
}