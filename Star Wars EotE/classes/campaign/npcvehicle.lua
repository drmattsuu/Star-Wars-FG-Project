--function onDrop(x, y, draginfo)
--	return NpcManager.onDrop(getDatabaseNode(), x, y, draginfo);
--end

function onInit()
	registerMenuItem(Interface.getString("npc_vehicle_clear"), "erase", 4);
end

function onMenuSelection(selection)
	if selection == 4 then
		clearVehicleDetails();
	end
end

function clearVehicleDetails()
	-- Sets the value of all fields in the vehicle DB record to nil
	for k,v in pairs(window.getDatabaseNode().getChild("vehicle").getChildren()) do
		if v.getName() == "hull_trauma" or v.getName() == "shields" or v.getName() == "strain" then
			for k2,v2 in pairs(v.getChildren()) do
				v2.setValue(nil);
			end
		end
		if v.getName() == "shipcriticals" or v.getName() == "starshipconditions" then
			for k2,v2 in pairs(v.getChildren()) do
				v2.delete();		
			end		
		end
		v.setValue(nil);
	end
	-- Remove any vehicle weapons from the current NPC inventory that have been assigned to the vehicle tab.  This assumes these weapons were only for the vehicle being cleared.
	local npcInventoryNode = window.getDatabaseNode().createChild("inventory");
	if npcInventoryNode then
		for k, v in pairs(npcInventoryNode.getChildren()) do
			if v.createChild("isstarshipweapon", "number").getValue() == 1 and v.createChild("isequipped", "number").getValue() == 1 then
				v.delete();
			end
		end
	end	
end