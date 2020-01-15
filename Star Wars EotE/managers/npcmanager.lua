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

	Debug.console("npcmanager.lua:onDrop: Type = " .. draginfo.getType() .. ", node = " .. npcnode.getNodeName());

	-- If dropped on an initslot, retrieve the NPC/PC DB node reference and use that for npcnode
	if string.find(npcnode.getNodeName(), "initiativetracker.initslots.") then
		initslotRefNode = npcnode.getChild("initslot_actornodename");
		if initslotRefNode then
			npcnode = DB.findNode(initslotRefNode.getValue());
			if not npcnode or npcnode.getNodeName() == "" then
				return;
			else
				Debug.console("Got node of " .. npcnode.getNodeName() .. " from " .. initslotRefNode.getNodeName());
				if string.find(npcnode.getNodeName(), "charsheet.id-") then
					-- We have a PC, not an NPC.  Run CharacterManager.onDrop.
					CharacterManager.onDrop(npcnode, x, y, draginfo);
					return;				
				end
			end
		end	
	end

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
		
		Debug.console("npcmanager.lua:onDrop: Shortcut class = " .. class);
		
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
		
		-- Condition
		if class == "condition" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCondition(npcnode, recordnode);
			end
		end	
		
		-- Ability
		if class == "ability" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addAbility(npcnode, recordnode);
			end
		end		
		
		-- Talent
		if class == "talent" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addTalent(npcnode, recordnode);
			end
		end		

		-- Vehicle
		if class == "vehicle" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addVehicle(npcnode, recordnode);
			end
		end
		
	end
	
	-- Chit - wound, strain, etc.
	if draginfo.isType("chit") then
		Debug.console("Customdata = " .. draginfo.getCustomData());
		if draginfo.getCustomData() == "wound" then
			return addWound(npcnode);
		elseif draginfo.getCustomData() == "strain" then
			-- Check for NPC category and apply strain to nemesis, wounds to rivals and minions.
			if npcnode.getChild("npc_category") then
				if string.lower(npcnode.getChild("npc_category").getValue()) == "nemesis" then
					return addStrain(npcnode);
				else
					return addWound(npcnode);
				end			
			else 
				return addStrain(npcnode);
			end
		elseif draginfo.getCustomData() == "critical" then
			return addCritical(npcnode);
		elseif draginfo.getCustomData() == "criticalvehicle" then
			return addCriticalVehicle(npcnode);			
		elseif string.find(draginfo.getCustomData(), "woundchit_") then
			addWoundsChit(npcnode, draginfo);
		elseif string.find(draginfo.getCustomData(), "strainchit_") then
			-- Check for NPC category and apply strain to nemesis, wounds to rivals and minions.
			if npcnode.getChild("npc_category") then
				if string.lower(npcnode.getChild("npc_category").getValue()) == "nemesis" then
					return addStrainChit(npcnode, draginfo);
				else
					return addWoundsChit(npcnode, draginfo);
				end			
			else 
				return addStrainChit(npcnode, draginfo);
			end								
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
			Comm.addChatMessage(msg);
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
		Comm.addChatMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addItem(npcnode, itemnode)
	if User.isHost() then	

		-- If either the personal weapon or vehicle weapon flag isn't 1 then set it to 0 - needed when not present for correct weapon processing
		if itemnode.createChild("isstarshipweapon", "number").getValue() ~= 1 then
			itemnode.createChild("isstarshipweapon", "number").setValue(0);
		end
		if itemnode.createChild("isweapon", "number").getValue() ~= 1 then
			itemnode.createChild("isweapon", "number").setValue(0);
		end		
	
		-- get the new item
		local newitemnode = npcnode.createChild("inventory").createChild();
		
		-- copy the item
		DatabaseManager.copyNode(itemnode, newitemnode);
		
		-- Check for starship weapon and dropping on a vehicle - automatically add to vehicles tab (i.e. enable the "Combat?" option).
		-- This is primarily for the separate vehicles entry so that there is no need for an inventory tab to manually enable "Combat?" to show the weapon.
		if npcnode.getParent().getName() == "vehicle" and newitemnode.createChild("isstarshipweapon", "number").getValue() == 1 then
			newitemnode.createChild("isequipped", "number").setValue(1);
		end
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcName(npcnode) .. " has gained the item: " .. itemnode.getChild("name").getValue();
		--Comm.addChatMessage(msg);
		-- Only deliver message to GM
		Comm.addChatMessage(msg);
		
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

