; Reference: http://wiki.eve-id.net/Database_Tables_-_Inventory

SELECT 
 concat_ws('','  <Setting Name="', invTypes.typeID, '"',' ItemName="', typeName, '"',' GroupID="', groupID, '"',' Volume="', volume, '"',' Capacity="', capacity, '"',' PortionSize="', portionSize, '"',' BasePrice="', basePrice, '"',' weaponRangeMultiplier="', (select valueFloat from dgmTypeAttributes where dgmTypeAttributes.typeID=invTypes.typeID and dgmTypeAttributes.attributeID = 120), '"','>0</Setting>') as SetString 
 FROM `invTypes`
 order by invTypes.typeID
 into outfile '/tmp/list.txt'