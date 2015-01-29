function getNpcGroupName(npcgroupnode)
	local name = "";
	local namenode = npcgroupnode.getChild("name");
	if namenode then
		name = namenode.getValue();
	end
	if name == "" then
		name = "- Unnamed -";
	end
	return name;
end

function openNpcGroupSheet(npcgroupnode)
	if User.isHost() then
		local npcgroupsheetwindowreference = Interface.findWindow("npcgroup", npcgroupnode);
		if not npcgroupsheetwindowreference then
			Interface.openWindow("npcgroup", npcgroupnode.getNodeName());
		else
			npcgroupsheetwindowreference.close();		
		end
	end
end

function onDrop(npcgroupnode, x, y, draginfo)

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();
		
		-- Blessing
		if class == "blessing" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addBlessing(npcgroupnode, recordnode);
			end
		end
		
		-- Melee
		if class == "melee" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMelee(npcgroupnode, recordnode);
			end
		end
		
		-- Ranged
		if class == "ranged" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRanged(npcgroupnode, recordnode);
			end
		end
		
		-- Social
		if class == "social" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSocial(npcgroupnode, recordnode);
			end
		end
		
		-- Spell
		if class == "spell" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSpell(npcgroupnode, recordnode);
			end
		end
		
		-- Support
		if class == "support" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSupport(npcgroupnode, recordnode);
			end
		end
	end
	
	-- Token
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "wound" then
			return addWound(npcgroupnode);
		end
		if draginfo.getCustomData() == "fatigue" then
			return addWound(npcgroupnode);
		end
		if draginfo.getCustomData() == "stress" then
			return addWound(npcgroupnode);
		end
	end	

end

function addAbility(slotnode, recordnode)
	if User.isHost() and slotnode then

		-- copy the name
		local namenode = recordnode.getChild("name");
		if namenode then
			slotnode.createChild("name", "string").setValue(namenode.getValue());
		end
		
		-- copy the description
		local descriptionnode = recordnode.getChild("description");
		if descriptionnode then
			slotnode.createChild("description", "formattedtext").setValue(descriptionnode.getValue());
		end
		
		-- and return true
		return true;
	end
end

function removeAbility(slotnode)
	if User.isHost() and slotnode then
		slotnode.createChild("name", "string").setValue("");
		slotnode.createChild("description", "formattedtext").setValue("");
		slotnode.createChild("currentrecharge", "number").setValue(0);
		return true;
	end
end

function endOfTurn(npcgroupnode)
	local actionperformed = nil;
	if removeRecharge(npcgroupnode) then
		actionperformed = true;
	end
	return actionperformed;
end

function removeRecharge(npcgroupnode)
	if User.isHost() then

		-- remove recharge from the relevant nodes
		local rechargeremoved = nil;
		if removeChildRecharge(npcgroupnode.getChild("blessings")) then
			rechargeremoved = true;
		end
		if removeChildRecharge(npcgroupnode.getChild("melee")) then
			rechargeremoved = true;
		end
		if removeChildRecharge(npcgroupnode.getChild("ranged")) then
			rechargeremoved = true;
		end
		if removeChildRecharge(npcgroupnode.getChild("slots")) then
			rechargeremoved = true;
		end
		if removeChildRecharge(npcgroupnode.getChild("social")) then
			rechargeremoved = true;
		end
		if removeChildRecharge(npcgroupnode.getChild("spells")) then
			rechargeremoved = true;
		end
		if removeChildRecharge(npcgroupnode.getChild("support")) then
			rechargeremoved = true;
		end

		-- print a message if required
		if rechargeremoved then
			local msg = {};
			msg.font = "msgfont";					
			msg.text = "Recharge has been removed from " .. getNpcGroupName(npcgroupnode);
			ChatManager.deliverMessage(msg);
			return true;
		end
		
	end
end

function removeChildRecharge(node)
	local rechargeremoved = nil;
	if node and node.isOwner() then

		-- reduce the recharge value for the node
		if node.getName() == "currentrecharge" then
			local nodevalue = node.getValue();
			if nodevalue > 0 then
				node.setValue(nodevalue - 1);
				rechargeremoved = true;
			end
		end

		-- recursively search all sub nodes
		for k, n in pairs(node.getChildren()) do
			if removeChildRecharge(n) then
				rechargeremoved = true;
			end
		end

	end
	return rechargeremoved;
end

function addBlessing(npcgroupnode, blessingnode)
	if User.isHost() then

		-- get the blessings node
		local blessingsnode = npcgroupnode.createChild("blessings");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(blessingsnode, blessingnode) then
			return false;
		end				
	
		-- get the new blessing
		local newblessingnode = blessingsnode.createChild();
		
		-- copy the blessing
		DatabaseManager.copyNode(blessingnode, newblessingnode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcGroupName(npcgroupnode) .. " has gained the blessing action: " .. blessingnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addMelee(npcgroupnode, meleenode)
	if User.isHost() then

		-- get the melee node
		local meleesnode = npcgroupnode.createChild("melee");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(meleesnode, meleenode) then
			return false;
		end				
	
		-- get the new melee
		local newmeleenode = meleesnode.createChild();
		
		-- copy the melee
		DatabaseManager.copyNode(meleenode, newmeleenode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcGroupName(npcgroupnode) .. " has gained the melee action: " .. meleenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addRanged(npcgroupnode, rangednode)
	if User.isHost() then	
	
		-- get the ranged node
		local rangesnode = npcgroupnode.createChild("ranged");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(rangesnode, rangednode) then
			return false;
		end				
		
		-- get the new ranged
		local newrangednode = rangesnode.createChild();
		
		-- copy the ranged
		DatabaseManager.copyNode(rangednode, newrangednode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcGroupName(npcgroupnode) .. " has gained the ranged action: " .. rangednode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSocial(npcgroupnode, socialnode)
	if User.isHost() then	
	
		-- get the social node
		local socialsnode = npcgroupnode.createChild("social");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(socialsnode, socialnode) then
			return false;
		end				
	
		-- get the new social
		local newsocialnode = socialsnode.createChild();
		
		-- copy the social
		DatabaseManager.copyNode(socialnode, newsocialnode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcGroupName(npcgroupnode) .. " has gained the social action: " .. socialnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSpell(npcgroupnode, spellnode)
	if User.isHost() then

		-- get the spell node
		local spellsnode = npcgroupnode.createChild("spells");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(spellsnode, spellnode) then
			return false;
		end				
	
		-- get the new spell
		local newspellnode = spellsnode.createChild();
		
		-- copy the spell
		DatabaseManager.copyNode(spellnode, newspellnode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcGroupName(npcgroupnode) .. " has gained the spell action: " .. spellnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSupport(npcgroupnode, supportnode)
	if User.isHost() then	
	
		-- get the support node
		local supportsnode = npcgroupnode.createChild("support");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(supportsnode, supportnode) then
			return false;
		end				
	
		-- get the new support
		local newsupportnode = supportsnode.createChild();
		
		-- copy the support
		DatabaseManager.copyNode(supportnode, newsupportnode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcGroupName(npcgroupnode) .. " has gained the support action: " .. supportnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addWound(npcgroupnode)
	if User.isHost() then
		local npcsnode = npcgroupnode.createChild("npcs");
		if npcsnode then
			for k, n in pairs(npcsnode.getChildren()) do
				NpcManager.addWound(n);
			end
			return true;
		end
	end
end