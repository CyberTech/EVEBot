#define TESTCASE 1

#include ../Support/TestAPI.iss

/*
	Test Fleet Broadcasts

	Revision $Id$

	Tests:
		Me.Fleet:Broadcast_*

	Requirements:
		You: In Space
		Other: In Fleet, In Space, on Grid

	Optional:
		Active Cyno (if you want the beacon broadcast to succeed)
*/

variable obj_UI UI
function main()
{
		echo " "
		echo "${Script.Filename} Starting..."
		echo " "
		echo "There are ${Me.Fleet.Size} fleet members"

		echo "Broadcast Tests:"
		Me.Fleet:Broadcast_AlignTo[${Entity["Stargate"].ID}]
		wait 10
		Me.Fleet:Broadcast_EnemySpotted
		wait 10
		Me.Fleet:Broadcast_HealArmor
		wait 10
		Me.Fleet:Broadcast_HealCapacitor
		wait 10
		Me.Fleet:Broadcast_HealShield
		wait 10
		Me.Fleet:Broadcast_HoldPosition
		wait 10
		Me.Fleet:Broadcast_InPosition
		wait 10
		Me.Fleet:Broadcast_JumpBeacon
		wait 10
		Me.Fleet:Broadcast_JumpTo[${Universe["Jita"].ID}]
		wait 10
		Me.Fleet:Broadcast_Location
		wait 10
		Me.Fleet:Broadcast_NeedBackup
		wait 10
		Me.Fleet:Broadcast_Target[${Me.ToEntity.ID}]
		wait 10
		Me.Fleet:Broadcast_TravelTo[${Universe["Jita"].ID}]
		wait 10
		Me.Fleet:Broadcast_WarpTo[${Entity["Stargate"].ID}]
		wait 10
		Me.Fleet:Broadcast_WarpTo[${Me.ToEntity.ID}]
		wait 10

		echo "${Script.Filename} Completed..."
}