function addCritical(npcnode)
--	if User.isHost() then
	
		Debug.console("Running addCritical.  npcnode = " .. npcnode.getNodeName())
	
		-- Check for NPC category and apply strain to nemesis, wounds to rivals and minions.
		if npcnode.getChild("npc_category") then
			if string.lower(npcnode.getChild("npc_category").getValue()) == "nemesis" or string.lower(npcnode.getChild("npc_category").getValue()) == "rival" then
	
				-- get the criticals node.  Used to check the number of current criticals sustained.
				local criticalsnode = npcnode.createChild("criticals");
				
				-- check for duplicates - WFRP
				--if DatabaseManager.checkForDuplicateName(criticalsnode, criticalnode) then
				--	return false;
				--end				
				
				-- Get the current number of criticals sustained.
				
				local critsSustained = criticalsnode.getChildCount();
				local modifier = critsSustained * 10;
				
				-- Roll d100 and add criticals sustained x 10.
				
				-- Set the description
				local description = "[CRITICAL]"
				
				-- build the dice table
				local dice = {};
				table.insert(dice, "d100");
				table.insert(dice, "d10");
				
				-- npc node name - used to apply result of critical in Chat Manager critical result handler
				if npcnode then
					npcnodename = npcnode.getNodeName();
				end
				
				-- throw the dice - need to handle the result in the chatmanager handler.
				ChatManager.throwDice("dice", dice, modifier, description, {npcnodename, msgidentity, gmonly});
			
			elseif string.lower(npcnode.getChild("npc_category").getValue()) == "minion" then
				-- Apply wounds equal to wounds per minion instead of critical - i.e. remove one minion.
				local woundsPerMinion = npcnode.createChild("minion.wounds_per_minion").getValue();
				local currentWounds = npcnode.createChild("wounds.current").getValue();
				local woundsToApply = 0;
				-- If current wounds for the minion group is 0 then apply wounds per minion +1 (to kill one minion).
				-- Otherwise, applying wounds per minion to the current wounds will kill one minion.
				if currentWounds == 0 then
					woundsToApply = woundsPerMinion + 1;
					if User.isHost() then
						npcnode.createChild("wounds.current").setValue(woundsToApply);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(npcnode, "wounds.current", woundsToApply)
					end					
				else
					woundsToApply = woundsPerMinion;
					if User.isHost() then
						npcnode.createChild("wounds.current").setValue(currentWounds + woundsToApply);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(npcnode, "wounds.current", currentWounds + woundsToApply)
					end					
				end
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";										
				msg.text = getNpcName(npcnode) .. " has gained a critical (" .. woundsToApply .. " wounds)"  .. extraIdentityText();
				ChatManager.deliverMessage(msg);				
			end
		end
	
	-- and return
	return true;
		
--	end
end

function addCriticalVehicle(npcnode)
--	if User.isHost() then
	
		Debug.console("Running addCriticalVehicle.  npcnode = " .. npcnode.getNodeName())
	
		-- Check for NPC category and apply strain to nemesis, wounds to rivals and minions.
		if npcnode.getChild("npc_category") then
			if string.lower(npcnode.getChild("npc_category").getValue()) == "nemesis" or string.lower(npcnode.getChild("npc_category").getValue()) == "rival" then
	
				-- get the criticals node.  Used to check the number of current criticals sustained.
				local criticalsnode = npcnode.createChild("vehicle.shipcriticals");
				
				-- check for duplicates - WFRP
				--if DatabaseManager.checkForDuplicateName(criticalsnode, criticalnode) then
				--	return false;
				--end				
				
				-- Get the current number of criticals sustained.
				
				local critsSustained = criticalsnode.getChildCount();
				local modifier = critsSustained * 10;
				
				-- Roll d100 and add criticals sustained x 10.
				
				-- Set the description
				local description = "[CRITVEHICLE]"
				
				-- build the dice table
				local dice = {};
				table.insert(dice, "d100");
				table.insert(dice, "d10");
				
				-- npc node name - used to apply result of critical in Chat Manager critical result handler
				if npcnode then
					npcnodename = npcnode.getNodeName();
				end
				
				-- throw the dice - need to handle the result in the chatmanager handler.
				ChatManager.throwDice("dice", dice, modifier, description, {npcnodename, msgidentity, gmonly});
			
			elseif string.lower(npcnode.getChild("npc_category").getValue()) == "minion" then
				-- Apply wounds equal to wounds per minion instead of critical - i.e. remove one minion.
				local woundsPerMinion = npcnode.createChild("minion.wounds_per_minion").getValue();
				local currentWounds = npcnode.createChild("wounds.current").getValue();
				local woundsToApply = 0;
				-- If current wounds for the minion group is 0 then apply wounds per minion +1 (to kill one minion).
				-- Otherwise, applying wounds per minion to the current wounds will kill one minion.
				if currentWounds == 0 then
					woundsToApply = woundsPerMinion + 1;
					if User.isHost() then
						npcnode.createChild("wounds.current").setValue(woundsToApply);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(npcnode, "wounds.current", woundsToApply)
					end					
				else
					woundsToApply = woundsPerMinion;
					if User.isHost() then
						npcnode.createChild("wounds.current").setValue(currentWounds + woundsToApply);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(npcnode, "wounds.current", currentWounds + woundsToApply)
					end					
				end
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";										
				msg.text = getNpcName(npcnode) .. " has gained a critical (" .. woundsToApply .. " wounds)"  .. extraIdentityText();
				ChatManager.deliverMessage(msg);				
			end
		end
	
	-- and return
	return true;
		
