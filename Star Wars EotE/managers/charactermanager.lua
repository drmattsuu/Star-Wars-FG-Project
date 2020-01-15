local SPECIAL_MSGTYPE_ADDPLAYERDICE = "addplayerdice";
local SPECIAL_MSGTYPE_PCSELECTED = "pcselected";

local addWoundsRunning = false;
local addStrainRunning = false;

function onInit()
	if User.isHost() or User.isLocal() then
		DB.createNode("charsheet");
		User.onLogin = onLogin;
	end
	if not User.isLocal() then
		ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_ADDPLAYERDICE, handleAddPlayerDice);	
		ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_PCSELECTED, handlePCSelected);
	end
end

function import()
	local file = Interface.dialogFileOpen();
	if file then
	
		-- delete the existing import node if required
		local importnode = DB.findNode("import");
		if importnode then
			importnode.delete();
		end
		
		-- create a new import node
		importnode = DB.createNode("import");
		if importnode then

			-- import the character to the temporary node
			DB.import(file, "import", "character");
		
			-- process each imported character
			for k, n in pairs(importnode.getChildren()) do
				importCharacter(n);
			end
		
			-- and delete the import node
			importnode.delete();
		end
	end
end

function importCharacter(sourcenode)
	cleanCharacter(sourcenode);
	DatabaseManager.upgradeCharacter(sourcenode);
	local destinationnode = DB.findNode("charsheet").createChild();
	DatabaseManager.copyNode(sourcenode, destinationnode);
end

function cleanCharacter(characternode)
	cleanCharacterNode(characternode);
end

function cleanCharacterNode(node)
	if node and node.isOwner() then
		for k, n in pairs(node.getChildren()) do
			cleanCharacterNode(n);
		end	
	
		-- clean up nodes
		if node.getName() == "currentrecharge" then
			if not string.find(node.getNodeName(), "insanities") then
				node.setValue(0);
			end
		elseif node.getName() == "socketed" then
			node.setValue(0);
		elseif node.getName() == "recordname" then
			node.delete();
		elseif node.getName() == "class" then
			node.delete();
		elseif node.getName() == "actor" then
			node.delete();
		end

	end
end

function export(characternode)
	local file = Interface.dialogFileSave();
	if file then
		if characternode then
			DB.export(file, characternode, "character");
		else
			DB.export(file, "charsheet", "character", true);
		end
	end
end

function playerSelectedPC(characternode, username)

	local msgparams = {};
	msgparams[1] = username;		
	msgparams[2] = characternode.getNodeName();
	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_PCSELECTED, msgparams)

end

function handlePCSelected(msguser, msgidentity, msgparams)

	if User.isHost() then

		local username = msgparams[1];
		local characternode = DB.findNode(msgparams[2]);
		
		Debug.console("charactermanager.lua - handlePCSelected.  username = " .. username .. ", character node = " .. msgparams[2]);
		
		DB.addHolder(characternode, username, True);	
	end

end

function openCharacterSheet(characternode, identity)
	--Debug.console("chractermanager.lua - openCharacterSheet.  Control Identity = " .. identity);
	-- Old code on next line - databasenode.isOwner doesn't seem to work when initial ownership of a character occurs.  Fixed in FG 3.0.2.
	--if characternode and characternode.isOwner() then
	if User.isHost() or User.isOwnedIdentity(identity) then
		local charactersheetwindowreference = Interface.findWindow("charsheet", characternode.getNodeName());
		if not charactersheetwindowreference then
			Interface.openWindow("charsheet", characternode);
			-- Call the OOB message so that the GM can give this player ownership of the character in the database.
			playerSelectedPC(characternode, User.getUsername());
			-- Change name in diebox viewer - need to tell the GM to rebuild the die box viewer
			DieBoxViewListManager.remoteRebuildDieBoxData();			
		else
			charactersheetwindowreference.close();		
		end
	end
end

function getIdentityName(characternode)
	return characternode.getName();
end

function getCharacterNode(identityname)
	return DB.findNode("charsheet." .. identityname);
end

function getCharacterName(characternode)
	local name = "";
	local namenode = characternode.getChild("name");
	if namenode then
		name = namenode.getValue();
	end
	if name == "" then
		name = "- Unnamed -";
	end
	return name;
end

