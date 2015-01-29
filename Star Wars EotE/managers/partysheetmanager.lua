SPECIAL_MSGTYPE_CLEARPARTYSLOT = "clearpartyslot";
SPECIAL_MSGTYPE_UPDATEPARTYSLOT = "updatepartyslot";

local linknamenode = {};

function onInit()

	if User.isHost() then
	
		-- we need to ensure that we create all database nodes
		-- before the party sheet is opened
		-- this is to avoid an issue which occurs when a client
		-- opens the party sheet if the host has never opened it
		DB.createNode("partysheet.name", "string");
		DB.createNode("partysheet.tension.direction", "number");
		DB.createNode("partysheet.tension.stepcount", "number");
		DB.createNode("partysheet.tension.stepstate", "number");
		DB.createNode("partysheet.tension.value", "number");
		DB.createNode("partysheet.fortune", "number");

		local eventsnode = DB.createNode("partysheet.events", "formattedtext");
		if eventsnode.isOwner() and eventsnode.getValue() == "" then
			eventsnode.setValue("<p></p>");
		end
		
		local abilitynode = DB.createNode("partysheet.ability", "formattedtext");
		if abilitynode.isOwner() and abilitynode.getValue() == "" then
			abilitynode.setValue("<p></p>");
		end
		
		-- build the slots
		for slotnumber = 1, 4 do
		
			-- build the socket details
			DB.createNode("partysheet.sockets." .. slotnumber, "string");
		
			-- build the slot details
			DB.createNode("partysheet.slots." .. slotnumber .. ".class", "string");
			DB.createNode("partysheet.slots." .. slotnumber .. ".name", "string");
			DB.createNode("partysheet.slots." .. slotnumber .. ".currentrecharge", "number");
			local recordnamenode = DB.createNode("partysheet.slots." .. slotnumber .. ".recordname", "string");
			
			-- get the link name node
			linknamenode[slotnumber] = DB.findNode(recordnamenode.getValue() .. ".name");
			if linknamenode[slotnumber] then
				linknamenode[slotnumber].onUpdate = updatePartySlotNames;	
			end
		end
		
		-- subscrive to the user login event
		--User.onLogin = onLogin;

	end
	
	-- register special messages
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_CLEARPARTYSLOT, handleClearPartySlot);
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATEPARTYSLOT, handleUpdatePartySlot);
end

function onLogin(username, activated)
	if User.isHost() and activated then
		DB.findNode("partysheet").addHolder(username);	
		for slotnumber = 1, 4 do		
			local recordnamenode = DB.createNode("partysheet.slots." .. slotnumber .. ".recordname", "string");
			local recordnode = DB.findNode(recordnamenode.getValue());
			if recordnode then
				recordnode.addHolder(username);			
			end
		end
	end
end

function getPartySheetName()
	return DB.findNode("partysheet.name").getValue();
end

function openPartySheet()
	local partysheetwindowreference = Interface.findWindow("partysheet", "partysheet");				
	if not partysheetwindowreference then
		Interface.openWindow("partysheet", "partysheet");
	else
		partysheetwindowreference.close();
	end
end

function clearPartySlot(slotnumber)
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_CLEARPARTYSLOT, {slotnumber});
end

function handleClearPartySlot(msguser, msgidentity, msgparams)
	if User.isHost() then
	
		-- get the message paramters
		local slotnumber = msgparams[1];
		
		-- determine if there is still recharge on the slot
		local rechargenode = DB.createNode("partysheet.slots." .. slotnumber .. ".currentrecharge", "number");
		if rechargenode and rechargenode.getValue() == 0 then
			
			-- get the class and recordname nodes
			local classnode = DB.createNode("partysheet.slots." .. slotnumber .. ".class", "string");
			local recordnamenode = DB.createNode("partysheet.slots." .. slotnumber .. ".recordname", "string");

			-- clear the existing socketed value
			local linktalentnode = DB.findNode(recordnamenode.getValue());
			if linktalentnode then	
				local linksocketednode = linktalentnode.createChild("socketed", "number");
				if linksocketednode then
					linksocketednode.setValue(0);
				end
			end

			-- clear the link name node
			linknamenode[slotnumber] = nil;

			-- clear the class and recordname values
			classnode.setValue("");
			recordnamenode.setValue("");		
			
			-- and update slot names
			updatePartySlotNames(nil);
			
		end
	end
	return true;
