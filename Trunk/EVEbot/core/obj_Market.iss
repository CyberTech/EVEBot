/*
	Market class
	
	Object to contain members related to market interaction.
	
	-- GliderPro
	
*/

objectdef obj_MarketItemList
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/${_Me.Name} Market.xml"
	variable string SET_NAME = "${_Me.Name} Market"
	variable iterator itemIterator
	
	method Initialize()
	{
		if ${LavishSettings[${This.SET_NAME}](exists)}
		{
			LavishSettings[${This.SET_NAME}]:Clear
		}
		LavishSettings:Import[${CONFIG_FILE}]
		LavishSettings[${This.SET_NAME}]:GetSetIterator[This.itemIterator]
		UI:UpdateConsole["obj_MarketItemList: Initialized", LOG_MINOR]
	}
	
	method Shutdown()	
	{
		LavishSettings[${This.SET_NAME}]:Clear
	}
	
	member:string FirstItem()
	{
		if ${This.itemIterator:First(exists)}
		{
			return ${This.itemIterator.Key}			
		}
		
		return NULL
	}
	
	member:string NextItem()
	{
		if ${This.itemIterator:Next(exists)}
		{
			return ${This.itemIterator.Key}			
		}
		
		return NULL
	}
	
	member:string CurrentItem()
	{
		return ${This.itemIterator.Key}			
	}

	method DumpList()
	{
		UI:UpdateConsole["obj_MarketItemList: Dumping list..."]
		
		UI:UpdateConsole["obj_MarketItemList: This.FirstItem   = ${This.FirstItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem    = ${This.NextItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem = ${This.CurrentItem}"]
		UI:UpdateConsole["obj_MarketItemList: This.NextItem(exists)    = ${This.NextItem(exists)}"]
		UI:UpdateConsole["obj_MarketItemList: This.CurrentItem(exists) = ${This.CurrentItem(exists)}"]
	}
}

