SPECIAL_MSGTYPE_REFRESHTURNINDICATOR = "refreshturnindicator";
SPECIAL_MSGTYPE_GETPLAYERDICEPOOL = "getplayerdicepool";

thisturnwidgets = {};
local thisturnwidget = nil;
local thiscontrol = nil;

local identityname = nil;

function onInit()
	
	-- GM side adds DB holder for all currently connected players, then refreshes the Combat Tracker.
	-- This is needed as the DB holder for a charsheet is reset to just the owning player and so the PC would disappear from other player's CTs.
	if User.isHost() then
		local controlName = self.getName();
		Debug.console("characterlistentry.lua  - onInit() running as host.  Control name = " .. controlName);
		local controlSource = "charsheet." .. string.gsub(controlName, "ctrl_", "");
		Debug.console("characterlistentry.lua  - onInit() - control DB source = " .. controlSource);
		for k, v in ipairs(User.getActiveUsers()) do
			DB.addHolder(controlSource, v);
		end
		InitiativeManager.refreshActorList();
		InitiativeManager.refreshInitSlotList();
	end

	-- register special messages
	--ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_REFRESHTURNINDICATOR, handleRefreshTurnIndicator);
	ChatManager.registerSpecialMessageHandler(SPECIAL_MSGTYPE_GETPLAYERDICEPOOL, handleGetPlayerDicepool);
	
	thiscontrol = self;
	
	-- Enable the addtoinitslot buttons.
	--InitiativeManager.getActiveInitSlot();	
	
	
	-- Change name in diebox viewer - need to tell the GM to rebuild the die box viewer
	DieBoxViewListManager.remoteRebuildDieBoxData();		
end

-- functions used to view the player dicepool via special messages
function getPlayerDicepool(indentityOwner)
	Debug.console("charlistentry.lua: getPlayerDicepool.  indentityOwner = " .. indentityOwner);
	local msgparams = {};
	msgparams[1] = indentityOwner;	
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_GETPLAYERDICEPOOL, msgparams);	
end

function handleGetPlayerDicepool(msguser, msgidentity, msgparams)
	local dicepoolPlayer = msgparams[1];
	Debug.console("charlistentry.lua: handleGetPlayerDicepool.  msguser = " .. msguser .. ", msgidentity = " .. msgidentity .. ", dicepoolPlayer = " .. dicepoolPlayer);
	if User.getUsername() == dicepoolPlayer then
		Debug.console("charlistentry.lua: handleGetPlayerDicepool.  I am the player with the dicepool!  This is the dicepool you are looking for.");
		DieBoxManager.readDicepool();
	end
end


function refreshTurnIndicator()
	local msgparams = {};
	msgparams[1] = thiscontrol.getName();
	if thiscontrol.turnwidget.isVisible() then
		msgparams[2] = "true"
	else
		msgparams[2] = "false"
	end
	msgparams[3] = "pc"
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_REFRESHTURNINDICATOR, msgparams);
end

function enableAllTurnIndicators()
	local msgparams = {};
	msgparams[1] = thiscontrol.getName();
	msgparams[2] = "true"
	msgparams[3] = "all"
	ChatManager.sendSpecialMessage(SPECIAL_MSGTYPE_REFRESHTURNINDICATOR, msgparams);
end

function handleRefreshTurnIndicator(msguser, msgidentity, msgparams)
	-- toggle turn indicator flag
	local pccontrol = msgparams[1];
	local flagvisible = msgparams[2];
	local tokens = msgparams[3];
	--Debug.console("thiscontrol name = " .. pccontrol);
	if tokens == "pc" then
		if thiscontrol.getName() == pccontrol then
			if flagvisible == "true" then
				thiscontrol.turnwidget.setVisible(true);
			else
				thiscontrol.turnwidget.setVisible(false);
			end
			--if thiscontrol.turnwidget.isVisible() then
			--	thiscontrol.turnwidget.setVisible(false);
			--else
			--	thiscontrol.turnwidget.setVisible(true);
			--end
		end
	elseif tokens == "all" then
		thiscontrol.turnwidget.setVisible(true);
	end
