function main()
{
	variable index:bookmark bmlist
	bmlist:Clear
	EVE:DoGetBookmarks[bmlist]

	echo \${bmlist.Used} = ${bmlist.Used}
	
	variable int idx
	idx:Set[${bmlist.Used}]
	
	while ${idx} > 0
	{
		variable string Label
		Label:Set[${bmlist.Get[${idx}].Label}]
		echo ${Label}
		if ${Label.Left[2].NotEqual["SS"]}
		{
			bmlist:Remove[${idx}]
		}				
		elseif ${bmlist.Get[${idx}].SolarSystemID} != ${Me.SolarSystemID}
		{
			bmlist:Remove[${idx}]
		}
		
		idx:Dec
	}
	
	echo \${bmlist.Used} = ${bmlist.Used}

	bmlist:Collapse

	echo \${bmlist.Used} = ${bmlist.Used}
	
	variable iterator bmiterator
	bmlist:GetIterator[bmiterator]

	if ${bmiterator:First(exists)}
	{
		do
		{
			echo \${bmiterator.Value.Label} = ${bmiterator.Value.Label}
		} 
		while ${bmiterator:Next(exists)}
	}
}

/*
function main()
{
	variable index:bookmark bmlist
	bmlist:Clear
	EVE:DoGetBookmarks[bmlist]

	echo \${bmlist.Used} = ${bmlist.Used}

	variable iterator bmiterator
	bmlist:GetIterator[bmiterator]
	
	variable queue:bookmark ssqueue
	
	if ${bmiterator:First(exists)}
	{
		do
		{
			echo \${bmiterator.Value.Label} = ${bmiterator.Value.Label}
			variable string Label
			Label:Set[${bmiterator.Value.Label}]
			if ${Label.Left[2].Equal["SS"]}
			{
				ssqueue:Queue[${bmiterator.Value}]
			}
		} 
		while ${bmiterator:Next(exists)}
	}
	
	echo \${ssqueue.Used} = ${ssqueue.Used}

	ssqueue:GetIterator[bmiterator]

	if ${bmiterator:First(exists)}
	{
		do
		{
			echo \${bmiterator.Value.Label} = ${bmiterator.Value.Label}
		} 
		while ${bmiterator:Next(exists)}
	}

	
}
*/
