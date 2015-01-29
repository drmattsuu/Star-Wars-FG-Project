local stepheightvalue = 33;
local stepwidthvalue = 33;
local stepicononvalue = "progresstracker_on";
local stepiconoffvalue = "progresstracker_off";
local stepfontnamevalue = "sheetlabelinline";
local stepcountmaxvalue = 10;
local iconnamevalue = "button_openwindow2";

local dragging = false;

local sourcenode = nil;
local valuenode = nil;
local stepstatenode = nil;
local stepcountnode = nil;
local stepstartnode = nil;
local directionnode = nil;

local steps = {};
local iconbitmap = nil;

function onInit()

	-- get the source node
	local sourcenodename;
	if sourcename then
		sourcenodename = sourcename[1];
	else
		sourcenodename = getName();
	end
	if window.getDatabaseNode().isOwner() then
		sourcenode = window.getDatabaseNode().createChild(sourcenodename);
	else
		sourcenode = window.getDatabaseNode().getChild(sourcenodename);
	end
	
	-- if the source node exists
	if sourcenode then
		
		-- get the other node
		if not sourcenode.isStatic() and sourcenode.isOwner() then
			valuenode = sourcenode.createChild("value", "number");
			stepstatenode = sourcenode.createChild("stepstate", "number");
			stepcountnode = sourcenode.createChild("stepcount", "number");
			stepstartnode = sourcenode.createChild("stepstart", "number");
			directionnode = sourcenode.createChild("direction", "number");
		else
			valuenode = sourcenode.getChild("value");
			stepstatenode = sourcenode.getChild("stepstate");
			stepcountnode = sourcenode.getChild("stepcount");
			stepstartnode = sourcenode.getChild("stepstart");
			directionnode = sourcenode.getChild("direction");
		end
				
		-- add menu items for the owner
		if not sourcenode.isStatic() and sourcenode.isOwner() then
			registerMenuItem("Add step", "insert", 4);
			registerMenuItem("Remove step", "delete", 6);
			if allowreverse then
				registerMenuItem("Change direction", "rotateccw", 5);
			end
		end
		
		-- get defaults
		if max then
			stepcountmaxvalue = tonumber(max[1]);
		end
		
		-- set the event listener
		sourcenode.onChildUpdate = onUpdate;
				
		-- and update the layout
		update();		
	end	
end

function onUpdate(source)
	update();
end

function onMenuSelection(selection)
	if selection == 4 then
		addStep();
	elseif selection == 5 then
		if directionnode then
			local direction = directionnode.getValue();
			if direction == 0 then
				directionnode.setValue(1);
			else
				directionnode.setValue(0);
			end
		end
	else
		removeStep();
	end
end

function addStep()
	if sourcenode then
		if sourcenode.isOwner() then
			local stepcount = getStepCount();
			if stepcount < stepcountmaxvalue + 1 then
				stepcountnode.setValue(stepcount + 1);
			end
		end
	end
end

function removeStep()
	if sourcenode then
		if sourcenode.isOwner() then
			local value = getValue();
			local stepcount = getStepCount();
			if stepcount > 1 then
				if stepcount == value + 1 then
					setValue(value - 1);
				end
				stepcountnode.setValue(stepcount - 1);
			end
		end
	end
end

function update()
	DebugManager.logMessage("progresstracker.update");
	if sourcenode then
	
		-- get the direction
		local direction = 0;
		if directionnode then
			direction = directionnode.getValue();
		end
		
		-- get the start value
		local stepstart = 0;
		if stepstartnode then
			stepstart = stepstartnode.getValue();
		end
	
		-- change our local list of step images to match the step count
		local stepcount = getStepCount();
		while table.getn(steps) ~= stepcount do
			if table.getn(steps) < stepcount then
				local step = {};
				step.icon = addBitmapWidget(stepiconoffvalue);
				step.label = addTextWidget(stepfontnamevalue, stepstart + table.getn(steps));
				table.insert(steps, step);
			else
				local step = steps[table.getn(steps)];
				step.icon.destroy();
				step.label.destroy();
				table.remove(steps);
			end
		end
		
		-- layout the step icons in the control
		if table.getn(steps) > 0 then
			local position = 0 - (stepwidthvalue * (table.getn(steps) - 1)) / 2;
			for k, v in ipairs(steps) do
				if direction == 0 then
					v.icon.setPosition("", position, 0);
					v.label.setPosition("", position, 0);
				else
					v.icon.setPosition("", -position, 0);
					v.label.setPosition("", -position, 0);
				end				
				position = position + stepwidthvalue;
			end
		end
		
		-- update the step icons state
		for k, v in ipairs(steps) do
			if stepstatenode then
				local stepstate = hasBit(stepstatenode.getValue(), bit(k - 1));
				if stepstate then
					v.icon.setBitmap(stepicononvalue);
				else
					v.icon.setBitmap(stepiconoffvalue);
				end
			else
				v.icon.setBitmap(stepiconoffvalue);			
			end
		end
		
		-- create and place the icon bitmap
		if not iconbitmap then
			iconbitmap = addBitmapWidget(iconnamevalue);
		end
		local value = getValue();
		local iconposition = (stepwidthvalue * value) - (stepwidthvalue * (table.getn(steps) - 1)) / 2;
		if direction == 0 then
			iconbitmap.setPosition("", iconposition, 0);
		else
			iconbitmap.setPosition("", -iconposition, 0);
		end
		iconbitmap.bringToFront();		
	end
