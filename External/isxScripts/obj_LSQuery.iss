/*
	obj_LSQuery by CyberTech

		Provides a class to cache commonly used Lavishscript Queries without needing to delete and
		recreate the query every time it is needed.

		See: http://www.lavishsoft.com/wiki/index.php/LavishScript:Object_Queries

		Queries are created and stored in obj_LSQuery, which will call FreeQuery on the query during shutdown

		obj_LSQueryCache stores a collection of obj_LSQuery, indexed by the query string.

		obj_LSQuery may be used directly, for specialized cases.

		Example:

			variable obj_LSQueryCache LSQueryCache
			variable uint Loop = 20

			while ${Loop:Dec}
			{
				echo ${LSQueryCache["Name = Fred"]}
				echo ${LSQueryCache["Name = Fred1"]}
			}

	-- CyberTech (cybertech@gmail.com
*/

objectdef obj_LSQuery
{
	variable uint ID

	member Initialize(uint _ID)
	{
		ID:Set[${_ID}]
	}

	member ToText()
	{
		return ${This.ID}
	}

	method Shutdown()
	{
		LavishScript:FreeQuery[${This.ID}]
	}
}

objectdef obj_LSQueryCache
{
	variable collection:obj_LSQuery Queries

	; This checks the collection for an existing query, or, failing that, creates a new query and stores it for future use
	; Returns 0 on error
	member:uint GetIndex(string QueryStr)
	{
		variable uint QueryID = 0

		if ${Queries.Element[${QueryStr}](exists)}
		{
			return ${Queries.Element[${QueryStr}].ID}
		}
		; Query does not exist yet, we need to create it and return the new ID

		QueryID:Set[${LavishScript.CreateQuery[${QueryStr}]}]
		if ${QueryID} == 0
		{
			if ${Logger(exists)}
			{
				Logger:Log["obj_LSQueryCache: Failed LavishScript.CreateQuery[${QueryStr}]", LOG_DEBUG]
			}
			else
			{
				echo "obj_LSQueryCache: Failed LavishScript.CreateQuery[${QueryStr}]"
			}
			return 0
		}

		declarevariable NewQuery obj_LSQuery
		Queries:Set[${QueryStr}, ${NewQuery}]
		Queries.Element[${QueryStr}].ID:Set[${QueryID}]

		return ${QueryID}
	}
}