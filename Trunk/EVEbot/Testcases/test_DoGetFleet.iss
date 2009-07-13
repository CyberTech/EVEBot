#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Fleet Member Iteration, FleetMember.ToPilot

	Revision $Id$

	Tests:
		Me.Fleet:GetWings
		Me.Fleet:GetSquads
		Me.Fleet:GetMembers
		Me.Fleet.WingName
		Me.Fleet.Size
		FleetMember - All Members
		FleetMember:SetScout
		FleetMember:SetBooster

	Requirements:
		You: In Space
		Other: In Fleet, In Space, on Grid
*/

variable obj_UI UI
function main(string Invitee)
{
		variable index:fleetmember FleetIndex
		variable iterator Wing
		variable index:int64 Wings

		echo " "
		echo "${Script.Filename} Starting..."

		echo " Inviting ${Invitee} to fleet..."

		if !${Me.Fleet.ID(exists)} && ${Invitee.Length} == 0
		{
			echo "Must be in fleet or specify character to invite on the command line"
			Script:End
		}

		if ${Invitee.Length} > 0
		{
			if !${Local[${Invitee}](exists)}
			{
				echo "Specified invitee ${Invitee} does not exist"
				Script:End
			}
			Local[${Invitee}]:InviteToFleet
			while ${Me.Fleet.Size} < 2
			{
				waitframe
			}
		}
		echo " "
		echo "There are ${Me.Fleet.Size} fleet members"

		Me.Fleet:GetWings[Wings]
		Wings:GetIterator[Wing]

		if ${Wing:First(exists)}
		{
			variable index:int64 Squads
			variable iterator Squad
			do
			{
				echo Wing ID: ${Wing.Value} -> Name: ${Me.Fleet.WingName[${Wing.Value}]} -> ID: ${Me.Fleet.WingNameToID[${Me.Fleet.WingName[${Wing.Value}]}]}
				Me.Fleet:GetSquads[Squads, ${Wing.Value}]
				Squads:GetIterator[Squad]
				if ${Squad:First(exists)}
				{
					do
					{
						echo " Squad ID: ${Squad.Value} -> Name: ${Me.Fleet.SquadName[${Squad.Value}]} -> ID: ${Me.Fleet.SquadNameToID[${Me.Fleet.SquadName[${Squad.Value}]}]}"
					}
					while ${Squad:Next(exists)}
				}
			}
			while ${Wing:Next(exists)}
		}
return
		echo "Fleet Member List:"

		Me.Fleet:GetMembers[FleetIndex]
		echo "GetMembers returned ${FleetIndex.Used} fleet members"
		variable iterator FleetMember
		FleetIndex:GetIterator[FleetMember]

		if ${FleetMember:First(exists)}
		{
			do
			{
				if ${FleetMember.Value.CharID} == ${Me.CharID}
				{
					continue
				}
				wait 10
				echo " "
				echo "*" FleetMember.ToPilot ${FleetMember.Value.ToPilot}
				echo "  " FleetMember.Boosting ${FleetMember.Value.Boosting}
				echo "  " FleetMember.CharID ${FleetMember.Value.CharID}
				echo "  " FleetMember.HasActiveBeacon ${FleetMember.Value.HasActiveBeacon}
				echo "  " FleetMember.Job ${FleetMember.Value.Job}
				echo "  " FleetMember.JobID ${FleetMember.Value.JobID}
				echo "  " FleetMember.Role ${FleetMember.Value.Role}
				echo "  " FleetMember.RoleID ${FleetMember.Value.RoleID}
				echo "  " FleetMember.SquadID ${FleetMember.Value.SquadID}
				echo "  " FleetMember.ToEntity ${FleetMember.Value.ToEntity}
				echo "  " FleetMember.WingID ${FleetMember.Value.WingID}

				echo " "
				echo " Testing Methods"
				echo "  Setting Scout Status ON"
					FleetMember.Value:SetScout[1]
					wait 20
					echo "  " FleetMember.Job ${FleetMember.Value.Job}
					echo "  " FleetMember.JobID ${FleetMember.Value.JobID}

				echo "  Setting Scout Status OFF"
					FleetMember.Value:SetScout[0]
					wait 20
					echo "  " FleetMember.Job ${FleetMember.Value.Job}
					echo "  " FleetMember.JobID ${FleetMember.Value.JobID}

				echo "  Setting Booster Status FLEET"
					FleetMember.Value:SetBooster[1]
					wait 20
					echo "  " FleetMember.Boosting ${FleetMember.Value.Boosting}

				echo "  Setting Booster Status WING"
					FleetMember.Value:SetBooster[2]
					wait 20
					echo "  " FleetMember.Boosting ${FleetMember.Value.Boosting}

				echo "  Setting Booster Status SQUAD"
					FleetMember.Value:SetBooster[3]
					wait 20
					echo "  " FleetMember.Boosting ${FleetMember.Value.Boosting}

				echo "  Setting Booster Status OFF"
					FleetMember.Value:SetBooster[0]
					wait 20
					echo "  " FleetMember.Boosting ${FleetMember.Value.Boosting}

				echo " "
				echo " Testing Me.Fleet members that require CharID"
				echo "  " Me.Fleet.IsMember[CharID] ${Me.Fleet.IsMember[${FleetMember.Value.CharID}]}
				echo "  " Me.Fleet.IsMember[-1] ${Me.Fleet.IsMember[-1]}
				echo "  " Me.Fleet.Member[CharID] ${Me.Fleet.Member[${FleetMember.Value.CharID}]}
			}
			while ${FleetMember:Next(exists)}
		}

	echo "${Script.Filename} Completed..."
}