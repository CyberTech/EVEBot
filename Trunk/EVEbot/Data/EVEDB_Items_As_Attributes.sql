; Reference: http://wiki.eve-id.net/Database_Tables_-_Inventory

SELECT
 	concat_ws('','\t\t<Setting Name="', invTypes.typeID, '"',' ItemName="', REPLACE(REPLACE(typeName,'&','&amp;'), '"', '&quot;'), '"',' GroupID="', groupID, '"',' Metalevel="', IFNULL(IFNULL(TA.valueInt,TA.valueFloat),1), '"',' Volume="', volume, '"',' Capacity="', capacity, '"',' PortionSize="', portionSize, '"',' BasePrice="', basePrice, '"',' weaponRangeMultiplier="', (select valueFloat from dgmTypeAttributes where dgmTypeAttributes.typeID=invTypes.typeID and dgmTypeAttributes.attributeID = 120), '"','>0</Setting>') as SetString
 FROM `invTypes`
 	left outer join dgmTypeAttributes as TA on TA.typeID = invTypes.typeID and TA.attributeID=633
 	order by invTypes.typeID
 INTO OUTFILE '/tmp/EVEDB_Items.xml'
 FIELDS ESCAPED BY ''
 LINES TERMINATED BY '\r\n'

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

 Dont forget to replace & with &amp; in new file before committing!