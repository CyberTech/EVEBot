#if ${ISXEVE(exists)}
#else
	#error This script requires ISXEVE to be loaded before running
#endif

function main(string Branch = "Stable")
{
	timedcommand 5 "runscript \"${Script.CurrentDirectory}/Branches/${Branch}/EVEBot.iss\""
}