end

function updatePartySlot(slotnumber, class, recordname)
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_UPDATEPARTYSLOT, {slotnumber, class, recordname});
end

function handleUpdatePartySlot(msguser, msgidentity, msgparams)
	if User.isHost() then
	
		-- get the message parameters
		local slotnumber = msgparams[1];
		local class = msgparams[2];
		local recordname = msgparams[3];
		
		-- get the slot type
		local typenode = DB.findNode("partysheet.sockets." .. slotnumber);
		if typenode then
		
			-- determine if the dropped type matches the slot type
			if string.lower(typenode.getValue()) == string.lower(class) or string.lower(class) == "invention" then
			
				-- get the class and recordname nodes
				local classnode = DB.createNode("partysheet.slots." .. slotnumber .. ".class", "string");
				local recordnamenode = DB.createNode("partysheet.slots." .. slotnumber .. ".recordname", "string");
							
				-- clear the existing socketed value
				local linktalentexistingnode = DB.findNode(recordnamenode.getValue());
				if linktalentexistingnode and not linktalentexistingnode.isStatic() then
					local linksocketedexistingnode = linktalentexistingnode.createChild("socketed", "number");
					if linksocketedexistingnode then
						linksocketedexistingnode.setValue(0);
					end
				end
					
				-- set the new socketed value
				local linktalentnewnode = DB.findNode(recordname);
				if linktalentnewnode and not linktalentnewnode.isStatic() then			
					local linksocketednewnode = linktalentnewnode.createChild("socketed", "number");
					if linksocketednewnode then
						linksocketednewnode.setValue(1);
						for k, v in ipairs(UserManager.getCurrentUsers()) do
							linktalentnewnode.addHolder(v);
						end							
					end
				end

				-- subscribe to name changes
				linknamenode[slotnumber] = DB.findNode(recordname .. ".name");
				if linknamenode[slotnumber] then
					linknamenode[slotnumber].onUpdate = updatePartySlotNames;
				end

				-- set the new class and record names
				classnode.setValue(class);
				recordnamenode.setValue(recordname);
				
				-- and update slot names now
				updatePartySlotNames(nil);
			end
		end
	end
	return true;
end

function updatePartySlotNames(source)
	for slotnumber = 1, 4 do

		-- define the name value
		local namevalue = "";

		-- get the record name node
		local recordnamenode = DB.createNode("partysheet.slots." .. slotnumber .. ".recordname", "string");

		-- get the slot name node
		local linknamenode = DB.findNode(recordnamenode.getValue());
		if linknamenode then
			linknamenode = linknamenode.getChild("name");
			if linknamenode then
				namevalue = linknamenode.getValue();
			end
		end
	
		-- get the name node
		local namenode = DB.createNode("partysheet.slots." .. slotnumber .. ".name", "string");
			
		-- set the name
		namenode.setValue(namevalue);
	end
end

