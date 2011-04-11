	variable int StartTime = ${Script.RunningTime}
	echo " "
	echo "* Testcase: ${MethodStr} starting"

	declarevariable TestIndex index:${ItemTest.TypeName} script
	declarevariable TestIterator iterator script
	variable float CallTime
	
	TestIndex:GetIterator[TestIterator]
	ItemTest:ParseMembers

	CallTime:Set[${Script.RunningTime}]
	noop ${MethodStr}\[TestIndex\]
	EVE:GetAgentMissions[TestIndex]
	echo " * ${MethodStr} returned ${TestIndex.Used} ${ItemTest.TypeName}s in ${Math.Calc[(${Script.RunningTime}-${CallTime}) / 1000]} seconds"

	if ${TestIterator:First(exists)}
	do
	{
		ItemTest:IterateMembers["TestIterator.Value"]
	}
	while ${TestIterator:Next(exists)}

	echo "* Testcase: ${MethodStr} completed in ${Math.Calc[(${Script.RunningTime}-${StartTime}) / 1000]} seconds"
	echo " "