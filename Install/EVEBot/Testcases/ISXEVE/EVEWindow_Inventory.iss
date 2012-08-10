function main()
{
    variable index:mutablestring InvWindowChildrenNames
    variable index:int64 InvWindowChildrenIDs
    variable iterator Iter
    variable int i = 1
    
    variable eveinvwindow InventoryWindow = "${EVEWindow[byName,"Inventory"]}"
    if (${InventoryWindow(exists)})
    {
        echo "- Name: ${InventoryWindow.Name}"
        echo "-- Type: ${InventoryWindow(type)}"
        echo "-- Caption: ${InventoryWindow.Caption}"
        
        InventoryWindow:GetChildren[InvWindowChildrenNames,InvWindowChildrenIDs]
        InvWindowChildrenNames:GetIterator[Iter]
        if ${Iter:First(exists)}
        {
            echo "------- Inventory Window Children (By Name):"
            do
            {
                echo "--| ${i}. '${Iter.Value}'"
                echo "-----| Capacity: ${InventoryWindow.ChildCapacity[${Iter.Value}].Precision[2]}"
                echo "-----| UsedCapacity: ${InventoryWindow.ChildUsedCapacity[${Iter.Value}].Precision[2]}"
                echo "-----| LocationFlag: ${InventoryWindow.ChildWindowLocationFlag[${Iter.Value}]}"
                echo "-----| LocationFlagID: ${InventoryWindow.ChildWindowLocationFlagID[${Iter.Value}]}"
                i:Inc
            }
            while ${Iter:Next(exists)}
        }
    
        i:Set[1]
        InvWindowChildrenIDs:GetIterator[Iter]
        if ${Iter:First(exists)}
        {
            echo "------- Inventory Window Children (By ItemID):"
            do
            {
                echo "--| ${i}. '${Iter.Value}'"
                echo "-----| Capacity: ${InventoryWindow.ChildCapacity[${Iter.Value}].Precision[2]}"
                echo "-----| UsedCapacity: ${InventoryWindow.ChildUsedCapacity[${Iter.Value}].Precision[2]}"
                echo "-----| LocationFlag: ${InventoryWindow.ChildWindowLocationFlag[${Iter.Value}]}"
                echo "-----| LocationFlagID: ${InventoryWindow.ChildWindowLocationFlagID[${Iter.Value}]}"
                i:Inc
            }
            while ${Iter:Next(exists)}
        }
    }
}