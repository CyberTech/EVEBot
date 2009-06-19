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
		FleetMember Members
		FleetMember:SetScout
		FleetMember:SetBooster

	Requirements:
		You: In Space
		Other: In Fleet, In Space, on Grid
*/

variable obj_UI UI
function main()
{
		variable index:fleetmember FleetIndex

		echo " "
		echo "${Script.Filename} Starting..."
		echo " "
		echo "There are ${Me.Fleet.Size} fleet members"

		variable iterator Wing
		variable index:int64 Wings

		Me.Fleet:GetWings[Wings]
		Wings:GetIterator[Wing]

		if ${Wing:First(exists)}
		{
			variable index:int64 Squads
			variable iterator Squad
			do
			{
				echo Wing: ${Wing.Value} WingName: ${Me.Fleet.WingName[${Wing.Value}]}
				Me.Fleet:GetSquads[Squads, ${Wing.Value}]
				Squads:GetIterator[Squad]
				if ${Squad:First(exists)}
				{
					do
					{
						echo " Squad: ${Squad.Value} = ${Me.Fleet.SquadName[${Squad.Value}]}"
					}
					while ${Squad:Next(exists)}
				}
			}
			while ${Wing:Next(exists)}
		}

		Script[${Script.Filename}]:End

		echo "Fleet Member List:"

		Me.Fleet:GetMembers[FleetIndex]
		echo "GetMembers returned ${FleetIndex.Used} fleet members"
		variable iterator FleetMember
		FleetIndex:GetIterator[FleetMember]

		if ${FleetMember:First(exists)}
		{
			do
			{
				echo " " FleetMember.ToPilot ${FleetMember.Value.ToPilot}
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

				;echo "  Setting Scout Status"
				;FleetMember.Value:SetScout[TRUE]

				;echo "  Setting Booster Status"
				;FleetMember.Value:SetBooster

				wait 50

			}
			while ${FleetMember:Next(exists)}
		}

}