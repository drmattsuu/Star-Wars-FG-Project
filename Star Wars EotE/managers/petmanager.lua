function getPetName(petnode)
	local name = "";
	local namenode = petnode.getChild("name");
	if namenode then
		name = namenode.getValue();
	end
	if name == "" then
		name = "- Unnamed -";
	end
	return name;
end

function openPetSheet(petnode)
	if petnode and petnode.isOwner() then
		local petsheetwindowreference = Interface.findWindow("pet", petnode);
		if not petsheetwindowreference then
			Interface.openWindow("pet", petnode.getNodeName());
		else
			petsheetwindowreference.close();		
		end
	end
end

function onDrop(petnode, x, y, draginfo)

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();
		
		-- Blessing
		if class == "blessing" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addBlessing(petnode, recordnode);
			end
		end
		
		-- Melee
		if class == "melee" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMelee(petnode, recordnode);
			end
		end
		
		-- Ranged
		if class == "ranged" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRanged(petnode, recordnode);
			end
		end
		
		-- Social
		if class == "social" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSocial(petnode, recordnode);
			end
		end
		
		-- Spell
		if class == "spell" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSpell(petnode, recordnode);
			end
		end
		
		-- Support
		if class == "support" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSupport(petnode, recordnode);
			end
		end
		
		-- Trick
		if class == "trick" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addTrick(petnode, recordnode);
			end
		end		
	end
	
	-- Token
	if draginfo.isType("chit") then
	
		-- Wound
		if draginfo.getCustomData() == "wound" then
			return reduceHealth(petnode);
		end
		
		-- Stress
		if draginfo.getCustomData() == "stress" then
			return reduceHealth(petnode);
		end
		
		-- Fatigue
		if draginfo.getCustomData() == "fatigue" then
			return reduceHealth(petnode);
		end
		
	end
	
end

function endOfTurn(petnode)
	local actionperformed = nil;
	if removeRecharge(petnode) then
		actionperformed = true;
	end
	return actionperformed;
end

function removeRecharge(petnode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then
		if removeChildRecharge(petnode) then
			local msg = {};
			msg.font = "msgfont";					
			msg.text = "Recharge has been removed from " .. getPetName(petnode);
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
		
		-- remove brief conditions
		if string.find(node.getParent().getNodeName(), "conditions") then
			local durationnode = node.getChild("duration");
			if durationnode and string.lower(durationnode.getValue()) == string.lower(LanguageManager.getString("Brief")) then
				local rechargenode = node.getChild("currentrecharge");
				if rechargenode and rechargenode.getValue() == 0 then
					node.delete();
				end
			end
		end	
			
	end
	return rechargeremoved;
end

function addBlessing(petnode, blessingnode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then	
	
		-- get the blessings node
		local blessingsnode = petnode.createChild("blessings");
		
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
		msg.text = getPetName(petnode) .. " has gained the blessing action: " .. blessingnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addMelee(petnode, meleenode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then	
	
		-- get the melee node
		local meleesnode = petnode.createChild("melee");
		
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
		msg.text = getPetName(petnode) .. " has gained the melee action: " .. meleenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addRanged(petnode, rangednode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then	
	
		-- get the ranges node
		local rangesnode = petnode.createChild("ranged");
		
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
		msg.text = getPetName(petnode) .. " has gained the ranged action: " .. rangednode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSocial(petnode, socialnode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then	
	
		-- get the social node
		local socialsnode = petnode.createChild("social");
		
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
		msg.text = getPetName(petnode) .. " has gained the social action: " .. socialnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSpell(petnode, spellnode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then	
	
		-- get the spells node
		local spellsnode = petnode.createChild("spells");
		
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
		msg.text = getPetName(petnode) .. " has gained the spell action: " .. spellnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSupport(petnode, supportnode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then	
	
		-- get the support node
		local supportsnode = petnode.createChild("support");
		
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
		msg.text = getPetName(petnode) .. " has gained the support action: " .. supportnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addTrick(petnode, tricknode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then
	
		-- get the tricks node
		local tricksnode = petnode.createChild("tricks");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(tricksnode, tricknode) then
			return false;
		end			
	
		-- get the new trick
		local newtricknode = petnode.createChild("tricks").createChild();

		-- copy the trick
		DatabaseManager.copyNode(tricknode, newtricknode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getPetName(petnode) .. " has gained the trick: " .. tricknode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function reduceHealth(petnode)
	if User.isHost() or User.isLocal() or petnode.isOwner() then

		-- get the health petnode
		local healthnode = petnode.createChild("health.value", "number");
		if healthnode then
		
			-- get the current health value
			local healthvalue = healthnode.getValue();
			
			-- decrease the health value by one
			if healthvalue and healthvalue > 0 then
			
				-- decrease the health
				healthnode.setValue(healthvalue - 1);
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";											
				msg.text = getPetName(petnode) .. " has lost obedience";
				ChatManager.deliverMessage(msg);				
				
			end

			-- and return
			return true;
		end
	end
end