end

function createWidgets(name)
	identityname = name;

	portraitwidget = addBitmapWidget("portrait_" .. name .. "_charlist");

	colorwidget = addBitmapWidget("indicator_pointer");
	colorwidget.setPosition("center", 34, 30);
	colorwidget.setVisible(false);

	namewidget = addTextWidget("sheetlabelsmall", "- Unnamed -");
	namewidget.setPosition("center", 0, 46);
	namewidget.setFrame("mini_name", 5, 2, 5, 2);
	namewidget.setMaxWidth(68);
	
	--local currentturnindicators = table.getn(thisturnwidgets) + 1;
	
	--Debug.console("Creating turn widget # " .. currentturnindicators);
	
	--thisturnwidgets[currentturnindicators] = addBitmapWidget("indicator_flag");
	--thisturnwidgets[currentturnindicators].setPosition("center", 30, -20);
	--thisturnwidgets[currentturnindicators].setVisible(false);
	
	--turnwidget = addBitmapWidget("indicator_flag");
	--turnwidget.setPosition("center", 30, -20);
	--turnwidget.setVisible(false);
	--turnwidget.setVisible(true);
	
	-- used for updating turn flag specific to this turnwidget only
	--thisturnwidget = thisturnwidgets[currentturnindicators];
	
	typingwidget = addBitmapWidget("indicator_typing");
	typingwidget.setPosition("center", -23, -23);
	typingwidget.setVisible(false);
	
	idlingwidget = addBitmapWidget("indicator_idling");
	idlingwidget.setPosition("center", -23, -23);
	idlingwidget.setVisible(false);
	
	-- Note AFK not implemented at this time.
	afkwidget = addBitmapWidget("charlist_afk");
	afkwidget.setPosition("center", -23, -23);
	afkwidget.setVisible(false);	

	resetMenuItems();
	if User.isHost() then
		--registerMenuItem("Enable all Turn Action Flags", "arrangegrid", 3);
		--registerMenuItem("Turn Action Flag", "turn", 4);	
		registerMenuItem("Ring Bell", "bell", 5);
		registerMenuItem("Kick", "kick", 3);
		registerMenuItem("Kick Confirm", "kickconfirm", 3, 5);
		--registerMenuItem("View Dicepool", "arrangedice", 6);
	else
		if User.isOwnedIdentity(name) then
			--registerMenuItem("Turn Action Flag toggle", "turn", 4);
			--registerMenuItem("Toggle AFK", "hand", 3);		-- TODO!
			registerMenuItem("Activate", "deletetoken", 5);
			registerMenuItem("Release", "erase", 6);
		end
	end
end

function stateChange(statename, state)
	if statename == "current" then
		if state then
			namewidget.setFont("sheetlabelsmallbold");
		else
			namewidget.setFont("sheetlabelsmall");
		end
	end
	
	if statename == "label" then
		if state ~= "" then
			name = state;			
		else
			name = "- Unnamed - ";
		end
		namewidget.setText(name);		
	end
	
	if statename == "color" then
		colorwidget.setColor(User.getIdentityColor(identityname));
		colorwidget.setVisible(true);
	end
	
	if statename == "active" then
		typingwidget.setVisible(false);
		idlingwidget.setVisible(false);
		afkwidget.setVisible(false);
	end
	
	if statename == "typing" then
		typingwidget.setVisible(true);
		idlingwidget.setVisible(false);
		afkwidget.setVisible(false);
	end
	
	if statename == "idle" then
		typingwidget.setVisible(false);
		idlingwidget.setVisible(true);
	end
	
	if statename == "afk" then
		typingwidget.setVisible(false);
		idlingwidget.setVisible(false);
		afkwidget.setVisible(true);
	end
	
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	-- Removing the one-click opening of character sheets - moving to double-click.  This is more in line with the FG 3.0 rulesets.
	--Debug.console("characterlistentry.lua: onClickRelease - dbnode = charsheet." .. identityname);
	--CharacterManager.openCharacterSheet(DB.findNode("charsheet." .. identityname), identityname);
	return true;
