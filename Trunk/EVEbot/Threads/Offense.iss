#include ..\core\defines.iss
/*
	Offense Thread

	This thread handles shooting targets (rats, players, structures, etc...)

	-- GliderPro

*/
objectdef obj_Offense
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool Running = TRUE

	variable time NextPulse
	variable int PulseIntervalInSeconds = 1

	method Initialize()
	{
		Event[OnFrame]:AttachAtom[This:Pulse]
		UI:UpdateConsole["Thread: obj_Offense: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
		if !${Script[EVEBot](exists)}
		{
			return
		}

		if ${EVEBot.Paused}
		{
			return
		}

		if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if ${This.Running}
			{
				This:TakeOffensiveAction
			}
			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	method TakeOffensiveAction()
	{
		if ${Me.ActiveTarget(exists)} && !${Me.ActiveTarget.IsPC}
		{
			if ${This.IsConcordTarget[${Me.ActiveTarget.GroupID}]} == FALSE
			{
				if ${Me.ActiveTarget.Distance} < 9999
				{
					Ship:Activate_StasisWebs
				}

				if ${Me.ActiveTarget.Distance} < ${Ship.OptimalWeaponRange}
				{
					Ship:Activate_Weapons
				}

				if ${Me.ActiveTarget.Distance} < 19999
				{
					Ship.Drones:SendDrones
				}
			}
		}
		else
		{
			Ship:Deactivate_Weapons
			Ship:Deactivate_StasisWebs
		}
	}

	member:bool IsConcordTarget(int groupID)
	{
		switch ${groupID}
		{
			case GROUP_LARGECOLLIDABLEOBJECT
			case GROUP_LARGECOLLIDABLESHIP
			case GROUP_LARGECOLLIDABLESTRUCTURE
			case GROUP_SENTRYGUN
			case GROUP_CONCORDDRONE
			case GROUP_CUSTOMSOFFICIAL
			case GROUP_POLICEDRONE
			case GROUP_CONVOYDRONE
			case GROUP_FACTIONDRONE
			case GROUP_BILLBOARD
				return TRUE
		}

		return FALSE
	}

	method Enable()
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["Offense: Enabled"]
#endif
		This.Running:Set[TRUE]
	}

	method Disable()
	{
#if EVEBOT_DEBUG
		UI:UpdateConsole["Offense: Disabled"]
#endif
		This.Running:Set[FALSE]
	}
}

variable(global) obj_Offense Offense

function main()
{
	while ${Script[EVEBot](exists)}
	{
		waitframe
	}
	echo "EVEBot exited, unloading ${Script.Filename}"
}