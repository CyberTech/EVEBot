/*
	Entity Cache Base Class

	Caches isxeve result data for Entity Searches, and keeps them up to date
	Intended to be instantiated one or more times for each module that requires
	frequent entity lookups.

	Keeps entity data in 2 lists -- the original index:int from isxeve, and an expanded
	index:obj_Entity which contains commonly accessed data fields.

	Proper Use:

	variable int Cached_Entity_Stations
	Cached_Entity_Stations:Set[${EntityCache.AddFilter["yourobject", GroupID = GROUP_STATION, 10]}]
	variable iterator EntityIterator
	EntityCache.Entities.Get[${Cached_Entity_Stations}]:GetIterator[EntityIterator]
	... use entityiterator ...

	-- CyberTech
*/


objectdef obj_EntityFilter
{
	variable string Owner
	variable int QueryID
	variable string LSFilter

	variable int Decay
	variable int MaxDecay

	variable index:entity Entities

	member ToText()
	{
		return ${QueryID}
	}

	method Shutdown()
	{
		LavishScript:FreeQuery[${QueryID}]
	}
}

objectdef obj_EntityCache inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string LogPrefix

	variable bool Initialized = false
	variable int NextPulse
	variable int PulseIntervalInMS = 250

	variable index:entity CachedEntities
	variable index:obj_EntityFilter EntityFilters
	variable iterator EntityFilterIterator

	variable bool Initialized = FALSE
	variable bool Updating = FALSE

	; These are the common and global items, we store them here because they don't belong to any particular behavior.
	variable int CacheID_Belts
	variable int CacheID_Stargates
	variable int CacheID_Stations
	variable int CacheID_Planets
	variable int CacheID_Moons
	variable int CacheID_Moons
	variable int CacheID_Ships
	variable int CacheID_Entities

	method Initialize()
	{
		LogPrefix:Set["EntityCache(${This.ObjectName})"]

		; Common entity searches that don't belong to any particular module
		This.CacheID_Belts:Set[${This.AddFilter["EntityCache_Belts", GroupID = GROUP_ASTEROIDBELT, 60]}]
		This.CacheID_Stargates:Set[${This.AddFilter["EntityCache_Stargates", GroupID = GROUP_STARGATE, 60]}]
		This.CacheID_Stations:Set[${This.AddFilter["EntityCache_Stations", GroupID = GROUP_STATION, 60]}]
		This.CacheID_Planets:Set[${This.AddFilter["EntityCache_Planets", GroupID = GROUP_PLANET, 60]}]
		This.CacheID_Moons:Set[${This.AddFilter["EntityCache_Moons", GroupID = GROUP_MOON, 60]}]

		This.CacheID_Ships:Set[${This.AddFilter["EntityCache_Ships", CategoryID = CATEGORYID_SHIP, 2]}]
		This.CacheID_Entities:Set[${This.AddFilter["EntityCache_Entities", CategoryID = CATEGORYID_ENTITY, 2]}]

		if ${Me.InSpace}
		{
			EVE:PopulateEntities[TRUE]
		}

		Logger:Log["${LogPrefix}: Initialized"]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Script.RunningTime} >= ${This.NextPulse}
		{
			This:UpdateEntityCache
			This.NextPulse:Set[${Script.RunningTime}]
			This.NextPulse:Inc[${This.PulseIntervalInMS}]
		}
	}

	/*
		 Args should be sent as a Query Object comparison: http://www.lavishsoft.com/wiki/index.php/LavishScript:Object_Queries

			Example: "ISNPC = 1 && IsTargetingMe = 1"
		Allowed Members are any member of Entity datatype
		Owner is to determine who is setting the Filter
		Filter is, the filter.
		DecaySeconds is the # of seconds to keep results around before refreshing them
	*/
	member:int AddFilter(string Owner, string Filter, float DecaySeconds=0)
	{
		variable int ID
		variable int QueryID
		variable obj_EntityFilter EntityFilter

		QueryID:Set[${LavishScript.CreateQuery[${Filter}]}]
		if ${QueryID} == 0
		{
			Logger:Log["${LogPrefix}: ${Owner} query addition FAILED", LOG_DEBUG]
			return 0
		}

		ID:Set[${This.EntityFilters.Insert[${EntityFilter}]}]
		This.EntityFilters.Get[${ID}].Owner:Set[${Owner}]
		This.EntityFilters.Get[${ID}].Decay:Set[0]
		This.EntityFilters.Get[${ID}].MaxDecay:Set[${Math.Calc[${DecaySeconds} * 1000]}]
		This.EntityFilters.Get[${ID}].LSFilter:Set[${LSFilter}]
		This.EntityFilters.Get[${ID}].QueryID:Set[${QueryID}]

		Logger:Log["${LogPrefix}: ${Owner} added entity filter ${ID}: QueryID:${QueryID}:'${Filter}'", LOG_DEBUG]

		return ${ID}
	}

	method DeleteFilter(int FilterID)
	{
		${This.EntityFilters:Remove[${FilterID}]
	}

	method ClearEntityCaches()
	{
		This.EntityFilters:GetIterator[EntityFilterIterator]
		if ${EntityFilterIterator:First(exists)}
		{
			do
			{
				EntityFilterIterator.Value.Entities:Clear
				EntityFilterIterator.Value.Decay:Set[0]
			}
			while ${EntityFilterIterator:Next(exists)}
		}
	}

	method UpdateEntityCache()
	{
		#define DEBUG_LOG_UPDATETIME 0

		This.Updating:Set[TRUE]

		if !${Me.InSpace}
		{
			; TODO - only do this once per dock.
			This:ClearEntityCaches
		}
		else
		{
			This.EntityFilters:GetIterator[EntityFilterIterator]

			#if DEBUG_LOG_UPDATETIME
			variable int StartTime1
			variable int FiltersPerFrame
			StartTime1:Set[${Script.RunningTime}]
			#endif

			if ${Display.FPS.Int} < ${This.EntityFilters.Used}
			{
				/* Make this dynamic. This is to avoid taking multiple seconds to iterate the filter list
				when FPS is very low.
				Need to scale it so that if FPS drops below filtercount, I let
				more than 1 filter run per frame, to the point where at 1fps, all filters run per frame */
				FiltersPerFrame:Set[${Math.Calc[${This.EntityFilters.Used} / ${Display.FPS.Int}].Ceil}]
			}
			else
			{
				FiltersPerFrame:Set[1]
			}
			if !${EntityFilterIterator.IsValid}
			{
				EntityFilterIterator:First
			}

			do
			{
				;Logger:Log["${LogPrefix}: Checking Query #${EntityFilterIterator.Value.QueryID}"]
				if ${EntityFilterIterator.Value.Decay} > 0
				{
					EntityFilterIterator.Value.Decay:Dec[${This.PulseIntervalInMS}]
				}

				if ${EntityFilterIterator.Value.Decay} <= 0
				{
					EVE:QueryEntities[EntityFilterIterator.Value.Entities, ${EntityFilterIterator.Value.QueryID}]
					#if DEBUG_LOG_UPDATETIME
					Logger:Log["${LogPrefix}: Updated Query #${EntityFilterIterator.Value.QueryID}: Entities: ${EntityFilterIterator.Value.Entities.Used} Owner: ${EntityFilterIterator.Value.Owner} MaxDecay: ${EntityFilterIterator.Value.MaxDecay} ${LavishScript.RetrieveQueryExpression[${EntityFilterIterator.Value.QueryID}]}"]
					#endif
					EntityFilterIterator.Value.Decay:Set[${EntityFilterIterator.Value.MaxDecay}]
					FiltersPerFrame:Dec
					if ${FiltersPerFrame} <= 0
					{
						EntityFilterIterator:Next
						break
					}
				}
			}
			while ${EntityFilterIterator:Next(exists)}
			#if DEBUG_LOG_UPDATETIME
			;Logger:Log["${LogPrefix}: Done: FPS: ${Display.FPS.Int} Time: ${Math.Calc[(${Script.RunningTime}-${StartTime1}) / 1000]} seconds to apply filters against ${EVE.EntitiesCount} Entities"]
			#endif

			This.Initialized:Set[TRUE]
		}

		This.Updating:Set[FALSE]
	}

	member:int Count(int FilterID)
	{
		return ${This.EntityFilters.Get[${FilterID}].Entities.Used}
	}

	member:int64 NearestByName(int FilterID, string EntityName)
	{
		variable iterator EntityIterator
; TODO - replace this so it calls proper query
		This.CachedEntities:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if ${EntityIterator.Value.Name.Equal[${EntityName}]}
				{
					return ${EntityIterator.Value.ID}
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		return 0
	}
}
