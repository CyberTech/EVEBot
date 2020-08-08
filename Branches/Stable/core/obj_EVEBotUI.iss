
objectdef obj_EVEBotUI inherits obj_BaseClass
{
	variable string Skin = "EVESkin"
	;variable string SkinFile = "EVESkin.xml"
	variable string SkinFile = "eveskin/EVESkin.xml"

	method Initialize()
	{
		LogPrefix:Set["${This.ObjectName}"]

		ui -load interface/${This.SkinFile}
		;ui -load "${LavishScript.HomeDirectory}/Interface/DefaultSkin.xml"
		;ui -load "${LavishScript.HomeDirectory}/Interface/Skins/EQ2/EQ2.xml"
		;ui -load "${LavishScript.HomeDirectory}/Interface/Skins/VGSkin/VGSkin.xml"
		;ui -load "${LavishScript.HomeDirectory}/Scripts/EQ2/UI/EQ2Skin.xml"

		ui -load interface/EVEBot.xml
		;ui -load -skin ${This.Skin} interface/EVEBot.xml

		This:LogSystemStats
		This:CheckUIPosition

		PulseTimer:SetIntervals[60.0,60.0]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
		ui -unload interface/EVEBot.xml
		ui -unload interface/${This.SkinFile}
	}

	method Reload()
	{
		ui -reload interface/EVEBot.xml
		;ui -reload -skin ${This.Skin} interface/EVEBot.xml
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
			echo "    You may fix this with 'UIElement[EVEBot]:Reset"
			echo "----"
		}

		if ${UIElement[EVEBot].Y} <= 1 || \
			${UIElement[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${UIElement[EVEBot].Height}]}
		{
			echo ${UIElement[EVEBot].Y} <= 1
			echo ${UIElement[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${UIElement[EVEBot].Height}]}

			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${UIElement[EVEBot].Y} > ${Display.Height}"
			echo "    You may fix this with 'UIElement[EVEBot]:Reset"
			echo "----"
		}
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
		;Logger:Log["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024].Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}
}
