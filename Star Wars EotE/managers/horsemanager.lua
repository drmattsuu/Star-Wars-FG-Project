function getHorseName(horsenode)
	local name = "";
	local namenode = horsenode.getChild("name");
	if namenode then
		name = namenode.getValue();
	end
	if name == "" then
		name = "- Unnamed -";
	end
	return name;
end

function openHorseSheet(horsenode)
	if horsenode and horsenode.isOwner() then
		local horsesheetwindowreference = Interface.findWindow("horse", horsenode);
		if not horsesheetwindowreference then
			Interface.openWindow("horse", horsenode.getNodeName());
		else
			horsesheetwindowreference.close();		
		end
	end
end

function onDrop(horsenode, x, y, draginfo)

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();
		
		-- Blessing
		if class == "blessing" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addBlessing(horsenode, recordnode);
			end
		end
		
		-- Melee
		if class == "melee" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMelee(horsenode, recordnode);
			end
		end
		
		-- Ranged
		if class == "ranged" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRanged(horsenode, recordnode);
			end
		end
		
		-- Social
		if class == "social" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSocial(horsenode, recordnode);
			end
		end
		
		-- Spell
		if class == "spell" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSpell(horsenode, recordnode);
			end
		end
		
		-- Support
		if class == "support" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSupport(horsenode, recordnode);
			end
		end
		
		-- Tactic
		if class == "tactic" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addTactic(horsenode, recordnode);
			end
		end
	end
	
	-- Token
	if draginfo.isType("chit") then
	
		-- Wound
		if draginfo.getCustomData() == "wound" then
			return reduceHealth(horsenode);
		end
		
		-- Stress
		if draginfo.getCustomData() == "stress" then
			return reduceHealth(horsenode);
		end
		
		-- Fatigue
		if draginfo.getCustomData() == "fatigue" then
			return reduceHealth(horsenode);
		end
		
	end
	
end

function endOfTurn(horsenode)
	local actionperformed = nil;
	if removeRecharge(horsenode) then
		actionperformed = true;
	end
	return actionperformed;
end

function removeRecharge(horsenode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then
		if removeChildRecharge(horsenode) then
			local msg = {};
			msg.font = "msgfont";					
			msg.text = "Recharge has been removed from " .. getHorseName(horsenode);
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
			if not string.find(node.getNodeName(), "insanities") then
				local nodevalue = node.getValue();
				if nodevalue > 0 then
					node.setValue(nodevalue - 1);
					rechargeremoved = true;
				end
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

function addBlessing(horsenode, blessingnode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then	
	
		-- get the blessings node
		local blessingsnode = horsenode.createChild("blessings");
		
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
		msg.text = getHorseName(horsenode) .. " has gained the blessing action: " .. blessingnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addMelee(horsenode, meleenode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then	
	
		-- get the melee node
		local meleesnode = horsenode.createChild("melee");
		
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
		msg.text = getHorseName(horsenode) .. " has gained the melee action: " .. meleenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addRanged(horsenode, rangednode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then	
	
		-- get the ranged node
		local rangesnode = horsenode.createChild("ranged");
		
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
		msg.text = getHorseName(horsenode) .. " has gained the ranged action: " .. rangednode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSocial(horsenode, socialnode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then	
	
		-- get the social node
		local socialsnode = horsenode.createChild("social");
		
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
		msg.text = getHorseName(horsenode) .. " has gained the social action: " .. socialnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSpell(horsenode, spellnode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then	
	
		-- get the spells node
		local spellsnode = horsenode.createChild("spells");
		
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
		msg.text = getHorseName(horsenode) .. " has gained the spell action: " .. spellnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSupport(horsenode, supportnode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then	
	
		-- get the support node
		local supportsnode = horsenode.createChild("support");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(supportsnode, supportnode) then
			return false;
		end			
	
		-- get the new support
		local newsupportnode = horsenode.createChild("support").createChild();
		
		-- copy the support
		DatabaseManager.copyNode(supportnode, newsupportnode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getHorseName(horsenode) .. " has gained the support action: " .. supportnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addTactic(horsenode, tacticnode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then
	
		-- get the tactics node
		local tacticsnode = horsenode.createChild("tactics");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(tacticsnode, tacticnode) then
			return false;
		end			
	
		-- get the new tactic
		local newtacticnode = tacticsnode.createChild();
		
		-- copy the tactic
		DatabaseManager.copyNode(tacticnode, newtacticnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getHorseName(horsenode) .. " has gained the tactic: " .. tacticnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function reduceHealth(horsenode)
	if User.isHost() or User.isLocal() or horsenode.isOwner() then

		-- get the health horsenode
		local healthnode = horsenode.createChild("health.value", "number");
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
				msg.text = getHorseName(horsenode) .. " has lost wind";
				ChatManager.deliverMessage(msg);
				
			end

			-- and return
			return true;
		end
	end
end
