#define QUANTITY_THRESHOLD 10000

/*
	The hauler object and subclasses
	
	The obj_Hauler object contains functions that a usefull in creating
	a hauler bot.  The obj_OreHauler object extends obj_Hauler and adds
	functions that are useful for bots the haul ore in conjunction with
	one or more miner bots.
	
	-- GliderPro	
*/
objectdef obj_Hauler
{
	/* The name of the player we are hauling for (null if using m_corpName) */
	variable string m_playerName
	
	/* The name of the corp we are hauling for (null if using m_playerName) */
	variable string m_corpName
	
	method Initialize(string player, string corp)
	{	
		if (${player.Length} && ${corp.Length})
		{
			echo "ERROR: obj_Hauler:Initialize -- cannot use a player and a corp name.  One must be blank"
		}
		else
		{			
			if ${player.Length}
			{
				m_playerName:Set[${player}]
			}
			
			if ${corp.Length}
			{
				m_corpName:Set[${corp}]
			}
			
			if (!${player.Length} && !${corp.Length})
			{
				echo "WARNING: obj_Hauler:Initialize -- player and corp name are blank.  Defaulting to Me.Corporation"
				m_corpName:Set[${Me.Corporation}]
			} 
		}
	}
	
	method Shutdown()
	{
		/* nothing needs cleanup AFAIK */
	}
		
	/* SetupEvents will attach atoms to all of the events used by the bot */
	method SetupEvents()
	{
		/* the base obj_Hauler class does not use events */
	}

	member:int NearestMatchingJetCan()
	{
		variable index:int JetCan
		variable int JetCanCount
		variable int JetCanCounter
		variable string tempString
			
		JetCanCounter:Set[1]
		JetCanCount:Set[${EVE.GetEntityIDs[JetCan,GroupID,12]}]
		do
		{
			if ${Entity[${JetCan.Get[${JetCanCounter}]}](exists)}
			{
 				if ${m_playerName.Length} 
 				{
 					tempString:Set[${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.Name}]
 					echo "DEBUG: owner ${tempString}"
 					if ${tempString.Equal[${m_playerName}]}
 					{
	 					echo "DEBUG: owner matched"
						echo "DEBUG: ${Entity[${JetCan.Get[${JetCanCounter}]}]}"
						echo "DEBUG: ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}"
						return ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}
 					}
 				}
 				elseif ${m_corpName.Length} 
 				{
 					tempString:Set[${Entity[${JetCan.Get[${JetCanCounter}]}].Owner.Corporation}]
 					echo "DEBUG: corp ${tempString}"
 					if ${tempString.Equal[${m_corpName}]}
 					{
	 					echo "DEBUG: corp matched"
						return ${Entity[${JetCan.Get[${JetCanCounter}]}].ID}
 					}
 				}
 				else
 				{
					echo "No matching jetcans found"
 				} 				
			}
			else
			{
				echo "No jetcans found"
			}
		}
		while ${JetCanCounter:Inc} <= ${JetCanCount}
		
		return 0	/* no can found */
	}
}

function main()
{
	; The name we want our container to have
	variable string ContainerName = "Cargo Container"
	variable index:item MyCargo
	variable int EndScript = 0
	variable int id
	variable int canOpen = 0

	/* The hauler object takes two parameters.     */
	/* The first is the name of the person you     */
	/* are hauling for.  The second is the name    */
	/* of a corporation you are hauling for.       */
	/* Only one of the two parameters may be used. */
	Declare Hauler obj_Hauler ${Me.Name} ""
	;Declare Hauler obj_OreHauler "" "TestCorp"

	canOpen:Set[0]
	do
	{
		if ${Me.Ship.Cargo[1](exists)}
		{
			id:Set[${Hauler.NearestMatchingJetCan}]

			echo "DEBUG: can ID = ${id}"
			if ${Entity[${id}](exists)}
			{
				if ${canOpen} == 0
				{
					echo "Opening Can"
					Entity[${ContainerName}]:OpenCargo
					wait 100
					canOpen:Set[1]
				}
				echo "Moving ${Me.Ship.Cargo[1].Name} to ${Entity[${ContainerName}].ID}"
				Me.Ship.Cargo[1]:MoveTo[${Entity[${ContainerName}].ID}]
				wait 100
				echo "Stacking cargo"
				Entity[${ContainerName}]:StackAllCargo
				wait 50
				
				echo "JetCan contains ${Entity[${ContainerName}].UsedCargoCapacity} m^3 of stuff."
				if ${Entity[${ContainerName}].UsedCargoCapacity} > QUANTITY_THRESHOLD
				{
					relay all local -event EVEBot_Miner_Full ${Entity[GroupID, 9].ID}
				}
				
			}  
			else
			{
				echo "New Can"
				canOpen:Set[0]
				Me.Ship.Cargo[1]:Jettison
				wait 100
			}            
		}

		echo "Starting 10 second sleep"
		wait 100


		echo "Is laser #1 active?"
		wait 5
		if !${Me.Ship.Module[HiSlot0].IsActive}
		{
			echo "Locking Target on ${Entity[CategoryID,25]}"
			Entity[CategoryID,25]:LockTarget
			wait 100
			echo "Powering on laser #1"
			Me.Ship.Module[HiSlot0]:Click
			wait 50
		}

		echo "Is laser #2 active?"
		wait 5
		if !${Me.Ship.Module[HiSlot1].IsActive}
		{
			echo "Locking Target on ${Entity[CategoryID,25]}"
			Entity[CategoryID,25]:LockTarget
			wait 100
			echo "Powering on laser #2"
			Me.Ship.Module[HiSlot1]:Click
			wait 50
		}


	}
	while ${EndScript} == 0

	echo Script Ended
}