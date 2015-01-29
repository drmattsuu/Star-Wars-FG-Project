function getRetainerName(retainernode)
	local name = "";
	local namenode = retainernode.getChild("name");
	if namenode then
		name = namenode.getValue();
	end
	if name == "" then
		name = "- Unnamed -";
	end
	return name;
end

function openRetainerSheet(retainernode)
	if retainernode and retainernode.isOwner() then
		local retainersheetwindowreference = Interface.findWindow("retainer", retainernode);
		if not retainersheetwindowreference then
			Interface.openWindow("retainer", retainernode.getNodeName());
		else
			retainersheetwindowreference.close();		
		end
	end
end

function onDrop(retainernode, x, y, draginfo)

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();
		
		-- Blessing
		if class == "blessing" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addBlessing(retainernode, recordnode);
			end
		end
		
		-- Melee
		if class == "melee" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMelee(retainernode, recordnode);
			end
		end
		
		-- Ranged
		if class == "ranged" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRanged(retainernode, recordnode);
			end
		end
		
		-- Social
		if class == "social" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSocial(retainernode, recordnode);
			end
		end
		
		-- Spell
		if class == "spell" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSpell(retainernode, recordnode);
			end
		end
		
		-- Support
		if class == "support" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSupport(retainernode, recordnode);
			end
		end
		
		-- Condition
		if class == "condition" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCondition(retainernode, recordnode);
			end
		end
		
		-- Critical
		if class == "critical" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCritical(retainernode, recordnode);
			end
		end

		-- Disease
		if class == "disease" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addDisease(retainernode, recordnode);
			end
		end
		
		-- Insanity
		if class == "insanity" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addInsanity(retainernode, recordnode);
			end
		end
		
		-- Miscast
		if class == "miscast" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMiscast(retainernode, recordnode);
			end
		end		
		
		-- Mutation
		if class == "mutation" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMutation(retainernode, recordnode);
			end
		end		
		
	end
	
	-- Token
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "wound" then
			return addWound(retainernode);
		end
		if draginfo.getCustomData() == "fatigue" then
			return addWound(retainernode);
		end
		if draginfo.getCustomData() == "stress" then
			return addWound(retainernode);
		end
	end	
end

function endOfTurn(retainernode)
	local actionperformed = nil;
	if removeRecharge(retainernode) then
		actionperformed = true;
	end
	return actionperformed;
end

function removeRecharge(retainernode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
		if removeChildRecharge(retainernode) then
			local msg = {};
			msg.font = "msgfont";					
			msg.text = "Recharge has been removed from " .. getRetainerName(retainernode);
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

function addBlessing(retainernode, blessingnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then	
	
		-- get the blessings node
		local blessingsnode = retainernode.createChild("blessings");
		
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
		msg.text = getRetainerName(retainernode) .. " has gained the blessing action: " .. blessingnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addMelee(retainernode, meleenode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then	
	
		-- get the melee node
		local meleesnode = retainernode.createChild("melee");
		
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
		msg.text = getRetainerName(retainernode) .. " has gained the melee action: " .. meleenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addRanged(retainernode, rangednode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then	
	
		-- get the ranged node
		local rangesnode = retainernode.createChild("ranged");
		
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
		msg.text = getRetainerName(retainernode) .. " has gained the ranged action: " .. rangednode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSocial(retainernode, socialnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then	
	
		-- get the social node
		local socialsnode = retainernode.createChild("social");
		
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
		msg.text = getRetainerName(retainernode) .. " has gained the social action: " .. socialnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSpell(retainernode, spellnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then	
	
		-- get the spells node
		local spellsnode = retainernode.createChild("spells");
		
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
		msg.text = getRetainerName(retainernode) .. " has gained the spell action: " .. spellnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSupport(retainernode, supportnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then	
	
		-- get the support node
		local supportsnode = retainernode.createChild("support");
		
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
		msg.text = getRetainerName(retainernode) .. " has gained the support action: " .. supportnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addCondition(retainernode, conditionnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
	
		-- get the condition node
		local conditionsnode = retainernode.createChild("conditions");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(conditionsnode, conditionnode) then
			return false;
		end			
	
		-- get the new condition
		local newconditionnode = conditionsnode.createChild();
		
		-- copy the condition
		DatabaseManager.copyNode(conditionnode, newconditionnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getRetainerName(retainernode) .. " has gained the condition: " .. conditionnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addCritical(retainernode, criticalnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
	
		-- get the criticals node
		local criticalsnode = retainernode.createChild("criticals");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(criticalsnode, criticalnode) then
			return false;
		end			
	
		-- get the new critical
		local newcriticalnode = criticalsnode.createChild();

		-- copy the critical
		DatabaseManager.copyNode(criticalnode, newcriticalnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getRetainerName(retainernode) .. " has gained the critical: " .. criticalnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addDisease(retainernode, diseasenode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
	
		-- get the diseases node
		local diseasesnode = retainernode.createChild("diseases");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(diseasesnode, diseasenode) then
			return false;
		end				
	
		-- get the new disease
		local newdiseasenode = diseasesnode.createChild();

		-- copy the disease
		DatabaseManager.copyNode(diseasenode, newdiseasenode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getRetainerName(retainernode) .. " has gained the disease: " .. diseasenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addInsanity(retainernode, insanitynode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
	
		-- get the insanities node
		local insanitiesnode = retainernode.createChild("insanities");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(insanitiesnode, insanitynode) then
			return false;
		end				
	
		-- get the new insanity
		local newinsanitynode = insanitiesnode.createChild();

		-- copy the insanity
		DatabaseManager.copyNode(insanitynode, newinsanitynode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getRetainerName(retainernode) .. " has gained the insanity: " .. insanitynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addMiscast(retainernode, miscastnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
	
		-- get the miscasts node
		local miscastsnode = retainernode.createChild("miscasts");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(miscastsnode, miscastnode) then
			return false;
		end		
	
		-- get the new miscast
		local newmiscastnode = miscastsnode.createChild();
		
		-- copy the miscast
		DatabaseManager.copyNode(miscastnode, newmiscastnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getRetainerName(retainernode) .. " has gained the miscast: " .. miscastnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	end
end

function addMutation(retainernode, mutationnode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then
	
		-- get the mutations node
		local mutationsnode = retainernode.createChild("mutations");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(mutationsnode, mutationnode) then
			return false;
		end				
	
		-- get the new mutation
		local newmutationnode = mutationsnode.createChild();

		-- copy the mutation
		DatabaseManager.copyNode(mutationnode, newmutationnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getRetainerName(retainernode) .. " has gained the mutation: " .. mutationnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end


function addWound(retainernode)
	if User.isHost() or User.isLocal() or retainernode.isOwner() then

		-- get the wounds retainernode
		local woundsnode = retainernode.createChild("wounds.current", "number");
		if woundsnode then

			-- increase the retainers wounds
			woundsnode.setValue(woundsnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getRetainerName(retainernode) .. " has gained a wound";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end
