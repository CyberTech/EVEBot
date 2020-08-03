#define TESTCASE 1

#include ../../Support/TestAPI.iss

/*
	Test: Me (character datatype)
	Requirements: Logged in

*/
function main()
{
	variable int EndTime
	variable obj_PulseTimer PulseTimer
	variable int StartTime = ${Script.RunningTime}

	PulseTimer:SetIntervals[2.5,4.0]
	PulseTimer:Update[FALSE]

	echo "PulseTimer Test:"
	while !${PulseTimer.Ready}
	{
		waitframe
	}
	EndTime:Set[${Script.RunningTime}]
	PulseTimer:Update[FALSE]
	while !${PulseTimer.Ready}
	{
		waitframe
	}
	EndTime:Set[${Script.RunningTime}]

	echo "PulseTimer completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}