
objectdef obj_EVEBotUI inherits obj_BaseClass
{
	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		ui -load interface/eveskin/eveskin.xml
		ui -load interface/evebotgui.xml

		This:LogSystemStats
		This:CheckUIPosition

		PulseTimer:SetIntervals[60.0,60.0]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Reload()
	{
		ui -reload interface/evebotgui.xml
		Logger:WriteQueue
		This:PopulateBehavioralComboBox
		This.Reloaded:Set[TRUE]
	}

	method PopulateBehavioralComboBox()
	{
		variable iterator Behavior
		Behaviors.Loaded:GetIterator[Behavior]

		if ${Behavior:First(exists)}
		{
			UIElement[EVEBot].FindUsableChild["CurrentBehavior","combobox"]:ClearItems
			UIElement[EVEBot].FindUsableChild["CurrentBehavior","combobox"]:AddItem["Idle"]
			do
			{
				UIElement[EVEBot].FindUsableChild["CurrentBehavior","combobox"]:AddItem["${Behavior.Value}"]
			}
			while ${Behavior:Next(exists)}
			UIElement[EVEBot].FindUsableChild["CurrentBehavior","combobox"].ItemByText[${Config.Common.CurrentBehavior}]:Select
		}
	}

	method CheckUIPosition()
	{
		if ${UIElement[EVEBot].X} <= -${Math.Calc[${UIElement[EVEBot].Width} * 0.66].Int} || \
			${UIElement[EVEBot].X} >= ${Math.Calc[${Display.Width} - ${UIElement[EVEBot].Width}]}
		{
			echo ${UIElement[EVEBot].X} <= -${Math.Calc[${UIElement[EVEBot].Width} * 0.66].Int}
			echo ${UIElement[EVEBot].X} >= ${Math.Calc[${Display.Width} - ${UIElement[EVEBot].Width}]}

			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${UIElement[EVEBot].X} > ${Display.Width}"
			echo "    You may fix this with 'UIElement[EVEbot]:Reset"
			echo "----"
		}

		if ${UIElement[EVEBot].Y} <= 1 || \
			${UIElement[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${UIElement[EVEBot].Height}]}
		{
			echo ${UIElement[EVEBot].Y} <= 1
			echo ${UIElement[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${UIElement[EVEBot].Height}]}

			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${UIElement[EVEBot].Y} > ${Display.Height}"
			echo "    You may fix this with 'UIElement[EVEbot]:Reset"
			echo "----"
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
		if ${EVEBot.Paused}
		{
			return
		}

		if ${This.PulseTimer.Ready}
		{
			This.PulseTimer:Update
			; This:LogSystemStats
		}
	}

	method LogSystemStats()
	{
		;Logger:Log["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024].Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}
}
