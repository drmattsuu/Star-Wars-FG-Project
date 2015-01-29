local dragging = false;

function onInit()

	-- determine if node is static
	if window.getDatabaseNode().isStatic() then
		setVisible(false);
		return
	end
	
	-- set the hover cursor
	setHoverCursor("hand");	
	
	-- get the check value
	local checknode = window.getDatabaseNode().getChild("check");
	if checknode then
		checknode.onUpdate = onUpdate;
	end

	-- force an update now
	update();

end

function onUpdate(source)
	update();
end

function update()
	local dice = {};
	local modifiers = {};
	DicePoolManager.addActionDice(window.getDatabaseNode(), dice, modifiers);
	if table.getn(dice) > 0 then
		setVisible(true);
	else
		setVisible(false);
	end
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		local sourcenode = window.getDatabaseNode();
		local dice = {};
		DicePoolManager.addActionDice(sourcenode, dice);
		if table.getn(dice) > 0 then						
			draginfo.setType("action");
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