--	end
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

function addStrainChit(npcnode, draginfo)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then

		--Debug.console("customdata = " .. draginfo.getCustomData());
	
		if string.find(draginfo.getCustomData(), "strainchit_soak") then
			local strainChitValue = "[Damage: " .. string.gsub(draginfo.getCustomData(),"strainchit_soak_", "") .. "]";
			addStrainWithSoak(npcnode, strainChitValue);
			return true;
		end
		
		-- Add strain, ignoring soak

		-- get the strain npcnode
		local strainnode = npcnode.createChild("strain.current", "number");
		if strainnode then
		
			local strainChitValue = string.gsub(draginfo.getCustomData(),"strainchit_nosoak_", "");
			--Debug.console("Strainchit value = " .. strainChitValue);
			
			local modifier = ModifierStack.getSum();
			
			--Debug.console("Modifier = " .. modifier);
			
			ModifierStack.reset();
			
			local damage = strainChitValue + modifier;
			
			if damage > 0 then
				-- increase the character's strain
				if User.isHost() then
					strainnode.setValue(strainnode.getValue() + damage);
				else
					-- Player doesn't own the NPC database record, so need to pass this to the GM to update
					PlayerDBManager.updateNonOwnedDB(strainnode, "", strainnode.getValue() + damage)
				end				
			end				
	

			-- print a message
			local msg = {};
			msg.font = "msgfont";				
			if damage > 0 then 
				msg.text = getNpcName(npcnode) .. " has gained " .. damage .." strain" .. extraIdentityText();
			else
				msg.text = getNpcName(npcnode) .. " has not taken any strain"
			end
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
--	end
end

function addStrainWithSoak(npcnode, strain)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then	
		if not addStrainRunning then
			addStrainRunning = true;
			-- get the strain npcnode
			local strainnode = npcnode.createChild("strain.current", "number");
			if strainnode then
				local sDamage = string.match(strain, "%[Damage:%s*(%w+)%]");
				local soaknode = npcnode.createChild("armour.soak", "number");
				local damage = 0;
				-- Add modifier stack, then reset stack.
				local modifier = ModifierStack.getSum();
				--Debug.console("Modifier = " .. modifier);
				ModifierStack.reset();				
				if soaknode then
					damage = tonumber(sDamage) - soaknode.getValue() + modifier;
				else
					damage = tonumber(sDamage) + modifier;
				end
				
				if damage > 0 then
					-- increase the npc's strain
					if User.isHost() then
						strainnode.setValue(strainnode.getValue() + damage);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(strainnode, "", strainnode.getValue() + damage)
					end					
				end
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";
				if damage > 0 then 
					msg.text = getNpcName(npcnode) .. " has gained " .. damage .." strain" .. extraIdentityText();
				else
					msg.text = getNpcName(npcnode) .. " has not taken any strain"
				end
				ChatManager.deliverMessage(msg);
				
				-- and return
				addStrainRunning = false;
				return true;
			end
		end
--	end
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

