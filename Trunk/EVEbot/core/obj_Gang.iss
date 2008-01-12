/*
	Fleet Class
	
	This class will contain funtions for managing and manipulating
	your Fleet.
	
	-- GliderPro

	HISTORY
	------------------------------------------
	10AUG2007 - Initial release of class template
*/

objectdef obj_Fleet
{
	variable int FleetMemberIndex = 1
	variable index:fleetmember FleetMembers
	variable int FleetMemberCount

	method Initialize()
	{
		FleetMemberCount:Set[${Me.GetFleet[FleetMembers]}]
		;echo DEBUG: Populating fleet member list:: ${FleetMemberCount} members total
		UI:UpdateConsole["obj_Fleet: Initialized"]
		
		/* BEGIN TEST CODE 
		variable int i = 1
		if (${FleetMemberCount} > 0)
		{
			do
			{ 
				echo DEBUG: Fleet member ${i} - ${FleetMembers.Get[${i}].ToPilot.Name}
			}
			while ${i:Inc} <= ${FleetMemberCount}
		}
		 END TEST CODE */
	}

	/* 	
		Issues a Fleet formation request to the player given
		by the id parameter.
	*/
	method FormFleetWithPlayer(int id)
	{
	}
	
	method UpdateFleetList()
	{
		FleetMemberIndex:Set[1]
		FleetMemberCount:Set[${Me.GetFleet[FleetMembers]}]
		;echo DEBUG: Populating Fleet member list:: ${FleetMemberCount} members total
	}
	
	method WarpToMember( int idx, int distance )
	{
		FleetMembers.Get[${idx}]:WarpTo[${distance}]
	}
	
	member:fleetmember CharIdToFleetMember( int charID )
	{
		variable fleetmember ReturnValue
		ReturnValue:Set[NULL]
		
		This:UpdateFleetList[]
		
		variable iterator FleetMemberIterator
		FleetMembers:GetIterator[FleetMemberIterator]
		
		if ${FleetMemberIterator:First(exists)}
		{
			do
			{
				if ${FleetMemberIterator.Value.CharID} == ${charID}
				{
					ReturnValue:Set[${FleetMemberIterator.Value}]
					break
				}
			}	
			while ${FleetMemberIterator:Next(exists)}
		}

		return ${ReturnValue}
	}

	method WarpToFleetMember( int charID )
	{
		This:UpdateFleetList[]
		
		variable int i = 1
		do
		{ 
			if ${FleetMembers.Get[${i}].CharID} == ${charID}
			{
				FleetMembers.Get[${i}]:WarpTo
				break
			}
		}
		while ${i:Inc} <= ${FleetMemberCount}
	}

	method WarpToNextMember(int distance = 0)
	{		
		FleetMemberIndex:Inc
		
		if ${FleetMembers.Get[${FleetMemberIndex}].CharID} == ${Me.CharID}
		{
			FleetMemberIndex:Inc
		}
		
		if ${FleetMemberIndex} > ${FleetMemberCount}
		{
			FleetMemberIndex:Set[1]
		}
		
		This:WarpToMember[${FleetMembers.Get[${FleetMemberIndex}].CharID},${distance}]
	}	

	method WarpToPreviousMember(int distance = 0)
	{
		if ${FleetMembers.Get[${FleetMemberIndex}].CharID} == ${Me.CharID}
		{
			FleetMemberIndex:Inc
		}
		
		if ${FleetMemberIndex} > ${FleetMemberCount}
		{
			FleetMemberIndex:Set[1]
		}
		
		This:WarpToMember[${FleetMembers.Get[${FleetMemberIndex}].CharID},${distance}]
	}	
	
}