/*
    Assets class
    
    Object to contain members related to asset activities.
    
    -- GliderPro
    
*/

objectdef obj_Assets
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

    variable queue:int64 StationsWithAssets
    variable index:int64 IgnoreTheseStations
    
    method Initialize()
    {
        IgnoreTheseStations:Clear[]
        UI:UpdateConsole["obj_Assets: Initialized", LOG_MINOR]
    }
    
    method UpdateList()
    {
        variable index:int64 AnIndex
        variable iterator  AnIterator
        
        StationsWithAssets:Clear[]
        ;;; WHY WHY WHY DOESN'T THIS WORK??? Me:GetStationsWithAssets[AnIndex]
        Me:GetStationsWithAssets[AnIndex]
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
    
    method IgnoreStation(int64 stationID)
    {
        IgnoreTheseStations:Insert[${stationID}]
        UI:UpdateConsole["Assets module will ignore ${EVE.GetLocationNameByID[${stationID}]}."]
    }
    
    member:bool IsIgnored(int64 stationID)
    {
        variable iterator AnIterator
        
        ;;;UI:UpdateConsole["DEBUG: Assets.IsIgnored(${stationID})"]
        IgnoreTheseStations:GetIterator[AnIterator]
        if ${AnIterator:First(exists)}
        {
            do
            {
                if ${stationID.Equal[${AnIterator.Value}]}
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
        variable int64 nextStatonID
        
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
    
    member:string SolarSystem(int64 stationID)
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
