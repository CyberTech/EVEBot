variable bool g_Quit = FALSE

atom EVEBot_Miner_Full_Executed(int64 id, string name)
{
	echo "EVEBot_Miner_Full_Executed -- ${id} -- ${name}"
	
	if ${id} == 4269
	{
		g_Quit:Set[TRUE]		
	}
}

function main()
{
	echo "DEBUG: Registering event..."
	LavishScript:RegisterEvent[EVEBot_Miner_Full]
	
	echo "DEBUG: Attaching atom to event..."
	Event[EVEBot_Miner_Full]:AttachAtom[EVEBot_Miner_Full_Executed]
	
	echo "DEBUG: Triggering an event..."
	Event[EVEBot_Miner_Full]:Execute

	echo "DEBUG: Triggering an event with a parameter..."
	Event[EVEBot_Miner_Full]:Execute[123456,"joe schmoe"]
	
	while !${g_Quit}
	{
		wait 100		/* ten seconds */
	}

	echo "DEBUG: Detaching atom from event..."
	Event[EVEBot_Miner_Full]:DetachAtom[EVEBot_Miner_Full_Executed]

	echo "DEBUG: Unregistering event..."
	Event[EVEBot_Miner_Full]:Unregister
}

