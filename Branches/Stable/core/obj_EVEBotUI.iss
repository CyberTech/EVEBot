#include ${LavishScript.HomeDirectory}/Scripts/LGUI2Scaling.iss

objectdef obj_EVEBotUI inherits obj_BaseClass
{
	variable bool NeedToSetComboBox = FALSE
	variable string ComboBoxValueToSet = ""
	variable index:string UIFiles

	method Initialize()
	{
		variable iterator UIFile

		LogPrefix:Set["${This.ObjectName}"]

		;; Populate the index (list) of UIFiles.  The order does matter; typically, any new files should go right before "EVEBot.json"
		UIFiles:Insert[interface/common.json]
		UIFiles:Insert[interface/tabStatus.json]
		UIFiles:Insert[interface/tabMain.json]
		UIFiles:Insert[interface/tabMiner.json]
		UIFiles:Insert[interface/tabCombat.json]
		UIFiles:Insert[interface/tabHauler.json]
		UIFiles:Insert[interface/tabLabels.json]
		UIFiles:Insert[interface/tabFreighter.json]
		UIFiles:Insert[interface/tabFleet.json]
		UIFiles:Insert[interface/tabMissions.json]
		UIFiles:Insert[interface/tabFleeing.json]
		UIFiles:Insert[interface/EVEBot.json]

		;; Load UI package files
		UIFiles:GetIterator[UIFile]
		do
		{
			LGUI2:LoadPackageFile[${UIFile.Value}]
		}
		while ${UIFile:Next(exists)}

		; temp: Set to tab 2 (Main)
		LGUI2.Element[EVEBotOptionsTab]:SelectTab[2]

		This:LogSystemStats
		This:CheckUIPosition

		PulseTimer:SetIntervals[60.0,60.0]
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		Logger:Log["${LogPrefix}: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		variable iterator UIFile

		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]

		;; Unload UI package files
		UIFiles:GetIterator[UIFile]
		do
		{
			LGUI2:UnloadPackageFile[${UIFile.Value}]
		}
		while ${UIFile:Next(exists)}
	}

	method Reload()
	{
		variable iterator UIFile

		;; LGUI2 does not have a "reload" function.  So, each package file must be unloaded and then loaded again.
		UIFiles:GetIterator[UIFile]
		do
		{
			LGUI2:UnloadPackageFile[${UIFile.Value}]
		}
		while ${UIFile:Next(exists)}

		UIFiles:GetIterator[UIFile]
		do
		{
			LGUI2:LoadPackageFile[${UIFile.Value}]
		}
		while ${UIFile:Next(exists)}

		; temp:  Set to tab 2
		LGUI2.Element[EVEBotOptionsTab]:SelectTab[2]

		Logger:WriteQueue
		This.Reloaded:Set[TRUE]
	}

	method SetBehavioralComboBoxWhenReady(string searchFor)
	{
		; Set flags for Pulse to handle (Pulse runs on frames, no wait needed)
		This.NeedToSetComboBox:Set[TRUE]
		This.ComboBoxValueToSet:Set["${searchFor}"]
	}

	method SetBehavioralComboBox(string searchFor)
	{
		variable jsonvalue ja="${This.GetBehaviors}"
		variable int i

		for (i:Set[1]; ${i} <= ${ja.Size}; i:Inc)
		{
			if ${ja[${i}].Get[text].Equal[${searchFor}]}
			{
				LGUI2.Element[CurrentBehaviorList]:SetItemSelected[${i},TRUE]
				return
			}
		}
	}

	method CheckUIPosition()
	{
		if ${LGUI2.Element[EVEBot].X} <= -${Math.Calc[${LGUI2.Element[EVEBot].Width} * 0.66].Int} || \
			${LGUI2.Element[EVEBot].X} >= ${Math.Calc[${Display.Width} - ${LGUI2.Element[EVEBot].Width}]}
		{
			echo ${LGUI2.Element[EVEBot].X} <= -${Math.Calc[${LGUI2.Element[EVEBot].Width} * 0.66].Int}
			echo ${LGUI2.Element[EVEBot].X} >= ${Math.Calc[${Display.Width} - ${LGUI2.Element[EVEBot].Width}]}

			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${LGUI2.Element[EVEBot].X} > ${Display.Width}"
			echo "    You may fix this with 'LGUI2.Element[EVEBot]:SetPosition[200,300]"
			echo "----"
		}

		if ${LGUI2.Element[EVEBot].Y} <= 1 || \
			${LGUI2.Element[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${LGUI2.Element[EVEBot].Height}]}
		{
			echo ${LGUI2.Element[EVEBot].Y} <= 1
			echo ${LGUI2.Element[EVEBot].Y} >= ${Math.Calc[${Display.Height} - ${LGUI2.Element[EVEBot].Height}]}

			echo "----"
			echo "    Warning: EVEBot window is outside window area: ${LGUI2.Element[EVEBot].Y} > ${Display.Height}"
			echo "    You may fix this with 'LGUI2.Element[EVEBot]:SetPosition[200,300]"
			echo "----"
		}
	}

	method Pulse()
	{
		; Check if we need to set the combobox (runs every frame until successful)
		if ${This.NeedToSetComboBox}
		{
			if ${LGUI2.Element[CurrentBehaviorList](exists)} && ${LGUI2.Element[CurrentBehaviorList].ItemCount} > 0
			{
				This:SetBehavioralComboBox["${This.ComboBoxValueToSet}"]
				This.NeedToSetComboBox:Set[FALSE]
			}
		}

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
		;Logger:Log["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024}.Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}

	; LGUI2 data binding member function for CurrentBehavior combobox
	member:string GetBehaviors()
	{
		variable string jsonOutput = "["
		variable iterator Behavior
		variable bool FirstItem = TRUE

		; Always add "Idle" first
		jsonOutput:Concat["{\"type\":\"textblock\",\"text\":\"Idle\"}"]
		FirstItem:Set[FALSE]

		; Add loaded behaviors
		Behaviors.Loaded:GetIterator[Behavior]
		if ${Behavior:First(exists)}
		{
			do
			{
				if !${FirstItem}
					jsonOutput:Concat[","]
				jsonOutput:Concat["{\"type\":\"textblock\",\"text\":\"${Behavior.Value.Escape}\"}"]
				FirstItem:Set[FALSE]
			}
			while ${Behavior:Next(exists)}
		}

		jsonOutput:Concat["]"]
		return "${jsonOutput.Escape}"
	}
}
