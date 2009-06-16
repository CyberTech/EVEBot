/*
    Assets class
    
    Object to contain members related to asset activities.
    
    -- GliderPro
    
*/

objectdef obj_Assets
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

    variable queue:int StationsWithAssets
    variable index:int IgnoreTheseStations
    
    method Initialize()
    {
        IgnoreTheseStations:Clear[]
        UI:UpdateConsole["obj_Assets: Initialized", LOG_MINOR]
    }
    
    method UpdateList()
    {
        variable index:int AnIndex
        variable iterator  AnIterator
        variable int       tempInt
        
        StationsWithAssets:Clear[]
        ;;; WHY WHY WHY DOESN'T THIS WORK??? Me:DoGetStationsWithAssets[AnIndex]
        tempInt:Set[${Me.GetStationsWithAssets[AnIndex]}]
        AnIndex:GetIterator[AnIterator]
        
        if ${AnIterator:First(exists)}
        {
            do
            {
                StationsWithAssets:Queue[${AnIterator.Value}]
            }
            while ${AnIterator:Next(exists)}        
        }
        
        UI:UpdateConsole["Assets:UpdateList found ${StationsWithAssets.Used} stations with assets."]
    }
    
    method IgnoreStation(int stationID)
    {
        IgnoreTheseStations:Insert[${stationID}]
        UI:UpdateConsole["Assets module will ignore ${EVE.GetLocationNameByID[${stationID}]}."]
    }
    
    member:bool IsIgnored(int stationID)
    {
        variable iterator AnIterator
        
        ;;;UI:UpdateConsole["DEBUG: Assets.IsIgnored(${stationID})"]
        IgnoreTheseStations:GetIterator[AnIterator]
        if ${AnIterator:First(exists)}
        {
            do
            {
                if ${stationID} == ${AnIterator.Value}
                {
                    ;;;UI:UpdateConsole["DEBUG: Assets.IsIgnored returning TRUE."]
                    return TRUE
                }
            }
            while ${AnIterator:Next(exists)}        
        }
        
        ;;;UI:UpdateConsole["DEBUG: Assets.IsIgnored returning FALSE."]
        return FALSE
    }

    member:int NextStation()
    {
        variable int nextStatonID
        
        if ${StationsWithAssets.Used} == 0
        {
            This:UpdateList[]
        }
        
        nextStatonID:Set[0]
        while ${StationsWithAssets.Peek(exists)} && !${nextStatonID}
        {
            if !${This.IsIgnored[${StationsWithAssets.Peek}]}
            {
                nextStatonID:Set[${StationsWithAssets.Peek}]
            }
            
            StationsWithAssets:Dequeue[]
        }
        
        ;;;UI:UpdateConsole["DEBUG: Assets.NextStation returning ${nextStatonID}."]
        return ${nextStatonID}
    }
    
    member:string SolarSystem(int stationID)
    {
		variable string tmp_string
		variable int    spaces
		variable string last_token
		variable int    last_token_pos

		tmp_string:Set[${EVE.GetLocationNameByID[${stationID}]}]
		if ${tmp_string.Find["("]} > 0
		{
			tmp_string:Set[${tmp_string.Token[1,"("]}]		
		}
		else
		{
			tmp_string:Set[${tmp_string.Token[1,"-"]}]
		}
		spaces:Set[${tmp_string.Count[" "]}]
		last_token:Set[${tmp_string.Token[${Math.Calc[${spaces}+1]}," "]}]
		last_token_pos:Set[${tmp_string.Find[" ${last_token}"]}]
		tmp_string:Set[${tmp_string.Left[${last_token_pos}]}]

		return ${tmp_string}
    }
}
