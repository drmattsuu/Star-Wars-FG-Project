SPECIAL_MSGTYPE_DICE = "dice";
SPECIAL_MSGTYPE_ACTION = "action";
SPECIAL_MSGTYPE_CHARACTERISTIC = "characteristic";
SPECIAL_MSGTYPE_SKILL = "skill";
SPECIAL_MSGTYPE_SPECIALISATION = "specialisation";

-- Used to pass rolled initiative to the InitiativeManager script using the Special Message functionality so the GM can act on the player's roll
SPECIAL_MSGTYPE_UPDATEACTORINIT = "updateactorinit";

--
--
-- INITIALIZATION
--
--

function onInit()

	-- register the comm handlers
	Comm.onReceiveOOBMessage = processSpecialMessage

	-- register slash handlers
	registerSlashHandler("whisper", processWhisper);
	registerSlashHandler("die", processDie);
	
	-- register autocomplete handlers
	registerAutocompleteHandler(autocompleteIdentityName);
	
	-- register dice handlers
	registerDiceHandler(SPECIAL_MSGTYPE_DICE, processDiceLanded);
	registerDiceHandler(SPECIAL_MSGTYPE_ACTION, processDiceLanded);
	registerDiceHandler(SPECIAL_MSGTYPE_CHARACTERISTIC, processDiceLanded);
	registerDiceHandler(SPECIAL_MSGTYPE_SKILL, processDiceLanded);
	registerDiceHandler(SPECIAL_MSGTYPE_SPECIALISATION, processDiceLanded);
	
	-- register for module activation requests
	if User.isHost() then
		Module.onActivationRequested = moduleActivationRequested;
	end
	Module.onUnloadedReference = moduleUnloadedReference;

	-- register special messages
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_UPDATEACTORINIT, handleUpdateActorInit);	
	
end

function registerEntryControl(ctrl)
	entrycontrol = ctrl;
end

function deliverMessage(msg)
	Comm.deliverChatMessage(msg);
end

function addMessage(msg)
	Comm.addChatMessage(msg);
end

function throwDice(dragtype, dice, modifier, description, customdata)
	Comm.throwDice(dragtype, dice, modifier, description, customdata);
end

--
--
-- SLASH COMMANDS HANDLING
--
--

function registerSlashHandler(command, callback)
	Comm.registerSlashHandler(command, callback);
end

--
--
-- SPECIAL MESSAGE COMMANDS HANDLING
--
--

SPECIAL_MSG_TAG = "[SPECIAL]";
SPECIAL_MSG_SEP = "|||";

specialmessagehandlers = {};

function registerSpecialMessageHandler(msgtype, callback)
	if not specialmessagehandlers[msgtype] then
		specialmessagehandlers[msgtype] = {};
	end
	table.insert(specialmessagehandlers[msgtype], callback);
end

function unregisterSpecialMessageHandler(msgtype, callback)
	Debug.console("chatmanager.lua: unregisterSpecialMessageHandler. msgtype = " .. msgtype .. ", function = " .. string.dump(callback));
	if specialmessagehandlers[msgtype] then		
		--Debug.console("chatmanager.lua: unregisterSpecialMessageHandler.  Before delete - specialmessagehandlers table = " .. table.concat(specialmessagehandlers[msgtype], ", "));	
		for k, v in pairs(specialmessagehandlers[msgtype]) do
			if v == callback then
				Debug.console("chatmanager.lua: unregisterSpecialMessageHandler.  Handler deleted. ");
				specialmessagehandlers[msgtype][k] = nil;
			end
		end
		--Debug.console("chatmanager.lua: unregisterSpecialMessageHandler.  After delete - specialmessagehandlers table = " .. table.concat(specialmessagehandlers[msgtype], ", "));
	end
end

function sendSpecialMessage(msgtype, msgparams)

	Debug.console("chatmanager.lua: sendSpecialMessage - msgtype = " .. msgtype);

	-- Build the special message to send
	local msg = {};
	
	-- type
	msg.type = msgtype;
	
	-- username
	msg.username = User.getUsername();
	
	-- identity
	if User.isHost() then
		local gmid, isgm = GmIdentityManager.getCurrent();
		msg.identity = gmid;
	else
		msg.identity = User.getIdentityLabel();
		if not msg.identity then
			msg.identity = "";
		end
	end

	-- message parameters
	msg.params = "";
	if msgparams then
		for k, v in ipairs(msgparams) do
			msg.params = msg.params .. v .. SPECIAL_MSG_SEP;
		end
	end

	-- deliver the message
	if User.isLocal() then	
		processSpecialMessage(msg);
	else
		Comm.deliverOOBMessage(msg);
	end
