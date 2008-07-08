/*
    Market class
    
    Object to contain members related to market interaction.
    
    -- GliderPro
    
*/

objectdef obj_Market
{
   variable string SVN_REVISION = "$Rev $"
   variable int Version

   variable index:marketorder orderIndex
   variable iterator          orderIterator

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

      EVE:UpdateMarketOrders_A[${typeID}]
      wait 40
      EVE:UpdateMarketOrders_B[${typeID}]
      wait 10
      EVE:DoGetMarketOrders[This.orderIndex,"Sell",${typeID}]
      wait 10
      UI:UpdateConsole["obj_Market: Found ${This.orderIndex.Used} sell orders."]
   }

   function TravelToBestSellOrder(bool AvoidLowSec)
   {
   }
}
