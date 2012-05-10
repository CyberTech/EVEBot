/*
	BaseClass
	
	This object is for inheritance only; it is designed to contain things that need to be inherited into
	all classes, so that they can work properly.  In the case of Sort, it's because we can't pass
	by reference, and we don't want to be copying indexes wholesale, or making them global.
	
	By making it inherited, the Sort methods have implicit access to the object that needs sorting.
	
	Sorting notes:
	
		Because we want to sort objects, and LS has no copy constructor, the only sorts we can use
		are those that use x.Swap() to handle moves.  We've settled on two sorts:
			
			1) in-place unstable quicksort
			2) in-place stable gnomesort
				(note that "stable" is used as a type of sort, not an indicator of code quality)
				
		The quicksort should be much faster, however it will not retain the ordering of equivilent items
		in the input list.  The gnomesort will retain said ordering, however is non-optimal for large
		input sets (over a few thousand items).
		
	-- CyberTech/GliderPro

Example Usage:
****		objectdef obj_session
****		{
****			variable int Lastping
****			variable string SessionName
****			
****			method Initialize(string sessname, int ping)
****			{
****				Lastping:Set[${ping}]
****				SessionName:Set[${sessname}]
****			}
****				
****		}
****		
****		objectdef obj_Main inherits obj_QuickSort
****		{
****			variable index:obj_session sessionlist
****		
****			method Initialize()
****			{
****				sessionlist:Insert["session01", 4]
****		
****				sessionlist:Insert["session01", 3]
****				sessionlist:Insert["session20", 20]
****				sessionlist:Insert["session11", 11]
****				sessionlist:Insert["session34", 34]
****				sessionlist:Insert["session22", 22]
****				sessionlist:Insert["session03", 1]
****				sessionlist:Insert["session44", 44]
****				sessionlist:Insert["session04", 0]
****			
****				variable iterator temps
****				sessionlist:GetIterator[temps]
****				if ${temps:First(exists)}
****				do
****				{
****					echo ${temps.Value.SessionName}: ${temps.Value.Lastping}
****				}
****				while ${temps:Next(exists)}
****				This:Sort[sessionlist, Lastping]
****				if ${temps:First(exists)}
****				do
****				{
****					echo ${temps.Value.SessionName}: ${temps.Value.Lastping}
****				}
****				while ${temps:Next(exists)}
****			}
****		}	
*/

objectdef obj_BaseClass
{
	method Sort(string IndexName, string MemberName)
	{
		variable string vartype = ${${IndexName}(type).Name}
		switch "${vartype}"
		{
			case index
				This:Gnomesort[${IndexName}, ${MemberName}]
				;This:QuickSort[${IndexName}, ${MemberName}, 1, ${${IndexName}.Used}}]
				break
			Default
				echo "Unexpected object type (${vartype}), cannot sort:"
				break
		}		
	}
	
	/* 	This is a stable sort, slow, but should be fine for most of our sets sizes.
		Ordering of equivilent objects IS guaranteed to be the same as the input.
		-- CyberTech
	*/
	method Gnomesort(string IndexName, string MemberName)
	{
		variable int i = 1
		
		while ${i} <= ${${IndexName}.Used}
		{
			if ( ${i} == 1 ) || ${${IndexName}[${Math.Calc[${i}-1]}].${MemberName}} <= ${${IndexName}[${i}].${MemberName}}
			{
				i:Inc
			}
			else
			{
				${IndexName}:Swap[${i}, ${Math.Calc[${i}-1]}]
				i:Dec
			}
		}
	}
	
	member:int QS_Partition(string IndexName, string MemberName, int First, int Last, int PivotIndex)
	{
		variable float64 PivotValue
		variable int StoredIndex = ${First}

		PivotValue:Set[${${IndexName}[${PivotIndex}].${MemberName}}]
		
		${IndexName}:Swap[${PivotIndex}, ${Last}]
		
		variable int Pos
		for ( Pos:Set[${First}]; ${Pos} < ${Last}; Pos:Inc )
		{
			if ${${IndexName}[${Pos}].${MemberName}} <= ${PivotValue}
			{
				${IndexName}:Swap[${Pos}, ${StoredIndex}]
				StoredIndex:Inc
			}
		}
		${IndexName}:Swap[${StoredIndex}, ${Last}]
		return ${StoredIndex}
	}
	
	/* 	This is not a stable sort, but should be much faster for larger sets.  
		Ordering of equivilent objects is not guaranteed to tbe the same as the input.
		-- CyberTech
	*/
	method QuickSort(string IndexName, string MemberName, int First, int Last)
	{
		variable int PivotIndex

		if ${First} < ${Last}
		{
			PivotIndex:Set[]
			PivotIndex:Set[${This.QS_Partition[${IndexName}, ${MemberName}, ${First}, ${Last}, ${First}]}]
			This:QuickSort[${IndexName}, ${MemberName}, ${First}, ${Math.Calc[${PivotIndex} - 1]}]
			This:QuickSort[${IndexName}, ${MemberName}, ${Math.Calc[${PivotIndex} + 1]}, ${Last}]
			
		}
	}
}