end

function processSpecialMessage(msg)
	-- get the message details
	local msgtype = msg.type;
	local msguser = msg.username;
	local msgidentity = msg.identity;

	-- parse out the special message parameters
	local msgparams = {};		
	local msg_clause;		
	local clause_match = "(.-)" .. SPECIAL_MSG_SEP;	
	for msg_clause in string.gmatch(msg.params, clause_match) do
		table.insert(msgparams, msg_clause);
	end
	
	-- Handle the special message
	return handleSpecialMessage(msgtype, msguser, msgidentity, msgparams);
end

function handleSpecialMessage(msgtype, msguser, msgidentity, msgparams)
	if specialmessagehandlers[msgtype] then		
		for k, v in pairs(specialmessagehandlers[msgtype]) do
			--Debug.console("chatmanager.lua: handleSpecialMessage.  Calling function with msguser = " .. msguser .. ", msgidentity = " .. msgidentity);
			v(msguser, msgidentity, msgparams);
		end
		return true;
	end
	return false;
end

--
--
-- DICE HANDLERS
--
--

dicehandlers = {};

function registerDiceHandler(droptype, callback)
	dicehandlers[droptype] = callback;
end

function unregisterDiceHandler(droptype, callback)
	dicehandlers[droptype] = nil;
end

function getDiceHandler(draginfo)
	for droptype, handler in pairs(dicehandlers) do
		if draginfo.isType(droptype) then
			return handler;
		end
	end
	
	return nil;
end

--
--
-- AUTOCOMPLETE HANDLERS
--
--

autocompletehandlers = {}

function resetAutocompleteHandlers()
	autocompletehandlers = {};
end

function registerAutocompleteHandler(callback)
	table.insert(autocompletehandlers, callback);
end

function unregisterAutocompleteHandler(callback)
	for k, v in pairs(autocompletehandlers) do
		if v == callback then
			autocompletehandlers[k] = nil;
		end
	end
end

--
--
-- AUTOCOMPLETE
--
--

