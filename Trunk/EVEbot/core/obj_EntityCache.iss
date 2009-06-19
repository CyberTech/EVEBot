/*
Entity Cache Base Class

Caches isxeve result data for Entity Searches, and keeps them up to date
Intended to be instantiated one or more times for each module that requires
frequent entity lookups.

Keeps entity data in 2 lists -- the original index:int from isxeve, and an expanded
index:obj_Entity which contains commonly accessed data fields.

-- CyberTech
*/

objectdef obj_Entity
{
	variable int EntityID
	variable string Name
	variable int TypeID
	variable int GroupID
	variable float Distance

	; Special-purpose vars
	; ORE Density - 1 regular, 2 medium, 3 dense
	variable int ORE_Density

	method Initialize(int _EntityID, string _Name, int _TypeID, int _GroupID, float _Distance, int _ORE_Density = 0)
	{
		This.EntityID:Set[${_EntityID}]
		This.Name:Set["${_Name}"]
		This.TypeID:Set[${_TypeID}]
		This.GroupID:Set[${_GroupID}]
		This.Distance:Set[${_Distance}]
		This.ORE_Density:Set[${_ORE_Density}]
	}
}

objectdef obj_EntityCache inherits BaseClass
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string LogPrefix

	variable bool Initialized = false
	variable time NextPulse
	variable int PulseIntervalInSeconds = 4

	variable string FilterMember = "NONE"
	variable string SearchParams = "byDist"
	variable index:entity Entities
	variable index:obj_Entity CachedEntities
	variable iterator EntityIterator
	variable bool Initialized = FALSE

	method Initialize()
	{
		;TODO: propagate this syntax to all other objects. it's spiffy handy.
		LogPrefix:Set["EntityCache(${This.ObjectName})"]
		UI:UpdateConsole["${LogPrefix}: Initialized"]
		Event[OnFrame]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:UpdateEntityCache
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method SetUpdateFrequency(float Seconds)
	{
		UI:UpdateConsole["${LogPrefix}: Updated with Update Frequency of ${Seconds.Deci} seconds"]
		This.PulseIntervalInSeconds:Set[${Seconds}]
	}

	method UpdateSearchParams(string VarName, string SearchTerms,string Filter = "NONE")
	{
		UI:UpdateConsole["${LogPrefix}: Search Params: ${SearchTerms}"]
		This.Initialized:Set[FALSE]
		This.SearchParams:Set["${SearchTerms}"]
		This.FilterMember:Set["${Filter}"]
		This:UpdateEntityCache
	}

	method ForceUpdate()
	{
		This.NextPulse:Set[${Time.Timestamp}]
	}

	method UpdateEntityCache()
	{
		variable string Name
		variable int ORE_Density

		if ${Me.InSpace}
		{
			EVE:DoGetEntities[This.Entities, ${This.SearchParams}]
			CachedEntities:Clear
			This.Entities:GetIterator[EntityIterator]
			if ${EntityIterator:First(exists)}
			{
				do
				{
					Name:Set[${EntityIterator.Value.Name}]
					switch ${EntityIterator.Value.CategoryID}
					{
						case CATEGORYID_ENTITY
						break
						case CATEGORYID_ORE
						switch ${Name}
						{
							case Crimson Arkonor
							case Triclinic Bistot
							case Sharp Crokite
							case Bright Spodumain
							case Onyx Ochre
							case Iridescent Gneiss
							case Vitric Hedbergite
							case Vivid Hemorphite
							case Pure Jaspet
							case Luminous Kernite
							case Silvery Omber
							case Azure Plagioclase
							case Solid Pyroxeres
							case Condensed Scordite
							case Concentrated Veldspar
							ORE_Density:Set[3]
							break
							case Prime Arkonor
							case Monoclinic Bistot
							case Crystalline Crokite
							case Gleaming Spodumain
							case Obsidian Ochre
							case Prismatic Gneiss
							case Glazed Hedbergite
							case Radiant Hemorphite
							case Pristine Jaspet
							case Fiery Kernite
							case Golden Omber
							case Rich Plagioclase
							case Viscous Pyroxeres
							case Massive Scordite
							case Dense Veldspar
							ORE_Density:Set[2]
							break
							default
							ORE_Density:Set[1]
							break
						}
						break
						default
						break
					}
					switch ${This.FilterMember}
					{
						case NONE
						{
							;method Initialize(int _EntityID, string _Name, int _TypeID, int _GroupID, float _Distance, int _ORE_Density = 0)

							CachedEntities:Insert[${EntityIterator.Value.ID}, "${Name}", ${EntityIterator.Value.TypeID}, ${EntityIterator.Value.GroupID}, ${EntityIterator.Value.Distance}, ${ORE_Density}]
						}
						case IsNPC
						{
							if ${Targets.IsNPCTarget[${EntityIterator.Value.GroupID}]}
							{
								CachedEntities:Insert[${EntityIterator.Value.ID}, "${Name}", ${EntityIterator.Value.TypeID}, ${EntityIterator.Value.GroupID}, ${EntityIterator.Value.Distance}, ${ORE_Density}]
							}
						}
					}
				}
				while ${EntityIterator:Next(exists)}
			}

			This.Initialized:Set[TRUE]
			echo "${LogPrefix}: ${CachedEntities.Used}"
		}
	}

	member:int Count()
	{
		return ${This.Entities.Used}
	}

	member:int NearestByName(string EntityName)
	{
		This.Entities:GetIterator[EntityIterator]
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
