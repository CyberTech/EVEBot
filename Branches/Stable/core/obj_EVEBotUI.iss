objectdef obj_EVEBotUI inherits obj_BaseClass
{
	; combobox variables
	variable bool NeedToSetCurrentBehaviorComboBox = FALSE
	variable string CurrentBehaviorComboBoxValueToSet = ""
	variable bool NeedToSetJetCanComboBox = FALSE
	variable int JetCanComboBoxValueToSet = 0
	variable bool NeedToSetCurrentAnomTypeComboBox = FALSE
	variable int CurrentAnomTypeComboBoxValueToSet = 0
	variable bool NeedToSetLowestStandingCombatComboBox = FALSE
	variable int LowestStandingCombatComboBoxValueToSet = 0
	variable bool NeedToSetSafeCooldownComboBox = FALSE
	variable int SafeCooldownComboBoxValueToSet = 0
	variable bool NeedToSetBreakDurationComboBox = FALSE
	variable int BreakDurationComboBoxValueToSet = 0
	variable bool NeedToSetTimeBetweenBreaksComboBox = FALSE
	variable int TimeBetweenBreaksComboBoxValueToSet = 0
	variable bool NeedToSetFreighterModeComboBox = FALSE
	variable int FreighterModeComboBoxValueToSet = 0
	variable bool NeedToSetDestinationComboBox = FALSE
	variable string DestinationComboBoxValueToSet = ""
	variable bool NeedToSetHaulerModeComboBox = FALSE
	variable int HaulerModeComboBoxValueToSet = 0
	variable bool NeedToSetLowestStandingMinerComboBox = FALSE
	variable int LowestStandingMinerComboBoxValueToSet = 0
	variable bool NeedToSetDeliveryLocationTypeComboBox = FALSE
	variable int DeliveryLocationTypeComboBoxValueToSet = 0
	variable bool NeedToSetSalvageModeComboBox = FALSE
	variable int SalvageModeComboBoxValueToSet = 0

	; All other obj_EVEBotUI variables
	variable index:string UIFiles

	method Initialize()
	{
		variable iterator UIFile

		LogPrefix:Set["${This.ObjectName}"]

		;; Populate the index of UIFiles.  The order matters; typically, any new files should go right before "EVEBot.json"
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

		; temp: Set to tab 4
		LGUI2.Element[EVEBotOptionsTab]:SelectTab[4]

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

		; temp:  Set to tab 4
		LGUI2.Element[EVEBotOptionsTab]:SelectTab[4]

		Logger:WriteQueue
		This.Reloaded:Set[TRUE]
	}

	method Pulse()
	{
		; Check if we need to set the CurrentBehavior combobox (runs every frame until successful)
		if ${This.NeedToSetCurrentBehaviorComboBox}
		{
			if ${LGUI2.Element[CurrentBehaviorList](exists)} && ${LGUI2.Element[CurrentBehaviorList].ItemCount} > 0
			{
				This:SetBehavioralComboBox["${This.CurrentBehaviorComboBoxValueToSet}"]
				This.NeedToSetCurrentBehaviorComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the JetCan combobox (runs every frame until successful)
		if ${This.NeedToSetJetCanComboBox}
		{
			if ${LGUI2.Element[cbJetCanNameList](exists)} && ${LGUI2.Element[cbJetCanNameList].ItemCount} > 0
			{
				This:SetJetCanComboBox[${This.JetCanComboBoxValueToSet}]
				This.NeedToSetJetCanComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the CurrentAnomType combobox
		if ${This.NeedToSetCurrentAnomTypeComboBox}
		{
			if ${LGUI2.Element[CurrentAnomTypeList](exists)} && ${LGUI2.Element[CurrentAnomTypeList].ItemCount} > 0
			{
				This:SetCurrentAnomTypeComboBox[${This.CurrentAnomTypeComboBoxValueToSet}]
				This.NeedToSetCurrentAnomTypeComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the LowestStandingCombat combobox
		if ${This.NeedToSetLowestStandingCombatComboBox}
		{
			if ${LGUI2.Element[cbLowestStandingCombatList](exists)} && ${LGUI2.Element[cbLowestStandingCombatList].ItemCount} > 0
			{
				This:SetLowestStandingCombatComboBox[${This.LowestStandingCombatComboBoxValueToSet}]
				This.NeedToSetLowestStandingCombatComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the SafeCooldown combobox
		if ${This.NeedToSetSafeCooldownComboBox}
		{
			if ${LGUI2.Element[comboSafeCooldownList](exists)} && ${LGUI2.Element[comboSafeCooldownList].ItemCount} > 0
			{
				This:SetSafeCooldownComboBox[${This.SafeCooldownComboBoxValueToSet}]
				This.NeedToSetSafeCooldownComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the BreakDuration combobox
		if ${This.NeedToSetBreakDurationComboBox}
		{
			if ${LGUI2.Element[comboBreakDurationList](exists)} && ${LGUI2.Element[comboBreakDurationList].ItemCount} > 0
			{
				This:SetBreakDurationComboBox[${This.BreakDurationComboBoxValueToSet}]
				This.NeedToSetBreakDurationComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the TimeBetweenBreaks combobox
		if ${This.NeedToSetTimeBetweenBreaksComboBox}
		{
			if ${LGUI2.Element[comboTimeBetweenBreaksList](exists)} && ${LGUI2.Element[comboTimeBetweenBreaksList].ItemCount} > 0
			{
				This:SetTimeBetweenBreaksComboBox[${This.TimeBetweenBreaksComboBoxValueToSet}]
				This.NeedToSetTimeBetweenBreaksComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the FreighterMode combobox
		if ${This.NeedToSetFreighterModeComboBox}
		{
			if ${LGUI2.Element[cbFreighterModeList](exists)} && ${LGUI2.Element[cbFreighterModeList].ItemCount} > 0
			{
				This:SetFreighterModeComboBox[${This.FreighterModeComboBoxValueToSet}]
				This.NeedToSetFreighterModeComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the HaulerMode combobox
		if ${This.NeedToSetHaulerModeComboBox}
		{
			if ${LGUI2.Element[HaulerModeList](exists)} && ${LGUI2.Element[HaulerModeList].ItemCount} > 0
			{
				This:SetHaulerModeComboBox[${This.HaulerModeComboBoxValueToSet}]
				This.NeedToSetHaulerModeComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the LowestStandingMiner combobox
		if ${This.NeedToSetLowestStandingMinerComboBox}
		{
			if ${LGUI2.Element[cbLowestStandingList](exists)} && ${LGUI2.Element[cbLowestStandingList].ItemCount} > 0
			{
				This:SetLowestStandingMinerComboBox[${This.LowestStandingMinerComboBoxValueToSet}]
				This.NeedToSetLowestStandingMinerComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the DeliveryLocationType combobox
		if ${This.NeedToSetDeliveryLocationTypeComboBox}
		{
			if ${LGUI2.Element[DeliveryLocationTypeList](exists)} && ${LGUI2.Element[DeliveryLocationTypeList].ItemCount} > 0
			{
				This:SetDeliveryLocationTypeComboBox[${This.DeliveryLocationTypeComboBoxValueToSet}]
				This.NeedToSetDeliveryLocationTypeComboBox:Set[FALSE]
			}
		}

		; Check if we need to set the SalvageMode combobox
		if ${This.NeedToSetSalvageModeComboBox}
		{
			if ${LGUI2.Element[comboSalvageModeList](exists)} && ${LGUI2.Element[comboSalvageModeList].ItemCount} > 0
			{
				This:SetSalvageModeComboBox[${This.SalvageModeComboBoxValueToSet}]
				This.NeedToSetSalvageModeComboBox:Set[FALSE]
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

	method SetBehavioralComboBoxWhenReady(string searchFor)
	{
		; Set flags for Pulse to handle (Pulse runs on frames, no wait needed)
		This.NeedToSetCurrentBehaviorComboBox:Set[TRUE]
		This.CurrentBehaviorComboBoxValueToSet:Set["${searchFor}"]
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

	method SetJetCanComboBoxWhenReady(int numericValue)
	{
		; Set flags for Pulse to handle (Pulse runs on frames, no wait needed)
		This.NeedToSetJetCanComboBox:Set[TRUE]
		This.JetCanComboBoxValueToSet:Set[${numericValue}]
	}

	method SetJetCanComboBox(int numericValue)
	{
		; Map numeric value (1-10) to text, then find and select the item
		variable string SelectedText

		switch ${numericValue}
		{
			case 1
				SelectedText:Set["CorpTicker Time"]
				break
			case 2
				SelectedText:Set["CorpTicker:Time"]
				break
			case 3
				SelectedText:Set["CorpTicker_Time"]
				break
			case 4
				SelectedText:Set["CorpTicker.Time"]
				break
			case 5
				SelectedText:Set["CorpTicker"]
				break
			case 6
				SelectedText:Set["Time"]
				break
			case 7
				SelectedText:Set["FirstName Time"]
				break
			case 8
				SelectedText:Set["FirstName"]
				break
			case 9
				SelectedText:Set["CharName"]
				break
			case 10
				SelectedText:Set["Do Not Rename"]
				break
		}

		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[cbJetCanNameList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[cbJetCanNameList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[cbJetCanNameList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnJetCanComboBoxChanged()
	{
		if (!${LGUI2.Element[cbJetCanName].SelectedItem.Data.Get[text](exists)})
			return

		; Called by JSON when user changes selection - converts text to numeric and saves to config
		variable string textValue = "${LGUI2.Element[cbJetCanName].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case CorpTicker Time
				numericValue:Set[1]
				break
			case CorpTicker:Time
				numericValue:Set[2]
				break
			case CorpTicker_Time
				numericValue:Set[3]
				break
			case CorpTicker.Time
				numericValue:Set[4]
				break
			case CorpTicker
				numericValue:Set[5]
				break
			case Time
				numericValue:Set[6]
				break
			case FirstName Time
				numericValue:Set[7]
				break
			case FirstName
				numericValue:Set[8]
				break
			case CharName
				numericValue:Set[9]
				break
			case Do Not Rename
				numericValue:Set[10]
				break
		}

		if (${numericValue} > 0)
		{
			Config.Miner:SetJetCanNaming[${numericValue}]
			;Script[EVEBot].VariableScope.Config.Miner:SetJetCanNaming[${numericValue}]
		}
	}

	method SetCurrentAnomTypeComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetCurrentAnomTypeComboBox:Set[TRUE]
		This.CurrentAnomTypeComboBoxValueToSet:Set[${numericValue}]
	}

	method SetCurrentAnomTypeComboBox(int numericValue)
	{
		variable string SelectedText

		switch ${numericValue}
		{
			case 1
				SelectedText:Set["None"]
				break
			case 2
				SelectedText:Set["Guristas Sanctum"]
				break
			case 3
				SelectedText:Set["Guristas Haven (Rock)"]
				break
			case 4
				SelectedText:Set["Guristas Haven (Gas)"]
				break
			case 5
				SelectedText:Set["Guristas Haven (Both)"]
				break
			case 6
				SelectedText:Set["Guristas Forlorn Hub"]
				break
			case 7
				SelectedText:Set["Guristas Forsaken Hub"]
				break
			case 8
				SelectedText:Set["Guristas Hidden Hub"]
				break
			case 9
				SelectedText:Set["Guristas Hub"]
				break
			case 10
				SelectedText:Set["Guristas Port"]
				break
			case 11
				SelectedText:Set["Guristas Forlorn Rally Point"]
				break
			case 12
				SelectedText:Set["Guristas Forsaken Rally Point"]
				break
			case 13
				SelectedText:Set["Guristas Hidden Rally Point"]
				break
			case 14
				SelectedText:Set["Guristas Rally Point"]
				break
			case 15
				SelectedText:Set["Guristas Yard"]
				break
			case 16
				SelectedText:Set["Guristas Forlorn Den"]
				break
			case 17
				SelectedText:Set["Guristas Forsaken Den"]
				break
			case 18
				SelectedText:Set["Guristas Hidden Den"]
				break
			case 19
				SelectedText:Set["Guristas Den"]
				break
			case 20
				SelectedText:Set["Guristas Refuge"]
				break
			case 21
				SelectedText:Set["Guristas Burrow"]
				break
			case 22
				SelectedText:Set["Guristas Forlorn Hideaway"]
				break
			case 23
				SelectedText:Set["Guristas Forsaken Hideaway"]
				break
			case 24
				SelectedText:Set["Guristas Hidden Hideaway"]
				break
			case 25
				SelectedText:Set["Guristas Hideaway"]
				break
			case 26
				SelectedText:Set["Sansha Forsaken Hub"]
				break
			case 27
				SelectedText:Set["Sansha Haven (Rock)"]
				break
			case 28
				SelectedText:Set["Sansha Haven (Gas)"]
				break
			case 29
				SelectedText:Set["Sansha Haven (Both)"]
				break
		}

		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[CurrentAnomTypeList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[CurrentAnomTypeList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[CurrentAnomTypeList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnCurrentAnomTypeComboBoxChanged()
	{
		if (!${LGUI2.Element[CurrentAnomType].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[CurrentAnomType].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case None
				numericValue:Set[1]
				break
			case Guristas Sanctum
				numericValue:Set[2]
				break
			case Guristas Haven (Rock)
				numericValue:Set[3]
				break
			case Guristas Haven (Gas)
				numericValue:Set[4]
				break
			case Guristas Haven (Both)
				numericValue:Set[5]
				break
			case Guristas Forlorn Hub
				numericValue:Set[6]
				break
			case Guristas Forsaken Hub
				numericValue:Set[7]
				break
			case Guristas Hidden Hub
				numericValue:Set[8]
				break
			case Guristas Hub
				numericValue:Set[9]
				break
			case Guristas Port
				numericValue:Set[10]
				break
			case Guristas Forlorn Rally Point
				numericValue:Set[11]
				break
			case Guristas Forsaken Rally Point
				numericValue:Set[12]
				break
			case Guristas Hidden Rally Point
				numericValue:Set[13]
				break
			case Guristas Rally Point
				numericValue:Set[14]
				break
			case Guristas Yard
				numericValue:Set[15]
				break
			case Guristas Forlorn Den
				numericValue:Set[16]
				break
			case Guristas Forsaken Den
				numericValue:Set[17]
				break
			case Guristas Hidden Den
				numericValue:Set[18]
				break
			case Guristas Den
				numericValue:Set[19]
				break
			case Guristas Refuge
				numericValue:Set[20]
				break
			case Guristas Burrow
				numericValue:Set[21]
				break
			case Guristas Forlorn Hideaway
				numericValue:Set[22]
				break
			case Guristas Forsaken Hideaway
				numericValue:Set[23]
				break
			case Guristas Hidden Hideaway
				numericValue:Set[24]
				break
			case Guristas Hideaway
				numericValue:Set[25]
				break
			case Sansha Forsaken Hub
				numericValue:Set[26]
				break
			case Sansha Haven (Rock)
				numericValue:Set[27]
				break
			case Sansha Haven (Gas)
				numericValue:Set[28]
				break
			case Sansha Haven (Both)
				numericValue:Set[29]
				break
		}

		if (${numericValue} > 0)
		{
			Config.Combat:SetCurrentAnomType[${numericValue}]
			Config.Combat:SetCurrentAnomTypeName[${textValue}]
		}
	}

	method SetLowestStandingCombatComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetLowestStandingCombatComboBox:Set[TRUE]
		This.LowestStandingCombatComboBoxValueToSet:Set[${numericValue}]
	}

	method SetLowestStandingCombatComboBox(int numericValue)
	{
		variable string SelectedText

		switch ${numericValue}
		{
			case 1
				SelectedText:Set["-11"]
				break
			case 2
				SelectedText:Set["-10"]
				break
			case 3
				SelectedText:Set["-5"]
				break
			case 4
				SelectedText:Set["0"]
				break
			case 5
				SelectedText:Set["5"]
				break
			case 6
				SelectedText:Set["10"]
				break
		}

		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[cbLowestStandingCombatList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[cbLowestStandingCombatList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[cbLowestStandingCombatList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnLowestStandingCombatComboBoxChanged()
	{
		if (!${LGUI2.Element[cbLowestStandingCombat].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[cbLowestStandingCombat].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case -11
				numericValue:Set[1]
				break
			case -10
				numericValue:Set[2]
				break
			case -5
				numericValue:Set[3]
				break
			case 0
				numericValue:Set[4]
				break
			case 5
				numericValue:Set[5]
				break
			case 10
				numericValue:Set[6]
				break
		}

		if (${numericValue} > 0)
			Config.Combat:SetLowestStanding[${numericValue}]
	}

	method SetSafeCooldownComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetSafeCooldownComboBox:Set[TRUE]
		This.SafeCooldownComboBoxValueToSet:Set[${numericValue}]
	}

	method SetSafeCooldownComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["5"]
				break
			case 2
				SelectedText:Set["10"]
				break
			case 3
				SelectedText:Set["20"]
				break
			case 4
				SelectedText:Set["30"]
				break
			case 5
				SelectedText:Set["40"]
				break
			case 6
				SelectedText:Set["60"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[comboSafeCooldownList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[comboSafeCooldownList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[comboSafeCooldownList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnSafeCooldownComboBoxChanged()
	{
		if (!${LGUI2.Element[comboSafeCooldown].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[comboSafeCooldown].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case 5
				numericValue:Set[1]
				break
			case 10
				numericValue:Set[2]
				break
			case 20
				numericValue:Set[3]
				break
			case 30
				numericValue:Set[4]
				break
			case 40
				numericValue:Set[5]
				break
			case 60
				numericValue:Set[6]
				break
		}

		if (${numericValue} > 0)
			Config.Combat:SetSafeCooldown[${numericValue}]
	}

	method SetBreakDurationComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetBreakDurationComboBox:Set[TRUE]
		This.BreakDurationComboBoxValueToSet:Set[${numericValue}]
	}

	method SetBreakDurationComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["1"]
				break
			case 2
				SelectedText:Set["2"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[comboBreakDurationList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[comboBreakDurationList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[comboBreakDurationList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnBreakDurationComboBoxChanged()
	{
		if (!${LGUI2.Element[comboBreakDuration].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[comboBreakDuration].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case 1
				numericValue:Set[1]
				break
			case 2
				numericValue:Set[2]
				break
		}

		if (${numericValue} > 0)
			Config.Combat:SetBreakDuration[${numericValue}]
	}

	method SetTimeBetweenBreaksComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetTimeBetweenBreaksComboBox:Set[TRUE]
		This.TimeBetweenBreaksComboBoxValueToSet:Set[${numericValue}]
	}

	method SetTimeBetweenBreaksComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["1"]
				break
			case 2
				SelectedText:Set["2"]
				break
			case 3
				SelectedText:Set["3"]
				break
			case 4
				SelectedText:Set["4"]
				break
			case 5
				SelectedText:Set["5"]
				break
			case 6
				SelectedText:Set["6"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[comboTimeBetweenBreaksList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[comboTimeBetweenBreaksList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[comboTimeBetweenBreaksList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnTimeBetweenBreaksComboBoxChanged()
	{
		if (!${LGUI2.Element[comboTimeBetweenBreaks].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[comboTimeBetweenBreaks].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case 1
				numericValue:Set[1]
				break
			case 2
				numericValue:Set[2]
				break
			case 3
				numericValue:Set[3]
				break
			case 4
				numericValue:Set[4]
				break
			case 5
				numericValue:Set[5]
				break
			case 6
				numericValue:Set[6]
				break
		}

		if (${numericValue} > 0)
			Config.Combat:SetTimeBetweenBreaks[${numericValue}]
	}

	method SetFreighterModeComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetFreighterModeComboBox:Set[TRUE]
		This.FreighterModeComboBoxValueToSet:Set[${numericValue}]
	}

	method SetFreighterModeComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["Source and Destination"]
				break
			case 2
				SelectedText:Set["Asset Gather"]
				break
			case 3
				SelectedText:Set["Move Minerals to Buyer"]
				break
			case 4
				SelectedText:Set["Container Test"]
				break
			case 5
				SelectedText:Set["Mission Runner"]
				break
			case 6
				SelectedText:Set["Stealth Hauler"]
				break
			case 7
				SelectedText:Set["Scavenger"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[cbFreighterModeList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[cbFreighterModeList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[cbFreighterModeList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnFreighterModeComboBoxChanged()
	{
		if (!${LGUI2.Element[cbFreighterMode].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[cbFreighterMode].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case Source and Destination
				numericValue:Set[1]
				break
			case Asset Gather
				numericValue:Set[2]
				break
			case Move Minerals to Buyer
				numericValue:Set[3]
				break
			case Container Test
				numericValue:Set[4]
				break
			case Mission Runner
				numericValue:Set[5]
				break
			case Stealth Hauler
				numericValue:Set[6]
				break
			case Scavenger
				numericValue:Set[7]
				break
		}

		if (${numericValue} > 0)
		{
			Config.Freighter:SetFreighterMode[${numericValue}]
			Config.Freighter:SetFreighterModeName[${textValue}]
		}
	}

	method SetHaulerModeComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetHaulerModeComboBox:Set[TRUE]
		This.HaulerModeComboBoxValueToSet:Set[${numericValue}]
	}

	method SetHaulerModeComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["Service Fleet Members"]
				break
			case 2
				SelectedText:Set["Service On-Demand"]
				break
			case 3
				SelectedText:Set["Service Orca"]
				break
			case 4
				SelectedText:Set["Jetcan Mode (Flip-guard)"]
				break
			case 5
				SelectedText:Set["Service Fleet Member"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[HaulerModeList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[HaulerModeList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[HaulerModeList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnHaulerModeComboBoxChanged()
	{
		if (!${LGUI2.Element[HaulerMode].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[HaulerMode].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case Service Fleet Members
				numericValue:Set[1]
				break
			case Service On-Demand
				numericValue:Set[2]
				break
			case Service Orca
				numericValue:Set[3]
				break
			case Jetcan Mode (Flip-guard)
				numericValue:Set[4]
				break
			case Service Fleet Member
				numericValue:Set[5]
				break
		}

		if (${numericValue} > 0)
		{
			Config.Hauler:SetHaulerMode[${numericValue}]
			Config.Hauler:SetHaulerModeName[${textValue}]
		}
	}

	method SetLowestStandingMinerComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetLowestStandingMinerComboBox:Set[TRUE]
		This.LowestStandingMinerComboBoxValueToSet:Set[${numericValue}]
	}

	method SetLowestStandingMinerComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["-11"]
				break
			case 2
				SelectedText:Set["-10"]
				break
			case 3
				SelectedText:Set["-5"]
				break
			case 4
				SelectedText:Set["0"]
				break
			case 5
				SelectedText:Set["5"]
				break
			case 6
				SelectedText:Set["10"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[cbLowestStandingList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[cbLowestStandingList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[cbLowestStandingList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnLowestStandingMinerComboBoxChanged()
	{
		if (!${LGUI2.Element[cbLowestStanding].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[cbLowestStanding].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case -11
				numericValue:Set[1]
				break
			case -10
				numericValue:Set[2]
				break
			case -5
				numericValue:Set[3]
				break
			case 0
				numericValue:Set[4]
				break
			case 5
				numericValue:Set[5]
				break
			case 10
				numericValue:Set[6]
				break
		}

		if (${numericValue} > 0)
			Config.Miner:SetLowestStanding[${numericValue}]
	}

	method SetDeliveryLocationTypeComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetDeliveryLocationTypeComboBox:Set[TRUE]
		This.DeliveryLocationTypeComboBoxValueToSet:Set[${numericValue}]
	}

	method SetDeliveryLocationTypeComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["Station"]
				break
			case 2
				SelectedText:Set["Hangar Array"]
				break
			case 3
				SelectedText:Set["Jetcan"]
				break
			case 4
				SelectedText:Set["XLarge Ship Assembly Array"]
				break
			case 5
				SelectedText:Set["Large Ship Assembly Array"]
				break
			case 6
				SelectedText:Set["Orca"]
				break
			case 7
				SelectedText:Set["No Delivery"]
				break
			case 8
				SelectedText:Set["Compression Array"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[DeliveryLocationTypeList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[DeliveryLocationTypeList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[DeliveryLocationTypeList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnDeliveryLocationTypeComboBoxChanged()
	{
		if (!${LGUI2.Element[DeliveryLocationType].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[DeliveryLocationType].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case Station
				numericValue:Set[1]
				break
			case Hangar Array
				numericValue:Set[2]
				break
			case Jetcan
				numericValue:Set[3]
				break
			case XLarge Ship Assembly Array
				numericValue:Set[4]
				break
			case Large Ship Assembly Array
				numericValue:Set[5]
				break
			case Orca
				numericValue:Set[6]
				break
			case No Delivery
				numericValue:Set[7]
				break
			case Compression Array
				numericValue:Set[8]
				break
		}

		if (${numericValue} > 0)
		{
			Config.Miner:SetDeliveryLocationType[${numericValue}]
			Config.Miner:SetDeliveryLocationTypeName[${textValue}]
		}
	}

	method SetSalvageModeComboBoxWhenReady(int numericValue)
	{
		This.NeedToSetSalvageModeComboBox:Set[TRUE]
		This.SalvageModeComboBoxValueToSet:Set[${numericValue}]
	}

	method SetSalvageModeComboBox(int numericValue)
	{
		variable string SelectedText
		switch ${numericValue}
		{
			case 1
				SelectedText:Set["None"]
				break
			case 2
				SelectedText:Set["Solo"]
				break
			case 3
				SelectedText:Set["Relay"]
				break
		}
		if ${SelectedText.NotNULLOrEmpty}
		{
			variable int i
			for (i:Set[1]; ${i} <= ${LGUI2.Element[comboSalvageModeList].ItemCount}; i:Inc)
			{
				if ${LGUI2.Element[comboSalvageModeList].Item[${i}].Data.Get[text].Equal[${SelectedText}]}
				{
					LGUI2.Element[comboSalvageModeList]:SetItemSelected[${i},TRUE]
					return
				}
			}
		}
	}

	method OnSalvageModeComboBoxChanged()
	{
		if (!${LGUI2.Element[comboSalvageMode].SelectedItem.Data.Get[text](exists)})
			return

		variable string textValue = "${LGUI2.Element[comboSalvageMode].SelectedItem.Data.Get[text]}"
		variable int numericValue = 0

		switch ${textValue}
		{
			case None
				numericValue:Set[1]
				break
			case Solo
				numericValue:Set[2]
				break
			case Relay
				numericValue:Set[3]
				break
		}

		if (${numericValue} > 0)
		{
			Config.Missioneer:SetSalvageMode[${numericValue}]
			Config.Missioneer:SetSalvageModeName[${textValue}]
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

	method LogSystemStats()
	{
		;Logger:Log["Memory: ${System.OS} Process: ${Math.Calc[${System.MemoryUsage}/1024}.Int}kb Free: ${System.MemFree}mb Texture Mem Free: ${Display.TextureMem}mb FPS: ${Display.FPS.Int} Windowed: ${Display.Windowed}(${Display.AppWindowed}) Foreground: ${Display.Foreground}", LOG_MINOR]
	}

}
