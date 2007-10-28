/*
	Gang Class
	
	This class will contain funtions for managing and manipulating
	your gang.
	
	-- GliderPro

	HISTORY
	------------------------------------------
	10AUG2007 - Initial release of class template
*/

objectdef obj_Gang
{
	variable int GangMemberIndex = 1
	variable index:gangmember GangMembers
	variable int GangMemberCount

	method Initialize()
	{
		GangMemberCount:Set[${Me.GetGang[GangMembers]}]
		echo DEBUG: Populating gang member list:: ${GangMemberCount} members total
		UI:UpdateConsole["obj_Gang: Initialized"]
		
		/* BEGIN TEST CODE */
		variable int i = 1
		do
		{ 
			echo DEBUG: Gang member ${i} - ${GangMembers.Get[${i}].ToPilot.Name}
		}
		while ${i:Inc} <= ${GangMemberCount}
		/* END TEST CODE */
	}

	/* 	
		Issues a gang formation request to the player given
		by the id parameter.
	*/
	method FormGangWithPlayer(int id)
	{
	}
	
	method UpdateGangList()
	{
		GangMemberIndex:Set[1]
		GangMemberCount:Set[${Me.GetGang[GangMembers]}]
		echo DEBUG: Populating gang member list:: ${GangMemberCount} members total
	}
	
	method WarpToMember( int idx, int distance )
	{
		GangMembers.Get[${idx}]:WarpTo[${distance}]
	}
	
	member:gangmember CharIdToGangMember( int charID )
	{
		variable gangmember ReturnValue
		ReturnValue:Set[NULL]
		
		This:UpdateGangList[]
		
		variable iterator GangMemberIterator
		GangMembers:GetIterator[GangMemberIterator]
		
		if ${GangMemberIterator:First(exists)}
		{
			do
			{
				if ${GangMemberIterator.Value.CharID} == ${charID}
				{
					ReturnValue:Set[${GangMemberIterator.Value}]
					break
				}
			}	
			while ${GangMemberIterator:Next(exists)}
		}

		return ${ReturnValue}
	}

	method WarpToGangMember( int charID )
	{
		This:UpdateGangList[]
		
		variable int i = 1
		do
		{ 
			if ${GangMembers.Get[${i}].CharID} == ${charID}
			{
				GangMembers.Get[${i}]:WarpTo
				break
			}
		}
		while ${i:Inc} <= ${GangMemberCount}
	}

	method WarpToNextMember(int distance = 0)
	{		
		GangMemberIndex:Inc
		
		if ${GangMembers.Get[${GangMemberIndex}].CharID} == ${Me.CharID}
		{
			GangMemberIndex:Inc
		}
		
		if ${GangMemberIndex} > ${GangMemberCount}
		{
			GangMemberIndex:Set[1]
		}
		
		This:WarpToMember[${GangMembers.Get[${GangMemberIndex}].CharID},${distance}]
	}	

	method WarpToPreviousMember(int distance = 0)
	{
		if ${GangMembers.Get[${GangMemberIndex}].CharID} == ${Me.CharID}
		{
			GangMemberIndex:Inc
		}
		
		if ${GangMemberIndex} > ${GangMemberCount}
		{
			GangMemberIndex:Set[1]
		}
		
		This:WarpToMember[${GangMembers.Get[${GangMemberIndex}].CharID},${distance}]
	}	
	
}