/*
	defines.iss
	
	Hardcoded defines for EVEBot
	
	- CyberTech
	
*/

/*
	I'm a comment to force SVN_REVISION update on checkin.. 
	How are you today?
	I'm fime. Touch of goiter, but doc says if I swallow these pills he'll be able to cut it out.
	So how's that goiter been? Any news from the doc on removal?
	Sure, he says we can go in thru my right ear to remove it.  I'm going to check the internet first, that doesn't sound right. I think it's the left.
*/
variable string APP_NAME = "EVEBot"
variable string APP_VERSION = "0.98"
variable string APP_PATH = "EVEBot/EVEBot.iss"
variable string SVN_REVISION = "$Rev$"
variable string APP_MANIFEST = "https://www.isxgames.com/EVEBot/Trunk/EVEbot/manifest.xml"
variable string APP_MANIFEST_TRUNK = "https://www.isxgames.com/EVEBot/Trunk/EVEbot/manifest-trunk.xml"

variable string Version = "${APP_NAME} ${APP_VERSION} Revision ${SVN_REVISION.Token[2, " "]}"

;#define USE_ISXIRC 1
#define USE_ISXIRC 0

#define WAIT_CARGO_WINDOW 15
#define WAIT_UNDOCK 130

/* If the miner's cargo hold doesn't increase during 
 * this period, return to base.  Interval depends on the 
 * IntervalInSeconds value used in obj_Miner.Pulse
 * This value is currently set to 2 seconds so 240*2 = 8 minutes
 * The check interval is set high to compensate for slowboating
 */
#define MINER_SANITY_CHECK_INTERVAL 240

#define GROUPID_PLANET			7
#define GROUPID_MOON 			8
#define GROUPID_ASTEROID_BELT 	9
#define GROUPID_STARGATE		10

/*
 * DEBUG: Slot: MedSlot3  Ballistic Deflection Field II
 *  DEBUG: Group: Shield Hardener  77
 *  DEBUG: Type: Ballistic Deflection Field II  2299
 * DEBUG: Slot: MedSlot1  Heat Dissipation Field II
 *  DEBUG: Group: Shield Hardener  77
 *  DEBUG: Type: Heat Dissipation Field II  2303
 * DEBUG: Slot: MedSlot0  Large Shield Booster II
 *  DEBUG: Group: Shield Booster  40
 *  DEBUG: Type: Large Shield Booster II  10858
 * DEBUG: Slot: HiSlot5  'Arbalest' Cruise Launcher I
 *  DEBUG: Group: Missile Launcher Cruise  506
 *  DEBUG: Type: 'Arbalest' Cruise Launcher I  16519 
 * DEBUG: Slot: HiSlot6  Prototype Cloaking Device I
 *  DEBUG: Group: Cloaking Device  330
 *  DEBUG: Type: Prototype Cloaking Device I  11370
 * DEBUG: Slot: HiSlot1  Cruise Missile Launcher II
 *  DEBUG: Group: Missile Launcher Cruise  506
 *  DEBUG: Type: Cruise Missile Launcher II  19739
 */
#define GROUPID_AFTERBURNER 				46
#define GROUPID_SHIELD_BOOSTER 				40
#define GROUPID_SHIELD_HARDENER 			77
#define GROUPID_ARMOR_REPAIRERS 			62
#define GROUPID_ARMOR_HARDENERS 			328
#define GROUPID_MISSILE_LAUNCHER_CRUISE 	506
#define GROUPID_MISSILE_LAUNCHER_ROCKET 	507
#define GROUPID_MISSILE_LAUNCHER_SIEGE 		508
#define GROUPID_MISSILE_LAUNCHER_STANDARD 	509
#define GROUPID_MISSILE_LAUNCHER_HEAVY 		510
#define GROUPID_MINING_CRYSTAL 				482
#define GROUPID_FREQUENCY_MINING_LASER 		483

#define GROUPID_CLOAKING_DEVICE		 		330
#define TYPEID_PROTOTYPE_CLOAKING_DEVICE	11370
#define TYPEID_COVERT_OPS_CLOAKING_DEVICE	11578
#define TYPEID_SMOKESCREEN_CLOAKING_DEVICE	99999	/* TBD */

/* Same group and type for secure cargo containers as well */
#define GROUPID_CORPORATE_HANGAR_ARRAY 471
#define GROUPID_CARGO_CONTAINER 12
#define TYPEID_CARGO_CONTAINER 23
#define TYPEID_CORPORATE_HANGAR_ARRAY 17621
#define GROUPID_SPAWN_CONTAINER 306
#define GROUPID_SECURE_CONTAINER 340

#define GROUPID_WRECK 186

#define WARP_RANGE 250000
#define DOCKING_RANGE 200
#define LOOT_RANGE 1450
#define JUMP_RANGE 2350
#define CORP_HANGAR_LOOT_RANGE 3000

#define TYPEID_GLACIAL_MASS 16263

;System (ID: 0)          Owner (ID: 1)           Celestial (ID: 2)           Station (ID: 3)
;Material (ID: 4)        Accessories (ID: 5)     Ship (ID: 6)                Module (ID: 7)
;Charge (ID: 8)          Blueprint (ID: 9)       Trading (ID: 10)            Entity (ID: 11)
;Bonus (ID: 14)          Skill (ID: 16)          Commodity (ID: 17)          Drone (ID: 18)
;Implant (ID: 20)        Deployable (ID: 22)     Structure (ID: 23)          Reaction (ID: 24)
;Asteroid (ID: 25)
	
#define CATEGORYID_CELESTIAL	2
#define CATEGORYID_STATION 		3
#define CATEGORYID_MINERAL 		4
#define CATEGORYID_SHIP    		6
#define CATEGORYID_CHARGE  		8
#define CATEGORYID_ENTITY		11
#define CATEGORYID_ORE     		25
#define CATEGORYID_GLACIAL_MASS 25

#define CATEGORYID_STRUCTURE	23
#define GROUPID_CONTROL_TOWER   365

/* for obj_Sound.iss */
#define ALARMSOUND	"${Script.CurrentDirectory}/sounds/alarm.wav"
#define DETECTSOUND	"${Script.CurrentDirectory}/sounds/detect.wav"
#define TELLSOUND	"${Script.CurrentDirectory}/sounds/tell.wav"
#define LEVELSOUND	"${Script.CurrentDirectory}/sounds/level.wav"
#define WARNSOUND	"${Script.CurrentDirectory}/sounds/warning.wav"

