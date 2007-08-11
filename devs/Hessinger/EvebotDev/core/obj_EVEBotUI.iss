
objectdef obj_EVEBotUI
{
	;; global variables (used in UI display)
	variable string CharacterName
	variable string MyTarget
	variable string MyRace
	variable string MyCorp

; TODO This doesn't belong here. - CyberTech
	variable bool ForcedReturn = FALSE					/* A variable for forced return */

; TODO These don't belong here - CyberTech
	variable int MinShieldPct = 50              /* What shields need to reach before entering combat */
	variable int MinStructurePct = 80              /* Min Structure that we should have, if we get into combat */

	variable int FrameCounter
	variable int FrameCounterMsgBoxes

	variable string LogFile
	variable string StatsLogFile
		
	method Initialize()
	{
		ui -load interface/eveskin/eveskin.xml
		ui -load interface/evebotgui.xml

		This.CharacterName:Set[${Me.Name}]
		This.MyRace:Set[${Me.ToPilot.Type}]
		This.MyCorp:Set[${Me.Corporation}]
		This.LogFile:Set["./config/logs/${Me.Name}-log.txt"]
		This.StatsLogFile:Set["./config/logs/${Me.Name}-stats.txt"]

		This:InitializeLogs

		Event[OnFrame]:AttachAtom[This:Pulse]
		This:UpdateConsole["obj_EVEBotUI: Initialized"]
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
		FrameCounterMsgBoxes:Inc
		
		variable int IntervalInSeconds = 1
		if ${FrameCounter} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			This:Update_Display_Values
			FrameCounter:Set[0]
		}
		
		IntervalInSeconds:Set[15]
		if ${FrameCounterMsgBoxes} >= ${Math.Calc[${Display.FPS} * ${IntervalInSeconds}]}
		{
			EVE:CloseAllMessageBoxes
			EVE:CloseAllChatInvites
			FrameCounterMsgBoxes:Set[0]
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
   
	member Runtime()
	{
		variable string Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int.LeadingZeroes[2]}
		variable string Minutes = ${Math.Calc[(${Script.RunningTime}/1000/60)%60].Int.LeadingZeroes[2]}
		variable string Seconds = ${Math.Calc[(${Script.RunningTime}/1000)%60].Int.LeadingZeroes[2]}
		
		return "${Hours}:${Minutes}:${Seconds}"
	}

	method UpdateConsole(string StatusMessage)
	{
		if ${StatusMessage(exists)}
		{
			UIElement[StatusConsole@Status@EvEBotOptionsTab@EVEBot]:Echo["${Time.Time24}: ${StatusMessage}"]
			redirect -append "${This.LogFile}" Echo "[${Time.Time24}] ${StatusMessage}"
		}
	}
	
	method InitializeLogs()
	{

		redirect -append "${This.LogFile}" echo "-------------------------------------------------"
		redirect -append "${This.LogFile}" echo "  Evebot Session time ${Time.Date} at ${Time.Time24}"
		redirect -append "${This.LogFile}" echo "  Evebot Session for  ${Me.Name}"
		redirect -append "${This.LogFile}" echo "  ${Version}"
		redirect -append "${This.LogFile}" echo "-------------------------------------------------"

		This:UpdateConsole["Starting EVEBot ${Version}"]

		redirect -append "${This.StatsLogFile}" echo "-------------------------------------------------"
		redirect -append "${This.StatsLogFile}" echo "  Evebot Session time ${Time.Date} at ${Time.Time24}"
		redirect -append "${This.StatsLogFile}" echo "  Evebot Session for  ${Me.Name}"
		redirect -append "${This.StatsLogFile}" echo "  ${Version}"
		redirect -append "${This.StatsLogFile}" echo "-------------------------------------------------"
	}	
}
