local iconwidth = 25;
local dragging = false;
local typename = "dice";
local sourcenode = nil;
local entries = {};
local descriptionwidget = nil;
local shadowwidget = nil;
local dieboxidentity = nil;

function onInit()
	DieBoxManager.registerControl(self);
	registerMenuItem("Clear dice", "erase", 4);
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if table.getn(entries) > 0 then
		if not dragging then
			if table.getn(getDice()) > 0 then
				draginfo.setType(typename);		
				draginfo.setDescription(getDescription());
				draginfo.setDieList(getDice());
				draginfo.setDatabaseNode(sourcenode);
				dragging = true;
				if PreferenceManager.getValue("interface_cleardicepoolondrag") then
					resetAll();
				end
				return true;						
			end
		end
	end
end

function onDragEnd(draginfo)
	dragging = false;
end

function onDrop(x, y, draginfo)
	if PreferenceManager.getValue("interface_cleardicepoolondrag") then
		Debug.console("Campaign Option interface_cleardicepoolondrag set");
	end
	if not dragging then
		
		-- Dice
		if draginfo.isType("dice") then
			local dielist = draginfo.getDieList();
			if dielist then
				setDescription(draginfo.getDescription());
				for k, v in pairs(dielist) do
					addDie(v.type);
				end
			end
		end
		
		-- Chit
		if draginfo.isType("chit") then
		
			if draginfo.getCustomData() == "lightside" then
				-- Upgrade PC dice or downgrade NPC dice.
				if User.isHost() then
					DieBoxUpgradeDowngradeButtonPress("dieboxupgradedifficulty");
				else
					DieBoxUpgradeDowngradeButtonPress("dieboxupgradeability");
				end
			elseif draginfo.getCustomData() == "darkside" then
				-- Downgrade PC dice or upgrade NPC dice.
				Debug.console("TODO: Darkside destiny token code.");
				if User.isHost() then
					DieBoxUpgradeDowngradeButtonPress("dieboxupgradeability");
				else
					--DieBoxUpgradeDowngradeButtonPress("dieboxupgradeability");
				end				
			end			
			
			-- WFRP3
			--if draginfo.getCustomData() == "fortune" then
			--	addDie("dFortune");
			--elseif draginfo.getCustomData() == "corruption" then
			--	addDie("dChallenge");
			--end		
		end
		
		-- Action
		if draginfo.isType("action") then
			local dielist = draginfo.getDieList();
			if dielist then
				if PreferenceManager.getValue("interface_cleardicepoolondrag") then
					resetAll();
				end
				setType(draginfo.getType());
				setDescription(draginfo.getDescription());
				setSourcenode(draginfo.getDatabaseNode());
				for k, v in pairs(dielist) do
					addDie(v.type);
				end
			end
		end
		
		-- Characteristic
		if draginfo.isType("characteristic") then
			local dielist = draginfo.getDieList();
			if dielist then
				if PreferenceManager.getValue("interface_cleardicepoolondrag") then
					resetAll();
				end			
				setType(draginfo.getType());
				setDescription(draginfo.getDescription());
				setSourcenode(draginfo.getDatabaseNode());
				for k, v in pairs(dielist) do
					addDie(v.type);
				end
			end
		end		

		-- Skill
		if draginfo.isType("skill") then
			local dielist = draginfo.getDieList();
			if dielist then
				if PreferenceManager.getValue("interface_cleardicepoolondrag") then
					resetAll();
				end			
				setType(draginfo.getType());
				setDescription(draginfo.getDescription());
				setSourcenode(draginfo.getDatabaseNode());
				for k, v in pairs(dielist) do
					addDie(v.type);
				end
			end
		end		

		-- Specialisation
		if draginfo.isType("specialisation") then
			local dielist = draginfo.getDieList();
			if dielist then
				if PreferenceManager.getValue("interface_cleardicepoolondrag") then
					resetAll();
				end			
				setType(draginfo.getType());
				setDescription(draginfo.getDescription());
				setSourcenode(draginfo.getDatabaseNode());
				for k, v in pairs(dielist) do
					addDie(v.type);
				end
			end
		end			
		
		-- Shortcut
		if draginfo.isType("shortcut") then
			local class, recordname = draginfo.getShortcutData();		
			
			-- skill
			if class == "skill" then
				local dice = {};
				local modifiers = {};
				local recordnode = DB.findNode(recordname);
				if recordnode then
					if PreferenceManager.getValue("interface_cleardicepoolondrag") then
						resetAll();
					end				
					setType("skill");
					local namenode = recordnode.getChild("name");
					if namenode then
						setDescription(namenode.getValue());
					end
					setSourcenode(recordnode);
					DicePoolManager.addSkillDice(recordnode, dice, modifiers);
					addDice(dice);
					addDice(modifiers);
				end
			end
			
			-- actions
			if class == "blessing" or class == "melee" or class == "ranged" or class == "social" or class == "spell" or class == "support" then
				local dice = {};
				local modifiers = {};
				local recordnode = DB.findNode(recordname);
				if recordnode then
					if PreferenceManager.getValue("interface_cleardicepoolondrag") then
						resetAll();
					end				
					setType("action");
					local namenode = recordnode.getChild("name");
					if namenode then
						setDescription(namenode.getValue());
					end
					setSourcenode(recordnode);
					DicePoolManager.addActionDice(recordnode, dice, modifiers);
					addDice(dice);
					addDice(modifiers);
				end
			end
			
			-- specialisation
			if class == "specialisation" then
				local dice = {};
				local modifiers = {};
				local recordnode = DB.findNode(recordname);
				if recordnode then
					if PreferenceManager.getValue("interface_cleardicepoolondrag") then
						resetAll();
					end				
					setType("specialisation");
					local namenode = recordnode.getChild("name");
					if namenode then
						setDescription(namenode.getValue());
					end
					setSourcenode(recordnode);
					DicePoolManager.addSpecialisationDice(recordnode, dice, modifiers);
					addDice(dice);
					addDice(modifiers);
				end
			end
		
		end
		
		-- and return true
		return true;		
	end
