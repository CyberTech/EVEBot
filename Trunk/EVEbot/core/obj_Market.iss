/*
	Market class

	Object to contain members related to market interaction.

	-- GliderPro

*/

objectdef obj_Market inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable index:marketorder  sellOrders
	variable index:marketorder  buyOrders
	variable index:myorder      mySellOrders
	variable index:myorder      myBuyOrders
	variable int                m_BestSellOrderSystem
	variable int                m_BestSellOrderStation

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		;PulseTimer:SetIntervals[0.5,1.0]
		;Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

 	function GetMarketOrders(int typeID)
 	{
		Logger:Log["obj_Market: Obtaining market data for ${EVEDB_Items.Name[${typeID}]} (${typeID})"]

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

		Logger:Log["obj_Market: Found ${This.sellOrders.Used} sell orders."]
		Logger:Log["obj_Market: Found ${This.buyOrders.Used} buy orders."]

		call This.QuicksortSellOrders 1 ${This.sellOrders.Used}
		call This.QuicksortBuyOrders 1 ${This.buyOrders.Used}
 	}

	function GetMarketSellOrders(int typeID)
	{
		;Logger:Log["${This.ObjectName}: Obtaining market sell orders for item ${typeID}:${EVEDB_Items.Name[${typeID}]}"]

		This.sellOrders:Clear

		EVE:UpdateMarketOrders_A[${typeID}]
		wait 50
		EVE:UpdateMarketOrders_B[${typeID}]
		wait 20
		EVE:DoGetMarketOrders[This.sellOrders,"Sell",${typeID}]
		wait 20

		Logger:Log["${This.ObjectName}: GetMarketSellOrders Item ${typeID}:${EVEDB_Items.Name[${typeID}]} Orders - Sell: ${This.sellOrders.Used}"]

		call This.QuicksortSellOrders 1 ${This.sellOrders.Used}
 	}

	function GetMarketBuyOrders(int typeID)
	{

		This.buyOrders:Clear

		EVE:UpdateMarketOrders_A[${typeID}]
		wait 50
		EVE:UpdateMarketOrders_B[${typeID}]
		wait 20
		EVE:DoGetMarketOrders[This.buyOrders,"Buy",${typeID}]
		wait 20

		Logger:Log["${This.ObjectName}: GetMarketBuyOrders: Item ${typeID}:${EVEDB_Items.Name[${typeID}]} Orders - Buy: ${This.buyOrders.Used}"]

		call This.QuicksortBuyOrders 1 ${This.buyOrders.Used}
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

		Logger:Log["obj_Market.BestSellOrderSystem(${avoidLowSec},${quantity})"]

		This.sellOrders:GetIterator[orderIterator]

		if ${Station.Docked}
		{
			Logger:Log["obj_Market.BestSellOrderSystem: WARNING:  Called while docked."]
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
		Logger:Log["obj_Market.BestSellOrderSystem: ERROR:  Could not find a system to purchase the item.  Pausing script!"]
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

		Logger:Log["obj_Market.BestSellOrderSystem(${avoidLowSec},${quantity})"]

		if ${Station.Docked}
		{
			Logger:Log["obj_Market.BestSellOrderSystem: WARNING:  Called while docked."]
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
			Logger:Log["DEBUG: obj_Market.FindBestWeightedSellOrder: ${This.sellOrders.Used} remain after purging low-sec routes."]
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

			;;Logger:Log["DEBUG: obj_Market.FindBestWeightedSellOrder ${This.sellOrders.Get[${idx}].Price} ${This.sellOrders.Get[${idx}].Jumps} ${weight}"]

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
		Logger:Log["obj_Market.FindBestWeightedSellOrder: ERROR:  Could not find a system to purchase the item.  Pausing script!"]
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
			Logger:Log["obj_Market.PurchaseItem: WARNING:  Called while undocked."]
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
						Logger:Log["obj_Market.PurchaseItem: ERROR:  Could not find a valid sell order.  Pausing script!"]
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

		;Logger:Log["DEBUG: ${left} ${right} ${pivotIndex} ${pivotValue}"]

		;Logger:Log["DEBUG: SWAP ${pivotIndex} ${right}"]
		This.buyOrders:Swap[${pivotIndex},${right}]

		storeIndex:Set[${left}]

		for ( idx:Set[${left}]; ${idx} < ${right}; idx:Inc )
		{
			if ${This.buyOrders.Get[${idx}].Price} <= ${pivotValue}
			{
				;Logger:Log["DEBUG: SWAP ${storeIndex} ${idx} ${This.buyOrders.Get[${idx}].Price} <= ${pivotValue}"]
				This.buyOrders:Swap[${storeIndex},${idx}]
				storeIndex:Inc
			}
		}

		;Logger:Log["DEBUG: SWAP ${storeIndex} ${right}"]
		This.buyOrders:Swap[${storeIndex},${right}]

		;Logger:Log["DEBUG: RTN ${storeIndex}"]

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

		Logger:Log["obj_Market: Filtering all orders more than ${jumps} jumps away from your present location."]

		count:Set[${This.sellOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.sellOrders.Get[${idx}].Jumps} > ${jumps}
			{
				This.sellOrders:Remove[${idx}]
			}
		}
		This.sellOrders:Collapse
		Logger:Log["obj_Market: Filtered ${Math.Calc[${count}-${This.sellOrders.Used}].Int} sell orders."]

		count:Set[${This.buyOrders.Used}]
		removed:Set[0]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.buyOrders.Get[${idx}].Jumps} > ${jumps}
			{
				This.buyOrders:Remove[${idx}]
			}
		}
		This.buyOrders:Collapse
		Logger:Log["obj_Market: Filtered ${Math.Calc[${count}-${This.buyOrders.Used}].Int} buy orders."]
 	}

 	function FilterBuyOrdersByRange(int jumps)
 	{
		variable int idx
		variable int count

		Logger:Log["${This.ObjectName}: Filtering all orders more than ${jumps} jumps away from your present location."]

		count:Set[${This.buyOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.buyOrders.Get[${idx}].Jumps} > ${jumps}
			{
				Logger:Log["${This.ObjectName}: Removing order ${This.buyOrders.Get[${idx}].ID}."]
				This.buyOrders:Remove[${idx}]
			}
		}
		This.buyOrders:Collapse
		;This:DumpBuyOrders
 	}

