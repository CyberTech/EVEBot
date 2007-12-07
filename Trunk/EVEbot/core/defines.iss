/*
	defines.iss
	
	Hardcoded defines for EVEBot
	
	- CyberTech
	
*/

/*
	I'm a comment to force SVN_REVISION update on checkin..

*/
variable string APP_NAME = "EVEBot"
variable string APP_VERSION = "0.962"
variable string APP_PATH = "EVEBot/EVEBot.iss"
variable string SVN_REVISION = "$Rev$"
variable string APP_MANIFEST = "https://www.isxgames.com/EVEBot/Trunk/EVEbot/manifest.xml"
variable string APP_MANIFEST_TRUNK = "https://www.isxgames.com/EVEBot/Trunk/EVEbot/manifest-trunk.xml"

variable string Version = "${APP_NAME} ${APP_VERSION} Revision ${SVN_REVISION.Token[2, " "]}"

#define WAIT_CARGO_WINDOW 15
#define WAIT_UNDOCK 130

#define GROUPID_ASTEROID_BELT 9

#define GROUPID_AFTERBURNER 46
#define GROUPID_SHIELD_BOOSTER 40
#define GROUPID_MINING_CRYSTAL 482
#define GROUPID_FREQUENCY_MINING_LASER 483

/* Same group and type for secure cargo containers as well */
#define GROUPID_CORPORATE_HANGAR_ARRAY 471
#define GROUPID_CARGO_CONTAINER 12
#define TYPEID_CARGO_CONTAINER 23
#define TYPEID_CORPORATE_HANGAR_ARRAY 17621
#define GROUPID_SPAWN_CONTAINER 306

#define GROUPID_WRECK 186

#define WARP_RANGE 250000
#define DOCKING_RANGE 1000
#define LOOT_RANGE 1450
#define CORP_HANGAR_LOOT_RANGE 3000

#define TYPEID_GLACIAL_MASS 16263

#define CATEGORYID_MINERAL 4
#define CATEGORYID_ORE 25
#define CATEGORYID_GLACIAL_MASS 25
#define CATEGORYID_STATION 3