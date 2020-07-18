/*
	LSTypeIterator by CyberTech

		This object is designed to allow for rapid testing of the members of a datatype, without needing to have
		advance knowledge or hardcoding of the members and methods of the datatype.

		-- CyberTech, cybertech@gmail.com

		Examples of the use of this object can be found at https://www.isxgames.com/EVEBot/Trunk/EVEbot/Testcases

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
				echo "    Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
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
					Me.Station:GetHangarItems[HangarItems]
					echo "    Me.Station:GetHangarItems returned ${HangarItems.Used} items"
					ItemTest:IterateMembers["HangarItems.Get[1]"]

					EndTime:Set[${Script.RunningTime}]
					echo "    Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
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
			Testing of datatype character completed in 0.156000 seconds
*/

objectdef obj_LSTypeIterator
{
	variable file TypeListTempFile = "${Script.CurrentDirectory}/lstypes.${Script.Filename}.txt"
	variable string TypeName
	variable set TypeMembers
	variable set TypeMethods
	variable int MaxMemberLen
	variable int MaxMethodLen

	/*
		The following sets allow you to exclude certain members from testing; for example if they're known to cause a crash.
		Use them with Instance.ExcludedMembers:Add["Membername"]
	*/
	variable set ExcludedMembers
	variable set ExcludedMethod

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
		TypeListTempFile:SetFilename["${Script.CurrentDirectory}/lstypes.${Script.Filename}.txt"]
	}

	method Shutdown()
	{
		This.TypeListTempFile:Delete
	}

	; Dump the list of members to a single line for review or loggging
	method PrintKnownMembers()
	{
		variable iterator Member
		variable string MemberStr
		This.TypeMembers:GetIterator[Member]

		echo "    LSTypeIterator: Members of datatype \"${This.TypeName}\""
		if ${Member:First(exists)}
		do
		{
			MemberStr:Concat[${Member.Key}]
			MemberStr:Concat[", "]
		}
		while ${Member:Next(exists)}
		echo "    LSTypeIterator: Members: ${MemberStr.Left[-2]}"
	}

	; Dump the list of methods to a single line for review or loggging
	method PrintKnownMethods()
	{
		variable iterator Method
		variable string MethodStr
		This.TypeMethods:GetIterator[Method]

		echo "    LSTypeIterator: Methods of datatype \"${This.TypeName}\""
		if ${Method:First(exists)}
		do
		{
			MethodStr:Concat[${Method.Key}]
			MethodStr:Concat[", "]
		}
		while ${Method:Next(exists)}
		echo "    LSTypeIterator: Methods: ${MethodStr.Left[-2]}"
	}


	; Parse the output of lstype typename, and place the results into sorted lists for members and methods.
	method ParseMembers()
	{
		variable string temp
		echo "    LSTypeIterator: Parsing datatype \"${This.TypeName}\" members and methods..."
		redirect "lstypes.${Script.Filename}.txt" "lstype ${This.TypeName}"
		This.TypeListTempFile:Open
		if !${This.TypeListTempFile.Open}
		{
			echo "    LSTypeIterator: Unable to open file ${This.TypeListTempFile.Filename}"
			return
		}
		do
		{
			declarevariable Position int 0
			temp:Set[${This.TypeListTempFile.Read}]
			if ${temp(exists)} && !${temp.Equal[NULL]}
			{
				temp:Set[${temp.Replace[\r, ""]}]
				temp:Set[${temp.Replace[\n, ""]}]
				if ${temp.Equal["No type '${This.TypeName}' found. Type names are case sensitive."]}
				{
					echo "    LSTypeIterator: Invalid datatype passed to ${This.ObjectName}.Initialize"
					return
				}
				if ${temp.Equal["Members of type ${This.TypeName}"]}
				{
					temp:Set[${This.TypeListTempFile.Read}]
					temp:Set[${This.TypeListTempFile.Read}]
					temp:Set[${temp.Replace[\r, ""]}]
					temp:Set[${temp.Replace[\n, ""]}]
					while ${temp.NotEqual["Methods of type ${This.TypeName}"]}
					{
						if ${temp.Find["*"](exists)} || ${temp.Find["----"](exists)}
						{
							temp:Set[${This.TypeListTempFile.Read}]
							temp:Set[${temp.Replace[\r, ""]}]
							temp:Set[${temp.Replace[\n, ""]}]
							continue
						}
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
						temp:Set[${This.TypeListTempFile.Read}]
						temp:Set[${temp.Replace[\r, ""]}]
						temp:Set[${temp.Replace[\n, ""]}]
					}
				}
				if ${temp.Equal["Methods of type ${This.TypeName}"]}
				{
					temp:Set[${This.TypeListTempFile.Read}]
					do
					{
						temp:Set[${This.TypeListTempFile.Read}]
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
					while ${This.TypeListTempFile.EOF(exists)} && !${This.TypeListTempFile.EOF}
				}
			}
		}
		while ${This.TypeListTempFile.EOF(exists)} && !${This.TypeListTempFile.EOF}

		This.TypeListTempFile:Close
		This.TypeListTempFile:Delete
	}

	/*
		In some cases, a member may be causing crashes. By calling this _instead_
		of IterateMembers, you can write a script to disk which contains each member
		echo'd with 2 second delay between each member.  You can then watch the screen
		for which member crashes, or (hopefully) see the crashing member in the lavishsoft
		crash report.

	*/
	method WriteTestScript(string ObjectName)
	{
		variable iterator Member
		This.TypeMembers:GetIterator[Member]
		declarevariable testfile string "lstypes.${Script.Filename}.iss"

		redirect ${testfile} echo "; Manual test script for ${ObjectName} members"
		redirect -append ${testfile} echo "function main()"
		redirect -append ${testfile} echo "\{"
		if ${Member:First(exists)}
		do
		{
			if ${This.ExcludedMembers.Contains["${Member.Key}"]}
			{
				; Comment out the echo in the output file
				redirect -append ${testfile} echo "  ;echo ${Member.Key} == \\$\\{${ObjectName}.${Member.Key}\\}"
				continue
			}
			redirect -append ${testfile} echo "  echo ${Member.Key} == \\$\\{${ObjectName}.${Member.Key}\\}"
			redirect -append ${testfile} echo "  wait 20"
		}
		while ${Member:Next(exists)}
		redirect -append ${testfile} echo "\}"

		echo "---"
		echo "    LSTypeIterator: Created manual test script: ${Script.CurrentDirectory}/${testfile}""
		echo "---"

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
			echo "    LSTypeIterator: Members of datatype \"${This.TypeName}\", instance \"${ObjectName}\""
		}

		variable float CallTime
		CallTime:Set[${Script.RunningTime}]
		if ${Member:First(exists)}
		do
		{
			if ${This.ExcludedMembers.Contains["${Member.Key}"]}
			{
				echo "    Excluded member: ${Member.Key}"
				continue
			}
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
					echo "      ${temp} == ${Result}"
				}
			}
		}
		while ${Member:Next(exists)}
		temp:Set["${ObjectName} Iteration Time"]
		while ${temp.Length} < ${PadLength}
		{
			temp:Concat[" "]
		}
		echo "      ${temp} == ${Math.Calc[(${Script.RunningTime}-${CallTime}) / 1000]} seconds"
	}
}
