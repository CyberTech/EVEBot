/*
	POS Inventory Script - CyberTech (cybertech@gmail.com)
	based on POSFinder by GliderPro
*/

#define CATEGORYID_CELESTIAL    2
#define GROUPID_MOON            8

#define CATEGORYID_STRUCTURE    23
#define GROUPID_CONTROL_TOWER   365

variable string LogFile

function atexit()
{
	echo "POS Inventory Script -- Ended"
	return
}

function LogEcho(string aString)
{
	echo "${aString}"
	redirect -append "${LogFile}" echo "${aString}"
}

function WarpWait()
{
	variable bool Warped = FALSE

	variable int Count
	for (Count:Set[0] ; ${Count}<10 ; Count:Inc)
	{
		if ${Me.ToEntity.Mode} == 3
		{
			echo "Warping..."
			break
		}
		wait 20
	}

	while ${Me.ToEntity.Mode} == 3
	{
		Warped:Set[TRUE]
		wait 20
	}
	echo "Dropped out of warp"
	wait 20
	return ${Warped}
}

function WarpToID(int Id)
{
	if (${Id} <= 0)
	{
		echo "Error: WarpToID: Id is <= 0 (${Id})"
		return
	}

	if !${Entity[${Id}](exists)}
	{
		echo "Error: WarpToID: No entity matched the ID given."
		return
	}

	/* The warp-in point for a moon is usually quite far   */
	/* away from the actual moon entity.  Most of the time */
	/* it is just over 5 million meters from the moon.     */
	while ${Entity[${Id}].Distance} >= 8000000
	{
		echo "Warping to ${Entity[${Id}].Name}"
		Entity[${Id}]:WarpTo[100000]
		call WarpWait
	}
}

function main(... Args)
{
	variable time Timestamp = ${Time.Timestamp}
	variable string Timestring = ${Timestamp.Year}-${Timestamp.Month}-${Timestamp.Day}_${Timestamp.Hour}-${Timestamp.Minute}
	LogFile:Set["${Script.CurrentDirectory}/${Universe[${Me.SolarSystemID}]}_POS_${Timestring}.log"]

	echo "EVE POS Inventory Script"

	call LogEcho "POS Inventory for ${Universe[${Me.SolarSystemID}]} on ${Timestamp.Date} at ${Timestamp.Time24}"
	call LogEcho " "

	echo "EVE POS Inventory will log to ${LogFile}"

	variable index:entity moonIndex
	variable iterator moonIterator
	variable index:entity posIndex
	variable iterator posIterator
	variable index:entity anchorIndex
	variable iterator anchorIterator
	variable float64 Distance
	variable string DistanceStr
	variable string posOwner
	variable string anchoredOwner
	variable collection:int AnchoredItems
	variable collection:int Moons
	variable int Counter
	variable string tempname

	EVE:PopulateEntities[TRUE]
	EVE:QueryEntities[moonIndex, CategoryID == CATEGORYID_CELESTIAL && GroupID == GROUPID_MOON]
	echo "Found ${moonIndex.Used} moons in ${Universe[${Me.SolarSystemID}]}."

	moonIndex:GetIterator[moonIterator]
	if ${moonIterator:First(exists)}
	{
		do
		{
			Moons:Set[${moonIterator.Value.Name},${moonIterator.Value.ID}]
		}
		while ${moonIterator:Next(exists)}
	}
	else
	{
		echo "Finished"
		Script:End
	}
	if !${Moons.FirstKey(exists)}
	{
		echo "Finished"
		Script:End
	}

	do
	{
		call WarpToID ${Moons.CurrentValue}

		call LogEcho "Moon: ${Moons.CurrentKey}"
		EVE:QueryEntities[posIndex, CategoryID == CATEGORYID_STRUCTURE && GroupID == GROUPID_CONTROL_TOWER]
		posIndex:GetIterator[posIterator]
		if ${posIterator:First(exists)}
		do
		{
			posOwner:Set["${posIterator.Value.Alliance} - ${posIterator.Value.Corp.Name}"]
			call LogEcho "\tType: ${posIterator.Value.Type} -- ${posOwner}"
			call LogEcho "\tName: ${posIterator.Value.Name}"

			EVE:QueryEntities[anchorIndex, CategoryID == CATEGORYID_STRUCTURE && ID != ${posIterator.Value.ID}]

			AnchoredItems:Clear
			call LogEcho "\tAnchored Modules:"
			anchorIndex:GetIterator[anchorIterator]
			if ${anchorIterator:First(exists)}
			do
			{
				if ${anchorIterator.Value.GroupID} != GROUPID_CONTROL_TOWER
				{
					anchoredOwner:Set[" ${anchorIterator.Value.Alliance} - ${anchorIterator.Value.Corp.Name}"]
					if ${posOwner.Equal[${anchoredOwner}]}
					{
						anchoredOwner:Set[""]
					}

					tempname:Set["${anchorIterator.Value.Type}${anchoredOwner}"]
					if ${AnchoredItems.Element[${tempname}](exists)}
					{

						Counter:Set[${AnchoredItems.Element[${tempname}]}]
						Counter:Inc
					}
					else
					{
						Counter:Set[1]
					}
					AnchoredItems:Set[${tempname},${Counter}]
				}
			}
			while ${anchorIterator:Next(exists)}

			if "${AnchoredItems.FirstKey(exists)}"
			{
				do
				{
					call LogEcho "\t\t${AnchoredItems.CurrentValue.LeadingZeroes[2]} x ${AnchoredItems.CurrentKey}"
				}
				while "${AnchoredItems.NextKey(exists)}"
			}
		}
		while ${posIterator:Next(exists)}
		call LogEcho " "
	}
	while "${Moons.NextKey(exists)}"
}