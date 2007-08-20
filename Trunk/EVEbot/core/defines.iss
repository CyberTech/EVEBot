/*
	defines.iss
	
	Hardcoded defines for EVEBot
	
	- CyberTech
	
*/

variable string APP_NAME = "EVEBot"
variable string APP_VERSION = "0.94"
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

#define LOOT_RANGE 1450
