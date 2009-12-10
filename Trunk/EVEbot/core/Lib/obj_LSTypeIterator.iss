/*
	LSTypeIterator by CyberTech
	Download: https://www.isxgames.com/EVEBot/Trunk/EVEbot/core/Lib/obj_LSTypeIterator.iss

		This object is designed to allow for rapid testing of the members of a datatype, without needing to have
		advance knowledge or hardcoding of the members and methods of the datatype.

		-- CyberTech, cybertech@gmail.com

		Some background for those doing testing:

		Given 'Me' - 'Me' is a Top Level Object, of datatype 'character'.  To test 'Me',
		you must pass the 'character' datatype to LSTypeIterator object, then pass
		an instance of the character datatype to the IterateMembers method.  In this case,
		the only instance of the 'character' datatype is "Me"

		In some other cases, this is not the case, for example, if you want the 'ability' datatype,
		it can be accessed via the instance 'Me.Ability[xxx,#]", or 'Me.Ability[id,1571882540]'

		An example is below:

		Example:
			function main()
			{
				variable int StartTime = ${Script.RunningTime}
				variable int EndTime

				variable obj_LSTypeIterator ItemTest = "character"

				ItemTest:ParseMembers
				ItemTest:IterateMembers["Me"]

				EndTime:Set[${Script.RunningTime}]
				echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
			}

		Additional Example, of the output of a datatype that is aquired into an index:
				function main()
				{
					variable int StartTime = ${Script.RunningTime}
					variable int EndTime

					declarevariable HangarItems index:item script
					variable obj_LSTypeIterator ItemTest = "item"

					ItemTest:ParseMembers
					;ItemTest:PrintKnownMembers
					;ItemTest:PrintKnownMethods

					EVE:Execute[OpenHangarFloor]
					wait 15
					Me.Station:DoGetHangarItems[HangarItems]
					echo "Me.Station:DoGetHangarItems returned ${HangarItems.Used} items"
					ItemTest:IterateMembers["HangarItems.Get[1]"]

					EndTime:Set[${Script.RunningTime}]
					echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
				}

		Example output:

			========================================================
			Parsing datatype character members and methods...
			Members of datatype "character", instance "Me"
			  Me.ActiveTarget           == NULL
			  Me.Alliance               == NULL
			  Me.AllianceID             == -1
			  Me.AllianceTicker         == NULL
			  Me.AutoPilotOn            == FALSE
			  Me.Charisma               == 15.400000
			  Me.DroneControlDistance   == 45000.000000
			  Me.Fleet                  == NULL
			  Me.GetActiveDroneIDs      == NULL
			  Me.GetActiveDrones        == NULL
			  Me.GetAssets              == 0
			  Me.GetAttackers           == 0
			  Me.GetCorpHangarItems     == NULL
			  Me.GetHangarItems         == 13
			  Me.GetHangarShips         == 5
			  Me.GetJammers             == NULL
			  Me.GetMyOrders            == NULL
			  Me.GetSkillQueue          == 1
			  Me.GetSkills              == NULL
			  Me.GetStationsWithAssets  == 0
			  Me.GetTargetedBy          == NULL
			  Me.GetTargeting           == NULL
			  Me.GetTargets             == NULL
			  Me.InSpace                == FALSE
			  Me.InStation              == TRUE
			  Me.Intelligence           == 30.800000
			  Me.MaxActiveDrones        == 5.000000
			  Me.MaxJumpClones          == 4.000000
			  Me.MaxLockedTargets       == 6.000000
			  Me.Memory                 == 23.100000
			  Me.MiningDroneAmountBonus == 100.000000
			  Me.Perception             == 22.000000
			  Me.RegionID               == 10000033
			  Me.Skill                  == NULL
			  Me.SkillCurrentlyTraining == NULL
			  Me.SkillPoints            == NULL
			  Me.StandingTo             == NULL
			  Me.Willpower              == 20.900000
			Testing of datatype character completed in 0.156000 seconds
*/

