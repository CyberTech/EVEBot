function main()
{
	variable index:entity Wrecks
	variable int count
	ui -load ./eveabandon.xml
	while ${UIElement[EVEAbandon].Visible}
	{
		if ${UIElement[EVEAbandon].FindUsableChild[AutoAbandon,checkbox].Checked}
		{
			Wrecks:Clear
			EVE:QueryEntities[Wrecks,HaveLootRights = TRUE && IsAbandoned = FALSE && GroupID = 186]
			echo Wrecks: ${Wrecks.Used}
			/* scan through and check for any non-abandoned wreck */
			for ( count:Set[1] ; ${count} <= ${Wrecks.Used} ; count:Inc )
			{
				Wrecks[${count}]:AbandonAll
				break
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
