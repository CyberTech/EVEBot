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

		UI:UpdateConsole["obj_Sound: Initialized", LOG_MINOR]
	}

	method TryPlaySound(string Filename)
	{
		if !${Config.Common.UseSound}
			return

		if ${Math.Calc64[${m_LastSoundTime} + ${m_SoundDelay}]} < ${LavishScript.RunningTime}
		{
			PlaySound ${Filename}
			m_LastSoundTime:Set[${LavishScript.RunningTime}]
		}
	}

	method PlayAlarmSound()
	{
		This:PlaySound[ALARMSOUND]
	}

	method PlayDetectSound()
	{
		This:PlaySound[DETECTSOUND]
	}

	method PlayTellSound()
	{
		This:PlaySound[TELLSOUND]
	}

	method PlayLevelSound()
	{
		This:PlaySound[LEVELSOUND]
	}

	method PlayWarningSound()
	{
		This:PlaySound[WARNSOUND]
	}
}