function onDrop(characternode, x, y, draginfo)

	Debug.console("charactermanager.lua:onDrop: Type = " .. draginfo.getType());

	-- Added to allow dragging of damage (type = wounds) drag data.
	if draginfo.isType("wounds") then
		--Debug.console("charactermanager.lua:onDrop: description = " .. draginfo.getDescription());
		if draginfo.getDescription() then
			return addWounds(characternode, draginfo.getDescription());		
		end
	end

	-- String
	if draginfo.isType("string") then
		return sendWhisper(characternode, draginfo.getStringData());
	end
		
	-- Portrait selection
	if draginfo.isType("portraitselection") then
		return setPortrait(characternode, draginfo.getStringData());
	end

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();
		Debug.console("charactermanager.lua:onDrop: shortcut class = " .. class);
		
		-- Ability
		if class == "ability" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addAbility(characternode, recordnode);
			end
		end
		
		-- Talent
		if class == "talent" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addTalent(characternode, recordnode);
			end
		end		
		
		-- Obligation
		if class == "obligation" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addObligation(characternode, recordnode);
			end
		end	
		
		-- Duty
		if class == "duty" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addDuty(characternode, recordnode);
			end
		end

		-- Morality
		if class == "morality" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMorality(characternode, recordnode);
			end
		end

		-- Motivation
		if class == "motivation" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMotivation(characternode, recordnode);
			end
		end		
		
		-- Condition
		if class == "condition" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCondition(characternode, recordnode);
			end
		end
		
		-- Item
		if class == "item" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addItem(characternode, recordnode);
			end
		end
		
		-- Skill
		if class == "skill" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSkill(characternode, recordnode);
			end
		end
		
		-- Rune
		if class == "rune" then
--			local recordnode = DB.findNode(recordname);
--			if recordnode then
--				return addRune(characternode, recordnode);
--			end		
			return true;
		end
		
		-- Vehicle
		if class == "vehicle" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addVehicle(characternode, recordnode);
			end
		end		

		-- Share
		local class, recordname = draginfo.getShortcutData();
		return shareWindow(characternode, class, recordname);
	end		

	-- Chits
	if draginfo.isType("chit") then
		Debug.console("draginfo.getCustomData() = " .. draginfo.getCustomData());
		if draginfo.getCustomData() == "wound" then
			return addWound(characternode);
		elseif draginfo.getCustomData() == "strain" then
			return addStrain(characternode);
		elseif draginfo.getCustomData() == "critical" then
			return addCritical(characternode);
		elseif draginfo.getCustomData() == "criticalvehicle" then
			return addCriticalVehicle(characternode);			
		elseif string.find(draginfo.getCustomData(), "woundchit_") then
			addWoundsChit(characternode, draginfo);
		elseif string.find(draginfo.getCustomData(), "strainchit_") then
			addStrainChit(characternode, draginfo);			
		end		
	end
	
	-- Dice
	if draginfo.isType("dice") then
		local dice = draginfo.getDieList();
		if dice then
			return addPlayerDice(characternode, dice);
		end	
	end
	
end

function sendWhisper(characternode, message)
	if User.isHost() or User.isLocal() then
	
		-- generate a message
		local msg = {};
		msg.text = message;
		msg.font = "msgfont";
		
		Debug.console("Sending whisper to: ", User.getIdentityOwner(getIdentityName(characternode)));
		
		-- send to the user
		msg.sender = "<whisper>";
		Comm.deliverChatMessage(msg, User.getIdentityOwner(getIdentityName(characternode)));
		
		-- add to the hosts chat window
		msg.sender = "-> " .. User.getIdentityLabel(getIdentityName(characternode));
		ChatManager.addMessage(msg);
		
		-- and return
		return true;
	end
end

function setPortrait(characternode, portrait)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then
	
		-- set the portrait
		User.setPortrait(getIdentityName(characternode), portrait);	
		
		-- and return
		return true;
	end
end

function shareWindow(characternode, class, recordname)
	if User.isHost() or User.isLocal() then
		local win = Interface.openWindow(class, recordname);
		if win then
		
			-- share the window
			local identityOwner = User.getIdentityOwner(getIdentityName(characternode));
			if identityOwner then
				win.share(identityOwner);
			end
			
			-- and return
			return true;
		end
	end
end

function endOfTurn(characternode)
	local actionperformed = nil;
	if removeRecharge(characternode) then
		actionperformed = true;
	end
	if movePowerToEquilibrium(characternode) then
		actionperformed = true;
	end
	if moveFavourToEquilibrium(characternode) then
		actionperformed = nil;
	end
	return actionperformed;
