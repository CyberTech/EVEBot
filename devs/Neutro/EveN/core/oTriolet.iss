/*  By Neutro
Member list
- AmI (role)            - State
- GetID(Name)

Methods
- Add(Name, Race)		- ProcessMessage		- Brain
- Remove(Name)		- SendMessage		- Broadcast
- Ping				- Update			- Pulse
- Plugin			- Shutdown
*/

objectdef oBot
{
	variable string Name
	variable string Role
	variable bool IsLeader
	variable string WhoNeedBackup
	variable int LastPing
	variable string Ship = ${Me.Ship}
	
	method Initialize(string Name)
	{
		This.Name:Set["${Name}"]
			if ${Ship.Equal["${Me.Name}'s Osprey"]}
			{
			This.Role:Set[Miner]
			}
			elseif ${Ship.Equal["${Me.Name}'s Iteron"]}
			{
			This.Role:Set[Transporter]
			}
			elseif ${Ship.Equal["${Me.Name}'s PewPewShip"]}
			{
			This.Role:Set[Defender]
			}
		This.LastPing:Set[${LavishScript.RunningTime}]
		if ${Triolet.LeaderExists}
		{
		This.IsLeader:Set[FALSE]
		}
		else
		{
		This.IsLeader:Set[TRUE]
		}
	}
	
	/* possibilities are limited to Miner, Defender, Transporter
	so like ${Bots[1].AmI[Miner]}   would return true if bot 1 is a miner... duh yea I know */
	
	member AmI(string role)
	{
		if ${Enabled} && ${Role.Equal[${role}]}
		{
		return TRUE
		}
	return FALSE
	}
}