function addWoundsChit(npcnode, draginfo)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then	
	
		Debug.console("getNumberData = ".. draginfo.getNumberData());
		
		if string.find(draginfo.getCustomData(), "strainchit_") then
			--Debug.console("Changing strainchit custom data to woundchit. ".. draginfo.getCustomData());
			local newDragInfo = string.gsub(draginfo.getCustomData(),"strainchit_", "woundchit_");
			draginfo.setCustomData(newDragInfo);
			--Debug.console("draginfo customdata = " .. draginfo.getCustomData());			
		end
	
		if string.find(draginfo.getCustomData(), "woundchit_soak") then
			local woundChitValue = "[Damage: " .. string.gsub(draginfo.getCustomData(),"woundchit_soak_", "") .. "]";
			addWounds(npcnode, woundChitValue);
			return true;
		end
		
		-- Add wounds, ignoring soak.

		-- get the wounds npcnode
		local woundsnode = npcnode.createChild("wounds.current", "number");
		if woundsnode then
		
			local woundChitValue = string.gsub(draginfo.getCustomData(),"woundchit_nosoak_", "");
			Debug.console("Woundchit value = " .. woundChitValue);
			
			-- Add modifier stack, then reset stack.
			local modifier = ModifierStack.getSum();
			--Debug.console("Modifier = " .. modifier);
			ModifierStack.reset();
			
			local damage = woundChitValue + modifier;
			
			if damage > 0 then
				-- increase the character's strain
					if User.isHost() then
						woundsnode.setValue(woundsnode.getValue() + damage);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(woundsnode, "", woundsnode.getValue() + damage)
					end				
			end				

			-- print a message
			local msg = {};
			msg.font = "msgfont";	
			if damage > 0 then 
				msg.text = getNpcName(npcnode) .. " has gained " .. damage .." wound/s" .. extraIdentityText();
			else
				msg.text = getNpcName(npcnode) .. " has not taken any wounds"
			end				
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
--	end
end

function addWounds(npcnode, wounds)
	Debug.console("addWounds.  NPC node = " .. npcnode.getNodeName());
	-- Adds wounds, taking soak into account.
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then	
		if not addWoundsRunning then
			addWoundsRunning = true;
			-- get the wounds npcnode
			local woundsnode = npcnode.createChild("wounds.current", "number");
			if woundsnode then
				local sDamage = string.match(wounds, "%[Damage:%s*(%w+)%]");
				local soaknode = npcnode.createChild("armour.soak", "number");
				local damage = 0;
				-- Add modifier stack, then reset stack.
				local modifier = ModifierStack.getSum();
				--Debug.console("Modifier = " .. modifier);
				ModifierStack.reset();				
				if soaknode then
					damage = tonumber(sDamage) - soaknode.getValue() + modifier;
				else
					damage = tonumber(sDamage) + modifier;
				end
				if damage > 0 then
					-- increase the characters wounds
					if User.isHost() then
						woundsnode.setValue(woundsnode.getValue() + damage);
					else
						-- Player doesn't own the NPC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(woundsnode, "", woundsnode.getValue() + damage)
					end
				end
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";
				if damage > 0 then 
						msg.text = getNpcName(npcnode) .. " has gained " .. damage .." wound/s" .. extraIdentityText();
				else
					msg.text = getNpcName(npcnode) .. " has not taken any damage"
				end
				ChatManager.deliverMessage(msg);
				
				-- and return
				addWoundsRunning = false;
				return true;
			end
		end
--	end
end

function extraIdentityText()
	-- Adds the PC, player or GM identity to wound/strain reported.  Indicates which PC/Player or NPC identity applied the wounds/strain.
	-- Also provides a level of auditing for the GM - they'll know which PC/Player applied strains/wounds. 
	if User.isHost() then
		return " from " .. GmIdentityManager.getCurrent();	
	elseif User.getIdentityLabel() then
		return " from " .. User.getIdentityLabel();
	elseif User.getUsername() then
		return " from " .. User.getUsername();
	end
	
	return "";
end

function getIdentityName(characternode)
	return characternode.getName();
end

