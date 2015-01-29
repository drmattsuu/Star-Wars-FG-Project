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
		DicePoolManager.addSpecialisationDice(sourcenode, dice, modifiers);
		if table.getn(dice) > 0 then						
			draginfo.setType("specialisation");
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
