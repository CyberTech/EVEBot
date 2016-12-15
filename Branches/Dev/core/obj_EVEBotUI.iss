
objectdef obj_EVEBotUI inherits obj_BaseClass
{
	variable string SVN_REVISION = "$Rev$"

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		ui -load interface/EVESkin.xml
		ui -load -skin EVESkin interface/EVEBot.xml

		This:LogSystemStats
		This:CheckUIPosition

		PulseTimer:SetIntervals[60.0,60.0]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Reload()
	{
		;ui -reload -skin EVESkin interface/EVEBot.xml
		Logger:WriteQueue
		This:PopulateBehavioralComboBox
	}

	method PopulateBehavioralComboBox()
	{
		variable iterator Behavior
		EVEBot.BehaviorList:GetIterator[Behavior]

		if ${Behavior:First(exists)}
		{
			UIElement[EVEBot].FindUsableChild["Behavior","combobox"]:ClearItems
			UIElement[EVEBot].FindUsableChild["Behavior","combobox"]:AddItem["Idle"]
			do
			{
				UIElement[EVEBot].FindUsableChild["Behavior","combobox"]:AddItem["${Behavior.Value}"]
			}
			while ${Behavior:Next(exists)}
			UIElement[EVEBot].FindUsableChild["Behavior","combobox"].ItemByText[${Config.Common.Behavior}]:Select
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
		ui -unload interface/EVEBot.xml
		ui -unload interface/EVESkin.xml
	}

	method Pulse()
	{
		if !${EVEBot.Loaded} || ${EVEBot.Disabled}
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
		This:UpdateConsole["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024].Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}
}
