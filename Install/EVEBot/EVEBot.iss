#if ${ISXEVE(exists)}
#else
	#error This script requires ISXEVE to be loaded before running
#endif

function MakeIncludeFiles(string RootDir, string SubDir, bool Define_Globals = TRUE, bool Testcases = FALSE)
{
	variable int Pos = 0
	variable file Includes_File = "${RootDir}${SubDir}/_includes.iss"
	variable file Variables_File = "${RootDir}${SubDir}/_variables.iss"

	variable filelist Script_List
	variable filelist Subdir_list
	
	Script_List:Reset
	Subdir_List:Reset
	
	Script_List:GetFiles["${RootDir}${SubDir}/\*"]
	Subdir_list:GetDirectories["${RootDir}${SubDir}/\*"]

	for (Pos:Set[1] ; ${Pos}<=${Subdir_list.Files} ; Pos:Inc)
	{
		if ${Subdir_list.File[${Pos}].Filename.Equal["Testcases"]} || \
			${Subdir_list.File[${Pos}].Filename.Equal[".svn"]}
		{
			continue
		}
		Script_List:GetFiles["${Subdir_list.File[${Pos}].FullPath}/\*"]
	}

	Includes_File:Open[]
	Includes_File:Seek[0]
	Includes_File:Truncate[]

	if ${Define_Globals}
	{
		Variables_File:Open[]
		Variables_File:Seek[0]
		Variables_File:Truncate[]
	}

	variable string CurrentFile
	variable string obj_name
	variable string var_name
	for (Pos:Set[1] ; ${Pos}<=${Script_List.Files} ; Pos:Inc)
	{
		CurrentFile:Set[${Script_List.File[${Pos}].Filename}]

		if ${CurrentFile.Equal["_includes.iss"]} || \
			${CurrentFile.Equal["_variables.iss"]}
		{
			continue
		}

		if ${CurrentFile.Right[4].Equal[".iss"]}
		{
			Includes_File:Write["#include ${Script_List.File[${Pos}].FullPath.Right[-${RootDir.Length}]}\n"]

			if ${Define_Globals}
			{
				if ${CurrentFile.Left[4].Equal["obj_"]}
				{
					obj_name:Set[${CurrentFile.Left[-4]}]
					var_name:Set[${obj_name.Right[-4]}]
					Variables_File:Write["Logger:Log[\"Creating global ${obj_name} as ${var_name}\", LOG_DEBUG]\n"]
					Variables_File:Write["declarevariable ${var_name} ${obj_name} global\n\n"]
				}
			}
		}
	}

	Includes_File:Close[]
	if ${Define_Globals}
	{
		Variables_File:Close[]
	}
}

function main(string Branch = "Stable")
{
	call MakeIncludeFiles "${Script.CurrentDirectory}/Branches/${Branch}/" "Behaviors" TRUE
	call MakeIncludeFiles "${Script.CurrentDirectory}/Branches/${Branch}/" "Modes" FALSE
	call MakeIncludeFiles "${Script.CurrentDirectory}/Branches/${Branch}/" "Behaviors/Testcases" TRUE TRUE

	timedcommand 5 "runscript \"${Script.CurrentDirectory}/Branches/${Branch}/EVEBot.iss\""
}