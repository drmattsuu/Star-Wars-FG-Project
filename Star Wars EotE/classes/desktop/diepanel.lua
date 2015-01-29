local dragging = false;

function onInit()
	if type then
		setIcon(type[1]);
		setHoverCursor("hand");
		registerMenuItem("Add 2", "num2", 1);
		registerMenuItem("Add 3", "num3", 2);
		registerMenuItem("Add 4", "num4", 3);
		registerMenuItem("Add 5", "num5", 4);
		registerMenuItem("Add 6", "num6", 5);
		registerMenuItem("Add 7", "num7", 6);
		registerMenuItem("Add 8", "num8", 7);
		registerMenuItem("Add 9", "num9", 8);
	end
end

function onMenuSelection(selection)
	if type then
		local dice = {};
		for index = 1, selection + 1 do
			table.insert(dice, type[1]);
		end
		DieBoxManager.addDice(dice);
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		if Input.isControlPressed() or button > 1 then
			if modifier then
				draginfo.setType("dice");				
				draginfo.setDieList({ modifier[1] });		
				dragging = true;
				return true;					
			end
		else
			if type then
				draginfo.setType("dice");					
				draginfo.setDieList({ type[1] });
				dragging = true;
				return true;			
			end
		end
	end
end

function onDragEnd(draginfo)
	dragging = false;
end

function onDoubleClick(x, y)
	if type then
		DieBoxManager.addDie(type[1]);
		return true;
	end
end