function doAutocomplete()
	local buffer = entrycontrol.getValue();
	local spacepos = string.find(string.reverse(buffer), " ", 1, true);
	
	local search = "";
	local remainder = buffer;
	
	if spacepos then
		search = string.sub(buffer, #buffer - spacepos + 2);
		remainder = string.sub(buffer, 1, #buffer - spacepos + 1);
	else
		search = buffer;
		remainder = "";
	end

	-- Call handlers
	for k, v in pairs(autocompletehandlers) do
		if v then
			local result = v(search);
			if type(result) == "string" then
				local replacement = remainder .. result;
				entrycontrol.setValue(replacement);
				entrycontrol.setCursorPosition(#replacement + 1);
				entrycontrol.setSelectionPosition(#replacement + 1);
				return;
			end
		end
	end
	
end

function autocompleteIdentityName(search)
	-- Check identities
	for k, v in ipairs(User.getAllActiveIdentities()) do
		local label = User.getIdentityLabel(v);
		if label and string.find(string.lower(label), string.lower(search), 1, true) == 1 then
			return label;
		end
	end
end

--
--
-- WHISPER
--
--

function processWhisper(command, params)
	if User.isHost() then
		local msg = {};
		msg.font = "msgfont";

		local spacepos = string.find(params, " ", 1, true);
		if spacepos then
			local recipient = string.sub(params, 1, spacepos-1);
			local originalrecipient = recipient;
			local message = string.sub(params, spacepos+1);

			-- Find user
			local user = nil;

			for k, v in ipairs(User.getAllActiveIdentities()) do
				local label = User.getIdentityLabel(v);
				if string.lower(label) == string.lower(originalrecipient) then
					-- Direct match
					user = User.getIdentityOwner(v);
					if user then
						recipient = label;
						break;
					end
				elseif not user and string.find(string.lower(label), string.lower(recipient), 1, true) == 1 then
					-- Partial match
					user = User.getIdentityOwner(v);
					if user then
						recipient = label;
					end
				end
			end

			if user then
				Debug.console("User for whisper = " .. user);
				msg.text = message;

				msg.sender = "<heard whisper>";
				Comm.deliverChatMessage(msg, user);

				msg.sender = "-> " .. recipient;
				addMessage(msg);
				
				return;
			end

			msg.font = "systemfont";
			msg.text = "Whisper recipient not found";
			addMessage(msg);
			
			return;
		end

		msg.font = "systemfont";
		msg.text = "Usage: /whisper [recipient] [message]";
		addMessage(msg);
	else
		-- Disable any form of player whisper.
		local msg = {};
		msg.font = "systemfont";
		msg.text = "I'm sorry, whispers from players currently doesn't work.  Only GMs can whisper to players at present.  This feature will become available at a future time when this ruleset is layered on top of CoreRPG.";
		addMessage(msg);
		--local msg = {};
		--msg.font = "msgfont";
		--msg.text = params;

		--msg.sender = User.getIdentityLabel();
		--deliverMessage(msg, "");

		--msg.sender = "<sent whisper>";
		--addMessage(msg);
	end
end

--
--
-- MODULE ACTIVATION
--
--

function moduleActivationRequested(module)
	local msg = {};
	msg.text = "Players have requested permission to load '" .. module .. "'";
	msg.font = "systemfont";
	msg.icon = "indicator_moduleloaded";
	addMessage(msg);
end

function moduleUnloadedReference(module)
	local msg = {};
	msg.text = "Could not open sheet with data from unloaded module '" .. module .. "'";
	msg.font = "systemfont";
	addMessage(msg);
end

--
-- 
-- DICE
--
--

local revealalldice = true;

-- Added to allow the diebox.lua script to determine if the /die reveal or /die hide slash commands are active
function gmDieHide()
	return not revealalldice;
end

-- Added to allow the setting dice reveal state
function gmRevealDieRolls(reveal)
	revealalldice = reveal;
end

function processDie(command, params)
	if User.isHost() then
		if params == "reveal" then
			revealalldice = true;

			local msg = {};
			msg.font = "systemfont";
			msg.text = "Revealing all die rolls";
			addMessage(msg);

			return;
		end
		if params == "hide" then
			revealalldice = false;

			local msg = {};
			msg.font = "systemfont";
			msg.text = "Hiding all die rolls";
			addMessage(msg);

			return;
		end
	end

	local diestring, descriptionstring = string.match(params, "%s*(%S+)%s*(.*)");
	
	if not diestring then
		local msg = {};
		msg.font = "systemfont";
		msg.text = "Usage: /die [dice] [description]";
		addMessage(msg);
		return;
	end
	
	local dice = {};
	local modifier = 0;
	
	for s, m, d in string.gmatch(diestring, "([%+%-]?)(%d*)(%w*)") do
		if m == "" and d == "" then
			break;
		end

		if d ~= "" then
			for i = 1, tonumber(m) or 1 do
				table.insert(dice, d);
				if d == "d100" then
					table.insert(dice, "d10");
				end
			end
		else
			if s == "-" then
				modifier = modifier - m;
			else
				modifier = modifier + m;
			end
		end
	end

	if #dice == 0 then
		local msg = {};
		
		msg.font = "systemfont";
		msg.text = descriptionstring;
		msg.dice = {};
		msg.diemodifier = modifier;
		msg.dicesecret = false;

		if User.isHost() then
			msg.sender = GmIdentityManager.getCurrent();
		else
			msg.sender = User.getIdentityLabel();
		end
	
		deliverMessage(msg);
	else
		throwDice("dice", dice, modifier, descriptionstring);
	end
end

function processDiceLanded(draginfo)
	ModifierStack.applyModifierStackToRoll(draginfo);
	return processDice(draginfo);
end

function processDice(draginfo)

	-- get the message details
	local type = draginfo.getType();
	local description = draginfo.getDescription();
	local modifier = draginfo.getNumberData();
	local sourcenode = draginfo.getDatabaseNode();
	local gmonly = false;
	
	Debug.console("processDice - draginfo = ", draginfo);
	
	-- Used to track success and advantages for initiative in the form of <successes>.<advantages>
	local initiativecount = 0;
	
	-- get the identity
	local identity = User.getIdentityLabel();
	if not identity then
		identity = User.getUsername();
	end
	if User.isHost() then
		local gmid, isgm = GmIdentityManager.getCurrent();
		identity = gmid;
	end	

	-- get the custom data
	local customdata = draginfo.getCustomData();
	if customdata then
		if customdata[1] then
			local sourcenodename = customdata[1];
			sourcenode = DB.findNode(sourcenodename);
		end
		if customdata[2] then
			identity = customdata[2];
		end
		if customdata[3] then
			gmonly = customdata[3];
		end
	end

	-- build the result dice table
	local dice = draginfo.getDieList();
	local resultdice = {};
	for k,v in ipairs(dice) do
		processResultDie(resultdice, v);
	end
	
	-- get the character node
	local characternode = nil;
	if sourcenode then
		if type == SPECIAL_MSGTYPE_ACTION then
			characternode = sourcenode.getParent().getParent();
		elseif type == SPECIAL_MSGTYPE_CHARACTERISTIC then
			characternode = sourcenode.getParent().getParent();		
		elseif type == SPECIAL_MSGTYPE_SKILL then
			characternode = sourcenode.getParent().getParent();		
		elseif type == SPECIAL_MSGTYPE_SPECIALISATION then
			characternode = sourcenode.getParent().getParent().getParent().getParent();		
		end
	end
	
	-- update the identity if we found the character node
	if characternode then
		local namenode = characternode.getChild("name");
		if namenode then
			identity = namenode.getValue();
		end
	end
	
	-- determine if a dice summary should be displayed
	--local showsummary = PreferenceManager.getValue("interface_showdiceresultsummary");
	-- Removed preference as ruleset automation relies on getting roll summary data (init rolls, damage calc, etc.).
	local showsummary = true;
	
	-- space the message
	local spacerMsg = {};
	spacerMsg.font = "narratorfont";
	spacerMsg.text = "";
	spacerMsg.dicesecret = gmonly;
	if User.isHost() and (gmonly or not revealalldice) then	
		addMessage(spacerMsg);
	else
		deliverMessage(spacerMsg);
	end

	-- build the header message	
	if identity ~= "" then		
	
		-- build the header message
		local headerMsg = {};
		headerMsg.font = "narratorfont";
		headerMsg.sender = identity;
		headerMsg.text = description;
		headerMsg.dicesecret = gmonly;
		if User.isHost() and (gmonly or not revealalldice) then	
			addMessage(headerMsg);
		else
			deliverMessage(headerMsg);
		end
		
	end
	
	-- build our dice result message
	local resultMsg = {};
	if showsummary then
		resultMsg.text = "Result:";
	end

	-- Crit rolls are just d100 rolls, no need to show the special dice summary.  Plus show total of the roll.
	if string.find(description, "CRITICAL") or string.find(description, "CRITVEHICLE") then
		showsummary = false;
		resultMsg.dicedisplay = 1;
	end
	
	resultMsg.font = "chatitalicfont";			
	resultMsg.dice = resultdice;
	resultMsg.diemodifier = modifier;
	resultMsg.dicesecret = gmonly;
	if User.isHost() and (gmonly or not revealalldice) then	
		addMessage(resultMsg);
	else
		deliverMessage(resultMsg);
	end


	
	-- determine if we need to show the summary details
	if showsummary then
	
		-- build our summary results	
		local resultSummary = {};
		resultSummary.success = 0;
		resultSummary.boon = 0;
		resultSummary.chaos = 0;
		resultSummary.delay = 0;
		resultSummary.exertion = 0;
		resultSummary.comet = 0;			
		for k,v in ipairs(resultdice) do
			processSummaryDie(resultSummary, v);
		end

		-- build the success dice table
		local successDice = {};
		if resultSummary.success ~= 0 then		
			for n = 1, math.abs(resultSummary.success) do
				local successDie = {};
				if resultSummary.success > 0 then
					successDie.type = "dSummary.7";
				else
					successDie.type = "dSummary.2";
				end
				successDie.result = 0;
				table.insert(successDice, successDie);
			end
		end

		-- build the success message			
		local successMsg = {};
		if resultSummary.success > 0 then
			successMsg.text = "Success:";
		else
			successMsg.text = "Failure:";				
		end
		if resultSummary.success ~= 0 then
			successMsg.dice = successDice;		
		end
		successMsg.font = "chatitalicfont";
		successMsg.dicesecret = gmonly;
		if User.isHost() and (gmonly or not revealalldice) then	
			addMessage(successMsg);
		else
			deliverMessage(successMsg);
		end

		-- process our boons
		if resultSummary.boon ~= 0 then

			-- build the boon dice table
			local boonDice = {};
			for n = 1, math.abs(resultSummary.boon) do
				local boonDie = {};
				if resultSummary.boon > 0 then
					boonDie.type = "dSummary.6";
				else
					boonDie.type = "dSummary.3";
				end
				boonDie.result = 0;
				table.insert(boonDice, boonDie);
			end

			-- build the boon message			
			local boonMsg = {};
			if resultSummary.boon > 0 then			
				boonMsg.text = "Advantage:";
				-- TODO - Launch advantage info/spend window
				Debug.console("TODO - Launch advantage info/spend window. Advantages = "  .. resultSummary.boon);
			else
				boonMsg.text = "Threat:";
				-- TODO - Launch threat info/spend window.  How to do this for the PCs when the GM rolls threat for an NPC?
				Debug.console("TODO - Launch threat info/spend window. Threat = "  .. resultSummary.boon);
			end
			boonMsg.font = "chatitalicfont";
			boonMsg.dice = boonDice;
			boonMsg.dicesecret = gmonly;
			if User.isHost() and (gmonly or not revealalldice) then	
				addMessage(boonMsg);
			else
				deliverMessage(boonMsg);
			end

		end

		-- process our specials
		if resultSummary.comet ~= 0 or resultSummary.exertion ~= 0 or resultSummary.delay ~= 0 or resultSummary.chaos ~= 0 then

			-- build the special dice table
			local specialDice = {};
			for n = 1, math.abs(resultSummary.comet) do
				-- Star Wars Triumph
				local specialDie = {};
				specialDie.type = "dSummary.8";
				specialDie.result = 0;
				table.insert(specialDice, specialDie);
				-- TODO - Launch Triumph info/spend window.
				Debug.console("TODO - Launch Triumph info/spend window.");				
			end
			for n = 1, math.abs(resultSummary.exertion) do
				local specialDie = {};
				specialDie.type = "dSummary.4";
				specialDie.result = 0;
				table.insert(specialDice, specialDie);
			end
			for n = 1, math.abs(resultSummary.delay) do
				local specialDie = {};
				specialDie.type = "dSummary.5";
				specialDie.result = 0;
				table.insert(specialDice, specialDie);
			end
			for n = 1, math.abs(resultSummary.chaos) do
				-- Star Wars Despair
				local specialDie = {};
				specialDie.type = "dSummary.1";
				specialDie.result = 0;
				table.insert(specialDice, specialDie);
				-- TODO - Launch Despair info/spend window.  How to do this for the PCs when the GM rolls threat for an NPC?
				Debug.console("TODO - Launch despair info/spend window.");				
			end

			-- build the special message			
			local specialMsg = {};
			specialMsg.text = "Special:";
			specialMsg.font = "chatitalicfont";
			specialMsg.dice = specialDice;
			specialMsg.dicesecret = gmonly;
			if User.isHost() and (gmonly or not revealalldice) then	
				addMessage(specialMsg);
			else
				deliverMessage(specialMsg);
			end
		end
		
		-- Handle initiative roll here - indicated by INIT in roll description
		if string.find(description, "INIT") then
			initiativecount = resultSummary.success + resultSummary.boon / 100;
			--Debug.console("Initiative roll = " .. initiativecount .. ", for characternode = " .. characternode.getNodeName());
			updateActorInit(characternode, initiativecount);
		end
		
		-- Handle attack roll here - indicated by ATTACK in roll description
		-- Currently only used to generate a damage result.
		if string.find(description, "ATTACK") then
			if resultSummary.success > 0 then
				local damagemsg = {};
				damagemsg.font = "msgfont";
				damagemsg.type = "wounds";
				local sDamage = "";
				--sDamage = string.match(description, "%[DAMAGE.*%((%w+)%)%]");
				sDamage = string.match(description, "%[DAMAGE:%s*(%w+)%]");
				local totaldamage = tonumber(sDamage) + resultSummary.success
				--Debug.console("Total Damage = " .. totaldamage);
				damagemsg.text = "[Damage: " .. totaldamage .. "]";
				if User.isHost() and (gmonly or not revealalldice) then	
					addMessage(damagemsg);
				else
					deliverMessage(damagemsg);
				end
			end
		end		
	end

	-- Handle critical roll here - indicated by CRITICAL in roll description
	if string.find(description, "CRITICAL") then
		Debug.console("Critical result handler.")
		Debug.console("Target node for critical = ", sourcenode);
		
		--resultMsg.dice = resultdice;
		local critModifier = resultMsg.diemodifier;
		
		local critResult = 0 + critModifier;
		
		for k,v in ipairs(resultMsg.dice) do
			critResult = critResult + v.result;
		end
		
		Debug.console("Critical result = " .. critResult)
		
		--  Determine the critical sustained from result of d100 roll plus modifiers

		local critDetails = {};
		
		for k,v in pairs(DataCommon.critical_injury_result_data) do
			if critResult >= v.d100_start and critResult <= v.d100_end then
				Debug.console("Found crit of " .. v.name);
				critDetails = v;
				break;
			end
		end		
		
		Debug.console("Crit = " .. critDetails.name .. ". Severity = " .. critDetails.severity .. ". Description = " .. critDetails.description);
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";	
		msg.type = "critical";
		
		if sourcenode.getNodeName() ~= "" then
			PlayerDBManager.createCriticalNonOwnedDB(sourcenode, critDetails.name, critDetails.description, critDetails.severity);
			if critDetails.severity == 999 then
				msg.text = NpcManager.getNpcName(sourcenode) .. " has gained the critical:  " .. critDetails.name .. NpcManager.extraIdentityText();
			else
				msg.text = NpcManager.getNpcName(sourcenode) .. " has gained the critical:  " .. critDetails.name .. ".  Severity = " .. critDetails.severity .. ", " .. NpcManager.extraIdentityText();
			end
		else
			if critDetails.severity == 999 then
				msg.text = "Critical:  " .. critDetails.name;
			else
				msg.text = "Critical:  " .. critDetails.name .. ".  Severity = " .. critDetails.severity;
			end		
		end
		ChatManager.deliverMessage(msg);
	end

	-- Handle vehicle critical roll here - indicated by CRITVEHICLE in roll description
	if string.find(description, "CRITVEHICLE") then
		Debug.console("Critical vehicle result handler.")
		Debug.console("Target node for critical = ", sourcenode);
		
		--resultMsg.dice = resultdice;
		local critModifier = resultMsg.diemodifier;
		
		local critResult = 0 + critModifier;
		
		for k,v in ipairs(resultMsg.dice) do
			critResult = critResult + v.result;
		end
		
		Debug.console("Critical result = " .. critResult)
		
		--  Determine the critical sustained from result of d100 roll plus modifiers

		local critDetails = {};
		
		for k,v in pairs(DataCommon.critical_vehicle_result_data) do
			if critResult >= v.d100_start and critResult <= v.d100_end then
				Debug.console("Found crit of " .. v.name);
				critDetails = v;
				break;
			end
		end		
		
		Debug.console("Crit = " .. critDetails.name .. ". Severity = " .. critDetails.severity .. ". Description = " .. critDetails.description);
		
		-- print a message
		local msg = {};
		msg.font = "msgfont";
		msg.type = "critvehicle";
		
		if sourcenode.getNodeName() ~= "" then		
			PlayerDBManager.createCriticalNonOwnedDB(sourcenode.createChild("vehicle"), critDetails.name, critDetails.description, critDetails.severity);
			if critDetails.severity == 999 then
				msg.text = NpcManager.getNpcName(sourcenode) .. " has gained the critical:  " .. critDetails.name .. NpcManager.extraIdentityText();
			else
				msg.text = NpcManager.getNpcName(sourcenode) .. " has gained the critical:  " .. critDetails.name .. ".  Severity = " .. critDetails.severity .. ", " .. NpcManager.extraIdentityText();
			end
		else
			if critDetails.severity == 999 then
				msg.text = "Vehicle critical:  " .. critDetails.name;
			else
				msg.text = "Vehicle critical:  " .. critDetails.name .. ".  Severity = " .. critDetails.severity;
			end		
		end
		ChatManager.deliverMessage(msg);
		

		
	end		

	-- and return true
	return true;
end

function processResultDie(dice, die)

	-- add the dice to the result
	local newDie = {};
	newDie.type = die.type .. "." .. die.result;
	newDie.result = die.result;
	Debug.console("die: type = " .. newDie.type .. ", result = " .. newDie.result);
	table.insert(dice, newDie);
	
	-- now explode the righteous success
	if newDie.type == "dExpertise.5" then
		local explodeDie = {};
		explodeDie.type = "dExpertise";
		explodeDie.result = math.random(1,6);
		processResultDie(dice, explodeDie);
	end
end

function processSummaryDie(summary, die)

	if die.type == "dChallenge.1" then
		
	elseif die.type == "dChallenge.2" then
		summary.success = summary.success - 1;
	elseif die.type == "dChallenge.3" then
		summary.success = summary.success - 1;
	elseif die.type == "dChallenge.4" then
		summary.success = summary.success - 2;
	elseif die.type == "dChallenge.5" then
		summary.success = summary.success - 2;
	elseif die.type == "dChallenge.6" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dChallenge.7" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dChallenge.8" then
		summary.boon = summary.boon - 1;
		summary.success = summary.success - 1;
	elseif die.type == "dChallenge.9" then
		summary.boon = summary.boon - 1;
		summary.success = summary.success - 1;
	elseif die.type == "dChallenge.10" then
		summary.boon = summary.boon - 2;
	elseif die.type == "dChallenge.11" then
		summary.boon = summary.boon - 2;
	elseif die.type == "dChallenge.12" then
		summary.success = summary.success - 1;
		summary.chaos = summary.chaos + 1;
	
	elseif die.type == "dBoost.3" then
		summary.boon = summary.boon + 2;	
	elseif die.type == "dBoost.4" then
		summary.boon = summary.boon + 1;	
	elseif die.type == "dBoost.5" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
	elseif die.type == "dBoost.6" then
		summary.success = summary.success + 1;	
		
	elseif die.type == "dSetback.3" then
		summary.success = summary.success - 1;	
	elseif die.type == "dSetback.4" then
		summary.success = summary.success - 1;		
	elseif die.type == "dSetback.5" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dSetback.6" then
		summary.boon = summary.boon - 1;	
	
		
	elseif die.type == "dAbility.2" then
		summary.success = summary.success + 1;	
	elseif die.type == "dAbility.3" then
		summary.success = summary.success + 1;	
	elseif die.type == "dAbility.4" then
		summary.success = summary.success + 2;	
	elseif die.type == "dAbility.5" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dAbility.6" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dAbility.7" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
	elseif die.type == "dAbility.8" then
		summary.boon = summary.boon + 2;
		
	elseif die.type == "dDifficulty.2" then
		summary.success = summary.success - 1;	
	elseif die.type == "dDifficulty.3" then
		summary.success = summary.success - 2;	
	elseif die.type == "dDifficulty.4" then
		summary.boon = summary.boon - 1;	
	elseif die.type == "dDifficulty.5" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dDifficulty.6" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dDifficulty.7" then
		summary.boon = summary.boon - 2;
	elseif die.type == "dDifficulty.8" then
		summary.success = summary.success - 1;
		summary.boon = summary.boon -1;
		
	elseif die.type == "dProficiency.2" then
		summary.success = summary.success + 1;
	elseif die.type == "dProficiency.3" then
		summary.success = summary.success + 1;
	elseif die.type == "dProficiency.4" then
		summary.success = summary.success + 2;		
	elseif die.type == "dProficiency.5" then
		summary.success = summary.success + 2;	
	elseif die.type == "dProficiency.6" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dProficiency.7" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
	elseif die.type == "dProficiency.8" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
	elseif die.type == "dProficiency.9" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
	elseif die.type == "dProficiency.10" then		
		summary.boon = summary.boon + 2;
	elseif die.type == "dProficiency.11" then		
		summary.boon = summary.boon + 2;
	elseif die.type == "dProficiency.12" then		
		summary.success = summary.success + 1;
		summary.comet = summary.comet + 1;
	
	elseif die.type == "dForce.1" then
		summary.exertion = summary.exertion + 1;		
	elseif die.type == "dForce.2" then
		summary.exertion = summary.exertion + 1;		
	elseif die.type == "dForce.3" then
		summary.exertion = summary.exertion + 1;		
	elseif die.type == "dForce.4" then
		summary.exertion = summary.exertion + 1;		
	elseif die.type == "dForce.5" then
		summary.exertion = summary.exertion + 1;		
	elseif die.type == "dForce.6" then		
		summary.exertion = summary.exertion + 1;		
	elseif die.type == "dForce.7" then
		summary.exertion = summary.exertion + 2;		
	elseif die.type == "dForce.8" then		
		summary.delay = summary.delay + 1;
	elseif die.type == "dForce.9" then		
		summary.delay = summary.delay + 1;
	elseif die.type == "dForce.10" then				
		summary.delay = summary.delay + 2;
	elseif die.type == "dForce.11" then				
		summary.delay = summary.delay + 2;
	elseif die.type == "dForce.12" then				
		summary.delay = summary.delay + 2;
		
		
	elseif die.type == "dConservative.2" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dConservative.3" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dConservative.4" then
		summary.success = summary.success + 1;
		summary.delay = summary.delay + 1;
	elseif die.type == "dConservative.5" then
		summary.success = summary.success + 1;
		summary.delay = summary.delay + 1;
	elseif die.type == "dConservative.6" then
		summary.success = summary.success + 1;
	elseif die.type == "dConservative.7" then
		summary.success = summary.success + 1;
	elseif die.type == "dConservative.8" then
		summary.success = summary.success + 1;
	elseif die.type == "dConservative.9" then
		summary.success = summary.success + 1;
	elseif die.type == "dConservative.10" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
		
	elseif die.type == "dExpertise.2" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dExpertise.3" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dExpertise.4" then
		summary.success = summary.success + 1;
	elseif die.type == "dExpertise.5" then
		summary.success = summary.success + 1;
	elseif die.type == "dExpertise.6" then
		summary.comet = summary.comet + 1;
		
	elseif die.type == "dFortune.4" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dFortune.5" then
		summary.success = summary.success + 1;
	elseif die.type == "dFortune.6" then
		summary.success = summary.success + 1;
		
	elseif die.type == "dMisfortune.1" then
		summary.success = summary.success - 1;
	elseif die.type == "dMisfortune.2" then
		summary.success = summary.success - 1;
	elseif die.type == "dMisfortune.3" then
		summary.boon = summary.boon - 1;
		
	elseif die.type == "dReckless.1" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dReckless.2" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dReckless.5" then
		summary.boon = summary.boon + 2;
	elseif die.type == "dReckless.6" then
		summary.success = summary.success + 1;
		summary.exertion = summary.exertion + 1;
	elseif die.type == "dReckless.7" then
		summary.success = summary.success + 1;
		summary.exertion = summary.exertion + 1;
	elseif die.type == "dReckless.8" then
		summary.success = summary.success + 1;
		summary.boon = summary.boon + 1;
	elseif die.type == "dReckless.9" then
		summary.success = summary.success + 2;
	elseif die.type == "dReckless.10" then
		summary.success = summary.success + 2;
		
	elseif die.type == "dSummary.1" then
		summary.chaos = summary.chaos + 1;
	elseif die.type == "dSummary.2" then
		summary.success = summary.success - 1;
	elseif die.type == "dSummary.3" then
		summary.boon = summary.boon - 1;
	elseif die.type == "dSummary.4" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "dSummary.5" then
		summary.delay = summary.delay + 1;
	elseif die.type == "dSummary.6" then
		summary.boon = summary.boon + 1;
	elseif die.type == "dSummary.7" then
		summary.success = summary.success + 1;
	elseif die.type == "dSummary.8" then
		summary.comet = summary.comet + 1;
		
	elseif die.type == "mBane.1" then
		summary.boon = summary.boon - 1;
	elseif die.type == "mBane.2" then
		summary.boon = summary.boon - 1;
	elseif die.type == "mBane.3" then
		summary.boon = summary.boon - 1;
	elseif die.type == "mBane.4" then
		summary.boon = summary.boon - 1;
	elseif die.type == "mBane.5" then
		summary.boon = summary.boon - 1;
	elseif die.type == "mBane.6" then
		summary.boon = summary.boon - 1;
		
	elseif die.type == "mBoon.1" then
		summary.boon = summary.boon + 1;
	elseif die.type == "mBoon.2" then
		summary.boon = summary.boon + 1;
	elseif die.type == "mBoon.3" then
		summary.boon = summary.boon + 1;
	elseif die.type == "mBoon.4" then
		summary.boon = summary.boon + 1;
	elseif die.type == "mBoon.5" then
		summary.boon = summary.boon + 1;
	elseif die.type == "mBoon.6" then
		summary.boon = summary.boon + 1;

	elseif die.type == "mChallenge.1" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.2" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.3" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.4" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.5" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.6" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.7" then
		summary.success = summary.success - 1;
	elseif die.type == "mChallenge.8" then
		summary.success = summary.success - 1;
		
	elseif die.type == "mComet.1" then
		summary.comet = summary.comet + 1;
	elseif die.type == "mComet.2" then
		summary.comet = summary.comet + 1;
	elseif die.type == "mComet.3" then
		summary.comet = summary.comet + 1;
	elseif die.type == "mComet.4" then
		summary.comet = summary.comet + 1;
	elseif die.type == "mComet.5" then
		summary.comet = summary.comet + 1;
	elseif die.type == "mComet.6" then
		summary.comet = summary.comet + 1;
		
	elseif die.type == "mDelay.1" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.2" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.3" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.4" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.5" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.6" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.7" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.8" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.9" then
		summary.delay = summary.delay + 1;
	elseif die.type == "mDelay.10" then
		summary.delay = summary.delay + 1;
		
	elseif die.type == "mExertion.1" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.2" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.3" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.4" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.5" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.6" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.7" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.8" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.9" then
		summary.exertion = summary.exertion + 1;
	elseif die.type == "mExertion.10" then
		summary.exertion = summary.exertion + 1;		
		
	elseif die.type == "mSuccess.1" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.2" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.3" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.4" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.5" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.6" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.7" then
		summary.success = summary.success + 1;
	elseif die.type == "mSuccess.8" then
		summary.success = summary.success + 1;
		
	end
end

-- Used to pass rolled initiative to the InitiativeManager script using the Special Message functionality so the GM can act on the player's roll
function updateActorInit(characternode, initiativecount)
	local msgparams = {};
	msgparams[1] = characternode.getNodeName();
	msgparams[2] = initiativecount;
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_UPDATEACTORINIT, msgparams);
end

function handleUpdateActorInit(msguser, msgidentity, msgparams)
	local characternode = DB.findNode(msgparams[1]);
	local initiativecount = msgparams[2];
	InitiativeManager.updateActorInitiative(characternode, initiativecount);
end