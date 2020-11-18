/*
	TestAPI

	Minimal copies of EVEBot objects required to do standalone testing of various evebot objects

	-- CyberTech
*/

#define TESTAPI_DEBUG 1

#include ../Branches/Stable/core/defines.iss
#include ../Branches/Stable/core/obj_IRC.iss
;#include ../External/isxScripts/obj_PulseTimer.iss
;#include ../Branches/Dev/core/Lib/obj_BaseClass.iss
#include ../External/isxScripts/obj_LSTypeIterator.iss

objectdef obj_UI
{
	variable string LogFile

	method Initialize()
	{
		This.LogFile:Set["./Logs/TestAPI_${Script.Filename}.log"]

		redirect -append "${This.LogFile}" echo "--------------------------------------------------------------------------------------"
		redirect -append "${This.LogFile}" echo "** ${Script.Filename} starting on ${Time.Date} at ${Time.Time24}"
	}

	method Log(string StatusMessage, int Level=LOG_STANDARD, int Indent=0)
	{
		This:UpdateConsole["${StatusMessage}",${Level},${Indent}]
	}

	method UpdateConsole(string StatusMessage, int Level=LOG_STANDARD, int Indent=0)
	{
		/*
			Level = LOG_MINOR - Minor - Log, do not print to screen.
			Level = LOG_STANDARD - Standard, Log and Print to Screen
			Level = LOG_CRITICAL - Critical, Log, Log to Critical Log, and print to screen
		*/
		variable string msg
		variable int Count

		if ${StatusMessage(exists)}
		{
			if ${Level} == LOG_DEBUG && TESTAPI_DEBUG == 0
			{
				return
			}

			msg:Set["${Time.Time24}: "]

			for (Count:Set[1]; ${Count}<=${Indent}; Count:Inc)
			{
  				msg:Concat[" "]
  		}
  		msg:Concat["${StatusMessage}"]

			echo ${msg}

			redirect -append "${This.LogFile}" Echo "${msg}"
		}
	}

}

variable obj_UI UI
variable obj_UI Logger
variable obj_IRC ChatIRC