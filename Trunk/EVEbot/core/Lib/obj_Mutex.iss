/*
	Mutex Class

	Provides mutex variables for exclusive access to controlled resource.

	-- CyberTech

*/

objectdef obj_Mutex
{
	variable bool _Locked = FALSE

	member:bool TryLock(int TimeoutSeconds)
	{
		while ${_Locked}
		{
			waitframe
			; TODO: Return false if lock not aquired in TimeOutSeconds
		}

		_Locked:Set[TRUE]
		return TRUE
	}

	member:bool Release()
	{
		_Locked:Set[FALSE]
	}

}