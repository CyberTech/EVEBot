/*
	Gang Class
	
	This class will contain funtions for managing and manipulating
	your gang.
	
	-- GliderPro

	HISTORY
	------------------------------------------
	10AUG2007 - Initial release of class template
*/

objectdef obj_Gang
{
	method Initialize()
	{
		UI:UpdateConsole["obj_Gang: Initialized"]
	}

	/* 	
		Issues a gang formation request to the player given
		by the id parameter.
	*/
	method FormGangWithPlayer(int id)
	{
	}
	
	/*
		Determine if the player is in your system and warp
		to them.
	*/
	method WarpToPlayer(int id, int distance)
	{
	}	
}