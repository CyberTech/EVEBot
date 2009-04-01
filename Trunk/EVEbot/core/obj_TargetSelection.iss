/* obj_TargetSelection - Contain all code related to the selection of
targets, i.e. rats for the Ratter, asteroids for Miner, etc. This object
will make heavy use of the Targeting queue. --Stealthy */

objectdef obj_TargetSelection
{
	method Initialize()
	{
		UI:UpdateConsole["obj_TargetSelection: Initialized"]
	}

	/* Enqueue all rats in our belt. Web/Scram/Jam will be considered mandatory, officers/faction highest priority. -- Stealthy */
	method Ratter_QueueTargets()
	{
		/* Temproary index and iterator */
		variable index:entity idxEntities
		variable iterator itrEntity

		/* Get a list of all entities near us. */
		EVE:DoGetEntities[idxEntities, CategoryID, CATEGORYID_ENTITY]
		idxEntities:GetIterator[itrEntity]

		/* Assume there are entities near us - this should only be called after the NPC check. */
		/* Queue non-players and non-concord, etc. We really only want to queue rats. */
		itrEntity:First
		do
		{
			switch ${itrEntity.Value.GroupID}
			{
				case GROUP_CONCORDDRONE
				case GROUP_CONVOYDRONE
				case GROUP_CONVOY
				case GROUP_LARGECOLLIDABLEOBJECT
				case GROUP_LARGECOLLIDABLESHIP
				case GROUP_LARGECOLLIDABLESTRUCTURE
					break
				default
					/* If something is webbing or scramming me, queue it mandatory. Otherwise, don't. */
					/* Since ISXEVE doesn't tell us -what- is warp scrambling us just check our target against
					known priority targets. Also be sure to not queue targets currently in warp. */
					/* Queue[ID, Priority, TypeID, Mandatory] */
					if !${Targeting.IsQueued[${itrEntity.Value.ID}]} && ${itrEntity.Value.Mode} != 3
					{
						UI:UpdateConsole["obj_TargetSelection: Queueing target ${itrEntity.Value.Name} ${itrEntity.Value.ID}"]
						/* If it's a priority target (web/scram/jam) make it mandatory and kill it first. */
						if ${Targets.IsPriorityTaraget[${itrEntity.Value.Name}]}
						{
							Targeting:Queue[${itrEntity.Value.ID},5,${itrEntity.Value.TypeID},TRUE]
						}
						elseif ${Targets.IsSpecialTarget[${itrEntity.Value.Name}]}
						{
							/* If it's not a priority target but is a special target, kill it second. I can escape from special targets. */
							Targeting:Queue[${itrEntity.Value.ID},3,${itrEntity.Value.TypeID},FALSE]
							;The below is borrowed from some legacy ratter code and moved to a more appropriate spot.
							UI:UpdateConsole["Special spawn Detected at ${Entity[GroupID, GROUP_ASTEROIDBELT]}!", LOG_CRITICAL]
							Sound:PlayDetectSound
						}
						else
						{
							/* If it's neither a special nor priority target, add it with a priority of 1 (low). */
							Targeting:Queue[${itrEntity.Value.ID},1,${itrEntity.Value.TypeID},FALSE]
						}
					}
				}
		}
		while ${itrEntity:Next(exists)}
	}
}