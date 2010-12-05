#if ${ISXEVE(exists)}
#else
	#error This script requires ISXEVE to be loaded before running
#endif

function MakeIncludeFiles(string root, string dir, bool make_globals = TRUE)
{
	echo ${root}
	
  variable int dir_idx = 0
  variable int file_idx = 0
  variable int len = 0
  variable filelist file_list
  variable filelist dir_list
  variable string include_path
  variable file includes_file
  variable file globals_file
	variable string obj_name
	variable string var_name
  
  file_list:GetFiles["${root}${dir}/\*"]
  dir_list:GetDirectories["${root}${dir}/\*"]
  while ( ${dir_idx:Inc} <= ${dir_list.Files} )
  {
    file_list:GetFiles["${dir_list.File[${dir_idx}].FullPath}/\*"]
  }
  
  includes_file:SetFilename["${root}${dir}/includes.iss"]
  includes_file:Open[]
  includes_file:Seek[0]
  includes_file:Truncate[]

	if ${make_globals}
	{
  	globals_file:SetFilename["${root}${dir}/globals.iss"]
  	globals_file:Open[]
  	globals_file:Seek[0]
  	globals_file:Truncate[]
  }

  ; break up _FILE_ directive so it isn't processed here
  includes_file:Write["#echo _"]
  includes_file:Write["FILE_\n\n"]
  
	if ${make_globals}
	{
	  globals_file:Write["#echo _"]
	  globals_file:Write["FILE_\n\n"]
	}
	
  file_idx:Set[0]
  len:Set[${root.Length}]
  while ( ${file_idx:Inc} <= ${file_list.Files} )
  {
  	if ${file_list.File[${file_idx}].Filename.Equal["includes.iss"]}
  	{
  		continue
  	}
  	
  	if ${file_list.File[${file_idx}].Filename.Equal["globals.iss"]}
  	{
  		continue
  	}
  	
  	if ${file_list.File[${file_idx}].Filename.Right[4].Equal[".iss"]}
  	{
    	include_path:Set[${file_list.File[${file_idx}].FullPath.Right[-${len}]}]
    	includes_file:Write["#include ${include_path}\n"]
    	
			if ${make_globals}
			{
				if ${file_list.File[${file_idx}].Filename.Left[4].Equal["obj_"]}
				{
					obj_name:Set[${file_list.File[${file_idx}].Filename.Left[-4]}]
					var_name:Set[${obj_name.Right[-4]}]
				  globals_file:Write["Logger:Log[\"Creating global ${obj_name} as ${var_name}\", LOG_DEBUG]\n"]
				  globals_file:Write["declarevariable ${var_name} ${obj_name} global\n\n"]
				}
			}
    }
  } 

  includes_file:Close[]
	if ${make_globals}
	{
	  globals_file:Close[]
	}
}

function main(string Branch = "Stable")
{
	call MakeIncludeFiles "${Script.CurrentDirectory}/Branches/${Branch}/" "Behaviors"
	call MakeIncludeFiles "${Script.CurrentDirectory}/Branches/${Branch}/" "Modes" FALSE
	timedcommand 5 "runscript \"${Script.CurrentDirectory}/Branches/${Branch}/EVEBot.iss\""
}