local SPECIAL_MSGTYPE_ADDPLAYERDICE = "addplayerdice";
local SPECIAL_MSGTYPE_PCSELECTED = "pcselected";

local addWoundsRunning = false;

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

	--Debug.console("charactermanager.lua:onDrop: Type = " .. draginfo.getType());

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
		
		-- Ability
		if class == "ability" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addAbility(characternode, recordnode);
			end
		end
		
		-- Blessing
		if class == "blessing" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addBlessing(characternode, recordnode);
			end
		end
		
		-- Melee
		if class == "melee" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMelee(characternode, recordnode);
			end
		end
		
		-- Ranged
		if class == "ranged" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRanged(characternode, recordnode);
			end
		end
		
		-- Social
		if class == "social" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSocial(characternode, recordnode);
			end
		end
		
		-- Spell
		if class == "spell" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSpell(characternode, recordnode);
			end
		end
		
		-- Support
		if class == "support" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSupport(characternode, recordnode);
			end
		end
		
		-- Career
		if class == "career" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCareer(characternode, recordnode)
			end
		end
		
		-- Condition
		if class == "condition" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCondition(characternode, recordnode);
			end
		end
		
		-- Critical
		if class == "critical" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addCritical(characternode, recordnode);
			end
		end
		
		-- Disease
		if class == "disease" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addDisease(characternode, recordnode);
			end
		end
		
		-- Insanity
		if class == "insanity" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addInsanity(characternode, recordnode);
			end
		end
		
		-- Invention
		if class == "invention" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addInvention(characternode, recordnode);
			end
		end
		
		-- Item
		if class == "item" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addItem(characternode, recordnode);
			end
		end
		
		-- Miscast
		if class == "miscast" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMiscast(characternode, recordnode);
			end
		end
		
		-- Mutation
		if class == "mutation" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addMutation(characternode, recordnode);
			end
		end
		
		-- Skill
		if class == "skill" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addSkill(characternode, recordnode);
			end
		end
		
		-- Faith
		if class == "faith" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addFaith(characternode, recordnode);
			end
		end
		
		-- Focus
		if class == "focus" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addFocus(characternode, recordnode);
			end
		end
		
		-- Oath
		if class == "oath" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addOath(characternode, recordnode);
			end
		end
		
		-- Order
		if class == "order" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addOrder(characternode, recordnode);
			end
		end
		
		-- Reputation
		if class == "reputation" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addReputation(characternode, recordnode);
			end
		end
		
		-- Tactic
		if class == "tactic" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addTactic(characternode, recordnode);
			end
		end
		
		-- Pet
		if class == "pet" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addPet(characternode, recordnode);
			end
		end
		
		-- Horse
		if class == "horse" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addHorse(characternode, recordnode);
			end
		end
		
		-- Retainer
		if class == "retainer" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRetainer(characternode, recordnode);
			end
		end
		
		-- Rune
		if class == "rune" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return addRune(characternode, recordnode);
			end		
		end

		-- Share
		local class, recordname = draginfo.getShortcutData();
		return shareWindow(characternode, class, recordname);
	end		

	-- Chits
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "fortune" then
			return addFortune(characternode);
		elseif draginfo.getCustomData() == "stress" then
			return addStress(characternode);
		elseif draginfo.getCustomData() == "fatigue" then
			return addFatigue(characternode);
		elseif draginfo.getCustomData() == "wound" then
			return addWound(characternode);
		elseif draginfo.getCustomData() == "strain" then
			return addStrain(characternode);
		elseif draginfo.getCustomData() == "power" then
			return addPower(characternode);
		elseif draginfo.getCustomData() == "favour" then
			return addFavour(characternode);
		elseif draginfo.getCustomData() == "corruption" then
			return addCorruption(characternode);
		elseif draginfo.getCustomData() == "crown" then
			return addGold(characternode);
		elseif draginfo.getCustomData() == "shilling" then
			return addSilver(characternode);
		elseif draginfo.getCustomData() == "penny" then
			return addBrass(characternode);
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
		
		-- send to the user
		msg.sender = "<whisper>";
		ChatManager.deliverMessage(msg, User.getIdentityOwner(getIdentityName(characternode)));
		
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

