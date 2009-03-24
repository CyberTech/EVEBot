#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss
#include Scripts/EVEBot/core/obj_Items.iss

variable obj_UI UI

function main()
{
	echo "obj_EVEDB_Items: Member Test Case:"
	
	declarevariable itemdb obj_EVEDB_Items

	echo Name: ${itemdb.Name[34]}
	echo Volume: ${itemdb.Volume[34]}
	echo Capacity: ${itemdb.Capacity[34]}
	echo GroupID: ${itemdb.GroupID[34]}
	echo PortionSize: ${itemdb.PortionSize[34]}
	echo BasePrice: ${itemdb.BasePrice[34]}	
	
/*	
 member:float BasePrice(int TypeID)
 member:float Volume(int TypeID)
 member:int Capacity(int TypeID)
 member:int GroupID(int TypeID)
 member:int PortionSize(int TypeID)
 member:int TypeID(string itemName)
 member:string Name(int TypeID)
 method DumpDB(string itemName)
 method Initialize()
 method Shutdown()
*/
}
