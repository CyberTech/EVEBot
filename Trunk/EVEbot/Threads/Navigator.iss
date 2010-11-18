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
	
	variable int TargetEntityID = 0
	variable int TargetDistance = 50
	variable int LastVelocity = 0
	variable int CurrentAcceleration = 0
	variable string MovementState = "STOPPED"
	variable string ActionState = "IDLE"
	method Initialize()
	{
		/* attach the pulse method to the onframe event */
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["Thread: obj_Navigator: Initialized", LOG_MINOR]
		/* set the entity cache update frequency */
		;if ${NavigatorCache.PulseIntervalInSeconds} != 9999
		;{
		;	NavigatorCache:SetUpdateFrequency[9999]
		;}
		;NavigatorCache:UpdateSearchParams["Unused","CategoryID,CATEGORYID_ENTITY,radius,60000"]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			Script:End
		}
		

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${This.Running} && ${EVEBot.SessionValid} && ${Me.InSpace}
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
		/*
		SET MOVEMENT STATE
		*/
		if ${Me.ToEntity.Mode} == 3
		{
			MovementState:Set["WARPING"]
		}
		elseif ${Me.ToEntity.Velocity} <= 4 && ${This.CurrentAcceleration} < 3 && ${This.CurrentAcceleration} > -1
		{
			MovementState:Set["STOPPED"]
		}
		elseif ${Me.ToEntity.Approaching(exists)}
		{
			MovementState:Set["APPROACHING"]
		}
		elseif !${Me.ToEntity.Approaching(exists)} && ${This.CurrentAcceleration} < 0
		{
			MovementState:Set["STOPPING"]
		}
		elseif !${Me.ToEntity.Approaching(exists)} && ${Me.ToEntity.Velocity} > 4
		{
			MovementState:Set["MOVING"]
		}
		/*
		SET ACTION STATE
		*/
		switch ${This.ActionState}
		{
			case APPROACH
				if ${TargetEntityID} != 0
				{
					if !${Entity[${TargetEntityID}](exists)} || ${Entity[${TargetEntityID}].Distance} < ${This.TargetDistance}
					{
						;if we are close enough or if the entity no longer exists, stop the ship
						TargetEntityID:Set[0]
						This.ActionState:Set["STOP"]
					}
				}
				else
				{
					;how did we get here, help i am not good with state machines
					This.ActionState:Set["STOP"]
				}
				break
			case STOP
				if ${This.MovementState.Equal["STOPPED"]}
				{
					This.ActionState:Set["IDLE"]
				}
				elseif ${TargetEntityID} != 0
				{
					This.ActionState:Set["APPROACH"]
				}
				break
			case IDLE
				break
		}
	}

	method Stop()
	{
		This.ActionState:Set["STOP"]
	}
	;removed default entityID , this function should not ever work unless you give it an entityid
	method Approach(int64 EntityID, int Distance=DOCKING_RANGE)
	{
		;If entity exists
		if ${Entity[${EntityID}](exists)}
		{
			;Set EntityID
			TargetEntityID:Set[${EntityID}]
			TargetDistance:Set[${Distance}]
			This.ActionState:Set["APPROACH"]
		}
		else
		{
			UI:UpdateConsole["Entity ID not found"]
		}
	}

	function ProcessState()
	{
		switch ${This.ActionState}
		{
			case IDLE
				;Be as lazy as the ship and do nothing
				break
			case APPROACH
				if ${This.TargetEntityID} != 0 && ${Entity[${TargetEntityID}](exists)}
				{
					switch ${This.MovementState}
					{
						case APPROACHING
						if ${Me.ToEntity.Approaching.ID} != ${This.TargetEntityID}
						{
							if ${Entity[${TargetEntityID}].Distance} < 150000
							{
								Entity[${TargetEntityID}]:Approach[${This.TargetDistance}]
							}
							else
							{
								Entity[${TargetEntityID}]:WarpTo
							}
						}
						case WARPING
						break
						default
						if ${Entity[${TargetEntityID}].Distance} < 150000
						{
							Entity[${TargetEntityID}]:Approach[${This.TargetDistance}]
						}
						else
						{
							Entity[${TargetEntityID}]:WarpTo
						}
						break
					}
				}
				break
			case STOP
				switch ${This.MovementState}
				{
					case MOVING
					Me:SetVelocity[0]
					break
					case APPROACHING
					Me:SetVelocity[0]
					break
					case WARPING
					break
					case STOPPING
					break
					case STOPPED
					break
				}
				break
		}
	}
}


variable(global) obj_Navigator Navigator
/* main thread */
function main()
{
	EVEBot.Threads:Insert[${Script.Filename}]
	while ${Script[EVEBot](exists)}
	{
		/* this is where we take action based on our current state */
		if ${Navigator.Running} && ${EVEBot.SessionValid} && ${Me.InSpace}
			{
				call Navigator.ProcessState
			}
		wait 30
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}