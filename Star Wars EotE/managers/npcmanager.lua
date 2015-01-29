local addWoundsRunning = false;

function getNpcName(npcnode)
	local name = "";
	local namenode = npcnode.getChild("name");
	if namenode then
		name = namenode.getValue();
	end
	if name == "" then
		name = "- Unnamed -";
	end
	return name;
end

function openNpcSheet(npcnode)
	if User.isHost() then
		local npcsheetwindowreference = Interface.findWindow("npc", npcnode);
		if not npcsheetwindowreference then
			Interface.openWindow("npc", npcnode.getNodeName());
		else
			npcsheetwindowreference.close();		
		end
	end
end

function onDrop(npcnode, x, y, draginfo)

	Debug.console("npcmanager.lua:onDrop: Type = " .. draginfo.getType());

	-- Added to allow dragging of damage (type = wounds) drag data.
	if draginfo.isType("wounds") then
		--Debug.console("charactermanager.lua:onDrop: description = " .. draginfo.getDescription());
		if draginfo.getDescription() then
			return addWounds(npcnode, draginfo.getDescription());		
		end
	end

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();
		
		-- Skill
		if class == "skill" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSkill(npcnode, recordnode);
			end
		end
		
		-- Item
		if class == "item" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addItem(npcnode, recordnode);
			end
		end
		
		-- Blessing
		if class == "blessing" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addBlessing(npcnode, recordnode);
			end
		end
		
		-- Melee
		if class == "melee" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMelee(npcnode, recordnode);
			end
		end
		
		-- Ranged
		if class == "ranged" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRanged(npcnode, recordnode);
			end
		end
		
		-- Social
		if class == "social" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSocial(npcnode, recordnode);
			end
		end
		
		-- Spell
		if class == "spell" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSpell(npcnode, recordnode);
			end
		end
		
		-- Support
		if class == "support" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSupport(npcnode, recordnode);
			end
		end
		
		-- Condition
		if class == "condition" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCondition(npcnode, recordnode);
			end
		end
		
		-- Critical
		if class == "critical" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCritical(npcnode, recordnode);
			end
		end
				
		-- Disease
		if class == "disease" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addDisease(npcnode, recordnode);
			end
		end
		
		-- Insanity
		if class == "insanity" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addInsanity(npcnode, recordnode);
			end
		end
		
		-- Miscast
		if class == "miscast" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMiscast(npcnode, recordnode);
			end
		end		
		
		-- Mutation
		if class == "mutation" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMutation(npcnode, recordnode);
			end
		end		
	end
	
	-- Chit - wound, strain, etc.
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "wound" then
			return addWound(npcnode);
		end
		if draginfo.getCustomData() == "strain" then
			return addStrain(npcnode);
		end
		if draginfo.getCustomData() == "fatigue" then
			return addWound(npcnode);
		end
		if draginfo.getCustomData() == "stress" then
			return addWound(npcnode);
		end
	end	
end

function endOfTurn(npcnode)
	local actionperformed = nil;
	if removeRecharge(npcnode) then
		actionperformed = true;
	end
	return actionperformed;
end

function removeRecharge(npcnode)
	if User.isHost() then
		if removeChildRecharge(npcnode) then
			local msg = {};
			msg.font = "msgfont";					
			msg.text = "Recharge has been removed from " .. getNpcName(npcnode);
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