end

function addDice(dice)
	if dice then
		for k, v in ipairs(dice) do
			addDie(v);
		end
	end
end

function addDie(type)
	local entry = {};
	entry.type = type;
	entry.icon = addBitmapWidget(type .. "icon");	
	table.insert(entries, entry);
	updateIcons();
end

function removeDie(index)
	local dice = {};
	for i = 1, #entries do
		if i ~= index then
			table.insert(dice, entries[i].type);
		end
	end
	resetEntries();
	addDice(dice);
	if #entries == 0 then
		resetAll();
	end
end

function findDieOfType(dietype)
	for k, v in pairs(getDice()) do
		if v == dietype then
			return k;
		end
	end
	return 0;
end

function replaceDie(dielistindex, dietype)
	local entry = {};
	entry.type = dietype;
	entry.icon = addBitmapWidget(dietype .. "icon");	
	table.insert(entries, dielistindex, entry);
	removeDie(dielistindex + 1);
	updateIcons();

end


function updateIcons()
	if table.getn(entries) > 0 then
		local position = 0 - (iconwidth * (table.getn(entries) - 1)) / 2;
		for k, v in ipairs(entries) do
			if v.type then
				v.icon.setPosition("", position, 0);
				position = position + iconwidth;
			end
		end
	end
	if shadowwidget then
		shadowwidget.bringToFront();
	end
	if descriptionwidget then
		descriptionwidget.bringToFront();
	end
	
	-- Update any remote clients viewing this diebox.  Only send GM info if reveal is on.
	if User.isHost() then
		if not ChatManager.gmDieHide() then
			DieBoxManager.sendPlayerDicepool(getDice(), getDescription());
		end
	else
		DieBoxManager.sendPlayerDicepool(getDice(), getDescription());
	end
end

function resetEntries()
	if table.getn(entries) > 0 then
		for k, v in ipairs(entries) do
			v.icon.destroy();
		end
		entries = {};
	end
	
end

function getDice()
	local dielist = {};
	for k, v in ipairs(entries) do
		if v.type then
			table.insert(dielist, v.type);
		end
	end
	return dielist;	
end

function setDice(dielist)
	resetEntries();
	--for k, v in ipairs(dielist) do
	addDice(dielist);
	--end
end

function onDoubleClick(x, y)
	if table.getn(entries) > 0 then
		local controlwidth, controlheight = getSize();
		
		-- calculate the x position relative to the entries
		local entrieswidth = table.getn(entries) * iconwidth;
		x = x - ((controlwidth - entrieswidth) / 2 );
		
		-- determine if the x value falls into the entries
		if x > 0 and x < entrieswidth then
			local index = math.floor(x / iconwidth) + 1;
			removeDie(index);
		end
	end