end

function onDoubleClick(button, x, y)
	if User.isOwnedIdentity(identityname) then
		-- Set as the active identity		
		User.setCurrentIdentity(identityname);
		if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[identityname] then
			local colortable = CampaignRegistry.colortables[identityname];
			User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);
		end
		-- Change name in diebox viewer - need to tell the GM to rebuild the die box viewer
		DieBoxViewListManager.remoteRebuildDieBoxData();	
		-- Open the character sheet
		CharacterManager.openCharacterSheet(DB.findNode("charsheet." .. identityname), identityname);	
	elseif User.isHost() then
		CharacterManager.openCharacterSheet(DB.findNode("charsheet." .. identityname), identityname);
	end
	
	return true;
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if User.isHost() or User.isOwnedIdentity(identityname) then
		draginfo.setType("playercharacter");
		draginfo.setTokenData("portrait_" .. identityname .. "_token");
		draginfo.setShortcutData("charsheet", "charsheet." .. identityname);
		draginfo.setDatabaseNode("charsheet." .. identityname);
		draginfo.setStringData(identityname);
		
		local base = draginfo.createBaseData();
		base.setType("token");
		base.setTokenData("portrait_" .. identityname .. "_token");
	
		return true;
	end
end

function onDrop(x, y, draginfo)
	return CharacterManager.onDrop(DB.findNode("charsheet." .. identityname), x, y, draginfo);
end

function onMenuSelection(selection, subselection)

	if User.isHost() then
		if selection == 3 and subselection == 5 then
			Debug.console("Identity name = " .. identityname);
			User.kick(User.getIdentityOwner(identityname));
			
		elseif selection == 4 then
	
			-- toggle turn indicator flag
			--Debug.console("Turn indicator flag = " .. turnwidget.isVisible());
			--if thiscontrol.turnwidget.isVisible() then
				--thiscontrol.turnwidget.setVisible(false);
			--else
				--thiscontrol.turnwidget.setVisible(true);
			--end
			--refreshTurnIndicator();
			
		elseif selection == 5 then
			User.ringBell(User.getIdentityOwner(identityname));
			
		elseif selection == 6 then
			--Code for showing the current dicepool of the owning player
			--Debug.console("characterlistentry.lua: onMenuSelection.  User.getIdentityOwner = " .. User.getIdentityOwner(identityname));
			--getPlayerDicepool(User.getIdentityOwner(identityname));
			
		end
	end

	if User.isOwnedIdentity(identityname) then
		
		if selection == 3 then
			-- AFK
			if afkwidget.isVisible() then
				stateChange("active","");
			else
				stateChange("afk","");
			end
		
		elseif selection == 4 then
		
			-- toggle turn indicator flag
			--Debug.console("Turn indicator flag = " .. turnwidget.isVisible());
			--if thiscontrol.turnwidget.isVisible() then
			--	thiscontrol.turnwidget.setVisible(false);
			--else
			--	thiscontrol.turnwidget.setVisible(true);
			--end
			--refreshTurnIndicator();
			
			-- Remove recharge
			--CharacterManager.endOfTurn(DB.findNode("charsheet." .. identityname));	
	
		elseif selection == 5 then
		
			-- Set as the active identity		
			User.setCurrentIdentity(identityname);
			if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[identityname] then
				local colortable = CampaignRegistry.colortables[identityname];
				User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);
			end
			
		elseif selection == 6 then
		
			-- Release the current identity
			User.releaseIdentity(identityname);
			-- Reset the addtoinitslot buttons.
			InitiativeManager.refreshInitSlotList();
			--InitiativeManager.getActiveInitSlot();
			
		end
	end

end