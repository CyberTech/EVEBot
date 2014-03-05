; Reference: http://wiki.eve-id.net/Database_Tables_-_Inventory

SELECT
 	concat_ws('','\t\t<Setting Name="', invTypes.typeID, '"',
	' ItemName="', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(typeName,'&','&amp;'), '<','&lt;'), '>','&gt;'), '"','&quot;'), '\'','&apos;'), '"',
	' GroupID="', groupID, '"',
	' Metalevel="', IFNULL(IFNULL(metalevel.valueInt,metalevel.valueFloat),1), '"',
	' Techlevel="', IFNULL(IFNULL(techLevel.valueInt,techLevel.valueFloat),1), '"',
	' Volume="', volume, '"',
	' Capacity="', capacity, '"',
	' PortionSize="', portionSize, '"',
	' BasePrice="', basePrice, '"',
	' weaponRangeMultiplier="', IFNULL(IFNULL(weaponRangeMultiplier.valueFloat,weaponRangeMultiplier.valueInt),1), '"',
	'>0</Setting>') as SetString
 FROM `invTypes`
 	left outer join dgmTypeAttributes as metalevel on metalevel.typeID = invTypes.typeID and metalevel.attributeID=633
 	left outer join dgmTypeAttributes as weaponRangeMultiplier on weaponRangeMultiplier.typeID = invTypes.typeID and weaponRangeMultiplier.attributeID=120
 	left outer join dgmTypeAttributes as techLevel on techLevel.typeID = invTypes.typeID and techLevel.attributeID=422
 	order by invTypes.typeID
 INTO OUTFILE '/tmp/EVEDB_Items.xml'
 FIELDS ESCAPED BY ''
 LINES TERMINATED BY '\r\n';


; attributeID 633 is metalevel

; Dont forget to replace & with &amp; in new file before committing!
; " => &quot;

;SELECT stationID, solarSystemID, stationName
;FROM staStations

SELECT
 concat_ws('','  <Setting Name="', stationName, '"',' StationID="', stationID, '"',' SolarSystemID="', solarSystemID, '"','>0</Setting>') as SetString
 FROM `staStations`
 order by staStations.solarSystemID
 into outfile '/tmp/EVEDB_Stations.xml'

SELECT 
* FROM dgmTypeAttributes as dta
left outer join dgmAttributeTypes as dat on dat.attributeID = dta.attributeID;