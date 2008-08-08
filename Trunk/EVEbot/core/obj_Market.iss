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
	variable index:myorder     mySellOrders
	variable index:myorder     myBuyOrders
	
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Market: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

   	function GetMarketOrders(int typeID)
   	{
		UI:UpdateConsole["obj_Market: Obtaining market data for ${EVEDB_Items.ItemName[${typeID}]}"]
		
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
			call This.QuicksortSellOrders ${left} ${Math.Calc[${pivotNewIndex} - 1]}
			call This.QuicksortSellOrders ${Math.Calc[${pivotNewIndex} + 1]} ${right}
		}
	}

	member:int PartitionBuyOrders(int left, int right, int pivotIndex)
	{
		variable float64 pivotValue
		variable int     storeIndex
		variable int     idx
				
		pivotValue:Set[${This.buyOrders.Get[${pivotIndex}].Price}]
		
		;UI:UpdateConsole["DEBUG: ${left} ${right} ${pivotIndex} ${pivotValue}"]

		;UI:UpdateConsole["DEBUG: SWAP ${pivotIndex} ${right}"]
		This.buyOrders:Swap[${pivotIndex},${right}]

		storeIndex:Set[${left}]
		
		for ( idx:Set[${left}]; ${idx} < ${right}; idx:Inc )
		{
			if ${This.buyOrders.Get[${idx}].Price} <= ${pivotValue}
			{
				;UI:UpdateConsole["DEBUG: SWAP ${storeIndex} ${idx} ${This.buyOrders.Get[${idx}].Price} <= ${pivotValue}"]
				This.buyOrders:Swap[${storeIndex},${idx}]			
				storeIndex:Inc
			}
		}

		;UI:UpdateConsole["DEBUG: SWAP ${storeIndex} ${right}"]
		This.buyOrders:Swap[${storeIndex},${right}]

		;UI:UpdateConsole["DEBUG: RTN ${storeIndex}"]
		
		return ${storeIndex}
	}

   	function QuicksortBuyOrders(int left, int right)
   	{
 		variable int pivotIndex
 		variable int pivotNewIndex
 		
 		;This:DumpBuyOrders
 		
		if ${right} > ${left}
		{
			pivotIndex:Set[${left}]
			pivotNewIndex:Set[${This.PartitionBuyOrders[${left}, ${right}, ${pivotIndex}]}]
			call This.QuicksortBuyOrders ${left} ${Math.Calc[${pivotNewIndex} - 1]}
			call This.QuicksortBuyOrders ${Math.Calc[${pivotNewIndex} + 1]} ${right}
		}
   	}
   	
   	function FilterOrdersByRange(int jumps)
   	{
		variable int idx
		variable int count
				
		UI:UpdateConsole["obj_Market: Filtering all orders more than ${jumps} jumps away from your present location."]

		count:Set[${This.sellOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.sellOrders.Get[${idx}].Jumps} > ${jumps}
			{
				;UI:UpdateConsole["obj_Market: Removing order ${This.sellOrders.Get[${idx}].ID}."]
				This.sellOrders:Remove[${idx}]
			}
		}
		This.sellOrders:Collapse		
		;This:DumpSellOrders		
		
		count:Set[${This.buyOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.buyOrders.Get[${idx}].Jumps} > ${jumps}
			{
				;UI:UpdateConsole["obj_Market: Removing order ${This.sellOrders.Get[${idx}].ID}."]
				This.buyOrders:Remove[${idx}]
			}
		}
		This.buyOrders:Collapse
		;This:DumpBuyOrders		
   	}

	member:float64 LowestSellOrder()
	{
		return ${This.sellOrders.Get[1].Price}
	}

	member:float64 HighestBuyOrder()
	{
		return ${This.buyOrders.Get[${This.buyOrders.Used}].Price}
	}
	
	function GetMyOrders(int typeID)
	{
		UI:UpdateConsole["obj_Market: Obtaining my orders for ${EVEDB_Items.ItemName[${typeID}]}"]
		Me:UpdateMyOrders
		wait 40
		Me:DoGetMyOrders[This.myBuyOrders,"Buy",${typeID}] 
		wait 10
		Me:DoGetMyOrders[This.mySellOrders,"Sell",${typeID}]
		wait 10

		UI:UpdateConsole["obj_Market: Found ${This.mySellOrders.Used} active sell orders for ${EVEDB_Items.ItemName[${typeID}]}."]
		UI:UpdateConsole["obj_Market: Found ${This.myBuyOrders.Used} active buy orders for ${EVEDB_Items.ItemName[${typeID}]}."]
	}
	
	member:int MySellOrderCount()
	{
		return ${This.mySellOrders.Used}
	}
	
	member:int MyBuyOrderCount()
	{
		return ${This.myBuyOrders.Used}
	}
	
	
	function UpdateMySellOrders(float64 delta)
	{
		variable iterator orderIterator
		
		This.mySellOrders:GetIterator[orderIterator]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				if ${orderIterator.Value.Price} > ${This.LowestSellOrder}
				{
					variable float64 sellPrice
					sellPrice:Set[${Math.Calc[${This.LowestSellOrder}-${delta}]}]							
					sellPrice:Set[${sellPrice.Precision[2]}]
					
					if ${sellPrice} < 5000000
					{
						UI:UpdateConsole["obj_Market: Adjusting order ${orderIterator.Value.ID} to ${sellPrice}."]
						orderIterator.Value:Modify[${sellPrice}]
					}
					else
					{
						UI:UpdateConsole["obj_Market: ERROR: Sell price (${sellPrice}) exceeds limit!!"]
					}
				}
				else
				{
					UI:UpdateConsole["obj_Market: Order ${orderIterator.Value.ID} is currently the lowest sell order."]
				}
			}
			while ${orderIterator:Next(exists)}
		}
	}
	
	function UpdateMyBuyOrders(float64 delta)
	{
		variable iterator orderIterator
		
		This.myBuyOrders:GetIterator[orderIterator]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				if ${orderIterator.Value.Price} < ${This.HighestBuyOrder}
				{
					variable float64 buyPrice
					buyPrice:Set[${Math.Calc[${This.HighestBuyOrder}+${delta}]}]							
					buyPrice:Set[${buyPrice.Precision[2]}]
					
					if ${buyPrice} < 5000000
					{
						UI:UpdateConsole["obj_Market: Adjusting order ${orderIterator.Value.ID} to ${buyPrice}."]
						orderIterator.Value:Modify[${buyPrice}]
					}
					else
					{
						UI:UpdateConsole["obj_Market: ERROR: Buy price (${buyPrice}) exceeds limit!!"]
					}
				}
				else
				{
					UI:UpdateConsole["obj_Market: Order ${orderIterator.Value.ID} is currently the highest buy order."]
				}
			}
			while ${orderIterator:Next(exists)}
		}
	}

	method DumpSellOrders()
	{
		variable iterator orderIterator
		
		UI:UpdateConsole["obj_Market.DumpSellOrders: dumping..."]
		
		This.sellOrders:GetIterator[orderIterator]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Market.DumpSellOrders: ${orderIterator.Value.ID} ${orderIterator.Value.Jumps} ${orderIterator.Value.Price} ${orderIterator.Value.QuantityRemaining.Int}/${orderIterator.Value.InitialQuantity}."]
			}
			while ${orderIterator:Next(exists)}
		}
	}

	method DumpBuyOrders()
	{
		variable iterator orderIterator
		
		UI:UpdateConsole["obj_Market.DumpBuyOrders: dumping..."]
		
		This.buyOrders:GetIterator[orderIterator]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Market.DumpBuyOrders: ${orderIterator.Value.ID} ${orderIterator.Value.Jumps} ${orderIterator.Value.Price} ${orderIterator.Value.QuantityRemaining.Int}/${orderIterator.Value.InitialQuantity}."]
			}
			while ${orderIterator:Next(exists)}
		}
	}
}