function addFortune(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the fortune characternode
		local currentnode = characternode.createChild("fortune.current", "number");
		local maximumnode = characternode.createChild("fortune.maximum", "number");		
		if currentnode and maximumnode then
		
			-- get the fortune values
			local currentvalue = currentnode.getValue();
			local maximumvalue = maximumnode.getValue();
			
			-- increase the characters fortune if required
			if maximumvalue > currentvalue then
			
				-- increase the characters fortune
				currentnode.setValue(currentvalue + 1);

				-- print a message
				local msg = {};
				msg.font = "msgfont";								
				msg.text = getCharacterName(characternode) .. " has gained fortune";
				ChatManager.deliverMessage(msg);
			
				-- and return
				return true;
			end
		end
	end
end

function addStress(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the stress characternode
		local stressnode = characternode.createChild("stress", "number");
		if stressnode then

			-- increase the characters stress
			stressnode.setValue(stressnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained stress";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
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

function addFatigue(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the fatigue characternode
		local fatiguenode = characternode.createChild("fatigue", "number");
		if fatiguenode then

			-- increase the characters fatigue
			fatiguenode.setValue(fatiguenode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained fatigue";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
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

function addWounds(characternode, wounds)
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
					msg.text = getCharacterName(characternode) .. " has gained " .. damage .." wounds";
				else
					msg.text = getCharacterName(characternode) .. " has not taken any damage."
				end
				ChatManager.deliverMessage(msg);
				
				-- and return
				addWoundsRunning = false;
				return true;
			end
		end
	end
end

function addPower(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then		

		-- get the power characternode
		local powernode = characternode.createChild("power", "number");
		if powernode then

			-- increase the characters power
			powernode.setValue(powernode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained power";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addFavour(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the favour characternode
		local favournode = characternode.createChild("favour", "number");
		if favournode then

			-- increase the characters favour
			favournode.setValue(favournode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained favour";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addCorruption(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the corruption characternode
		local corruptionnode = characternode.createChild("corruption.current", "number");
		if corruptionnode then

			-- increase the characters corruption
			corruptionnode.setValue(corruptionnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained corruption";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addAbility(characternode, abilitynode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the abilities node
		local abilitiesnode = characternode.createChild("abilities");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(abilitiesnode, abilitynode) then
			return false;
		end		
	
		-- get the new ability
		local newabilitynode = abilitiesnode.createChild();

		-- copy the ability
		DatabaseManager.copyNode(abilitynode, newabilitynode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the ability: " .. abilitynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;		
	end
end

function addBlessing(characternode, blessingnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the blessing node
		local blessingsnode = characternode.createChild("blessings");
	
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
		msg.text = getCharacterName(characternode) .. " has gained the blessing action: " .. blessingnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addMelee(characternode, meleenode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the melee node
		local meleesnode = characternode.createChild("melee");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the melee action: " .. meleenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addRanged(characternode, rangednode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the ranged node
		local rangesnode = characternode.createChild("ranged");
	
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
		msg.text = getCharacterName(characternode) .. " has gained the ranged action: " .. rangednode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSocial(characternode, socialnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the social node
		local socialsnode = characternode.createChild("social");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(socialsnode, socialnode) then
			return false;
		end		
	
		-- get the new social
		local newsocialnode = characternode.createChild("social").createChild();
		
		-- copy the social
		DatabaseManager.copyNode(socialnode, newsocialnode);
	
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the social action: " .. socialnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSpell(characternode, spellnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the spells node
		local spellsnode = characternode.createChild("spells");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the spell action: " .. spellnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addSupport(characternode, supportnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the support node
		local supportsnode = characternode.createChild("support");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the support action: " .. supportnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;	
	end
end

function addCareer(characternode, careernode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the careers node
		local careersnode = characternode.createChild("careers");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(careersnode, careernode) then
			return false;
		end
	
		-- get the new career
		local newcareernode = careersnode.createChild();
		
		-- copy the career
		DatabaseManager.copyNode(careernode, newcareernode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the career: " .. careernode.getChild("name").getValue();
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

function addCritical(characternode, criticalnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the criticals node
		local criticalsnode = characternode.createChild("criticals");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the critical: " .. criticalnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- now ensure that the number of character wounds is not below the number of criticals
		local woundsnode = characternode.createChild("wounds.current", "number");
		if woundsnode then
			local woundsvalue = woundsnode.getValue();
			local criticalsvalue = criticalsnode.getChildCount();
			if woundsvalue < criticalsvalue then
				woundsnode.setValue(criticalsvalue);
			end
		end		
		
		-- and return
		return true;
		
	end
end

function addDisease(characternode, diseasenode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the diseases node
		local diseasesnode = characternode.createChild("diseases");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the disease: " .. diseasenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addInsanity(characternode, insanitynode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the insanities node
		local insanitiesnode = characternode.createChild("insanities");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the insanity: " .. insanitynode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addInvention(characternode, inventionnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the inventions node
		local inventionsnode = characternode.createChild("inventions");
	
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(inventionsnode, inventionnode) then
			return false;
		end	
	
		-- get the new invention
		local newinventionnode = inventionsnode.createChild();

		-- copy the invention
		DatabaseManager.copyNode(inventionnode, newinventionnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the invention: " .. inventionnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addItem(characternode, itemnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the new item
		local newitemnode = characternode.createChild("inventory").createChild();
		
		-- copy the item
		DatabaseManager.copyNode(itemnode, newitemnode);
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the item: " .. itemnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	end
end

function addMiscast(characternode, miscastnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the miscasts node
		local miscastsnode = characternode.createChild("miscasts");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the miscast: " .. miscastnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	end
end

function addMutation(characternode, mutationnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the mutations node
		local mutationsnode = characternode.createChild("mutations");
		
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
		msg.text = getCharacterName(characternode) .. " has gained the mutation: " .. mutationnode.getChild("name").getValue();
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

function addFaith(characternode, faithnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the faiths node
		local faithsnode = characternode.createChild("faiths");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(faithsnode, faithnode) then
			return false;
		end		
	
		-- get the new faith
		local newfaithnode = faithsnode.createChild();
		
		-- copy the faith
		DatabaseManager.copyNode(faithnode, newfaithnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the faith: " .. faithnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addFocus(characternode, focusnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the focuses node
		local focusesnode = characternode.createChild("focuses");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(focusesnode, focusnode) then
			return false;
		end		
	
		-- get the new focus
		local newfocusnode = focusesnode.createChild();
		
		-- copy the focus
		DatabaseManager.copyNode(focusnode, newfocusnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the focus: " .. focusnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addOath(characternode, oathnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the oaths node
		local oathsnode = characternode.createChild("oaths");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(oathsnode, oathnode) then
			return false;
		end		
	
		-- get the new skill
		local newoathnode = oathsnode.createChild();
		
		-- copy the oath
		DatabaseManager.copyNode(oathnode, newoathnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the oath: " .. oathnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addOrder(characternode, ordernode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the orders node
		local ordersnode = characternode.createChild("orders");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(ordersnode, ordernode) then
			return false;
		end		
	
		-- get the new skill
		local newordernode = characternode.createChild("orders").createChild();
		
		-- copy the oath
		DatabaseManager.copyNode(ordernode, newordernode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the order: " .. ordernode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addReputation(characternode, reputationnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the reputations node
		local reputationsnode = characternode.createChild("reputations");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(reputationsnode, reputationnode) then
			return false;
		end		
	
		-- get the new skill
		local newreputationnode = reputationsnode.createChild();
		
		-- copy the reputation
		DatabaseManager.copyNode(reputationnode, newreputationnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the reputation: " .. reputationnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addTactic(characternode, tacticnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the tactics node
		local tacticsnode = characternode.createChild("tactics");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(tacticsnode, tacticnode) then
			return false;
		end		
	
		-- get the new skill
		local newtacticnode = tacticsnode.createChild();
		
		-- copy the tactic
		DatabaseManager.copyNode(tacticnode, newtacticnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the tactic: " .. tacticnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addPet(characternode, petnode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the pets node
		local petsnode = characternode.createChild("pets");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(petsnode, petnode) then
			return false;
		end		
		
		-- get the new skill
		local newpetnode = petsnode.createChild();
		
		-- copy the pet
		DatabaseManager.copyNode(petnode, newpetnode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the pet: " .. petnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addHorse(characternode, horsenode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the horses node
		local horsesnode = characternode.createChild("horses");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(horsesnode, horsenode) then
			return false;
		end		
		
		-- get the new skill
		local newhorsenode = horsesnode.createChild();
		
		-- copy the horse
		DatabaseManager.copyNode(horsenode, newhorsenode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the horse: " .. horsenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addRetainer(characternode, retainernode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the retainers node
		local retainersnode = characternode.createChild("retainers");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(retainersnode, retainernode) then
			return false;
		end		
		
		-- get the new skill
		local newretainernode = retainersnode.createChild();
		
		-- copy the retainer
		DatabaseManager.copyNode(retainernode, newretainernode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the retainer: " .. retainernode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addRune(characternode, runenode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	
	
		-- get the runes node
		local runesnode = characternode.createChild("runes");
		
		-- check for duplicates
		if DatabaseManager.checkForDuplicateName(runesnode, runenode) then
			return false;
		end		
		
		-- get the new skill
		local newrunenode = runesnode.createChild();
		
		-- copy the rune
		DatabaseManager.copyNode(runenode, newrunenode);

		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = getCharacterName(characternode) .. " has gained the rune: " .. runenode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
		
	end
end

function addGold(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the gold characternode
		local goldnode = characternode.createChild("currency.gold", "number");
		if goldnode then

			-- increase the characters gold
			goldnode.setValue(goldnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained a gold crown";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addSilver(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the silver characternode
		local silvernode = characternode.createChild("currency.silver", "number");
		if silvernode then

			-- increase the characters silver
			silvernode.setValue(silvernode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained a silver shilling";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
	end
end

function addBrass(characternode)
	if User.isHost() or User.isLocal() or User.isOwnedIdentity(getIdentityName(characternode)) then	

		-- get the brass characternode
		local brassnode = characternode.createChild("currency.brass", "number");
		if brassnode then

			-- increase the characters brass
			brassnode.setValue(brassnode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";											
			msg.text = getCharacterName(characternode) .. " has gained a brass penny";
			ChatManager.deliverMessage(msg);
			
			-- and return
			return true;
		end
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

function movePowerToEquilibrium(characternode)
	if characternode and characternode.isOwner() then
		local ordersnode = characternode.createChild("orders");
		if ordersnode and ordersnode.getChildCount() > 0 then
			local willpowernode = characternode.createChild("willpower.current", "number");
			local powernode = characternode.createChild("power", "number");
			if willpowernode and powernode then
				local willpowervalue = willpowernode.getValue();
				local powervalue = powernode.getValue();
				if powervalue < willpowervalue then
				
					-- increase power
					powernode.setValue(powervalue + 1);
					
					-- display a message
					local msg = {};
					msg.font = "msgfont";					
					msg.text = getCharacterName(characternode) .. "'s power has moved towards equilibrium";
					ChatManager.deliverMessage(msg);
					
					-- and return
					return true;			
				
				end
			end
		end
	end
end

function moveFavourToEquilibrium(characternode)
	if characternode and characternode.isOwner() then
		local faithsnode = characternode.createChild("faiths");
		if faithsnode and faithsnode.getChildCount() > 0 then
			local willpowernode = characternode.createChild("willpower.current", "number");
			local favournode = characternode.createChild("favour", "number");
			if willpowernode and favournode then
				local willpowervalue = willpowernode.getValue();
				local favourvalue = favournode.getValue();
				if favourvalue < willpowervalue then
				
					-- increase favour
					favournode.setValue(favourvalue + 1);
					
					-- display a message
					local msg = {};
					msg.font = "msgfont";					
					msg.text = getCharacterName(characternode) .. "'s favour has moved towards equilibrium";
					ChatManager.deliverMessage(msg);
					
					-- and return
					return true;			
				
				end
			end
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