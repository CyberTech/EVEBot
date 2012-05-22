/*

	Fleet Class
	
	Primary Fleet behavior module for EVEBot
	
	-- Tehtsuo
	
*/

objectdef obj_Fleet
{
	;	Versioning information
	variable string SVN_REVISION = "$Rev: 2248 $"
	variable int Version
	
	;	Pulse tracking information
	variable time NextPulse
	variable int PulseIntervalInSeconds = 10
	
	
	
	
/*	
;	Step 1:  	Get the module ready.  This includes init and shutdown methods, as well as the pulse method that runs each frame.
;				Adjust PulseIntervalInSeconds above to determine how often the module will Process.
*/	
	
	method Initialize()
	{

		This.TripStartTime:Set[${Time.Timestamp}]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This.NextPulse:Set[${Time.Timestamp}]
		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
		This.NextPulse:Update
		
		UI:UpdateConsole["obj_Fleet: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}	
	
	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}
		
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${Config.Fleet.ManageFleet}
			{
				This:Process
			}
			
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}	
	

/*	
;	Step 1:  	Method used by the Pulse event.
;				
*/	
	
	
	method Process()
	{
		;	Step 1 - Accept fleet invites from my leader
		if ${Me.Fleet.Invited}
		{
			if ${Me.Fleet.InvitationText.Find[${Config.Fleet.FleetLeader}]}
			{
				Me.Fleet:AcceptInvite
			}
		}

		;	Step 2 - Send fleet invites if I'm leader
		if ${Config.Fleet.IsLeader}
		{
			Config.Fleet:RefreshFleetMembers
			variable iterator InfoFromSettings
			Config.Fleet.FleetMembers:GetIterator[InfoFromSettings]
			
			if ${InfoFromSettings:First(exists)}
				do
				{
					if !${Me.Fleet.IsMember[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]}
					{
						This:InviteToFleet[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]
					}
					else
					{
						if ${Config.Fleet.IsWing[${InfoFromSettings.Value.FleetMemberName}]}
						{
							variable index:int64 Wings
							variable index:int64 Squads
							variable int64 OtherWing
							variable int64 OtherSquad
							variable iterator Wing
							Me.Fleet:GetWings[Wings]
							if ${Wings.Used} == 1
							{
								Me.Fleet:CreateWing
								return
							}
							Me.Fleet:GetWings[Wings]
							Wings:GetIterator[Wing]
							if ${Wing:First(exists)}
								do
								{
									if ${Wing.Value} != ${Me.Fleet.Member[${Me.CharID}].WingID}
									{
										OtherWing:Set[${Wing.Value}]
										Me.Fleet:GetSquads[Squads, ${Wing.Value}]
										OtherSquad:Set[${Squads[1]}]
									}
								}
								while ${Wing:Next(exists)}
							
							if ${Me.Fleet.Member[${Me.CharID}].WingID} == ${Me.Fleet.Member[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}].WingID}
							{
								Me.Fleet.Member[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]:Move[${OtherWing}, ${OtherSquad}]
							}
						}
					}
				}
				while ${InfoFromSettings:Next(exists)}
		}
		else
		{
			if ${Me.Fleet.IsMember[${Me.CharID}]}
			{
				if !${Me.Fleet.IsMember[${This.ResolveCharID[${Config.Fleet.FleetLeader}]}]}
					{
					Me.Fleet:LeaveFleet
					}
			}
		}
		
				
	}
	
	member:int64 ResolveCharID(string value)
	{
		variable index:pilot CorpMembers
		variable iterator CorpMember

		EVE:GetOnlineCorpMembers[CorpMembers]
		CorpMembers:GetIterator[CorpMember]
		if ${CorpMember:First(exists)}
			do
			{
				if ${CorpMember.Value.Name.Equal[${value}]} && ${CorpMember.Value.IsOnline}
					return ${CorpMember.Value.CharID}
			}
			while ${CorpMember:Next(exists)}

		variable index:being Buddies
		variable iterator Buddy

		EVE:GetBuddies[Buddies]
		Buddies:GetIterator[Buddy]
		if ${Buddy:First(exists)}
			do
			{
				if ${Buddy.Value.Name.Equal[${value}]} && ${Buddy.Value.IsOnline}
					return ${Buddy.Value.CharID}
			}
			while ${Buddy:Next(exists)}

		variable index:pilot LocalPilots
		variable iterator LocalPilot

		EVE:GetLocalPilots[LocalPilots]
		LocalPilots:GetIterator[LocalPilot]
		if ${LocalPilot:First(exists)}
			do
			{
				if ${LocalPilot.Value.Name.Equal[${value}]}
					return ${LocalPilot.Value.CharID}
			}
			while ${LocalPilot:Next(exists)}
			

		return 0
	}
	
	method InviteToFleet(int64 value)
	{
		variable index:pilot CorpMembers
		variable iterator CorpMember

		EVE:GetOnlineCorpMembers[CorpMembers]
		CorpMembers:GetIterator[CorpMember]
		if ${CorpMember:First(exists)}
			do
			{
				if ${CorpMember.Value.CharID} == ${value}
				{
					CorpMember.Value:InviteToFleet
					return
				}
			}
			while ${CorpMember:Next(exists)}

		variable index:being Buddies
		variable iterator Buddy

		EVE:GetBuddies[Buddies]
		Buddies:GetIterator[Buddy]
		if ${Buddy:First(exists)}
			do
			{
				if ${Buddy.Value.CharID} == ${value}
				{
					Buddy.Value:InviteToFleet
					return
				}
			}
			while ${Buddy:Next(exists)}

		variable index:pilot LocalPilots
		variable iterator LocalPilot

		EVE:GetLocalPilots[LocalPilots]
		LocalPilots:GetIterator[LocalPilot]
		if ${LocalPilot:First(exists)}
			do
			{
				if ${LocalPilot.Value.CharID} == ${value}
				{
					LocalPilot.Value:InviteToFleet
					return
				}
			}
			while ${LocalPilot:Next(exists)}
		
	}
	
	method WarpTo(string value, int distance=0)
	{
		if ${Local[${value}](exists)}
		{
			if ${Entity[${value}](exists)}
			{
				Entity[${value}]:WarpTo[${distance}]
			}
			elseif ${Local[${value}].ToFleetMember(exists)}
			{
				Local[${value}].ToFleetMember:WarpTo[${distance}]
			}
		}
	}
}