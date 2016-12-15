#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss
/*
	Test: CharSelect (charselect datatype)
	Requirements: At character select screen

*/
function main()
{
	variable int StartTime = ${Script.RunningTime}
	variable int EndTime

	variable obj_LSTypeIterator ItemTest = "charselect"

	ItemTest:ParseMembers
	ItemTest:IterateMembers["CharSelect"]

	echo "    Manual Tests (for members requiring a parameter):"
	if ${CharSelect.SelectedCharID} != -1
	{
		echo "      CharSelect.CharExists[${CharSelect.SelectedChar}] == ${CharSelect.CharExists[${CharSelect.SelectedChar}]}"
		echo "      CharSelect.CharExists[${CharSelect.SelectedCharID}] == ${CharSelect.CharExists[${CharSelect.SelectedCharID}]}"
	}
	else
	{
		echo "      CharSelect.CharExists[${CharSelect.SelectedChar}] Not tested, no currently selected character"
		echo "      CharSelect.CharExists[${CharSelect.SelectedCharID}] == Not tested, no currently selected character"
	}

	EndTime:Set[${Script.RunningTime}]
	echo "Testing of datatype ${ItemTest.TypeName} completed in ${Math.Calc[(${EndTime}-${StartTime}) / 1000]} seconds"
}