objectdef obj_Market
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	
	variable obj_MarketItemList ItemList
	variable index:marketorder  sellOrders
	variable index:marketorder  buyOrders
	variable index:myorder      mySellOrders
	variable index:myorder      myBuyOrders
	variable int                m_BestSellOrderSystem
	variable int                m_BestSellOrderStation
	
	method Initialize()
	{
		UI:UpdateConsole["obj_Market: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

   	function GetMarketOrders(int typeID)
   	{
		UI:UpdateConsole["obj_Market: Obtaining market data for ${EVEDB_Items.Name[${typeID}]} (${typeID})"]
		
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
   	
   	
	member:int BestSellOrderSystem()
	{
		return ${This.m_BestSellOrderSystem}
	}
	
	member:int BestSellOrderStation()
	{
		return ${This.m_BestSellOrderStation}
	}
	
	;; This must be a function because you need a wait between setting a destination and getting the path
	function FindBestSellOrder(bool avoidLowSec, int quantity)
	{
		variable iterator orderIterator
		
		UI:UpdateConsole["obj_Market.BestSellOrderSystem(${avoidLowSec},${quantity})"]

		This.sellOrders:GetIterator[orderIterator]
		
		if ${Station.Docked}
		{
			UI:UpdateConsole["obj_Market.BestSellOrderSystem: WARNING:  Called while docked."]
		}
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				if ${orderIterator.Value.QuantityRemaining} > ${quantity}
				{
					if ${avoidLowSec} == FALSE
					{
						This.m_BestSellOrderSystem:Set[${orderIterator.Value.SolarSystemID}]
						This.m_BestSellOrderStation:Set[${orderIterator.Value.StationID}]
						return
					}
					else
					{
						Autopilot:SetDestination[${orderIterator.Value.SolarSystemID}]
						wait 10	
						if ${Autopilot.LowSecRoute} == FALSE
						{
							This.m_BestSellOrderSystem:Set[${orderIterator.Value.SolarSystemID}]
							This.m_BestSellOrderStation:Set[${orderIterator.Value.StationID}]
							return
						}
					}
				}
			}
			while ${orderIterator:Next(exists)}
		}

		; If this happens just pause the script to avoid errors
		UI:UpdateConsole["obj_Market.BestSellOrderSystem: ERROR:  Could not find a system to purchase the item.  Pausing script!"]
		Script:Pause
	}

	; Rank orders based on price versus distance
	; Items closed to your location will be given priority even if more expensive
	; This function is intended for use with the trade mission bot.
	; DO NOT use this function with expensive items!!!
	; NOTE: THIS FUNCTION MODIFIES THE SELL ORDER INDEX
	function FindBestWeightedSellOrder(bool avoidLowSec, int quantity)
	{
		variable int     idx
		variable int     count
		variable int     bestIdx
		variable float64 bestWeight
				
		UI:UpdateConsole["obj_Market.BestSellOrderSystem(${avoidLowSec},${quantity})"]

		if ${Station.Docked}
		{
			UI:UpdateConsole["obj_Market.BestSellOrderSystem: WARNING:  Called while docked."]
		}

		; if avoiding low-sec, remove all orders that go through low-sec
		if ${avoidLowSec} == TRUE
		{				
			count:Set[${This.sellOrders.Used}]	
			for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
			{
				Autopilot:SetDestination[${This.sellOrders.Get[${idx}].SolarSystemID}]
				wait 10	
				if ${Autopilot.LowSecRoute} == FALSE
				{
					This.sellOrders:Remove[${idx}]
				}
			}
			This.sellOrders:Collapse
			UI:UpdateConsole["DEBUG: obj_Market.FindBestWeightedSellOrder: ${This.sellOrders.Used} remain after purging low-sec routes."]
		}

		count:Set[${This.sellOrders.Used}]	
		bestIdx:Set[-1]
		bestWeight:Set[999999999.99]

		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			variable float64 weight
		
			if 	${This.sellOrders.Get[${idx}].QuantityRemaining} < ${quantity}
			{
				continue
			}
			
			weight:Set[${Math.Calc[${This.sellOrders.Get[${idx}].Price}*${This.Weight[${This.sellOrders.Get[${idx}].Jumps}]}]}]

			;;UI:UpdateConsole["DEBUG: obj_Market.FindBestWeightedSellOrder ${This.sellOrders.Get[${idx}].Price} ${This.sellOrders.Get[${idx}].Jumps} ${weight}"]

			if ${weight} < ${bestWeight}
			{
				bestWeight:Set[${weight}]
				bestIdx:Set[${idx}]
			}
		}
		
		if ${bestIdx} >= 1
		{
			This.m_BestSellOrderSystem:Set[${This.sellOrders.Get[${bestIdx}].SolarSystemID}]
			This.m_BestSellOrderStation:Set[${This.sellOrders.Get[${bestIdx}].StationID}]
			return
		}

		; If this happens just pause the script to avoid errors
		UI:UpdateConsole["obj_Market.FindBestWeightedSellOrder: ERROR:  Could not find a system to purchase the item.  Pausing script!"]
		Script:Pause
	}

	member:float Weight(int jumps)
	{
		if ${jumps} <= 0
		{
			return 0.20
		}
		
		return ${Math.Calc[${jumps}*0.50]}
	}
	
	function PurchaseItem(int typeID, int quantity)
	{
		variable iterator orderIterator
		
		call This.GetMarketOrders ${typeID}

		This.sellOrders:GetIterator[orderIterator]
		
		if ${Station.Docked} == FALSE
		{
			UI:UpdateConsole["obj_Market.PurchaseItem: WARNING:  Called while undocked."]
		}
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				if ${orderIterator.Value.Jumps} == 0
				{
					if ${orderIterator.Value.QuantityRemaining} > ${quantity}
					{
						EVE:PlaceBuyOrder[${orderIterator.Value.StationID},${orderIterator.Value.TypeID},${orderIterator.Value.Price},${quantity},"Station",1,7]
						return
					}
					else
					{
						; If this happens just pause the script to avoid errors
						UI:UpdateConsole["obj_Market.PurchaseItem: ERROR:  Could not find a valid sell order.  Pausing script!"]
						Script:Pause
					}
				}
			}
			while ${orderIterator:Next(exists)}
		}
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
		UI:UpdateConsole["obj_Market: Obtaining my orders for ${EVEDB_Items.Name[${typeID}]}"]
		Me:UpdateMyOrders
		wait 40
		Me:DoGetMyOrders[This.myBuyOrders,"Buy",${typeID}] 
		wait 10
		Me:DoGetMyOrders[This.mySellOrders,"Sell",${typeID}]
		wait 10

		UI:UpdateConsole["obj_Market: Found ${This.mySellOrders.Used} active sell orders for ${EVEDB_Items.Name[${typeID}]}."]
		UI:UpdateConsole["obj_Market: Found ${This.myBuyOrders.Used} active buy orders for ${EVEDB_Items.Name[${typeID}]}."]
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
