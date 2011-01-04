; Reference: http://wiki.eve-id.net/Database_Tables_-_Inventory

SELECT
 concat_ws('','  <Setting Name="', invTypes.typeID, '"',' ItemName="', typeName, '"',' GroupID="', groupID, '"',' Metalevel="', IFNULL(MT.metaGroupID, 1), '"',' Volume="', volume, '"',' Capacity="', capacity, '"',' PortionSize="', portionSize, '"',' BasePrice="', basePrice, '"',' weaponRangeMultiplier="', (select valueFloat from dgmTypeAttributes where dgmTypeAttributes.typeID=invTypes.typeID and dgmTypeAttributes.attributeID = 120), '"','>0</Setting>') as SetString
 FROM `invTypes`
 left outer join invMetaTypes as MT on MT.typeID = invTypes.typeID
 order by invTypes.typeID
 into outfile '/tmp/EVEDB_Items.xml'

; Dont forget to replace & with &amp; in new file before committing!

;SELECT stationID, solarSystemID, stationName
;FROM staStations

SELECT
 concat_ws('','  <Setting Name="', stationName, '"',' StationID="', stationID, '"',' SolarSystemID="', solarSystemID, '"','>0</Setting>') as SetString
 FROM `staStations`
 order by staStations.solarSystemID
 into outfile '/tmp/EVEDB_Stations.xml'

 Dont forget to replace & with &amp; in new file before committing!