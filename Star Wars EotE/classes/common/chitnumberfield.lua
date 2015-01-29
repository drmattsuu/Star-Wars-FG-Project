local chitvalue = nil;
local allowdropvalue = false;
local dragging = false;

function onInit()
	super.onInit();	
	if chit then
		chitvalue = chit[1];
		if User.isHost() or getDatabaseNode().isOwner() then
			setHoverCursor("hand");
		end
	end
	if allowdrop then
		if string.lower(allowdrop[1]) == "true" then
			allowdropvalue = true;
		end
	end
	onValueChanged();				
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if getDatabaseNode().isOwner() then
		if chitvalue then
			local value = getValue();
			if value > 0 then
				if not dragging then
					draginfo.setType("chit");
					draginfo.setIcon(chitvalue .. "chit");
					draginfo.setCustomData(chitvalue);
					dragging = true;
					setValue(value - 1);
					onValueChanged();
					return true;
				end
			end
		end
	end
	return false;	
end

function onDragEnd(draginfo)
	if dragging then
		if chitvalue then
			if allowdropvalue then
				local x, y = getControlMousePosition();
				local w, h = getSize();
				if x >= 0 and x <= w and y >= 0 and y <= h then
					setValue(getValue() + 1);
					onValueChanged();
				end
			end
		end
		dragging = false;		
	end
end

function onDrop(x, y, draginfo)
	if chitvalue then
		if allowdropvalue then
			if draginfo.getType() == "chit" then
				if draginfo.getCustomData() == chitvalue then
					setValue(getValue() + 1);
					onValueChanged();
					return true;
				end
			end
		end
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

