function main()
{
	variable index:entity Wrecks
	variable int count
	ui -load scripts/eveabandon.xml
	while ${UIElement[EVEAbandon].Visible}
	{
		if ${UIElement[EVEAbandon].FindUsableChild[AutoAbandon,checkbox].Checked}
		{
			Wrecks:Clear
			EVE:DoGetEntities[Wrecks,OwnerID,${Me.CharID},GroupID,186]
			/* scan through and check for any non-abandoned wreck */
			for ( count:Set[1] ; ${count} <= ${Wrecks.Used} ; count:Inc )
			{
				if !${Wrecks[${count}].IsAbandoned}
				{
					Wrecks[${count}]:AbandonAll
					break
				}
			}
			wait 100 !${UIElement[EVEAbandon].Visible}
		}
		waitframe
	}
}

function atexit()
{
	UIElement[EVEAbandon]:Destroy
}
