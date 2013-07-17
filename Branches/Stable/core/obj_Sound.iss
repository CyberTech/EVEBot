/*
	Sound class

	Object to handle playing sounds.

	-- GliderPro

*/

objectdef obj_Sound
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

    variable int m_LastSoundTime
    variable int m_SoundDelay

	method Initialize()
	{
		m_LastSoundTime:Set[${LavishScript.RunningTime}]
		m_SoundDelay:Set[15000]	/* milliseconds */
		uplink Speech:Initialize
		
		UI:UpdateConsole["obj_Sound: Initialized", LOG_MINOR]
	}

	function PlaySound(string Filename)
	{
		if !${Config.Common.UseSound}
			return

		if ${Math.Calc64[${m_LastSoundTime} + ${m_SoundDelay}]} < ${LavishScript.RunningTime}
		{
			PlaySound "${Filename}"
			;System:APICall[${System.GetProcAddress[WinMM.dll,PlaySound].Hex},Filename.String,0,"Math.Dec[22001]"]
			m_LastSoundTime:Set[${LavishScript.RunningTime}]
		}
	}

	function PlayAlarmSound()
	{
		call This.PlaySound ALARMSOUND
	}

	function PlayDetectSound()
	{
		call This.PlaySound DETECTSOUND
	}

	function PlayTellSound()
	{
		call This.PlaySound TELLSOUND
	}

	function PlayLevelSound()
	{
		call This.PlaySound LEVELSOUND
	}

	function PlayWarningSound()
	{
		call This.PlaySound WARNSOUND
	}
	
	method Speak(string Phrase, float speed=0.7)
	{
		if !${Config.Common.UseSound}
			return

		; Spelling below is to help the speech engine prononce it right since we don't have PromptBuilder support for the speech SDK in IS
		uplink Speech:Speak[-speed,${Speed},"EEVEBautt: ${Phrase}"]
	}
}
