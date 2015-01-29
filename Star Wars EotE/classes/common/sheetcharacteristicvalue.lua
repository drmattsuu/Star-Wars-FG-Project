local dragging = false;
local dicewidget = nil;

function onInit()
	super.onInit();
	setHoverCursor("hand");
	dicewidget = addBitmapWidget("textentry_die");
	dicewidget.setPosition("bottomleft", 0, -4);
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		local sourcenode = getDatabaseNode();
		if sourcenode then
			local sourcename = sourcenode.getNodeName();
		
			-- build the description
			local description = "";
			if string.find(sourcename, string.lower(LanguageManager.getString("Strength")), 1, true) then
				description = LanguageManager.getString("Strength");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Toughness")), 1, true) then
				description = LanguageManager.getString("Toughness");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Agility")), 1, true) then
				description = LanguageManager.getString("Agility");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Intelligence")), 1, true) then
				description = LanguageManager.getString("Intelligence");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Willpower")), 1, true) then
				description = LanguageManager.getString("Willpower");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Fellowship")), 1, true) then
				description = LanguageManager.getString("Fellowship");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Brawn")), 1, true) then
				description = LanguageManager.getString("Brawn");
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Intellect")), 1, true) then
				description = LanguageManager.getString("Intellect");	
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Cunning")), 1, true) then
				description = LanguageManager.getString("Cunning");	
			elseif string.find(sourcename, string.lower(LanguageManager.getString("Presence")), 1, true) then
				description = LanguageManager.getString("Presence");					
			end
			
			-- build the dice pool
			local dice = {};
			DicePoolManager.addCharacteristicDice(sourcenode, dice);
				
			-- complete the drag information
			if table.getn(dice) > 0 then						
				draginfo.setType("characteristic");
				draginfo.setDescription(description);
				draginfo.setDieList(dice);
				draginfo.setDatabaseNode(sourcenode);
				dragging = true;
				return true;								
			end
		end
	end
	return false;
end

function onDragEnd(draginfo)
	dragging = false;
end

-- Allows population of the dice pool by a double-click on the dice button by the skill
function onDoubleClick()
	--local sourcenode = window.getDatabaseNode();
	local sourcenode = getDatabaseNode();
	--Debug.console("Characteristic roll databasenode = " .. sourcenode.getNodeName());
	
	if sourcenode then
		local sourcename = sourcenode.getNodeName();
		local description = "";
	
		-- build the description
		local description = "";
		if string.find(sourcename, string.lower(LanguageManager.getString("Agility")), 1, true) then
			description = LanguageManager.getString("Agility");
		elseif string.find(sourcename, string.lower(LanguageManager.getString("Willpower")), 1, true) then
			description = LanguageManager.getString("Willpower");
		elseif string.find(sourcename, string.lower(LanguageManager.getString("Brawn")), 1, true) then
			description = LanguageManager.getString("Brawn");
		elseif string.find(sourcename, string.lower(LanguageManager.getString("Intellect")), 1, true) then
			description = LanguageManager.getString("Intellect");	
		elseif string.find(sourcename, string.lower(LanguageManager.getString("Cunning")), 1, true) then
			description = LanguageManager.getString("Cunning");	
		elseif string.find(sourcename, string.lower(LanguageManager.getString("Presence")), 1, true) then
			description = LanguageManager.getString("Presence");					
		end
			
		local dice = {};
		local msgidentity = DB.getValue(sourcenode, "..name", "");
		DicePoolManager.addCharacteristicDice(sourcenode, dice);
		if table.getn(dice) > 0 then
			DieBoxManager.addCharacteristicDice(description, dice, sourcenode, msgidentity);
		end
	end
end