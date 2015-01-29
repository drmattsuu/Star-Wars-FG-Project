local dicevalue = nil;
local dragging = false;

function onInit()
	super.onInit();	
	if dice then
		dicevalue = dice[1];
	end	
	onValueChanged();				
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if getDatabaseNode().isOwner() then
		if dicevalue then
			local value = getValue();
			if value > 0 then
				if not dragging then
					draginfo.setType("dice");

					local dicetable = {};
					table.insert(dicetable, dicevalue);
					draginfo.setDieList(dicetable);

					dragging = true;
					setValue(value - 1);
					return true;
				end
			end
			return false;
		end
	end
end

function onDragEnd(draginfo)
	if dragging then
		local x, y = getControlMousePosition();
		local w, h = getSize();
		if x >= 0 and x <= w and y >= 0 and y <= h then
			setValue(getValue() + 1);
		end
		dragging = false;
	end
end

function getControlMousePosition()
	local mousex, mousey = Input.getMousePosition();
	local windowx, windowy = window.getPosition();
	local controlx, controly = getPosition();
	local x = mousex - controlx - windowx;
	local y = mousey - controly - windowy;
	return x, y;
end