function addAbility(npcnode, abilitynode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then	

		-- get the abilities node
		local abilitiesnode = npcnode.createChild("abilities");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(abilitiesnode, abilitynode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add ability as " .. getNpcName(npcnode) .. " already has ability: " .. abilitynode.getChild("name").getValue();
			Comm.addChatMessage(msg);
			return true;
		end		
	
		-- get the new ability
		local newabilitynode = abilitiesnode.createChild();

		-- copy the ability
		DatabaseManager.copyNode(abilitynode, newabilitynode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcName(npcnode) .. " has gained the species/special ability: " .. abilitynode.getChild("name").getValue();
		Comm.addChatMessage(msg);
		
		-- and return
		return true;		
	end
end

function addTalent(npcnode, talentnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then	

		-- get the abilities node
		local talentsnode = npcnode.createChild("talents");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(talentsnode, talentnode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add talent as " .. getNpcName(npcnode) .. " already has talent: " .. talentnode.getChild("name").getValue();
			Comm.addChatMessage(msg);
			return true;
		end		
	
		-- get the new talent
		local newtalentnode = talentsnode.createChild();

		-- copy the talent
		DatabaseManager.copyNode(talentnode, newtalentnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcName(npcnode) .. " has gained the talent: " .. talentnode.getChild("name").getValue();
		Comm.addChatMessage(msg);
		
		-- and return
		return true;		
	end
end

function addVehicle(npcnode, vehiclenode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(npcnode)) then	

		-- get the npcVehicleNode node
		local npcVehicleNode = npcnode.createChild("vehicle");
		
		-- The current information will be overwritten with the new info in the dragged vehiclenode
		-- Entries in the inventory will be added to the NPC inventory - these should just be vehicle weapons.
		
		-- check for duplicates
		--if DatabaseManager.checkForDuplicateName(talentsnode, talentnode) then
			-- print a message
			--local msg = {};
			--msg.font = "msgfont";										
			--msg.text = "Cannot add talent as " .. getNpcName(npcnode) .. " already has talent: " .. talentnode.getChild("name").getValue();
			--Comm.addChatMessage(msg);
			--return true;
		--end		
		
		-- Need to use a temporary node to hold the new vehicle information - we'll remove the inventory information for the copy of the vehicle information.
		DB.deleteNode("temp.npcvehicle");
		local tempVehicleNode = DB.createNode("temp.npcvehicle");
		if not tempVehicleNode then
			return nil;
		end		
		DB.copyNode(vehiclenode, tempVehicleNode);
		
		-- Find the inventory node, copy it to a temp inventory node and then delete it from the vehicle record
		--local inventoryNode;  -- Will hold the vehicle inventory for copying to the NPC inventory
		DB.deleteNode("temp.npcvehicleinventory");
		local inventoryNode = DB.createNode("temp.npcvehicleinventory");
		if not inventoryNode then
			return nil;
		end		
		local tempInventoryNode = tempVehicleNode.getChild("inventory");
		if tempInventoryNode then
			DB.copyNode(tempInventoryNode, inventoryNode);
			tempInventoryNode.delete();
		end		
	
		-- get the new vehicle
		local newvehiclenode = npcnode.createChild("vehicle");

		-- copy the temp vehicle node (doesn't contain the vehicle inventory);
		DB.copyNode(tempVehicleNode, newvehiclenode);
		
		-- Create and set showvehicleinct = 1 as a default when adding a vehicle to the NPC
		newvehiclenode.createChild("showvehicleinct", "number").setValue(1);
		
		-- Remove any vehicle weapons from the current NPC inventory that have been assigned to the vehicle tab.  This assumes these weapons were for the previous vehicle.
		local npcInventoryNode = npcnode.createChild("inventory");
		if npcInventoryNode then
			for k, v in pairs(npcInventoryNode.getChildren()) do
				if v.createChild("isstarshipweapon", "number").getValue() == 1 and v.createChild("isequipped", "number").getValue() == 1 then
					v.delete();
				end
			end
		end		
		
		-- Handle copying the vehicle inventory to the NPC inventory.  Should just be vehicle weapons to enable processing of the weapons on the vehicle sheet.
		if inventoryNode then
			for k, v in pairs(inventoryNode.getChildren()) do
				childInventoryNode = npcInventoryNode.createChild();
				DB.copyNode(v, childInventoryNode);
			end
		end

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getNpcName(npcnode) .. " has gained the vehicle: " .. vehiclenode.getChild("name").getValue();
		Comm.addChatMessage(msg);
		
		-- and return
		return true;		
	end
end

--function addWounds(characternode, wounds)
--	Debug.console("npcmanager.lua: addWounds.");
--	if User.isLocal() then
--		Debug.console("User is local.");
--	end
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then
--		if not addWoundsRunning then
--			addWoundsRunning = true;
			-- get the wounds characternode
--			local woundsnode = characternode.createChild("wounds.current", "number");
--			if woundsnode then
--				local sDamage = string.match(wounds, "%[Damage:%s*(%w+)%]");
--				local soaknode = characternode.createChild("armour.soak", "number");
--				local damage = 0;
--				if soaknode then
--					damage = tonumber(sDamage) - soaknode.getValue();
--				else
--					damage = tonumber(sDamage);
--				end
--				if damage > 0 then
--					-- increase the characters wounds
--					woundsnode.setValue(woundsnode.getValue() + damage);
--				end
--				
--				-- print a message
--				local msg = {};
--				msg.font = "msgfont";
--				if damage > 0 then 
--					msg.text = getNpcName(characternode) .. " has gained " .. damage .." wounds";
--				else
--					msg.text = getNpcName(characternode) .. " has not taken any damage."
--				end
--				Comm.addChatMessage(msg);
--				
--				-- and return
--				addWoundsRunning = false;
--				return true;
--			end
--		end
--	end
--end
