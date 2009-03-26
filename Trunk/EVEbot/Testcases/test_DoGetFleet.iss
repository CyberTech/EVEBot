#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss

/*
	Test Fleet Member Iteration, FleetMember.ToPilot

	Requirements:
		You: In Space
		Other: In Fleet, In Space, on Grid
*/

variable obj_UI UI
function main()
{
		variable index:fleetmember FleetIndex
		Me:DoGetFleet[FleetIndex]
		variable iterator FleetMember
		FleetIndex:GetIterator[FleetMember]

		if ${FleetMember:First(exists)}
		{
			do
			{
				echo FleetMember.Value.Name ${FleetMember.Value.Name}
				echo FleetMember.Value.Job ${FleetMember.Value.Job}
				echo FleetMember.Value.JobID ${FleetMember.Value.JobID}
				echo FleetMember.Value.Role ${FleetMember.Value.Role}
				echo FleetMember.Value.RoleID ${FleetMember.Value.RoleID}
				echo FleetMember.Value.Boosting ${FleetMember.Value.Boosting}
				echo FleetMember.Value.SquadID ${FleetMember.Value.SquadID}
				echo FleetMember.Value.WingID ${FleetMember.Value.WingID}
				echo FleetMember.Value.ToPilot ${FleetMember.Value.ToPilot}
				echo FleetMember.Value.ToEntity ${FleetMember.Value.ToEntity}

			}
			while ${FleetMember:Next(exists)}
		}
}