objectdef oTriolet
{
	variable int LastPing
	variable int LastRequest
	variable string Role
	variable string CurrentState
	variable bool Enabled = TRUE
	variable index:oBot Bots
	variable index:string NeedBackupList
	variable index:string EnnemyList
	variable index:int CanList
	
	method Plugin()
	{
	Echo "I r teh botz temz!"
	LavishScript:RegisterEvent[Trioleto]
	Event[Trioleto]:AttachAtom[This:Brain]
	This:Ping
	;This:Elect
	}	
	
	method Ping()
	{
		This:Broadcast[Trio_Pong]
	}
	
	method Broadcast(string Cmd, string Params)
	{
		relay all Event[Trioleto]:Execute["${Me.Name}",All,${Cmd},"${Params}"]
	}
	
	method Brain(string From, string To, string Cmd, string Params)
	{
		if ${Enabled} && (${To.Equal[All]} || ${To.Equal["${Me.Name}"]})
		{
			This:ProcessMessage["${From}",${Cmd},${Params}]
		}
	}

	member GetID(string Name)
	{
		variable int Idx = 1
		This.Bots:Collapse
		if ${This.Bots.Get[${Idx}](exists)}
		{
			do
			{
				if ${This.Bots.Get[${Idx}].Name.Equal["${Name}"]}
				{
					return ${Idx}
				}
			}
			while ${This.Bots.Get[${Idx:Inc}](exists)}
		}
		else
		{
		return 0
		}
	}
	
	method Add(string Name)
	{
		Bots:Insert["${Name}"]
		This.Bots:Collapse
		Echo "Bot ${Name} added to the Triolet."
		;This:Update
	}
	
	method Remove(string Name)
	{
		variable int Whom
		Whom:Set[${GetID["${Name}"]}]
		if ${Whom}
		{
			Echo "Bot ${name} removed from the Triolet."
			Bots:Remove[${Whom}]
		}
		;This:Update
	}
	
	method ProcessMessage(string From, string Cmd, string Params)
	{
		variable int Whom
		Whom:Set[${GetID["${Me.Name}"]}]
		
		switch ${Cmd}
		{
			case Trio_Ping
				This:Broadcast[Trio_Pong]
				break
			case Trio_Pong
				if ${Whom} == 0
				{
					This:Add["${From}"]
				}
				Whom:Set[${GetID["${Name}"]}]
				if ${Whom}
				{
					This.Bots.Get[${Whom}].LastPing:Set[${LavishScript.RunningTime}]
				}
				break
			case Trio_Backup
				NeedBackupList:Insert[${From}]
				
				/*
				in the main function switch for the defender, it should go as follow
				variable int i
				variable int j
				for (j:Set[1], ${j} <= ${NeedBackupList}, ${j:inc})   ; for needs to be based on hp/ship/number of EnnemyCount for this Miner/transporter
				{
					${Triolet.GetEntity[${From}]}:WarpTo ;j
					for (i:Set[1], ${i} <= ${EnnemyList.Count}, ${i:inc})
					{
						${Triolet.GetEntity[${EnnemyIs}]}:LockTarget
						call DefendAndDestroy
						EnnemyList:Remove[${i}]
					}
					NeedBackupList:Remove[${j}]
				}
				NeedBackupList:Collapse
				EnnemyList:Collapse
				*/
				
				EnnemyList:Insert[${Params.Token[1,:]}] /* token 1 is enemy to destroy */
				NeedBackupList:Insert[${From}]
				
				/*
				for the miner it should look like that
				if ${Triolet.RoleExists[Defender]}
				{
					Triolet:NeedBackup[${HostileTarget}] ; need a declaration for HostileTarget
					;continue minning in peace
				}
				else
				{
					;No defender, getting in a safety spot
					Call Dock
				}
				*/
				break
			case Trio_Invite
				if ${Bots.Get[${Whom}].IsMaster}
				{
				;Evebot:CmdExecute[Invite[${From}]]   ; doesn't exist right know
				call Invite ${from} ;(pixel bot ftw)
				}
				
				if ${Me.Name.Equal[${From}]}
				{
				;Evebot:CmdExecute[AcceptInvite]  ; doesn't exist right know
				call AcceptInvite ;(pixel bot ftw)
				}
				break
			case Trio_CanLoc
				CanList:Insert[${Params}]
				
				/*
				for the transporter it would look like that
				CanList:Collapse
				for (k:Set[1], ${k} <= ${CanList.Count}, ${k:Inc}
				{
					${GetEntity[CanList.Get[${k}].ID]}:WarpTo
					; set destination (not supported by isxeve yet)
					; Eve:ExecuteCmd[Autopilot]
					call TransferCan
					call CheckMarket
					call GoToBestPriceLoc
					call SellTo
					CanList:Del[CanList.Get[${k}].Name]
				}
				*/
				
				break
			case Trio_Elect
				Bots.Get[${GetID[${From}]}].IsLeader:Set[TRUE]
				break
			case Trio_Remove
				This:Remove[${Whom}]
				break
		}
	}
	
	method GetEntity(string Name)
	{
	 /* while to get the entity number that equals the name */
	 
	}
	
	method AddCan(int ID)
	{
		This:Broadcast[Trio_CanLoc, ${ID}]
	}
	
	member RoleExists(string Role)
	{	
		variable int i = 1
		variable int Count = 0
		while ${Bots.Get[${i}](exists)}
		{
			if ${Bots.Get[${i}].Role.Equal[${Role}]}
			{
			Count:Inc
			}
		i:Inc
		}
		return ${Count}
	}
	
	method SendMessage(string To, string Cmd, string Params)
	{
		relay all Event[Trioleto]:Execute[${Me.Name},${To},${Cmd},"${Params}"]
	}
	
	method Elect()
	{
		if ${Bots.Get[${GetID[${Me.Name}]}].IsLeader}
		{
		This:Broadcast[Trio_Elect, ${Me.Name}]
		}
	}
	
	member LeaderExists()
	{
		variable int Idx = 1
			do
			{
				if ${This.Bots.Get[${Idx}].IsLeader}
				{
					return TRUE
				}
			}
			while ${This.Bots.Get[${Idx:Inc}](exists)}
		return FALSE
	}
	
	method Invite()
	{
	This:Broadcast[Trio_Invite]
	}
	
	method Update()
	{
		variable int Idx = 1
		UIElement[Member1@Trio@Pages@EVEBOTGUI]:ClearItems
		Bots:Collapse
		
		if ${This.Bots.Get[${Idx}](exists)}
		{
			do
			{
				if ${Math.Calc[${LavishScript.RunningTime} - ${Bots.Get[${Idx}].LastPing}]} > 120000
				{
					;too long buddy, peace out
					This:Remove[${Bots.Get[${Idx}].Name}]
				}
				else
				{
					UIElement[Member1@Trio@Pages@EVEBOTGUI]:AddItem["${Bots.Get[${Idx}].Name}"]
					UIElement[txtRole@Trio@Pages@EVEBOTGUI]:SetText["${This.Role}"]
				}
			}
			while ${Bots.Get[${Idx:Inc}](exists)}
		}
	}
	
	method Shutdown()
	{
		This:Broadcast[Trio_Remove, "${Me.Name}"]
		Event[Trioleto]:DetachAtom[This:Brain]
		Event[Trioleto]:Unregister
	}
}