function onDrop(x, y, draginfo)

	-- Shortcuts
	if draginfo.isType("shortcut") then
		local class, recordname = draginfo.getShortcutData();

		-- Party Sheet
		if class == "partysheet" then
			local recordnode = DB.findNode(recordname);
			if recordnode then
				return setPartySheet(recordnode);
			end
		end
		
		-- Item
		if class == "item" then			
			local recordnode = DB.findNode(recordname);
			if recordnode then				
				return addItem(recordnode);
			end
		end
		
	end
	
		
	-- Chits
	if draginfo.isType("chit") then
		if draginfo.getCustomData() == "fortune" then
			return addFortune();
		elseif draginfo.getCustomData() == "stress" then
			return addStress();
		elseif draginfo.getCustomData() == "fatigue" then
			return addFatigue();
		elseif draginfo.getCustomData() == "wound" then
			return addWound();
		elseif draginfo.getCustomData() == "power" then
			return addPower();
		elseif draginfo.getCustomData() == "favour" then
			return addFavour();
		elseif draginfo.getCustomData() == "corruption" then
			return addCorruption();
		elseif draginfo.getCustomData() == "crown" then
			return addGold();
		elseif draginfo.getCustomData() == "shilling" then
			return addSilver();
		elseif draginfo.getCustomData() == "penny" then
			return addBrass();
		elseif draginfo.getCustomData() == "recharge" then
			return addTension();		
		end		
	end
end

function addItem(itemnode)
	--if User.isHost() then	
		
		-- get the partysheet node
		local partynode = DB.findNode("partysheet");
				
		-- get the new item
		local newitemnode = partynode.createChild("inventory").createChild();
		
		-- copy the item
		DatabaseManager.copyNode(itemnode, newitemnode);
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";										
		msg.text = "The party has gained the item: " .. itemnode.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;

	--end
end

function addFortune()
	if User.isHost() then

		-- get the partysheet node
		local node = DB.findNode("partysheet");

		-- get the fortune node
		local fortunenode = node.createChild("fortune", "number");
		if fortunenode then

			-- increase the characters fortune
			fortunenode.setValue(fortunenode.getValue() + 1);

			-- print a message
			local msg = {};
			msg.font = "msgfont";			
			msg.text = "The party has gained fortune";
			ChatManager.deliverMessage(msg);

			-- and return
			return true;

		end
	end
end

function addTension()
	if User.isHost() then
	
		-- get the partysheet node
		local node = DB.findNode("partysheet");

		-- get the tension node
		local tensionnode = node.createChild("tension.value", "number");
		if tensionnode then
		
			-- increase the party tension
			tensionnode.setValue(tensionnode.getValue() + 1);
			
			-- print a message
			local msg = {};
			msg.font = "msgfont";			
			msg.text = "The party tension has increased";
			ChatManager.deliverMessage(msg);

			-- and return
			return true;			
		end
	end
end

function addStress()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addStress(characternode);
			end
		end
		return true;
	end
end

function addFatigue()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addFatigue(characternode);
			end
		end
		return true;
	end
end

function addWound()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addWound(characternode);
			end
		end
		return true;
	end
end

function addPower()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addPower(characternode);
			end
		end
		return true;
	end
end

function addFavour()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addFavour(characternode);
			end
		end
		return true;
	end
end

function addCorruption()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addCorruption(characternode);
			end
		end
		return true;
	end
end

function addGold()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addGold(characternode);
			end
		end
		return true;
	end
end

function addSilver()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addSilver(characternode);
			end
		end
		return true;
	end
end

function addBrass()
	if User.isHost() then
		for k, v in pairs(User.getAllActiveIdentities()) do
			local characternode = CharacterManager.getCharacterNode(v);
			if characternode then
				CharacterManager.addBrass(characternode);
			end
		end
		return true;
	end
end

function endOfTurn()
	local actionperformed = nil;
	if removeRecharge() then
		actionperformed = true;
	end
	return actionperformed;
end

function removeRecharge()
	if User.isHost() then
		local node = DB.findNode("partysheet");
		if node and node.isOwner() then
			if removeChildRecharge(node) then
				local msg = {};
				msg.font = "msgfont";					
				msg.text = "Recharge has been removed from the party";
				ChatManager.deliverMessage(msg);
				return true;				
			end
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

function setPartySheet(node)
	if User.isHost() then

		-- copy the partysheet
		DatabaseManager.copyNode(node, DB.findNode("partysheet"));

		-- print a message
		local msg = {};
		msg.font = "msgfont";					
		msg.text = "The party has changed to " .. node.getChild("name").getValue();
		ChatManager.deliverMessage(msg);
		
		-- and return
		return true;
	end
end