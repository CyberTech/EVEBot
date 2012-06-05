SELECT
concat('\t\t<Set Name="', REPLACE(REPLACE(typeName,'&','&amp;'), '"', '&quot;'), '">', '\n',
		'\t\t\t<Setting Name="TypeID">', typeID, '</Setting>', '\n',
		'\t\t\t<Setting Name="GroupID">', groupID, '</Setting>', '\n',
		'\t\t\t<Setting Name="Volume">', volume, '</Setting>', '\n',
		'\t\t\t<Setting Name="Capacity">', capacity, '</Setting>', '\n',
		'\t\t\t<Setting Name="PortionSize">', portionSize, '</Setting>', '\n',
		'\t\t\t<Setting Name="BasePrice">', basePrice, '</Setting>', '\n',
		'\t\t</Set>'
		) as SetString
 FROM `invTypes`
	order by typeName
 INTO OUTFILE '/tmp/EVEDB_Items_Stable.xml'
 FIELDS ESCAPED BY ''
 LINES TERMINATED BY '\r\n'
		'\t\t\t<Setting Name="MarketGroupID">', marketGroupID, '</Setting>', '\n',

This export is missing all items which are not sold on the market, because concat gets rid of null rows and MarketGroupID is null
