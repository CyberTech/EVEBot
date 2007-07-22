
objectdef obj_EVEBotUI
{
	;; global variables (used in UI display)
	variable string CharacterName
	variable string MyTarget
	variable string MyRace
	variable string MyCorp
	variable int TotalRuns = 0						/* Total Times we've had to transfer to hanger */

; TODO This doesn't belong here. - CyberTech
	variable bool ForcedReturn = FALSE					/* A variable for forced return */

; TODO These don't belong here - CyberTech
	variable int MinShieldPct = 50              /* What shields need to reach before entering combat */
	variable int MinStructurePct = 80              /* Min Structure that we should have, if we get into combat */

	variable int FrameCounter
	
	method Initialize()
	{
		ui -load interface/eveskin/eveskin.xml
		ui -load interface/evebotgui.xml

		Event[OnFrame]:AttachAtom[This:Pulse]
		This.CharacterName:Set[${Me.Name}]
		This.MyRace:Set[${Me.ToPilot.Type}]
		This.MyCorp:Set[${Me.Corporation}]
	}

	method Shutdown()
	{
		Event[OnFrame]:DetachAtom[This:Pulse]
		ui -unload interface/evebotgui.xml
		ui -unload interface/eveskin/eveskin.xml
	}

	method Pulse()
	{
		FrameCounter:Inc
		
		if ${FrameCounter} >= 80
		{
			This:Update_Display_Values
			FrameCounter:Set[0]
		}
	}

	method Update_Display_Values()
	{
 
		; Some variables just aren't going to change...they should be set initially and left alone
   
		if (${Me.ActiveTarget(exists)})
		{
			This.MyTarget:Set[${Me.ActiveTarget}]
		}
		else
		{
			This.MyTarget:Set[None]
		}
   }
}
