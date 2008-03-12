/*
	The stealth hauler object
	
	The obj_StealthHauler object is a bot mode designed to be used with 
	obj_Freighter bot module in EVEBOT.  It will move cargo from point A
	to point B in a covert ops or force recon ship.  It will stay cloaked
	the entire time and it will attempt to avoid bubbles and 'dictors.
	
	-- GliderPro	
*/

/* obj_StealthHauler is a "bot-mode" which is similar to a bot-module.
 * obj_StealthHauler runs within the obj_Freighter bot-module.  It would 
 * be very straightforward to turn obj_StealthHauler into a independent 
 * bot-module in the future if it outgrows its place in obj_Freighter.
 */
 
objectdef obj_StealthHauler
{
	variable index:int apRoute
	variable index:int apWaypoints
	variable iterator  apIterator
	
	method Initialize()
	{
		UI:UpdateConsole["obj_StealthHauler: Initialized"]
	}

	method Shutdown()
	{
	}
	
	method SetState()
	{
		
	}

	function ProcessState()
	{
		if ${Station.Docked}
		{
			call Station.Undock
		}
		elseif ${Ship.HasCovOpsCloak}
		{
			if ${apRoute.Used} == 0
			{
				EVE:DoGetToDestinationPath[apRoute]	
				EVE:DoGetWaypoints[apWaypoints]
				apRoute:GetIterator[apIterator]
			}
			else
			{
			}
		}
		else
		{
			UI:UpdateConsole["obj_StealthHauler: ERROR: You need a CovOps cloak to use this script!!"]
		}
	}
}
