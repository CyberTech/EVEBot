/* Explanation of room numbers -

they are intended to be used when the salvaging part of the bot is completed so we can inform our salvager which areas are clear

room 0 is always the area that is where the mission bookmark is
rooms are divided by a warp , so using an acceleration gate or warping to another boookmark would mean whereever you land is room 1
*/

/* TODO FOR MISSIONS - Evebot must 1. Change ammo type to that required by the mission (absolutley vital as l4s are simply not possible without this)
																	 2. Change tank type to that required by te mission (impossible with current isxeve)
																	 3. Check we have commands for the mission before we accept the damn thing
																	 */
objectdef obj_MissionCombat
{
	
	
	function WarpToEncounter(int agentID)
	{
		variable index:agentmission amIndex
		variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

		EVE:DoGetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:DoGetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["dungeon"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value} FALSE
								return
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}
}