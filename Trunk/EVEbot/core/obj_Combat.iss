 #ifndef __OBJ_COMBAT__
 #define __OBJ_COMBAT__

/*
    The combat object
    
    The obj_Combat object is a bot-support module designed to be used
    with EVEBOT.  It provides a common framework for combat decissions
    that the various bot modules can call.
    
    USAGE EXAMPLES
    --------------
    
    objectdef obj_Miner
    {
        variable obj_Combat Combat
        
        method Initialize()
        {
            ;; bot module initialization
            ;; ...
            ;; ...
            ;; call the combat object's init routine
            This.Combat:Initialize
            ;; set the combat "mode"
            This.Combat:SetMode["DEFENSIVE"]
        }
        
        method Pulse()
        {
            if ${EVEBot.Paused}
                return
            if !${Config.Common.BotModeName.Equal[Miner]}
                return
            ;; bot module frame action code
            ;; ...
            ;; ...
            ;; call the combat frame action code
            This.Combat:Pulse
        }
        
        function ProcessState()
        {               
            if !${Config.Common.BotModeName.Equal[Miner]}
                return
            
            ; call the combat object state processing
            call This.Combat.ProcessState
            
            ; see if combat object wants to 
            ; override bot module state.
            if ${This.Combat.Override}
                return
                        
            ; process bot module "states"
            switch ${This.CurrentState}
            {
                ;; ...
                ;; ...
            }
        }       
    }
    
    COMBAT OBJECT "MODES"
    ---------------------
    
        * DEFENSIVE -- If under attack (by NPCs) AND damage taken exceeds threshold, fight back
        * AGGRESSIVE -- If hostile NPC is targeted, destroy it
        * TANK      -- Maintain defenses but attack nothing
        
        NOTE: The combat object will activate and maintain your "tank" in all modes.  
              It will also manage any enabled "flee" state.

    -- GliderPro    
*/

