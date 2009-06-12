#define TESTCASE 1

#include Scripts/EVEBotDev/Support/TestAPI.iss

/*
 *	Test DoGetAssets (Listed as GetAssets) [Shiva]
 *
 *	Requirements:
 *		Open Assets window & Have a Station Micro-tabbed out.
 *
 *  Note: Only lists assets cache'd already :(
 *        Can't get around the 5 mins enforced min update time of assets.
 */

#define WITH_STATIONID 0

variable obj_UI UI
function main()
{
	if !${EVEWindow[ByCaption,"ASSETS"](exists)}
	{
		EVE:Execute[OpenAssets]
		; May want a Pause here while it loads...
	}

	variable index:asset AssetsIndex
	variable int RTime = ${Script.RunningTime}

	variable int temp
	if WITH_STATIONID
	{
		; Shiva: Just a value from known list... You could just check entity list in system for a station and then check assets there?
		;        Ala Asset Gatherer.
		temp:Set[${Me.GetAssets[AssetsIndex,60012157]}] ; Alkez VII I think.. Don't recall.
	}
	else
	{
		temp:Set[${Me.GetAssets[AssetsIndex]}]
	}

	echo "- GetAssets took ${Math.Calc[${Script.RunningTime}-${RTime}]} ms. (Used: ${AssetsIndex.Used})"

	variable iterator AssetsIterator
	AssetsIndex:GetIterator[AssetsIterator]

	;echo ${AssetsIndex.ExpandComma}
	/*
		int ID, int OwnerID, string Group, int GroupID, string Category, int CategoryID, string Type, int TypeID, string MacroLocation,
		int MacroLocationID, string Location, int LocationID, int Quantity, string Description, int GraphicID, double Volume,
		int MarketGroupID, double BasePrice, double Capacity, double Radius
	 */
	if ${AssetsIterator:First(exists)}
	{
		do
		{
			echo AssetsIterator.Value.ID ${AssetsIterator.Value.ID}
			echo AssetsIterator.Value.OwnerID ${AssetsIterator.Value.OwnerID}
			echo AssetsIterator.Value.Group ${AssetsIterator.Value.Group}
			echo AssetsIterator.Value.GroupID ${AssetsIterator.Value.GroupID}
			; I'd prefer to see something like this though
			; echo AssetsIterator.Value.Group [ID: ${AssetsIterator.Value.GroupID}] ${AssetsIterator.Value.Group}
			echo AssetsIterator.Value.Category ${AssetsIterator.Value.Category}
			echo AssetsIterator.Value.CategoryID ${AssetsIterator.Value.CategoryID}
			echo AssetsIterator.Value.Type ${AssetsIterator.Value.Type}
			echo AssetsIterator.Value.TypeID ${AssetsIterator.Value.TypeID}
			echo AssetsIterator.Value.MacroLocation ${AssetsIterator.Value.MacroLocation}
			echo AssetsIterator.Value.MacroLocationID ${AssetsIterator.Value.MacroLocationID}
			echo AssetsIterator.Value.Location ${AssetsIterator.Value.Location}
			echo AssetsIterator.Value.LocationID ${AssetsIterator.Value.LocationID}
			echo AssetsIterator.Value.Quantity ${AssetsIterator.Value.Quantity}
			echo AssetsIterator.Value.Description ${AssetsIterator.Value.Description}
			echo AssetsIterator.Value.GraphicID ${AssetsIterator.Value.GraphicID}
			echo AssetsIterator.Value.Volume ${AssetsIterator.Value.Volume}
			echo AssetsIterator.Value.MarketGroupID ${AssetsIterator.Value.MarketGroupID}
			echo AssetsIterator.Value.BasePrice ${AssetsIterator.Value.BasePrice}
			echo AssetsIterator.Value.Capacity ${AssetsIterator.Value.Capacity}
			echo AssetsIterator.Value.Radius ${AssetsIterator.Value.Radius}
		}
		while ${AssetsIterator:Next(exists)}
	}
}