;	member:float64 LowestSellOrder()
;	{
;		return ${This.sellOrders.Get[1].Price}
;	}
	member:float64 LowestSellOrder(int MinQuantity=1, float MinPrice=0.0)
	{
		variable int idx
		variable int count

		; Return the lowest order that is NOT ours AND meets our min price AND meets our minquantity remaining
		if ${MinQuantity} > 1
		{
			count:Set[${This.sellOrders.Used}]
			for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
			{
				if ${This.IsMySellOrder[${This.sellOrders.Get[${idx}].ID}]}
				{
					continue
				}

				if ${This.sellOrders.Get[${idx}].QuantityRemaining} >= ${MinQuantity}
				{
					if ${This.sellOrders.Get[${idx}].Price} >= ${MinPrice}
					{
						return ${This.sellOrders.Get[${idx}].Price}
					}
					else
					{
						Logger:LogIRC["LowestSellOrder: Ignored Order: ${This.sellOrders.Get[${idx}].Name}: ${This.sellOrders.Get[${idx}].QuantityRemaining.Int} @ ${This.sellOrders.Get[${idx}].Price.Centi} (Price Delta)", LOG_CRITICAL]
					}
				}
				else
				{
					Logger:LogIRC["LowestSellOrder: Ignored Order: ${This.sellOrders.Get[${idx}].Name}: ${This.sellOrders.Get[${idx}].QuantityRemaining.Int} @ ${This.sellOrders.Get[${idx}].Price.Centi} (Small order)", LOG_CRITICAL]
				}
			}
			; Fell thru -- no order have the min quantity, so return the lowest
			Logger:LogIRC["LowestSellOrder: Warning: No orders had requested min quantity of ${MinQuantity} and min price of ${MinPrice.Centi}, returning lowest price of all orders", LOG_CRITICAL]
		}

		; Return the lowest order that is NOT ours AND meets our min price
		if ${MinPrice} > 0.0
		{
			count:Set[${This.sellOrders.Used}]
			for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
			{
				if ${This.IsMySellOrder[${This.sellOrders.Get[${idx}].ID}]}
				{
					continue
				}

				if ${This.sellOrders.Get[${idx}].Price} >= ${MinPrice}
				{
					return ${This.sellOrders.Get[${idx}].Price}
				}
				Logger:LogIRC["LowestSellOrder: Ignored Order: ${This.sellOrders.Get[${idx}].Name}: ${This.sellOrders.Get[${idx}].QuantityRemaining.Int} @ ${This.sellOrders.Get[${idx}].Price.Centi} (Price Delta)", LOG_CRITICAL]
			}
			Logger:LogIRC["LowestSellOrder: Warning: No orders had requested min price of ${MinPrice.Centi}, returning lowest price of all orders", LOG_CRITICAL]
		}

		; Return the lowest order that is NOT ours
		count:Set[${This.sellOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.IsMySellOrder[${This.sellOrders.Get[${idx}].ID}]}
			{
				continue
			}
			return ${This.sellOrders.Get[${idx}].Price}
		}

		; Fell thru -- no order have the min quantity, so return the lowest
		return ${This.sellOrders.Get[1].Price}
	}

	member:float64 HighestBuyOrder()
	{
		variable int idx

		for ( idx:Set[${This.buyOrders.Used}]; ${idx} > 0; idx:Dec )
		{
			if ${This.IsMyBuyOrder[${This.buyOrders.Get[${idx}].ID}]}
			{
				continue
			}
			return ${This.buyOrders.Get[${idx}].Price}
		}

		; Shouldn't get here.  If we do, return the highest entry.
		return ${This.buyOrders.Get[${This.buyOrders.Used}].Price}
	}

	function GetMyBuyOrders(int typeID=0)
	{
		variable int TotalOrders

		This.myBuyOrders:Clear

		if ${typeID} != 0
		{
			Logger:Log["${This.ObjectName}: Obtaining my buy orders for ${EVEDB_Items.Name[${typeID}]}"]
			TotalOrders:Set[${Me.GetMyOrders[This.myBuyOrders,"Buy",${typeID}]}]
		}
		else
		{
			Logger:Log["${This.ObjectName}: Obtaining my buy orders for all items"]
			TotalOrders:Set[${Me.GetMyOrders[This.myBuyOrders,"Buy"]}]
		}

		if ${TotalOrders} > 0
		{
			Logger:Log["${This.ObjectName}: Waiting up to 1 minute to retrieve ${TotalOrders} orders"]
			wait 600 ${This.myBuyOrders.Get[${TotalOrders}].Name(exists)}
		}
	}

	function GetMySellOrders(int typeID=0)
	{
		variable int TotalOrders

		This.mySellOrders:Clear
		if ${typeID} != 0
		{
			Logger:Log["${This.ObjectName}: Obtaining my sell orders for ${EVEDB_Items.Name[${typeID}]}"]
			TotalOrders:Set[${Me.GetMyOrders[This.mySellOrders,"Sell",${typeID}]}]
			wait 30
		}
		else
		{
			Logger:Log["${This.ObjectName}: Obtaining my sell orders for all items"]
			TotalOrders:Set[${Me.GetMyOrders[This.mySellOrders,"Sell"]}]
			wait 30
		}

		if ${TotalOrders} > 0
		{
			Logger:Log["${This.ObjectName}: Waiting up to 1 minute to retrieve ${TotalOrders} orders"]
			wait 600 ${This.mySellOrders.Get[${TotalOrders}].Name(exists)}
		}
	}

	function GetMyOrders(int typeID)
	{
		Logger:Log["obj_Market: Obtaining my orders for ${EVEDB_Items.Name[${typeID}]}"]
		Me:UpdateMyOrders
		wait 40
		Me:DoGetMyOrders[This.myBuyOrders,"Buy",${typeID}]
		wait 10
		Me:DoGetMyOrders[This.mySellOrders,"Sell",${typeID}]
		wait 10

		Logger:Log["obj_Market: Found ${This.mySellOrders.Used} active sell orders for ${EVEDB_Items.Name[${typeID}]}."]
		Logger:Log["obj_Market: Found ${This.myBuyOrders.Used} active buy orders for ${EVEDB_Items.Name[${typeID}]}."]
	}

	member:bool IsMySellOrder(int OrderID)
	{
		variable int idx
		variable int count

		count:Set[${This.mySellOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.mySellOrders.Get[${idx}].ID} == ${OrderID}
			{
				return TRUE
			}
		}

		return FALSE
	}

	member:bool IsMyBuyOrder(int OrderID)
	{
		variable int idx
		variable int count

		count:Set[${This.myBuyOrders.Used}]
		for ( idx:Set[1]; ${idx} <= ${count}; idx:Inc )
		{
			if ${This.myBuyOrders.Get[${idx}].ID} == ${OrderID}
			{
				return TRUE
			}
		}

		return FALSE
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
						Logger:Log["obj_Market: Adjusting order ${orderIterator.Value.ID} to ${sellPrice}."]
						orderIterator.Value:Modify[${sellPrice}]
					}
					else
					{
						Logger:Log["obj_Market: ERROR: Sell price (${sellPrice}) exceeds limit!!"]
					}
				}
				else
				{
					Logger:Log["obj_Market: Order ${orderIterator.Value.ID} is currently the lowest sell order."]
				}
			}
			while ${orderIterator:Next(exists)}
		}
	}

	function UpdateMySellOrdersEx(int TypeID, float64 delta=0.01, float64 MaxChange=481, float64 MaxPrice=5000000, MinQuantity=2)
	{
		variable iterator Orders
		variable float LowestPrice

		This.mySellOrders:GetIterator[Orders]
		if ${Orders:First(exists)}
		{
			do
			{
				if !${Orders.Value(exists)}
				{
					Logger:Log["UpdateMySellOrders: ERROR - Found null order", LOG_CRITICAL]
					continue
				}

				if ${Orders.Value.TypeID} != ${TypeID}
				{
					;Logger:Log["UpdateMySellOrders: TypeID: ${Orders.Value.TypeID} != ${TypeID}"]
					continue
				}
				if ${Orders.Value.RegionID} != ${Me.RegionID}
				{
					Logger:Log["UpdateMySellOrders: RegionID: ${Orders.Value.RegionID} != ${Me.RegionID}"]
					continue
				}

				Logger:LogIRC["Processing Sell Order: ${Orders.Value.Name} ${Orders.Value.QuantityRemaining.Int}/${Orders.Value.InitialQuantity} @ ${Orders.Value.Price.Centi}"]

				; Find the lowest price that has both the minquantity AND ourprice-maxchange in price
				; This is so that if we are at 10, our maxchange is 2, and there are orders for 5, 8, and 10, we will still pricematch the 8, but ignore the 5
				sellPrice:Set[${Math.Calc[${Orders.Value.Price}-${MaxChange}]}]
				LowestPrice:Set[${This.LowestSellOrder[${MinQuantity}, ${sellPrice}]}]

				if ${Orders.Value.Price} > ${LowestPrice}
				{
					variable float64 sellPrice
					variable float64 PriceDiff
					sellPrice:Set[${Math.Calc[${LowestPrice}-${delta}]}]
					sellPrice:Set[${sellPrice.Precision[2]}]
					PriceDiff:Set[${Math.Calc[${sellPrice} - ${Orders.Value.Price}]}]

					if ${PriceDiff} > 0
					{
						Logger:LogIRC["UpdateMySellOrders: Increasing Sell Price: ${Orders.Value.Name} Old: ${Orders.Value.Price.Centi} New: ${sellPrice.Centi} Increase: ${PriceDiff.Centi}", LOG_CRITICAL]
						Orders.Value:Modify[${sellPrice}]
					}
					else
					{
						; Get a positive difference
						PriceDiff:Set[${Math.Calc[${Orders.Value.Price} - ${sellPrice}]}]
						if ${sellPrice} > ${MaxPrice}
						{
							Logger:LogIRC["UpdateMySellOrders: Ignoring Order: ${Orders.Value.Name} Old: ${Orders.Value.Price.Centi} New: ${sellPrice.Centi} Decrease: ${PriceDiff.Centi}, maximum price (${MaxPrice.Centi}) exceeded", LOG_CRITICAL]
						}
						elseif ${PriceDiff} > ${MaxChange}
						{
							Logger:LogIRC["UpdateMySellOrders: Warning: ${Orders.Value.Name} Current: ${Orders.Value.Price.Centi} New: ${sellPrice.Centi} Decrease: ${PriceDiff.Centi}, price change limit (${MaxChange.Centi}) exceeded", LOG_CRITICAL]
						}
						else
						{
							Logger:LogIRC["UpdateMySellOrders: Decreasing Price: ${Orders.Value.Name} Old: ${Orders.Value.Price.Centi} New: ${sellPrice.Centi} Decrease: ${PriceDiff.Centi}", LOG_CRITICAL]
							Orders.Value:Modify[${sellPrice}]
						}
					}
				}
				else
				{
					Logger:Log["Skipping Order: ${Orders.Value.Name} Price: ${Orders.Value.Price.Centi}, already lowest"]
				}
				wait 5
			}
			while ${Orders:Next(exists)}
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
						Logger:Log["obj_Market: Adjusting order ${orderIterator.Value.ID} to ${buyPrice}."]
						orderIterator.Value:Modify[${buyPrice}]
					}
					else
					{
						Logger:Log["obj_Market: ERROR: Buy price (${buyPrice}) exceeds limit!!"]
					}
				}
				else
				{
					Logger:Log["obj_Market: Order ${orderIterator.Value.ID} is currently the highest buy order."]
				}
			}
			while ${orderIterator:Next(exists)}
		}
	}

	method DumpSellOrders()
	{
		variable iterator orderIterator

		Logger:Log["obj_Market.DumpSellOrders: dumping..."]

		This.sellOrders:GetIterator[orderIterator]

		if ${orderIterator:First(exists)}
		{
			do
			{
				Logger:Log["obj_Market.DumpSellOrders: ${orderIterator.Value.ID} ${orderIterator.Value.Jumps} ${orderIterator.Value.Price} ${orderIterator.Value.QuantityRemaining.Int}/${orderIterator.Value.InitialQuantity}."]
			}
			while ${orderIterator:Next(exists)}
		}
	}

	method DumpBuyOrders()
	{
		variable iterator orderIterator

		Logger:Log["obj_Market.DumpBuyOrders: dumping..."]

		This.buyOrders:GetIterator[orderIterator]

		if ${orderIterator:First(exists)}
		{
			do
			{
				Logger:Log["obj_Market.DumpBuyOrders: ${orderIterator.Value.ID} ${orderIterator.Value.Jumps} ${orderIterator.Value.Price} ${orderIterator.Value.QuantityRemaining.Int}/${orderIterator.Value.InitialQuantity}."]
			}
			while ${orderIterator:Next(exists)}
		}
	}
}
