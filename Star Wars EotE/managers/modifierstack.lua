control = nil;
freeadjustment = 0;
slots = {};

function registerControl(ctrl)
	control = ctrl;
end

function updateControl()
	if control then
		if adjustmentedit then
			control.label.setValue("Adjusting");
		else
			control.label.setValue("Modifier");
			
			if freeadjustment > 0 then
				control.label.setValue("(+" .. freeadjustment .. ")");
			elseif freeadjustment < 0 then
				control.label.setValue("(" .. freeadjustment .. ")");
			end
			
			control.modifier.setValue(getSum());
			
			control.base.resetCounters();
			
			for i = 1, #slots do
				control.base.addCounter();
			end
			
			if hoverslot and hoverslot ~= 0 and slots[hoverslot] then
				control.label.setValue(slots[hoverslot].description);
			end
		end
		
		if math.abs(control.modifier.getValue()) > 999 then
			control.modifier.setFont("modcollectorlabel");
		else
			control.modifier.setFont("modcollector");
		end
	end
end

function isEmpty()
	if freeadjustment == 0 and #slots == 0 then
		return true;
	end

	return false;
end

function getSum()
	local total = freeadjustment;
	
	for i = 1, #slots do
		total = total + slots[i].number;
	end
	
	return total;
end

function getDescription(forcebonus)
	local str = "";
	
	if not forcebonus and #slots == 1 and freeadjustment == 0 then
		str = slots[1].description;
	else
		for i = 1, #slots do
			if i ~= 1 then
				str = str .. ", ";
			end
			
			str = str .. slots[i].description;
			if slots[i].number > 0 then
				str = str .. " +" .. slots[i].number;
			else
				str = str .. " " .. slots[i].number;
			end
		end
		
		if freeadjustment ~= 0 and #slots > 0 then
			if freeadjustment > 0 then
				str = str .. ", +" .. freeadjustment;
			else
				str = str .. ", " .. freeadjustment;
			end
		end
	end
	
	return str;
end

function addSlot(description, number)
	if #slots < 6 then
		table.insert(slots, { ['description'] = description, ['number'] = number });
	end
	
	updateControl();
end

function removeSlot(number)
	table.remove(slots, number);
	updateControl();
end

function adjustFreeAdjustment(amount)
	freeadjustment = freeadjustment + amount;
	
	updateControl();
end

function setFreeAdjustment(amount)
	freeadjustment = amount;
	
	updateControl();
end

function setAdjustmentEdit(state)
	if state then
		control.modifier.setValue(freeadjustment);
	else
		setFreeAdjustment(control.modifier.getValue());
	end

	adjustmentedit = state;
	updateControl();
end

function reset()
	if control and control.modifier.hasFocus() then
		control.modifier.setFocus(false);
	end

	freeadjustment = 0;
	slots = {};
	updateControl();
end

function hoverDisplay(n)
	hoverslot = n;
	updateControl();
end

-- Hot key handling
function checkHotkey(keyinfo)
	if keyinfo.getType() == "number" or keyinfo.getType() == "modifierstack" then
		addSlot(keyinfo.getDescription(), keyinfo.getNumberData());
		return true;
	end
end

function onInit()
	Interface.onHotkeyActivated = checkHotkey;
end

function applyModifierStackToRoll(draginfo)
	if isEmpty() then
		--[[ do nothing ]]
	elseif draginfo.getNumberData() == 0 and draginfo.getDescription() == "" then
		draginfo.setDescription(getDescription());
		draginfo.setNumberData(getSum());
	else
		local originalnumber = draginfo.getNumberData();
		local numstr = tostring(originalnumber);
		if originalnumber > 0 then
			numstr = "+" .. originalnumber;
		end

		local moddesc = getDescription(true);
		local desc = draginfo.getDescription();
		
		if numstr ~= "0" then
			desc = desc .. " " .. numstr;
		end
		if moddesc ~= "" then
			desc = desc .. " (" .. moddesc .. ")";
		end
		
		draginfo.setDescription(desc);
		draginfo.setNumberData(draginfo.getNumberData() + getSum());
	end
	
	if PreferenceManager.getValue("interface_resetmodifierstack") then
		reset();
	end
end
