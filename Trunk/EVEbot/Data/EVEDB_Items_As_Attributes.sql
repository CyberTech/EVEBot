SELECT 
concat_ws('','  <Setting Name="', typeID, '"',' ItemName="', typeName, '"',' GroupID="', groupID, '"',' Volume="', volume, '"',' Capacity="', capacity, '"',' PortionSize="', portionSize, '"',' BasePrice="', basePrice, '"','>0</Setting>') as SetString
FROM `invTypes`
order by typeID
into outfile '/tmp/list.txt'