objectdef obj_Combat
{
	variable time NextPulse
	variable int PulseIntervalInSeconds = 5

    variable bool   Override
    variable string CombatMode
    variable string CurrentState
    variable bool   Fled
    
    method Initialize()
    {
        This.CurrentState:Set["IDLE"]
        This.Fled:Set[FALSE]
        UI:UpdateConsole["obj_Combat: Initialized"]
    }
    
    method Shutdown()
    {
    }
    
    method Pulse()
    {
		if ${EVEBot.Paused}
		{
			return
		}
		
	    if ${Time.Timestamp} > ${This.NextPulse.Timestamp}
		{
            This:SetState

    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.IntervalInSeconds}]
    		This.NextPulse:Update
        }
    }
    
    method SetState()
    {
		if ${Me.GetTargets(exists)} && ${Me.GetTargets} > 0
		{
			This.CurrentState:Set["FIGHT"]
		}
		else
		{
			This.CurrentState:Set["IDLE"]
		}
    }
    
    method SetMode(string newMode)
    {
        This.CombatMode:Set[${newMode}]
    }
    
    member:string Mode()
    {
        return ${This.CombatMode}
    }
    
    member:bool Override()
    {
        return ${This.Override}
    }
    
    function ProcessState()
    {
        This.Override:Set[FALSE]
        
        /* flee on (Social.IsSafe == FALSE) regardless of state */
        if !${Social.IsSafe}
        {
            call This.Flee
            This.Override:Set[TRUE]
        }
        elseif (!${Ship.IsAmmoAvailable} &&  ${Config.Combat.RunOnLowAmmo})
        {
            call This.Flee
            This.Override:Set[TRUE]
        }
        else
        {
            call This.ManageTank
            call This.CheckTank
            switch ${This.CurrentState}
            {
                case IDLE
                    break
                case FLEE
                    call This.Flee
                    This.Override:Set[TRUE]
                    break
                case FIGHT
                   call This.Fight
                   break
            }
        }
    }           
	
	function Fight()
	{
		; Reload the weapons -if- ammo is below 30% and they arent firing
		Ship:Reload_Weapons[FALSE]

		; Activate the weapons, the modules class checks if there's a target (no it doesn't - ct)
		Ship:Activate_StasisWebs
		Ship:Activate_Weapons
		call Ship.Drones.SendDrones
	}
    
    function Flee()
    {
        This.Fled:Set[TRUE]
        
        if ${Config.Combat.RunToStation}
        {
        	UI:UpdateConsole["obj_Combat: DEBUG: Fleeing to Station"]
            call This.FleeToStation
        }
        else
        {
        	UI:UpdateConsole["obj_Combat: DEBUG: Fleeing to Safespots"]
            call This.FleeToSafespot
        }
    }
    
    function FleeToStation()
    {
        if !${Station.Docked}
        {
            call Station.Dock
        }
    }
    
    function FleeToSafespot()
    {   
        ; Are we at the safespot and not warping?
        if ${Me.ToEntity.Mode} != 3 && !${Safespots.IsAtSafespot}
        {
            call Safespots.WarpTo
            wait 30
        }
        
        if ${Safespots.IsAtSafespot} && !${Ship.IsCloaked}
        {           
            wait 60
            ;UI:UpdateConsole["obj_Combat: DEBUG: At Safespot."]
            Ship:Deactivate_Hardeners[]
			Ship:Deactivate_Shield_Booster[]
			Ship:Deactivate_Armor_Reps[]
            Ship:Activate_Cloak[]
        }
    }
    
    function CheckTank()
    {
        variable int Counter
        variable float aPct
        variable float sPct
        variable float cPct
        
        /* see if tank checking is configured */
        if !${Config.Combat.RunOnLowTank}
            return
        
        /* TODO - clean up this code when ArmorPct/ShieldPct wierdness is gone */
        Counter:Set[0]
        do
        {
            aPct:Set[${Me.Ship.ArmorPct}]
            if (${aPct} == NULL || ${aPct} <= 0)
            {
                wait 20
                Counter:Inc[20]
                if ${Counter} > 600
                {
                    UI:UpdateConsole["Me.Ship.ArmorPct was invalid for longer than a minute!"]
                    This.CurrentState:Set["FLEE"]
                    return
                }
            }
        }
        while (${aPct} == NULL || ${aPct} <= 0)
        
        Counter:Set[0]
        do
        {
            sPct:Set[${Me.Ship.ShieldPct}]
            if (${sPct} == NULL || ${sPct} <= 0)
            {
                wait 20
                Counter:Inc[20]
                if ${Counter} > 600
                {
                    UI:UpdateConsole["Me.Ship.ShieldPct was invalid for longer than a minute!"]
                    This.CurrentState:Set["FLEE"]
                    return
                }
            }
        }
        while (${sPct} == NULL || ${sPct} <= 0)

        Counter:Set[0]
        do
        {
            cPct:Set[${Me.Ship.CapacitorPct}]
            if (${cPct} == NULL || ${cPct} <= 0)
            {
                wait 20
                Counter:Inc[20]
                if ${Counter} > 600
                {
                    UI:UpdateConsole["Me.Ship.CapacitorPct was invalid for longer than a minute!"]
                    This.CurrentState:Set["FLEE"]
                    return
                }
            }
        }
        while (${cPct} == NULL || ${cPct} <= 0)

        if ${This.Fled}
        {
            /* don't leave the "fled" state until we regen */
            if (${aPct} < 98 || ${sPct} < 80 || ${cPct} < 80)
            {
                This.CurrentState:Set["FLEE"]           
            }
            else
            {
                This.Fled:Set[FALSE]
                This.CurrentState:Set["IDLE"]           
            }
        }
        elseif (${aPct} < ${Config.Combat.MinimumArmorPct}  || \
                ${sPct} < ${Config.Combat.MinimumShieldPct} || \
                ${cPct} < ${Config.Combat.MinimumCapPct})
        {
            UI:UpdateConsole["Armor is at ${aPct}%: ${Me.Ship.Armor}/${Me.Ship.MaxArmor}"]
            UI:UpdateConsole["Shield is at ${sPct}%: ${Me.Ship.Shield}/${Me.Ship.MaxShield}"]
            UI:UpdateConsole["Cap is at ${cPct}%: ${Me.Ship.Capacitor}/${Me.Ship.MaxCapacitor}"]
            UI:UpdateConsole["Fleeing due to defensive status"]
            This.CurrentState:Set["FLEE"]
        }           
    }   

    function ManageTank()
    {
        variable int Counter
        variable float aPct
        variable float sPct
        variable float cPct
        
        /* TODO - clean up this code when ArmorPct/ShieldPct wierdness is gone */
        Counter:Set[0]
        do
        {
            aPct:Set[${Me.Ship.ArmorPct}]
            if (${aPct} == NULL || ${aPct} <= 0)
            {
                wait 20
                Counter:Inc[20]
                if ${Counter} > 600
                {
                    UI:UpdateConsole["Me.Ship.ArmorPct was invalid for longer than a minute!"]
                    This.CurrentState:Set["FLEE"]
                    return
                }
            }
        }
        while (${aPct} == NULL || ${aPct} <= 0)
        
        Counter:Set[0]
        do
        {
            sPct:Set[${Me.Ship.ShieldPct}]
            if (${sPct} == NULL || ${sPct} <= 0)
            {
                wait 20
                Counter:Inc[20]
                if ${Counter} > 600
                {
                    UI:UpdateConsole["Me.Ship.ShieldPct was invalid for longer than a minute!"]
                    This.CurrentState:Set["FLEE"]
                    return
                }
            }
        }
        while (${sPct} == NULL || ${sPct} <= 0)

        Counter:Set[0]
        do
        {
            cPct:Set[${Me.Ship.CapacitorPct}]
            if (${cPct} == NULL || ${cPct} <= 0)
            {
                wait 20
                Counter:Inc[20]
                if ${Counter} > 600
                {
                    UI:UpdateConsole["Me.Ship.CapacitorPct was invalid for longer than a minute!"]
                    This.CurrentState:Set["FLEE"]
                    return
                }
            }
        }
        while (${cPct} == NULL || ${cPct} <= 0)


        ;;UI:UpdateConsole["DEBUG: Combat ${aPct} ${sPct} ${cPct}"]

        ; Armor Repair
        ; If you don't have armor repairers this code does nothing.
        if ${aPct} < 90
        {
            Ship:Activate_Armor_Reps[]
        }
                
        if ${aPct} > 98
        {
            Ship:Deactivate_Armor_Reps[]
        }
        
        ; Shield Boosters
        ; If you don't have a shield booster this code does nothing.
        ; The code below pulses your booster around the sweet spot
        if ${sPct} < 70 || ${Config.Combat.AlwaysShieldBoost}
        {   /* Turn on the shield booster */
            Ship:Activate_Shield_Booster[]
        }
        
        if ${sPct} > 80 && !${Config.Combat.AlwaysShieldBoost}
        {   /* Turn off the shield booster */
            Ship:Deactivate_Shield_Booster[]
        }               
        
        ; Capacitor
        ; If you don't have a cap booster this code does nothing.
        if ${cPct} < 20
        {   /* Turn on the cap booster */
            Ship:Activate_Cap_Booster[]
        }
        
        if ${cPct} > 80
        {   /* Turn off the cap booster */
            Ship:Deactivate_Cap_Booster[]
        }               
                
        ; Active shield (or armor) hardeners
        ; If you don't have hardeners this code does nothing.
        if ${Me.GetTargetedBy} > 0
        {
            Ship:Activate_Hardeners[]       

            /* We have aggro now, yay! */
			if ${Config.Combat.LaunchCombatDrones} && \
				${Ship.Drones.DronesInSpace} == 0 && \
				!${Ship.InWarp}
			{
				Ship.Drones:LaunchAll[]
			}
        }
        else
        {
            Ship:Deactivate_Hardeners[]     
        }
    }
}

#endif /* __OBJ_COMBAT__ */