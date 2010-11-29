
objectdef obj_EVEBotUI
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable time NextPulse
	variable time NextMsgBoxPulse
	variable int PulseIntervalInSeconds = 60
	variable int PulseMsgBoxIntervalInSeconds = 15

	method Initialize()
	{
		ui -load interface/eveskin/eveskin.xml
		ui -load interface/evebotgui.xml

		This:LogSystemStats

		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This:UpdateConsole["obj_EVEBotUI: Initialized", LOG_MINOR]
	}

	method Reload()
	{
		;ui -reload interface/evebotgui.xml
		Logger:WriteQueue

		variable iterator Behavior
		EVEBot.BehaviorList:GetIterator[Behavior]

		if ${BotModule:First(exists)}
		{
			UIElement[EVEBot].FindUsableChild["Behavior","combobox"]:ClearItems
			UIElement[EVEBot].FindUsableChild["Behavior","combobox"]:AddItem["Idle"]
			do
			{
				UIElement[EVEBot].FindUsableChild["Behavior","combobox"]:AddItem["${Behavior.Value}"]
			}
			while ${BotModule:Next(exists)}
			UIElement[EVEBot].FindUsableChild["Behavior","combobox"].ItemByText[${Config.Common.Behavior}]:Select
		}
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		ui -unload interface/evebotgui.xml
		ui -unload interface/eveskin/eveskin.xml
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
    		; This:LogSystemStats
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}

	    if ${Time.Timestamp} > ${This.NextMsgBoxPulse.Timestamp}
		{

			if !${EVEBot.Paused}
			{
				if ${Me(exists)}
				{
					Config.Common:AutoLoginCharID[${EVEBot.CharID}]
				}
			}

    		This.NextMsgBoxPulse:Set[${Time.Timestamp}]
    		This.NextMsgBoxPulse.Second:Inc[${This.PulseMsgBoxIntervalInSeconds}]
    		This.NextMsgBoxPulse:Update
		}

	}

	method LogSystemStats()
	{
		This:UpdateConsole["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024].Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}
}
