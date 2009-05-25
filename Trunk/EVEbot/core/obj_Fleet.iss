/*
	Fleet Class

	This class will contain funtions for managing and manipulating
	your Fleet.

	-- GliderPro

*/

objectdef obj_Fleet
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable int FleetMemberIndex = 1
	variable set AllowedFleetMembers
	variable index:fleetmember FleetMembers
	variable int FleetMemberCount
	variable iterator FleetMembersIterator

	method Initialize()
	{
		Config.FleetMembers.Ref:GetSettingIterator[This.FleetMembersIterator]
		if ${This.FleetMembersIterator:First(exists)}
		do
		{
			This.AllowedFleetMembers:Add[${This.FleetMembersIterator.Value}]
		}
		while ${This.FleetMembersIterator:Next(exists)}

		UI:UpdateConsole["obj_Fleet: Initialized", LOG_MINOR]
		UI:UpdateConsole["obj_Fleet: ${This.AllowedFleetMembers.Used} permitted fleet members added"]
	}

	method ProcessInvitations()
	{
		variable string Inviter

		if ${Me.IsInFleet} || !${Me.IsInvitedToFleet}
		{
			return
		}

		;<html><body>charname wants you to join their fleet
		Inviter:Set[${Me.FleetInvitationText}]
		Inviter:Set[${Inviter.Left[${Inviter.Find[" wants you to join their fleet"]}]}]
		Inviter:Set[${Inviter.Mid[13, -1]}]

		if ${This.AllowedFleetMembers.Contains["${Inviter}"]}
		{
			UI:UpdateConsole["obj_Fleet: Accepting fleet invitation from ${Inviter}"]
			Me:AcceptFleetInvite
		}
		else
		{
			UI:UpdateConsole["obj_Fleet: Rejecting fleet invitation from ${Inviter}"]
			Me:RejectFleetInvite
		}
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

	method WarpToNextMember(int distance = 0)
	{
		FleetMemberIndex:Inc

		if ${FleetMembers.Get[${FleetMemberIndex}].CharID} == ${_Me.CharID}
		{
			FleetMemberIndex:Inc
		}

		if ${FleetMemberIndex} > ${FleetMemberCount}
		{
			FleetMemberIndex:Set[1]
		}

		Ship:WarpToMember[${FleetMembers.Get[${FleetMemberIndex}].CharID},${distance}]
	}

	method WarpToPreviousMember(int distance = 0)
	{
		if ${FleetMembers.Get[${FleetMemberIndex}].CharID} == ${_Me.CharID}
		{
			FleetMemberIndex:Inc
		}

		if ${FleetMemberIndex} > ${FleetMemberCount}
		{
			FleetMemberIndex:Set[1]
		}

		Ship:WarpToMember[${FleetMembers.Get[${FleetMemberIndex}].CharID},${distance}]
	}

}