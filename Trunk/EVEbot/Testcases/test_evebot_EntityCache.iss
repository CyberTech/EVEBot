#define TESTCASE 1

/*
 *	Test EVEBot EntityCache
 *
 *	Revision $Id$
 *
 *	Requirements:
 *		In Space
 *
 */

#include ../Support/TestAPI.iss
#include ../core/obj_EntityCache.iss

variable obj_UI UI

function main()
{
	Turbo 100
	echo "obj_EntityCache: Member Test Case:"

	declarevariable EntityCache obj_EntityCache
	variable index:entity Stations

	variable int Entity_Moons
	variable int Entity_Stations
	variable int Entity_AsteroidBelts
	variable int Entity_NPCs
	variable int Entity_Defense
	variable int Entity_Rats
	variable int Entity_Mission
	variable int Entity_Asteroids

	;member:int AddFilter(string Owner, string Filter, float DecaySeconds=0)

	Entity_Stations:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_STATION, 10, \${EntityIterator.Value.GroupID} = GROUP_STATION]}]
	Entity_Moons:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_MOON, 11]}]
	Entity_AsteroidBelts:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_ASTEROIDBELT, 5]}]
	Entity_NPCs:Set[${EntityCache.AddFilter["test_evebot_EntityCache", CategoryID = CATEGORYID_ENTITY && Distance <= 5000, 2]}]
	Entity_Defense:Set[${EntityCache.AddFilter["obj_Defense", CategoryID = CATEGORYID_ENTITY, 1.5]}]
	Entity_Rats:Set[${EntityCache.AddFilter["obj_Ratter", CategoryID = CATEGORYID_ENTITY && IsNPC = 1 && IsMoribund = 0, 2.0]}]
	Entity_Asteroids:Set[${EntityCache.AddFilter["obj_Asteroids", CategoryID = CATEGORYID_ORE, 1.0]}]
	variable string QueryString
	QueryString:Concat["CategoryID = CATEGORYID_ENTITY"]
	QueryString:Concat[" && IsNPC = 1"]
	QueryString:Concat[" && IsMoribund = 0"]
	QueryString:Concat[" && GroupID != GROUP_LARGECOLLIDABLEOBJECT"]
	QueryString:Concat[" && GroupID != GROUP_LARGECOLLIDABLESHIP"]
	QueryString:Concat[" && GroupID != GROUP_LARGECOLLIDABLESTRUCTURE"]
	QueryString:Concat[" && GroupID != GROUP_SENTRYGUN"]
	QueryString:Concat[" && GroupID != GROUP_CONCORDDRONE"]
	QueryString:Concat[" && GroupID != GROUP_CUSTOMSOFFICIAL"]
	QueryString:Concat[" && GroupID != GROUP_POLICEDRONE"]
	QueryString:Concat[" && GroupID != GROUP_CONVOYDRONE"]
	QueryString:Concat[" && GroupID != GROUP_FACTIONDRONE"]
	QueryString:Concat[" && GroupID != GROUP_BILLBOARD"]
	QueryString:Concat[" && GroupID != GROUPID_SPAWN_CONTAINER"]
	QueryString:Concat[" && GroupID != GROUP_DEADSPACEOVERSEERSSTRUCTURE"]

	Entity_Mission:Set[${EntityCache.AddFilter["obj_MissionCommands", ${QueryString}, 1.0]}]

	while 1
	{
		wait 10
		echo Entity_Stations: ${EntityCache.Count[${Entity_Stations}]}
		echo Entity_Moons: ${EntityCache.Count[${Entity_Moons}]}
		echo Entity_AsteroidBelts: ${EntityCache.Count[${Entity_AsteroidBelts}]}
		echo Entity_NPCs: ${EntityCache.Count[${Entity_NPCs}]}
		echo Entity_Defense: ${EntityCache.Count[${Entity_Defense}]}
		echo Entity_Rats: ${EntityCache.Count[${Entity_Rats}]}
		echo Entity_Mission: ${EntityCache.Count[${Entity_Mission}]}
		echo Entity_Asteroids: ${EntityCache.Count[${Entity_Asteroids}]}
	}
}

