/*
	UplinkManager Class by CyberTech (cybertech@gmail.com)

	This class handles automatic registration of all peers on the
	uplink who are running the same script, sending and accepting
	heartbeats and any data the bot might require handling.

	TODO - CyberTech - Add validation that the other sessions are running the same script!!!!!!

	Additionally, using obj_UplinkManager:RelayInfo, a script may relay
	any data point to one or more peers for their local use, which will
	be dynamically inserted into the obj_RegisteredSession instance for
	that peer.  This completely avoids the requirement of hard-coding
	datapoints for bot behaviors or modules which may not even be loaded
	or running.

	Using this dynamic insertion, a bot behavior module may wish to check for
	a request -- by iterating obj_UplinkManager.RegisteredSessions,
	the module can perform the following steps:

		variable string VarName = "ExampleData"
		if ${RegisteredSession.Value.${VarName}(exists)}
		{
			... do something with ${RegisteredSession.Value.${VarName}} ...
		}

	Peers which have not been heard from for more than the MaxHeartBeat
	time below will be removed from the local session list by PrunePeerSessions()

	If you wish to create a descendant class from this, be sure to instantiate
	it as a global named "UplinkManager".

	It is designed to be fairly game-agnostic. Exceptions are as follows:
		RelayMySkills - EVE-Specific
		EVEBot.CharID - Possibly requires update
		Me.Name - Possibly requires update
		Config.Common.Behavior - Possibly requires update

		The Skill list is designed to be used for a module which assigns group
		(or fleet, for EVE Online) roles for proper bonuses. There is no reason
		these values cannot be sent via the dynamic variable system, except	that
		EVE requires so many of them that sending in one relay was considered
		more efficient.

	-- CyberTech
*/

objectdef obj_RegisteredSession
{
	variable string SessionName
	variable int CharID
	variable string CharName
	variable string Behavior
	variable time LastPing

	variable int SkillLevel_Leadership = -1
	variable int SkillLevel_Wing_Command
	variable int SkillLevel_Fleet_Command

	variable int SkillLevel_Armored_Warfare			/* Armor HP */
	variable int SkillLevel_Information_Warfare		/* Targeting Range */
	variable int SkillLevel_Mining_Foreman			/* Mining Yield */
	variable int SkillLevel_Siege_Warfare			/* Shield HP */
	variable int SkillLevel_Skirmish_Warfare		/* Agility */

	method Initialize(string _SessionName, int _CharID, string _CharName, string _Behavior, string _LastPing)
	{
		SessionName:Set[${_SessionName}]
		CharID:Set[${_CharID}]
		CharName:Set[${_CharName}]
		Behavior:Set[${_Behavior}]
		LastPing:Set[${_LastPing}]
	}

	method ShowInfo()
	{
		Logger:Log["Session ${SessionName} Name: ${CharName} Mode ${Behavior}"]

#if EVEBOT_DEBUG
		variable iterator MyVar
		This.VariableScope:GetIterator[MyVar]

		if ${MyVar:First(exists)}
		{
			do
			{
				if ${MyVar.Key.NotEqual["SessionName"]} && \
					${MyVar.Key.NotEqual["CharName"]} && \
					${MyVar.Key.NotEqual["Behavior"]}
				{
					Logger:Log["  ${MyVar.Key} ${MyVar.Value} ${MyVar.Value(type)}"]
				}
			}
			while ${MyVar:Next(exists)}
		}
#endif
	}
}

