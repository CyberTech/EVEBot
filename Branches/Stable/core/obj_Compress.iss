/*
	Compression Class

	Interacting with ore in space

BUGS:

*/

objectdef obj_Compress inherits obj_BaseClass
{
	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]
		Logger:Log["obj_Compress: Initialized", LOG_MINOR]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	function CheckForCompression()
	{
		Logger:Log["Debug: Loading Check for compression"]

		while ${Me.InSpace}
		{
			Logger:Log["Debug: Lets check if the inventory window is open"]
			if !${EVEWindow[Inventory](exists)}
			{
				echo "Opening Inventory..."
		        EVE:Execute[OpenInventory]
		        wait 10
			}
			Logger:Log["Debug: Lets make our ore hold the active window"]
            EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold]:MakeActive
	        wait 50
			
			Logger:Log["Debug: Lets lets add everything in our ore hold to a list of items"]
            
			variable index:item MyOre
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipGeneralMiningHold]:GetItems[MyOre]
			wait 10
	        echo "Compiling Ore In Hold"
			Logger:Log["Debug: Ship Mining Hold contains ${MyOre.Used}"]
			Logger:Log["Debug: Now that we have a list lets set it to an iterator"]

			variable iterator OreIterator
            MyOre:GetIterator[OreIterator]
			wait 10
			Logger:Log["Debug: #1"]
            if ${OreIterator:First(exists)}
	        {
				Logger:Log["Debug: Iterator shows it has items in its list lets check if we can open the compression window"]
		        do
		        {
						echo "Open compression window"
						OreIterator.Value:Compress
						wait 10
		        }
		    while ${OreIterator:Next(exists)}
			wait 10
			wait ${Math.Rand[30]}
			Logger:Log["Debug: Lets Try To Compress"]
			EVEWindow[ByCaption, Compression].Button[compress_button]:Press
			wait 16
			wait ${Math.Rand[30]}
			Logger:Log["Debug: Lets close the window"]
			EVEWindow[ByCaption, Compression].Button[cancel_button]:Press
	        }
			break
		}

	}
}