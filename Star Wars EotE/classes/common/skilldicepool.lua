local dragging = false;

function onInit()

	-- determine if node is static
	if window.getDatabaseNode().isStatic() then
		setVisible(false);
		return
	end
	
	-- set the hover cursor
	setHoverCursor("hand");	
	
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		local sourcenode = window.getDatabaseNode();
		local dice = {};
		DicePoolManager.addSkillDice(sourcenode, dice);
		if table.getn(dice) > 0 then
			draginfo.setType("skill");
			if sourcenode.getChild("name") then
				draginfo.setDescription(sourcenode.getChild("name").getValue());
			end
			draginfo.setDieList(dice);
			draginfo.setDatabaseNode(sourcenode);
			dragging = true;
			return true;								
		end		
	end
	return false;
end

function onDragEnd(draginfo)
	dragging = false;
end

-- Allows population of the dice pool by a double-click on the dice button by the skill
function onDoubleClick()
	local sourcenode = window.getDatabaseNode();
	--Debug.console("Skill roll databasenode = " .. sourcenode.getNodeName());
	local dice = {};
	local skilldescription;
	local msgidentity = DB.getValue(sourcenode, "...name", "");
	DicePoolManager.addSkillDice(sourcenode, dice);
	if table.getn(dice) > 0 then
		if sourcenode.getChild("name") then
			skilldescription = sourcenode.getChild("name").getValue();
		end
		DieBoxManager.addSkillDice(skilldescription, dice, sourcenode, msgidentity);
	end
end