objectdef obj_UplinkManager inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"

	variable int MaxHeartBeat = 35	/* Max time, in seconds, since we last heard from a session */
	variable index:obj_RegisteredSession RegisteredSessions
	variable bool Initialized = FALSE


	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		Logger:Log["${LogPrefix}: Setting IS Session Name & Window Title"]

		Squelch Uplink name ${Me.Name}
		Squelch WindowText "EVE - ${Me.Name}"

		PulseTimer:SetIntervals[0.5,1.0]
		; Schedule the first pulse for 5 seconds from now, instead of immediate, to allow the uplink time to update name.
		PulseTimer:Extend[5.0]

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]

		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if !${EVEBot.Loaded} || ${EVEBot.Disabled}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			if !${Initialized}
			{
				This:RelayRegistration["all"]
				This:RelayMySkills["all"]
				Initialized:Set[TRUE]
			}
			else
			{
				This:RelayRegistration["all", TRUE]
				This:PrunePeerSessions[]
			}

			This.PulseTimer:Update
		}
	}

	member:bool PeerExists(string CharName)
	{
		variable iterator RegisteredSession
		This.RegisteredSessions:GetIterator[RegisteredSession]
		if ${RegisteredSession:First(exists)}
		{
			do
			{
				echo ${RegisteredSession.Value.SessionName}
				if ${RegisteredSession.Value.SessionName.Equal[${CharName}]}
				{
					return TRUE
				}
			}
			while ${RegisteredSession:Next(exists)}
		}
		return FALSE
	}

	method RequestSkills(string Requester)
	{
		This:RelayMySkills[${Requester}]
	}

	method RelayMySkills(string Destination="all")
	{
		Logger:Log["${LogPrefix}:RelayMySkills(${Destination})", LOG_DEBUG]
		relay "${Destination}" -noredirect "UplinkManager:UpdatePeerSkills[${Session}, ${If[${Me.Skill[Leadership](exists)}, ${Me.Skill[Leadership].Level}, 0]}, ${If[${Me.Skill[Wing Command](exists)}, ${Me.Skill[Wing Command].Level}, 0]}, ${If[${Me.Skill[Fleet Command](exists)}, ${Me.Skill[Fleet Command].Level}, 0]}, ${If[${Me.Skill[Armored Warfare](exists)}, ${Me.Skill[Armored Warfare].Level}, 0]}, ${If[${Me.Skill[Information Warfare](exists)}, ${Me.Skill[Information Warfare].Level}, 0]}, ${If[${Me.Skill[Mining Foreman](exists)}, ${Me.Skill[Mining Foreman].Level}, 0]}, ${If[${Me.Skill[Siege Warfare](exists)}, ${Me.Skill[Siege Warfare].Level}, 0]}, ${If[${Me.Skill[Skirmish Warfare](exists)}, ${Me.Skill[Skirmish Warfare].Level}, 0]}]"
		/* This one won't work, something about the line continuations -- CyberTech
		relay "${Destination}" -noredirect \
			"UplinkManager:UpdatePeerSkills[${Session}, \
											${If[${Me.Skill[Leadership](exists)}, ${Me.Skill[Leadership].Level}, 0]}, \
											${If[${Me.Skill[Wing Command](exists)}, ${Me.Skill[Wing Command].Level}, 0]}, \
											${If[${Me.Skill[Fleet Command](exists)}, ${Me.Skill[Fleet Command].Level}, 0]}, \
											${If[${Me.Skill[Armored Warfare](exists)}, ${Me.Skill[Armored Warfare].Level}, 0]}, \
											${If[${Me.Skill[Information Warfare](exists)}, ${Me.Skill[Information Warfare].Level}, 0]}, \
											${If[${Me.Skill[Mining Foreman](exists)}, ${Me.Skill[Mining Foreman].Level}, 0]}, \
											${If[${Me.Skill[Siege Warfare](exists)}, ${Me.Skill[Siege Warfare].Level}, 0]}, \
											${If[${Me.Skill[Skirmish Warfare](exists)}, ${Me.Skill[Skirmish Warfare].Level}, 0]}]"
		*/
	}

	; Register this session with other peers
	method RelayRegistration(string Destination, bool Update=FALSE)
	{
		relay "${Destination}" -noredirect "UplinkManager:UpdatePeerSession[${Session},${EVEBot.CharID},${Me.Name},${Config.Common.Behavior}]"
	}

	; Called by the script to send misc info to all peers
	method RelayInfo(string VarName, string VarType, string Value)
	{
		relay "all other" -noredirect "UplinkManager:UpdateInfo[${Session}, ${VarName}, ${VarType}, ${Value}]"
	}

	method UpdateInfo(string RemoteSessionName, string VarName, string VarType, string Value)
	{
		variable iterator RegisteredSession
		This.RegisteredSessions:GetIterator[RegisteredSession]
		if ${RegisteredSession:First(exists)}
		{
			do
			{
				if ${RegisteredSession.Value.SessionName.Equal[${RemoteSessionName}]}
				{
					if ${RegisteredSession.Value.${VarName}(exists)}
					{
						RegisteredSession.Value.${VarName}:Set[${Value}]
					}
					else
					{
						RegisteredSession.Value.VariableScope:CreateVariable[${VarType}, "${VarName}", "${Value}"]
					}
					RegisteredSession.Value.LastPing:Set[${Time.Timestamp}]
					Logger:Log["${LogPrefix}:UpdateInfo: ${RegisteredSession.Value.CharName}: ${VarName}=${Value}", LOG_DEBUG]
					return
				}
			}
			while ${RegisteredSession:Next(exists)}
		}
		Logger:Log["${LogPrefix}:UpdateInfo: Warning: Received info for unknown session ${RemoteSessionName} (${VarName}=${Value})", LOG_DEBUG]
	}
	; Called by a remote peer to update our list of the skills it has
	method UpdatePeerSkills(string RemoteSessionName, int Leadership, int Wing_Command, int Fleet_Command, int Armored_Warfare, int Information_Warfare, int Mining_Foreman, int Siege_Warfare, int Skirmish_Warfare)
	{
		variable iterator RegisteredSession
		This.RegisteredSessions:GetIterator[RegisteredSession]
		if ${RegisteredSession:First(exists)}
		{
			do
			{
				if ${RegisteredSession.Value.SessionName.Equal[${RemoteSessionName}]}
				{
					RegisteredSession.Value.SkillLevel_Leadership:Set[${Leadership}]
					RegisteredSession.Value.SkillLevel_Wing_Command:Set[${Wing_Command}]
					RegisteredSession.Value.SkillLevel_Fleet_Command:Set[${Fleet_Command}]

					RegisteredSession.Value.SkillLevel_Armored_Warfare:Set[${Armored_Warfare}]
					RegisteredSession.Value.SkillLevel_Information_Warfare:Set[${Information_Warfare}]
					RegisteredSession.Value.SkillLevel_Mining_Foreman:Set[${Mining_Foreman}]
					RegisteredSession.Value.SkillLevel_Siege_Warfare:Set[${Siege_Warfare}]
					RegisteredSession.Value.SkillLevel_Skirmish_Warfare:Set[${Skirmish_Warfare}]
					RegisteredSession.Value.LastPing:Set[${Time.Timestamp}]
					Logger:Log["${LogPrefix}:UpdatePeerSkills: Updated Skills for ${RemoteSessionName}", LOG_DEBUG]
					RegisteredSession.Value:ShowInfo
					return
				}
			}
			while ${RegisteredSession:Next(exists)}
		}
	}

	; Called by a remote peer to update it's registration everytime Pulse() triggers
	method UpdatePeerSession(string RemoteSessionName, int CharID, string CharName, string Behavior)
	{
		variable iterator RegisteredSession
		This.RegisteredSessions:GetIterator[RegisteredSession]

		if ${RegisteredSession:First(exists)}
		{
			do
			{
				if ${RegisteredSession.Value.SkillLevel_Leadership} == -1
				{
					; We have no skill info for this session, so let's ask for it.
					relay "${RegisteredSession.Value.SessionName}" -noredirect "UplinkManager:RequestSkills[${Session}]"
				}
				if ${RegisteredSession.Value.SessionName.Equal[${RemoteSessionName}]}
				{
					RegisteredSession.Value.Behavior:Set[${Behavior}]
					RegisteredSession.Value.LastPing:Set[${Time.Timestamp}]
					;Logger:Log["${LogPrefix}: Updated Registration for ${RemoteSessionName}:${Behavior}", LOG_DEBUG]
					return
				}
			}
			while ${RegisteredSession:Next(exists)}
		}

		This.RegisteredSessions:Insert[${RemoteSessionName}, ${CharID}, ${CharName}, ${Behavior}, ${Time.Timestamp}]
		relay "${RemoteSessionName}" -noredirect "UplinkManager:RequestSkills[${Session}]"
		Logger:Log["${LogPrefix}: Registered ${RemoteSessionName}:${Behavior}"]
	}

	method PrunePeerSessions()
	{
		variable iterator RegisteredSession
		This.RegisteredSessions:GetIterator[RegisteredSession]

		if ${RegisteredSession:First(exists)}
		{
			do
			{
				if ${Math.Calc[${Time.Timestamp} - ${RegisteredSession.Value.LastPing.Timestamp}].Int} > ${This.MaxHeartBeat}
				{
					Logger:Log["${LogPrefix}: Removed ${RegisteredSession.Value.SessionName}:${RegisteredSession.Value.Behavior} from known sessions"]
					This.RegisteredSessions:Remove[${RegisteredSession.Key}]
					This.RegisteredSessions:Collapse
					return
				}
			}
			while ${RegisteredSession:Next(exists)}
		}
	}
}
