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
	variable index:cachedentity Stations

	variable int Entity_Moons
	variable int Entity_Stations
	variable int Entity_AsteroidBelts
	variable int Entity_NPCs

	;member:int AddFilter(string Owner, string Filter, int DecaySeconds=0)

	Entity_Stations:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_STATION, 10, \${EntityIterator.Value.GroupID} == GROUP_STATION]}]
	Entity_Moons:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_MOON, 11]}]
	Entity_AsteroidBelts:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_ASTEROIDBELT, 5]}]
	Entity_NPCs:Set[${EntityCache.AddFilter["test_evebot_EntityCache", CategoryID = CATEGORYID_ENTITY && Distance <= 60000, 2]}]

	;FilterID:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_STATION, 11]}]
	;FilterID:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_MOON, 14]}]
	;FilterID:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_PLANET, 9]}]
	;FilterID:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_ASTEROIDBELT, 10]}]
	;FilterID:Set[${EntityCache.AddFilter["test_evebot_EntityCache", GroupID = GROUP_STARGATE, 15]}]

	echo ${EVE:QueryCachedEntities[${Entity_Stations}, Stations]}
	echo ${Stations.Used}
	echo ${Stations[1].Name}

	while 1
	{
		wait 10
		echo Count: ${EntityCache.Count[${Entity_Stations}]}
		echo Count: ${EntityCache.Count[${Entity_Moons}]}
		echo Count: ${EntityCache.Count[${Entity_AsteroidBelts}]}
		echo Count: ${EntityCache.Count[${Entity_NPCs}]}
		;echo Count: ${EntityCache.EntityFilters.Get[${Entity_Stations}].Entities.Used}  \${MyRef(type)}=${MyRef(type)} \${MyRef.Reference(type)}=${MyRef.Reference(type)} \${MyRef.Reference.Entities(type)}=${MyRef.Reference.Entities(type)} \${MyRef.Reference.Entities.Used}=${MyRef.Reference.Entities.Used}
	}
}