end

function removeRecharge(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then
		if removeChildRecharge(characternode) then
			local msg = {};
			msg.font = "msgfont";					
			msg.text = "Recharge has been removed from " .. getCharacterName(characternode);
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
			if not string.find(node.getNodeName(), "insanities") and not string.find(node.getNodeName(), "pets") and not string.find(node.getNodeName(), "horses") and not string.find(node.getNodeName(), "retainers") then
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

function addStrain(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the strain characternode
		local strainnode = characternode.createChild("strain.current", "number");
		if strainnode then

			-- increase the characters stress
			strainnode.setValue(strainnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained strain";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addCritical(characternode)

	Debug.console("Running addCritical.  characternode = " .. characternode.getNodeName());
	
--	if User.isHost() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
			-- get the criticals node.  Used to check the number of current criticals sustained.
			local criticalsnode = characternode.createChild("criticals");
			
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
			
			-- character node name - used to apply result of critical in Chat Manager critical result handler
			if characternode then
				characternodename = characternode.getNodeName();
			end
			
			-- throw the dice - need to handle the result in the chatmanager handler.
			ChatManager.throwDice("dice", dice, modifier, description, {characternodename, msgidentity, gmonly});

		-- and return
		return true;
		
--	end
end

function addCriticalVehicle(characternode)

	Debug.console("Running addCriticalVehicle.  characternode = " .. characternode.getNodeName());
	
--	if User.isHost() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
			-- get the criticals node.  Used to check the number of current criticals sustained.
			local criticalsnode = characternode.createChild("vehicle.shipcriticals");
			
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
			
			-- character node name - used to apply result of critical in Chat Manager critical result handler
			if characternode then
				characternodename = characternode.getNodeName();
			end
			
			-- throw the dice - need to handle the result in the chatmanager handler.
			ChatManager.throwDice("dice", dice, modifier, description, {characternodename, msgidentity, gmonly});

		-- and return
		return true;
		
--	end
end

function addWound(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the wounds characternode
		local woundsnode = characternode.createChild("wounds.current", "number");
		if woundsnode then

			-- increase the characters wounds
			woundsnode.setValue(woundsnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained a wound";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addWoundsChit(characternode, draginfo)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		if string.find(draginfo.getCustomData(), "woundchit_soak") then
			local woundChitValue = "[Damage: " .. string.gsub(draginfo.getCustomData(),"woundchit_soak_", "") .. "]";
			addWounds(characternode, woundChitValue);
			return true;
		end
		
		-- Adding wounds without soak.

		-- get the wounds characternode
		local woundsnode = characternode.createChild("wounds.current", "number");
		if woundsnode then
		
			local woundChitValue = string.gsub(draginfo.getCustomData(),"woundchit_nosoak_", "");
			--Debug.console("Woundchit value = " .. woundChitValue);
			
			-- Add modifier stack, then reset stack.
			local modifier = ModifierStack.getSum();
			--Debug.console("Modifier = " .. modifier);
			ModifierStack.reset();	

			local damage = woundChitValue + modifier;
			
			if damage > 0 then
				-- increase the character's wounds
				if User.isHost() or User.isOwnedIdentity(getIdentityName(characternode)) then
					woundsnode.setValue(woundsnode.getValue() + damage);
				else
					-- Player doesn't own the PC database record, so need to pass this to the GM to update
					PlayerDBManager.updateNonOwnedDB(woundsnode, "", woundsnode.getValue() + damage)
				end				
			end			

			-- print a message
			local msg = {};
			msg.font = "msgfont";							
			if damage > 0 then 
				msg.text = getCharacterName(characternode) .. " has gained " .. damage .." wound/s" .. NpcManager.extraIdentityText();
			else
				msg.text = getCharacterName(characternode) .. " has not taken any wounds"
			end			
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
--	end
end

function addWounds(characternode, wounds)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
		if not addWoundsRunning then
			addWoundsRunning = true;
			-- get the wounds characternode
			local woundsnode = characternode.createChild("wounds.current", "number");
			if woundsnode then
				local sDamage = string.match(wounds, "%[Damage:%s*(%w+)%]");
				local soaknode = characternode.createChild("armour.soak", "number");
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
					-- increase the character's wounds
					if User.isHost() or User.isOwnedIdentity(getIdentityName(characternode)) then
						woundsnode.setValue(woundsnode.getValue() + damage);
					else
						-- Player doesn't own the PC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(woundsnode, "", woundsnode.getValue() + damage)
					end				
				end				
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";
				if damage > 0 then 
					msg.text = getCharacterName(characternode) .. " has gained " .. damage .." wound/s" .. NpcManager.extraIdentityText();
				else
					msg.text = getCharacterName(characternode) .. " has not taken any damage"
				end
				ChatManager.deliverMessage(msg);
				
				-- and return
				addWoundsRunning = false;
				return true;
			end
		end
--	end
end

function addStrainChit(characternode, draginfo)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		if string.find(draginfo.getCustomData(), "strainchit_soak") then
			local strainChitValue = "[Damage: " .. string.gsub(draginfo.getCustomData(),"strainchit_soak_", "") .. "]";
			addStrainWithSoak(characternode, strainChitValue);
			return true;
		end
		
		-- Adding strain without soak.

		-- get the strain characternode
		local strainnode = characternode.createChild("strain.current", "number");
		if strainnode then
		
			local strainChitValue = string.gsub(draginfo.getCustomData(),"strainchit_nosoak_", "");
			--Debug.console("Strainchit value = " .. strainChitValue);

			-- Add modifier stack, then reset stack.
			local modifier = ModifierStack.getSum();
			--Debug.console("Modifier = " .. modifier);
			ModifierStack.reset();			
			
			local damage = strainChitValue + modifier;
			
			if damage > 0 then
				-- increase the character's strain
				if User.isHost() or User.isOwnedIdentity(getIdentityName(characternode)) then
					strainnode.setValue(strainnode.getValue() + damage);
				else
					-- Player doesn't own the PC database record, so need to pass this to the GM to update
					PlayerDBManager.updateNonOwnedDB(strainnode, "", strainnode.getValue() + damage)
				end				
			end			
		

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			if damage > 0 then 
				msg.text = getCharacterName(characternode) .. " has gained " .. damage .." strain" .. NpcManager.extraIdentityText();
			else
				msg.text = getCharacterName(characternode) .. " has not taken any strain"
			end			
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
--	end
end

function addStrainWithSoak(characternode, strain)
--	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
		if not addStrainRunning then
			addStrainRunning = true;
			-- get the strain characternode
			local strainnode = characternode.createChild("strain.current", "number");
			if strainnode then
				local sDamage = string.match(strain, "%[Damage:%s*(%w+)%]");
				local soaknode = characternode.createChild("armour.soak", "number");
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
					-- increase the character's strain
					if User.isHost() or User.isOwnedIdentity(getIdentityName(characternode)) then
						strainnode.setValue(strainnode.getValue() + damage);
					else
						-- Player doesn't own the PC database record, so need to pass this to the GM to update
						PlayerDBManager.updateNonOwnedDB(strainnode, "", strainnode.getValue() + damage)
					end				
				end	
				
				-- print a message
				local msg = {};
				msg.font = "msgfont";
				if damage > 0 then 
					msg.text = getCharacterName(characternode) .. " has gained " .. damage .." strain" .. NpcManager.extraIdentityText();
				else
					msg.text = getCharacterName(characternode) .. " has not taken any strain"
				end
				ChatManager.deliverMessage(msg);
				
				-- and return
				addStrainRunning = false;
				return true;
			end
		end
--	end
end

function addAbility(characternode, abilitynode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the abilities node
		local abilitiesnode = characternode.createChild("abilities");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(abilitiesnode, abilitynode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add ability as " .. getCharacterName(characternode) .. " already has ability: " .. abilitynode.getChild("name").getValue();
			ChatManager.deliverMessage(msg);
			return true;
		end		
	
		-- get the new ability
		local newabilitynode = abilitiesnode.createChild();

		-- copy the ability
		DatabaseManager.copyNode(abilitynode, newabilitynode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the species/special ability: " .. abilitynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addTalent(characternode, talentnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the abilities node
		local talentsnode = characternode.createChild("talents");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(talentsnode, talentnode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add talent as " .. getCharacterName(characternode) .. " already has talent: " .. talentnode.getChild("name").getValue();
			ChatManager.deliverMessage(msg);
			return true;
		end		
	
		-- get the new talent
		local newtalentnode = talentsnode.createChild();

		-- copy the talent
		DatabaseManager.copyNode(talentnode, newtalentnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the talent: " .. talentnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addObligation(characternode, obligationnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the obligations node
		local obligationsnode = characternode.createChild("obligations");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(obligationsnode, obligationnode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add obligation as " .. getCharacterName(characternode) .. " already has obligation: " .. obligationnode.getChild("name").getValue();
			ChatManager.deliverMessage(msg);
			return true;
		end		
	
		-- get the new obligation
		local newobligationnode = obligationsnode.createChild();

		-- copy the obligation
		DatabaseManager.copyNode(obligationnode, newobligationnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the obligation: " .. obligationnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addDuty(characternode, dutynode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the duties node
		local dutiesnode = characternode.createChild("duties");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(dutiesnode, dutynode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add duty as " .. getCharacterName(characternode) .. " already has duty: " .. dutynode.getChild("name").getValue();
			ChatManager.deliverMessage(msg);
			return true;
		end		
	
		-- get the new duty
		local newdutynode = dutiesnode.createChild();

		-- copy the duty
		DatabaseManager.copyNode(dutynode, newdutynode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the duty: " .. dutynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addMorality(characternode, moralitynode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the moralities node
		local moralitiesnode = characternode.createChild("moralities");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(moralitiesnode, moralitynode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add morality as " .. getCharacterName(characternode) .. " already has morality: " .. moralitynode.getChild("name").getValue();
			ChatManager.deliverMessage(msg);
			return true;
		end		
	
		-- get the new morality
		local newmoralitynode = moralitiesnode.createChild();

		-- copy the morality
		DatabaseManager.copyNode(moralitynode, newmoralitynode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the morality: " .. moralitynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addMotivation(characternode, motivationnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the motivations node
		local motivations = characternode.createChild("motivations");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(motivations, motivationnode) then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add motivation as " .. getCharacterName(characternode) .. " already has motivation: " .. motivationnode.getChild("name").getValue();
			ChatManager.deliverMessage(msg);		
			return true;
		end		
	
		-- get the new motivation
		local newmotivationnode = motivations.createChild();

		-- copy the motivation
		DatabaseManager.copyNode(motivationnode, newmotivationnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the motivation: " .. motivationnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addCondition(characternode, conditionnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the conditions node
		local conditionsnode = characternode.createChild("conditions");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the condition: " .. conditionnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addItem(characternode, itemnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- Handle trying to add a non vehicle weapon/item to a vehicle - reject the drop.
		-- Not currently available to players
		if characternode.getParent().getName() == "vehicle" and itemnode.createChild("isstarshipweapon").getValue() ~= 1 then
			-- print a message
			local msg = {};
			msg.font = "msgfont";										
			msg.text = "Cannot add the non-vehicle weapon: " .. itemnode.getChild("name").getValue() .. " to the vehicle: " .. getNpcName(characternode);
			ChatManager.deliverMessage(msg);

			return true;
		end
		
		-- get the new item
		local newitemnode = characternode.createChild("inventory").createChild();
		
		-- copy the item
		DatabaseManager.copyNode(itemnode, newitemnode);
		
		-- If either the personal weapon or vehicle weapon flag isn't 1 then set it to 0 - needed when not present for correct weapon processing
		if newitemnode.createChild("isstarshipweapon", "number").getValue() ~= 1 then
			newitemnode.createChild("isstarshipweapon", "number").setValue(0);
		end
		if newitemnode.createChild("isweapon", "number").getValue() ~= 1 then
			newitemnode.createChild("isweapon", "number").setValue(0);
		end			
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the item: " .. itemnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	end
end

function addSkill(characternode, skillnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the skills node
		local skillsnode = characternode.createChild("skills");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the skill: " .. skillnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addPlayerDice(characternode, dice)
	if User.isHost() then
		local username = User.getIdentityOwner(getIdentityName(characternode));
		if username and dice then
			local msgparams = {};
			msgparams[1] = username;		
			msgparams[2] = PreferenceManager.getValue("user_gmidentity");
			msgparams[3] = table.maxn(dice);		
			for n = 1, msgparams[3] do
				msgparams[3 + n] = dice[n].type;
			end
			ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_ADDPLAYERDICE, msgparams)			
			return true;
		end
	end
end

function handleAddPlayerDice(msguser, msgidentity, msgparams)
	if not User.isHost() then
		local username = msgparams[1];
		if User.getUsername() == username then
		
			-- get the gm identity
			local gmidentity = msgparams[2];			
			
			-- add the dice to the dice pool
			for n = 1, msgparams[3] do
				DieBoxManager.addDie(msgparams[3 + n]);
			end
		
			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = gmidentity .. " has added dice to " .. username .. "'s dice pool";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;		
		
		end
	end
end


function onLogin(username, activated)
-- Need to give the user access to all character records so that they show up on the combat tracker
-- Don't need to own them, just be a holder to them.

	Debug.console("charactermanager.lua: onLogin.");

	if User.isHost() and DB.findNode("charsheet") and activated then
		DB.addHolder(DB.findNode("charsheet"), username);
	end

end

function addVehicle(characternode, vehiclenode)
	Debug.console("Running addVehicle()");
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
		Debug.console("addVehicle() : Starting code...");

		-- get the characterVehicleNode node
		local characterVehicleNode = characternode.createChild("vehicle");
		
		-- The current information will be overwritten with the new info in the dragged vehiclenode
		-- Entries in the inventory will be added to the character inventory - these should just be vehicle weapons.
		
		-- check for duplicates
		--if DatabaseManager.checkForDuplicateName(talentsnode, talentnode) then
			-- print a message
			--local msg = {};
			--msg.font = "msgfont";										
			--msg.text = "Cannot add talent as " .. getcharacterName(characternode) .. " already has talent: " .. talentnode.getChild("name").getValue();
			--ChatManager.deliverMessage(msg);
			--return true;
		--end		
		
		-- Need to use a temporary node to hold the new vehicle information - we'll remove the inventory information for the copy of the vehicle information.
		-- Remove a previous temporary holder
		if characternode.getChild("temp.charactervehicle") then
			characternode.getChild("temp.charactervehicle").delete();
		end
		--local tempVehicleNode = DB.createNode("temp.charactervehicle");
		local tempVehicleNode = characternode.createChild("temp.charactervehicle");
		if not tempVehicleNode then
			Debug.console("addVehicle() - unable to create temporary vehicle node.");
			return nil;
		end		
		DB.copyNode(vehiclenode, tempVehicleNode);
		
		-- Find the inventory node, copy it to a temp inventory node and then delete it from the vehicle record
		--local inventoryNode;  -- Will hold the vehicle inventory for copying to the character inventory
		if characternode.getChild("temp.charactervehicleinventory") then
			characternode.getChild("temp.charactervehicleinventory").delete();
		end		
		local inventoryNode = characternode.createChild("temp.charactervehicleinventory");
		if not inventoryNode then
			Debug.console("addVehicle() - unable to create temporary inventory Node.");
			return nil;
		end		
		local tempInventoryNode = tempVehicleNode.getChild("inventory");
		if tempInventoryNode then
			DB.copyNode(tempInventoryNode, inventoryNode);
			tempInventoryNode.delete();
		end		
	
		-- get the new vehicle
		local newvehiclenode = characternode.createChild("vehicle");

		-- copy the temp vehicle node (doesn't contain the vehicle inventory);
		DB.copyNode(tempVehicleNode, newvehiclenode);
		
		-- Create and set showvehicleinct = 1 as a default when adding a vehicle to the PC
		newvehiclenode.createChild("showvehicleinct", "number").setValue(1);
		
		-- Remove any vehicle weapons from the current character inventory that have been assigned to the vehicle tab.  This assumes these weapons were for the previous vehicle.
		local characterInventoryNode = characternode.createChild("inventory");
		if characterInventoryNode then
			for k, v in pairs(characterInventoryNode.getChildren()) do
				if v.createChild("isstarshipweapon", "number").getValue() == 1 and v.createChild("isequipped", "number").getValue() == 1 then
					v.delete();
				end
			end
		end		
		
		-- Handle copying the vehicle inventory to the character inventory.  Should just be vehicle weapons to enable processing of the weapons on the vehicle sheet.
		if inventoryNode then
			for k, v in pairs(inventoryNode.getChildren()) do
				childInventoryNode = characterInventoryNode.createChild();
				DB.copyNode(v, childInventoryNode);
			end
		end
		
		-- Delete the temporary holder
		if characternode.getChild("temp.charactervehicle") then
			characternode.getChild("temp.charactervehicle").delete();
		end		

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the vehicle: " .. vehiclenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end