end

function onMenuSelection(...)
	resetAll();
end

function setDescription(description)
	if description and description ~= "" then
		if descriptionwidget then
			descriptionwidget.setText(description);
		else
			descriptionwidget = addTextWidget("hotkey", description);
		end
		if shadowwidget then
			shadowwidget.setText(description);
		else
			shadowwidget = addTextWidget("chatfont", description);
		end
		descriptionwidget.setPosition("",0,0);
		shadowwidget.setPosition("",1,1);
	end
end

function resetDescription()
	if descriptionwidget then
		descriptionwidget.destroy();
		descriptionwidget = nil;

	end
	if shadowwidget then
		shadowwidget.destroy();
		shadowwidget = nil;	
	end
end

function getDescription()
	if descriptionwidget then
		return descriptionwidget.getText();
	end
	return "";
end

function resetAll()
	resetType();
	resetDescription();
	resetSourcenode();
	resetEntries();
	resetIdentity();
	
	-- Update any remote clients viewing this diebox
	DieBoxManager.sendPlayerDicepool(getDice(), getDescription());	
end
	
function setType(type)
	typename = type;
end

function resetType()
	typename = "dice";
end

function setSourcenode(node)
	sourcenode = node;
end

function resetSourcenode()
	sourcenode = nil;
end

function setIdentity(actoridentity)
	dieboxidentity = actoridentity;
end

function resetIdentity()
	dieboxidentity = nil;
end

function onDieboxButtonPress()
		local sourcenodename = "";
		-- type
		--local type = "dice";
		local type = typename;
		-- description
		local description = getDescription();
		-- modifier
		local modifier = "0";
		-- source node name
		if sourcenode then
			sourcenodename = sourcenode.getNodeName();
		end
		-- gm only
		--local gmonly = PreferenceManager.getValue("interface_gmonly");		
		local gmonly = ChatManager.gmDieHide();
		-- build the dice table
		local dice = getDice();
		-- verify the identity - use the user if no identity has been set via setIdentity
		msgidentity = dieboxidentity;		
		if msgidentity == "" then
			msgidentity = msguser;
		end
		-- throw the dice
		ChatManager.throwDice(type, dice, modifier, description, {sourcenodename, msgidentity, gmonly});

		resetAll();		
end	

function DieBoxUpgradeDowngradeButtonPress(controlname)
	--Debug.console("diebox.lua: DieBoxUpgradeDowngradeButtonPress().  Controlname = " .. controlname);
	
	local dietoreplace = "";
	local dietochangeto = "";
	local keepupgrading = false;
	
	if controlname == "dieboxupgradedifficulty" then
		dietoreplace = "dDifficulty";
		dietochangeto = "dChallenge";
		keepupgrading = true;
	elseif controlname == "dieboxdowngradechallenge" then
		dietoreplace = "dChallenge";
		dietochangeto = "dDifficulty";
	elseif controlname == "dieboxupgradeability" then
		dietoreplace = "dAbility";
		dietochangeto = "dProficiency";
		keepupgrading = true;	
	elseif controlname == "dieboxdowngradeproficiency" then
		dietoreplace = "dProficiency";
		dietochangeto = "dAbility";	
	end
	
	--Debug.console("diebox.lua: DieBoxUpgradeDowngradeButtonPress().  Looking to replace " .. dietoreplace .. ", with " .. dietochangeto);
	local dietoreplaceindex = findDieOfType(dietoreplace);
	if dietoreplaceindex > 0 then
		replaceDie(dietoreplaceindex, dietochangeto);
	elseif keepupgrading then
		-- No more dice found to upgrade, but this is an upagrade process that can keep going!  Add another die.
		addDie(dietoreplace);
	end
		
end	

function onHiddenButtonPress(control)
	Debug.console("diebox.lua: onHiddenButtonPress.  Button state = " .. control.getValue());
	if control.getValue() == 0 then
		DieBoxManager.readDicepool();
		ChatManager.gmRevealDieRolls(true);
	elseif control.getValue() == 1 then
		DieBoxManager.sendPlayerDicepool({}, "");
		ChatManager.gmRevealDieRolls(false);
	end	
end
