/*
	Market class
	
	Object to contain members related to market interaction.
	
	-- GliderPro
	
*/

objectdef obj_Market
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	variable index:marketorder sellOrders
	variable index:marketorder buyOrders
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Market: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

   	function GetMarketOrders(int typeID)
   	{
		UI:UpdateConsole["obj_Market: Obtaining market data for type ${typeID}"]
		
		This.sellOrders:Clear
		This.buyOrders:Clear
		
		EVE:UpdateMarketOrders_A[${typeID}]
		wait 40
		EVE:UpdateMarketOrders_B[${typeID}]
		wait 10
		EVE:DoGetMarketOrders[This.sellOrders,"Sell",${typeID}]
		wait 10
		EVE:DoGetMarketOrders[This.buyOrders,"Buy",${typeID}]
		wait 10
		
		UI:UpdateConsole["obj_Market: Found ${This.sellOrders.Used} sell orders."]
		UI:UpdateConsole["obj_Market: Found ${This.buyOrders.Used} buy orders."]
		
		;This:DumpSellOrders
		call This.QuicksortSellOrders 1 ${This.sellOrders.Used}
		;This:DumpSellOrders
		
		;This:DumpBuyOrders
		call This.QuicksortBuyOrders 1 ${This.buyOrders.Used}
		;This:DumpBuyOrders
   	}
   	
	member:int PartitionSellOrders(int left, int right, int pivotIndex)
	{
		variable float64 pivotValue
		variable int     storeIndex
		variable int     idx
				
		pivotValue:Set[${This.sellOrders.Get[${pivotIndex}].Price}]
		
		This.sellOrders:Swap[${pivotIndex},${right}]

		storeIndex:Set[${left}]
		
		for ( idx:Set[${left}]; ${idx} < ${right}; idx:Inc )
		{
			if ${This.sellOrders.Get[${idx}].Price} <= ${pivotValue}
			{
				This.sellOrders:Swap[${storeIndex},${idx}]			
				storeIndex:Inc
			}
		}

		This.sellOrders:Swap[${storeIndex},${right}]

		return ${storeIndex}
	}

 	function QuicksortSellOrders(int left, int right)
 	{
 		variable int pivotIndex
 		variable int pivotNewIndex
 		
		if ${right} > ${left}
		{
			pivotIndex:Set[${left}]
			pivotNewIndex:Set[${This.PartitionSellOrders[${left}, ${right}, ${pivotIndex}]}]
			This:QuicksortSellOrders[${left}, ${pivotNewIndex} - 1]
			This:QuicksortSellOrders[${pivotNewIndex} + 1, ${right}]
		}
	}

	member:int PartitionBuyOrders(int left, int right, int pivotIndex)
	{
		variable float64 pivotValue
		variable int     storeIndex
		variable int     idx
				
		pivotValue:Set[${This.buyOrders.Get[${pivotIndex}].Price}]
		
		This.buyOrders:Swap[${pivotIndex},${right}]

		storeIndex:Set[${left}]
		
		for ( idx:Set[${left}]; ${idx} < ${right}; idx:Inc )
		{
			if ${This.buyOrders.Get[${idx}].Price} <= ${pivotValue}
			{
				This.buyOrders:Swap[${storeIndex},${idx}]			
				storeIndex:Inc
			}
		}

		This.buyOrders:Swap[${storeIndex},${right}]

		return ${storeIndex}
	}

   	function QuicksortBuyOrders(int left, int right)
   	{
 		variable int pivotIndex
 		variable int pivotNewIndex
 		
		if ${right} > ${left}
		{
			pivotIndex:Set[${left}]
			pivotNewIndex:Set[${This.PartitionBuyOrders[${left}, ${right}, ${pivotIndex}]}]
			This:QuicksortBuyOrders[${left}, ${pivotNewIndex} - 1]
			This:QuicksortBuyOrders[${pivotNewIndex} + 1, ${right}]
		}
   	}

	member:float64 LowestSellOrder()
	{
		return ${This.sellOrders.Get[1].Price}
	}

	member:float64 HighestBuyOrder()
	{
		variable iterator anIterator
		
		This.buyOrders:GetIterator[anIterator]
		anIterator:Last
		return ${anIterator.Value.Price}
		
		;return ${This.buyOrders.Get[This.buyOrders.Used].Price}
	}
	
	method DumpSellOrders()
	{
		variable iterator orderIterator
		
		This.sellOrders:GetIterator[orderIterator]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Market.DumpSellOrders: ${orderIterator.Value.ID} ${orderIterator.Value.Price} ${orderIterator.Value.QuantityRemaining.Int}/${orderIterator.Value.InitialQuantity}."]
			}
			while ${orderIterator:Next(exists)}
		}
	}

	method DumpBuyOrders()
	{
		variable iterator orderIterator
		
		This.buyOrders:GetIterator[orderIterator]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Market.DumpBuyOrders: ${orderIterator.Value.ID} ${orderIterator.Value.Price} ${orderIterator.Value.QuantityRemaining.Int}/${orderIterator.Value.InitialQuantity}."]
			}
			while ${orderIterator:Next(exists)}
		}
	}
}