objectdef obj_LSTypeIterator
{
	variable string SVN_REVISION = "$Rev$"
	variable string SVN_PATH = "$HeadURL$"
	variable string SVN_AUTHOR = "$Author$"

	variable file TypeList = "${Script.CurrentDirectory}/lstypes.${Script.Filename}.txt"
	variable string TypeName
	variable set TypeMembers
	variable set TypeMethods
	variable int MaxMemberLen
	variable int MaxMethodLen

	/*
		Initialize with the type being tested.  ie, for most isxGames extensions to test "Me", the type would be "character"
	*/
	method Initialize(string typename)
	{
		TypeMembers:Clear
		TypeMethods:Clear
		MaxMemberLen:Set[0]
		MaxMethodLen:Set[0]

		This.TypeName:Set[${typename}]
		TypeList:SetFilename["${Script.CurrentDirectory}/lstypes.${Script.Filename}.txt"]
	}

	method Shutdown()
	{
		This.TypeList:Delete
	}

	; Dump the list of members to a single line for review or loggging
	method PrintKnownMembers()
	{
		variable iterator Member
		variable string MemberStr
		This.TypeMembers:GetIterator[Member]

		echo "Members of datatype \"${This.TypeName}\""
		if ${Member:First(exists)}
		do
		{
			MemberStr:Concat[${Member.Key}]
			MemberStr:Concat[", "]
		}
		while ${Member:Next(exists)}
		echo "Members: ${MemberStr.Left[-2]}"
	}

	; Dump the list of methods to a single line for review or loggging
	method PrintKnownMethods()
	{
		variable iterator Method
		variable string MethodStr
		This.TypeMethods:GetIterator[Method]

		echo "Methods of datatype \"${This.TypeName}\""
		if ${Method:First(exists)}
		do
		{
			MethodStr:Concat[${Method.Key}]
			MethodStr:Concat[", "]
		}
		while ${Method:Next(exists)}
		echo "Methods: ${MethodStr.Left[-2]}"
	}


	; Parse the output of lstype typename, and place the results into sorted lists for members and methods.
	method ParseMembers()
	{
		variable string temp
		echo "========================================================"
		echo "Parsing datatype ${This.TypeName} members and methods..."
		redirect "lstypes.${Script.Filename}.txt" "lstype ${This.TypeName}"
		This.TypeList:Open
		if !${This.TypeList.Open}
		{
			echo "Unable to open file ${This.TypeList.Filename}"
			return
		}
		do
		{
			declarevariable Position int 0
			temp:Set[${This.TypeList.Read}]
			if ${temp(exists)} && !${temp.Equal[NULL]}
			{
				temp:Set[${temp.Replace[\r, ""]}]
				temp:Set[${temp.Replace[\n, ""]}]
				if ${temp.Equal["No type '${This.TypeName}' found. Type names are case sensitive."]}
				{
					echo "Invalid datatype passed to ${This.ObjectName}.Initialize"
					return
				}
				if ${temp.Equal["Members of type ${This.TypeName}"]}
				{
					temp:Set[${This.TypeList.Read}]
					temp:Set[${This.TypeList.Read}]
					temp:Set[${temp.Replace[\r, ""]}]
					temp:Set[${temp.Replace[\n, ""]}]
					while ${temp.NotEqual["Methods of type ${This.TypeName}"]}
					{
						Position:Set[1]
						while ${temp.Token[${Position}, " "](exists)} && ${temp.Token[${Position}, " "].NotEqual["NULL"]}
						{
							if ${temp.Token[${Position}, " "].Length} > 1
							{
								TypeMembers:Add[${temp.Token[${Position}, " "]}]
								if ${This.MaxMemberLen} < ${temp.Token[${Position}, " "].Length}
								{
									This.MaxMemberLen:Set[${temp.Token[${Position}, " "].Length}]
								}
							}
							Position:Inc
						}
						temp:Set[${This.TypeList.Read}]
						temp:Set[${temp.Replace[\r, ""]}]
						temp:Set[${temp.Replace[\n, ""]}]
					}
				}
				if ${temp.Equal["Methods of type ${This.TypeName}"]}
				{
					temp:Set[${This.TypeList.Read}]
					do
					{
						temp:Set[${This.TypeList.Read}]
						temp:Set[${temp.Replace[\r, ""]}]
						temp:Set[${temp.Replace[\n, ""]}]
						Position:Set[1]
						while ${temp.Token[${Position}, " "](exists)} && ${temp.Token[${Position}, " "].NotEqual["NULL"]}
						{
							if ${temp.Token[${Position}, " "].Length} > 1
							{
								TypeMethods:Add[${temp.Token[${Position}, " "]}]
								if ${This.MaxMethodLen} < ${temp.Token[${Position}, " "].Length}
								{
									This.MaxMethodLen:Set[${temp.Token[${Position}, " "].Length}]
								}
							}
							Position:Inc
						}
					}
					while ${This.TypeList.EOF(exists)} && !${This.TypeList.EOF}
				}
			}
		}
		while ${This.TypeList.EOF(exists)} && !${This.TypeList.EOF}

		This.TypeList:Close
		This.TypeList:Delete
	}

	/*
		Given a script or global variable name, dump the value of each member of that variable
		Pass output = false to avoid the cost of the echo to console call, for timing purposes.

		ObjectName should be a script or globally defined object name, of type TypeName

	*/
	method IterateMembers(string ObjectName, bool Output = TRUE, bool OutputNullOnly = FALSE)
	{
		variable iterator Member
		variable string temp
		variable int PadLength
		declarevariable Result string

		PadLength:Set[${This.MaxMemberLen}]
		PadLength:Inc[${ObjectName.Length}]
		PadLength:Inc[1]

		This.TypeMembers:GetIterator[Member]

		if ${Output}
		{
			echo "Members of datatype \"${This.TypeName}\", instance \"${ObjectName}\""
		}

		if ${Member:First(exists)}
		do
		{
			Result:Set[${${ObjectName}.${Member.Key}}]
			if ${Output}
			{
				temp:Set["${ObjectName}.${Member.Key}"]
				while ${temp.Length} < ${PadLength}
				{
					temp:Concat[" "]
				}
				if !${OutputNullOnly} || ${Result.Equal["NULL"]}
				{
					echo "  ${temp} == ${Result}"
				}
			}
		}
		while ${Member:Next(exists)}
	}
}
