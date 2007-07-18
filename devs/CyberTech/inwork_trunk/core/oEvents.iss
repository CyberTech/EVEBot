objectdef oEvent
{
	; Register and Atomize needed events here
	method Register()
	{
			; Register specific Events
			LavishScript:RegisterEvent[COMBAT_SETTING_CHANGE]
			
			; Atomize specific Events
			Event[COMBAT_SETTING_CHANGE]:AttachAtom[Combat:CombatSettingsChange]
	}
	;;;;;;;;;;;;;;;;;;;;;;;;
	;Need a method to debug;
	;;;;;;;;;;;;;;;;;;;;;;;;
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Below is how I would like to go about having settings writtin into files,               ;
;  (may not be completely right btw, never done this before, just beed doing reading =))  ;
; This example is for the CombatSettingsChange                                            ;
; This would go in the new oCombat.iss file I believe you are writing.                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

method CombatSettingsChange(string Action)
		{
			switch ${Action}
			{
			case MinShieldPct
			
			  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				;In this case, We would use a drop down box to have the min shield pct value selected;
				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				
				if ${UIElement[MinShieldPctInput@Combat@EvebotChild@EvEbot].SelectedItem.Value(exists)}
				{
					This.MinShieldPct:Set[${UIElement[MinShieldPctInput@Combat@EvebotChild@EvEbot].SelectedItem}]
				}
				
				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				; This pulls the settings directly from the tab instead of using an input change event;
			  ; The GUI would be closer to running Real Time then just a BIO type GUI.              ;
			  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			  
			}
		}	
			