function addBlessing(npcnode, blessingnode)
	if User.isHost() then

		-- get the blessings node
		local blessingsnode = npcnode.createChild("blessings");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the blessing action: " .. blessingnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addMelee(npcnode, meleenode)
	if User.isHost() then

		-- get the melee node
		local meleesnode = npcnode.createChild("melee");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the melee action: " .. meleenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addRanged(npcnode, rangednode)
	if User.isHost() then	
	
		-- get the ranged node
		local rangesnode = npcnode.createChild("ranged");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the ranged action: " .. rangednode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSkill(npcnode, skillnode)
	if User.isHost() then	
	
		-- get the skills node
		local skillsnode = npcnode.createChild("skills");
		--if not skillsnode then
		--	skillsnode = npcnode.createChild("skills").setValue("skills");
		--end
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(skillsnode, skillnode) then
			return false;
		end		
	
		-- get the new skill
		local newskillnode = skillsnode.createChild();

		-- copy the skill
		DatabaseManager.copyNode(skillnode, newskillnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcName(npcnode) .. " has gained the skill: " .. skillnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addItem(npcnode, itemnode)
	if User.isHost() then	
	
		-- get the new item
		local newitemnode = npcnode.createChild("inventory").createChild();
		
		-- copy the item
		DatabaseManager.copyNode(itemnode, newitemnode);
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcName(npcnode) .. " has gained the item: " .. itemnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	end
end

function addSocial(npcnode, socialnode)
	if User.isHost() then	
	
		-- get the social node
		local socialsnode = npcnode.createChild("social");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the social action: " .. socialnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSpell(npcnode, spellnode)
	if User.isHost() then

		-- get the spell node
		local spellsnode = npcnode.createChild("spells");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the spell action: " .. spellnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSupport(npcnode, supportnode)
	if User.isHost() then	
	
		-- get the support node
		local supportsnode = npcnode.createChild("support");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the support action: " .. supportnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addCondition(npcnode, conditionnode)
	if User.isHost() then
	
		-- get the conditions node
		local conditionsnode = npcnode.createChild("conditions");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the condition: " .. conditionnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addCritical(npcnode, criticalnode)
	if User.isHost() then
	
		-- get the criticals node
		local criticalsnode = npcnode.createChild("criticals");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the critical: " .. criticalnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addDisease(npcnode, diseasenode)
	if User.isHost() then
	
		-- get the diseases node
		local diseasesnode = npcnode.createChild("diseases");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the disease: " .. diseasenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addInsanity(npcnode, insanitynode)
	if User.isHost() then
	
		-- get the insanities node
		local insanitiesnode = npcnode.createChild("insanities");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the insanity: " .. insanitynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addMiscast(npcnode, miscastnode)
	if User.isHost() then
	
		-- get the miscasts node
		local miscastsnode = npcnode.createChild("miscasts");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the miscast: " .. miscastnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	end
end

function addMutation(npcnode, mutationnode)
	if User.isHost() then
	
		-- get the mutations node
		local mutationsnode = npcnode.createChild("mutations");
		
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
		msg.text = getNpcName(npcnode) .. " has gained the mutation: " .. mutationnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addStrain(npcnode)
	if User.isHost() then

		-- get the strain npcnode
		local strainnode = npcnode.createChild("strain.current", "number");
		if strainnode then

			-- increase the npcs strain
			strainnode.setValue(strainnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getNpcName(npcnode) .. " has gained strain";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end	
	
function addWound(npcnode)
	if User.isHost() then

		-- get the wounds npcnode
		local woundsnode = npcnode.createChild("wounds.current", "number");
		if woundsnode then

			-- increase the npcs wounds
			woundsnode.setValue(woundsnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getNpcName(npcnode) .. " has gained a wound";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function getIdentityName(characternode)
	return characternode.getName();
end

function addWounds(characternode, wounds)
	Debug.console("npcmanager.lua: addWounds.");
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then
		if not addWoundsRunning then
			addWoundsRunning = true;
			-- get the wounds characternode
			local woundsnode = characternode.createChild("wounds.current", "number");
			if woundsnode then
				local sDamage = string.match(wounds, "%[Damage:%s*(%w+)%]");
				local soaknode = characternode.createChild("armour.soak", "number");
				local damage = 0;
				if soaknode then
					damage = tonumber(sDamage) - soaknode.getValue();
				else
					damage = tonumber(sDamage);
				end
				if damage > 0 then
					-- increase the characters wounds
					woundsnode.setValue(woundsnode.getValue() + damage);
				end
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";
				if damage > 0 then 
					msg.text = getNpcName(characternode) .. " has gained " .. damage .." wounds";
				else
					msg.text = getNpcName(characternode) .. " has not taken any damage."
				end
				ChatManager.deliverMessage(msg);
				
				-- and return
				addWoundsRunning = false;
				return true;
			end
		end
	end
end