end

function getValue()
	local value = 0;
	if valuenode then
		value = valuenode.getValue();
		if value < 0 then
			value = 0;
		end
		if value > stepcountmaxvalue then
			value = stepcountmaxvalue;
		end
	end
	return value;
end

function setValue(value)
	if valuenode then
		if value < 0 then
			value = 0;
		end
		if value > stepcountmaxvalue then
			value = stepcountmaxvalue;
		end
		valuenode.setValue(value);
	end
end

function getStepCount()
	if stepcountnode then
		stepcount = stepcountnode.getValue();
		if stepcount == 0 then
			stepcount = stepcountmaxvalue + 1;
		end
		return stepcount;
	end
	return stepcountmaxvalue + 1;
end

function getStepIndex(x, y)
	if sourcenode then
		local w, h = getSize();
		local stepcount = getStepCount();
		if y > ((h - stepheightvalue) / 2) and y < ((h + stepheightvalue) / 2) then
			local totalstepwidth = stepwidthvalue * stepcount;
			local xpos = x - ((w - totalstepwidth) / 2);
			if xpos > 0 and xpos < totalstepwidth then
				local stepindex = math.floor(xpos / stepwidthvalue);
				if directionnode then
					if directionnode.getValue() == 1 then
						stepindex = stepcount - stepindex - 1;
					end
				end
				return stepindex;
			end
		end
	end
	return nil;
end

function onClickDown(button, x, y)
	if sourcenode then
		if not sourcenode.isStatic() and sourcenode.isOwner() then
			if not dragging then		
				local stepindex = getStepIndex(x, y);
				if stepindex ~= getValue() then
					if stepindex then
						local stepstate = stepstatenode.getValue();
						if hasBit(stepstate, bit(stepindex)) then
							stepstate = clearBit(stepstate, bit(stepindex));
						else
							stepstate = setBit(stepstate, bit(stepindex));
						end
						stepstatenode.setValue(stepstate);
					end
				end
			end
		end
	end
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if sourcenode then
		if not sourcenode.isStatic() and sourcenode.isOwner() then
			if not dragging then
				if iconbitmap then
					local stepindex = getStepIndex(x, y);
					if stepindex then
						if stepindex == getValue() then
							draginfo.setType("progresstracker");
							draginfo.setIcon(iconnamevalue);
							iconbitmap.setColor("80FFFFFF");
							dragging = true;
							return true;
						end
					end
				end
			end
		end
	end
	return nil;
end

function onDragEnd(draginfo)
	if sourcenode then
		if not sourcenode.isStatic() and sourcenode.isOwner() then
			if dragging then
				local mousex, mousey = Input.getMousePosition();
				local windowx, windowy = window.getPosition();
				local controlx, controly = getPosition();
				local x = mousex - controlx - windowx;
				local y = mousey - controly - windowy;
				local stepindex = getStepIndex(x, y);
				if stepindex then
					setValue(stepindex);
				end
				if iconbitmap then
					iconbitmap.setColor("FFFFFFFF");
				end
				dragging = false;
				update();
			end
		end
	end
end

-- Bit functions for step state value
function bit(p)
  return 2 ^ p;
end

function hasBit(x, p)
  return x % (p + p) >= p;     
end

function setBit(x, p)
  return hasBit(x, p) and x or x + p;
end

function clearBit(x, p)
  return hasBit(x, p) and x - p or x;
end