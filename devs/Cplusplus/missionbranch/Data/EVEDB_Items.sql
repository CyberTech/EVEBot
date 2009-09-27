SELECT
concat('\t\t<Set Name="', typeName, '">', '\n',
		'\t\t\t<Setting Name="TypeID">', typeID, '</Setting>', '\n',
		'\t\t\t<Setting Name="GroupID">', groupID, '</Setting>', '\n',
		'\t\t\t<Setting Name="Volume">', volume, '</Setting>', '\n',
		'\t\t\t<Setting Name="Capacity">', capacity, '</Setting>', '\n',
		'\t\t\t<Setting Name="PortionSize">', portionSize, '</Setting>', '\n',
		'\t\t\t<Setting Name="BasePrice">', basePrice, '</Setting>', '\n',
		'\t\t\t<Setting Name="MarketGroupID">', marketGroupID, '</Setting>', '\n',
		'\t\t</Set>\n'
		) as SetString
FROM `invTypes`
order by typeName
into outfile '/tmp/list.txt'


Don't forget to replace & with &amp; in new file before committing!