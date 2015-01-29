local sourcenode = nil;

function onInit()
	sourcenode = window.getDatabaseNode();
	if sourcenode.isOwner() then
		setHoverCursor("hand");		
	else
		setVisible(false);
	end
end

function onDragStart(button, x, y, draginfo)
	if sourcenode.isOwner() then
		local classname = window.getClass();
		if classname == "charsheetskillsmall" or classname == "npcskillsmall" then
			return createSkillDicePool(draginfo);
		elseif classname == "charsheetspellsmall" or classname == "npcspellsmall" then
			return createSpellDicePool(draginfo);
		elseif classname == "charsheetitemweapon" or classname == "charsheetitemarmour" then
			return createWeaponDicePool(draginfo);
		elseif classname == "npcitemweapon" or classname == "npcitemarmour" then
			return createArmourDicePool(draginfo);
		end
	end
end

function createSkillDicePool(draginfo)
	local dice = {};
	table.insert(dice, "d8");
	table.insert(dice, "d6");
	draginfo.setType("skill");
	draginfo.setDieList(dice);
	draginfo.setDescription(sourcenode.getChild("name").getValue());
	draginfo.setDatabaseNode(sourcenode);
	return true;
end

function createSpellDicePool(draginfo)
	local dice = {};
	table.insert(dice, "d10");
	table.insert(dice, "d6");
	draginfo.setType("spell");
	draginfo.setDieList(dice);
	draginfo.setDescription(sourcenode.getChild("name").getValue());
	draginfo.setDatabaseNode(sourcenode);
	return true;
end

function createWeaponDicePool(draginfo)
	local dice = {};
	table.insert(dice, "d6");
	table.insert(dice, "d6");
	if PreferenceManager.getValue("dice_rollcombatdice") then
		table.insert(dice, "dCombat");
	end
	draginfo.setType("weapon");
	draginfo.setDieList(dice);
	draginfo.setDescription(sourcenode.getChild("name").getValue());
	draginfo.setDatabaseNode(sourcenode);	
	return true;
end

function createArmourDicePool(draginfo)
	local dice = {};
	table.insert(dice, "d6");
	table.insert(dice, "d6");
	if PreferenceManager.getValue("dice_rollcombatdice") then
		table.insert(dice, "dCombat");
	end
	draginfo.setType("armour");
	draginfo.setDieList(dice);
	draginfo.setDescription(sourcenode.getChild("name").getValue());
	draginfo.setDatabaseNode(sourcenode);	
	return true;
end