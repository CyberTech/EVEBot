#include ..\core\defines.iss
/*
	Navigator thread
	
	This handles movement 
*/

objectdef obj_Navigator
{
	variable string SVN_REVISION = "$Rev: 1345 $"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1
  variable int ApproachingEntityID = 0
  variable string MovementType = "IDLE" 
  variable int TargetEntityID = 0
  variable int Distance = 50
  variable int LastVelocity = 0
  variable int CurrentAcceleration = 0
  variable bool SlowingDown = FALSE
  variable bool Stopped = FALSE

	;variable obj_EntityCache NavigatorCache

	method Initialize()
	{
		/* attach the pulse method to the onframe event */
		Event[OnFrame]:AttachAtom[This:Pulse]
		;UI:UpdateConsole["Thread: obj_Defense: Initialized", LOG_MINOR]
		/* set the entity cache update frequency */
		;if ${NavigatorCache.PulseIntervalInSeconds} != 9999
		;{
		;	NavigatorCache:SetUpdateFrequency[9999]
		;}
		;NavigatorCache:UpdateSearchParams["Unused","CategoryID,CATEGORYID_ENTITY,radius,60000"]
	}

	method Pulse()
	{
		/*if !${Script[EVEBot](exists)}
		{
			Script:End
		}
		*/
	
		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${This.Running}
			{
				/*this is where we set state , ie check if we should be approaching something and check if we are moving towards it*/
				This:SetState								
				CurrentAcceleration:Set[${Math.Calc[(${Me.ToEntity.Velocity} - ${LastVelocity}) / ${PulseIntervalInSeconds}]}]
				LastVelocity:Set[${Me.ToEntity.Velocity}]
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}
	
	method SetState()
	{
		; TODO -
		;				Need to use keep at range instead of approach, with moving targets we could end up spamming approach as they move in and out of range
		echo ${This.TargetEntityID} != 0 && !${This.MovementType.Equal["STOP"]}
		if ${Me.ToEntity.Mode} == 3
		{
			;cant do anything while we are in warp
			MovementType:Set["WARPING"]
		}
		elseif ${This.TargetEntityID} != 0 && ${Entity[${TargetEntityID}].Distance} < ${Distance}
		{ 
			;we are at the required distance of the target so we can stop moving
			MovementType:Set["STOP"]				
		}
		elseif ${This.TargetEntityID} != 0 && !${This.MovementType.Equal["STOP"]}
		{
			;we are approaching the correct target and we have not been told to stop
			MovementType:Set["APPROACHING_TARGET"]
		}
		elseif ${Me.ToEntity.Approaching(exists)} && !${This.MovementType.Equal["STOP"]} 
		{
			;we have not been told to approach anything but we are anyway
			;for the moment we just leave it, when all modules are using navigator we should stop the ship though
			MovementType:Set["APPROACHING"]
		}
		elseif !${Me.ToEntity.Approaching(exists)} && ${Me.ToEntity.Velocity} > 4 && !${This.MovementType.Equal["STOP"]}
		{
			;we are not approaching anything but we are still moving this is most likely when we are aligning to warp
			MovementType:Set["MOVING"]
		}
		elseif ${This.MovementType.Equal["STOP"]} && ${Me.ToEntity.Velocity} <= 3 && ${This.CurrentAcceleration} < 3
		{
			;TODO - we should be checking acceleration over the last second or so here as we could pass through 0 velocity
			;				while being bounced off in a random direction
			
			;we have been asked to stop and we have now stopped , therefore we can goto idle state
			This.TargetEntityID:Set[0]
			MovementType:Set["IDLE"]
		}		
	}
	
	method Stop()
	{

		if (${MovementType.Equal["WARPING"]})
		{
			;Can't stop when warping or not moving
			UI:UpdateConsole["Can't stop because currently ${MovementType}."]
			return
		}
		else
		{
			;Stop

			;use an OR because we could be stuck on something still trying to approach(0 velocity)
			if (${Me.ToEntity.Velocity} >=3) || ${Me.ToEntity.Approaching(exists)}
			{
				MovementType:Set["STOP"]
				UI:UpdateConsole["Stopping"]
			}
			else
			{
				MovementType:Set["IDLE"]
				UI:UpdateConsole["Idle"]
			}	
		}
	}
	;removed default entityID , this function should not ever work unless you give it an entityid
	method Approach(int EntityID, int Distance=DOCKING_RANGE)
	{
		;If entity exists
		if ${Entity[${EntityID}](exists)}
		{
			;Set EntityID
			TargetEntityID:Set[${EntityID}]
			Distance:Set[${Distance}]
		
		}
		else
		{
			UI:UpdateConsole["Entity ID not found"]
		}
	}

	function ProcessState()
	{
		switch ${This.MovementType}
		{
			case IDLE
				;Be as lazy as the ship and do nothing
				break
			case APPROACHING_TARGET
				;Approach to target
				if ${This.TargetEntityID} != 0 && ${Entity[${TargetEntityID}](exists)}
				{
					if ${Me.ToEntity.Approaching.ID} != ${TargetEntityID}
					{				
						if ${Entity[${TargetEntityID}].Distance} < 150000
						{	
							;Approach
							Entity[${TargetEntityID}]:Approach[${Distance}]
						}					
						else
						{
							;this will get spammed currently, figure out a way of telling we have have asked to warp or not
							Entity[${TargetEntityID}]:WarpTo					
						}
					}					
				}
				else
				{
					TargetEntityID:Set[0]
				}
				break
			case APPROACHING
				;something else is making us approach, do nothing
				break
			case WARPING
				;Currently warping, do nothing until stopped
				break
			case STOP
				;Stop
				if ${Me.ToEntity.Velocity} > 3 && ${This.CurrentAcceleration} >= 0 
				{
					Me:SetVelocity[0]
				}
				break
		}
	}
}

variable(global) obj_Navigator Navigator
/* main thread */
function main()
{
	;EVEBot.Threads:Insert[${Script.Filename}]
	while TRUE
	{
		/* this is where we take action based on our current state */
		call Navigator.ProcessState
		wait 30
	}
	;echo "EVEBot exited, unloading ${Script.Filename}"
}