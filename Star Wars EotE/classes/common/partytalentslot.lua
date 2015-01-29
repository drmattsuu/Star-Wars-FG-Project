local sloticonvalue = "button_openwindow";
local sloticonemptyvalue = "button_emptytarget";
local slotnumbervalue = 1;

local sourcenode = nil;
local typenode = nil;
local namenode = nil;
local rechargecontrol = nil;

local type = "";
local sloticon = nil
local sloticonw = 0;
local sloticonh = 0;
local slottext = nil;

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
	
		-- create the slot icon
		sloticon = addBitmapWidget(sloticonemptyvalue);
		sloticonw, sloticonh = sloticon.getSize();
		sloticon.setPosition("left", (sloticonw / 2), 0);
	
		-- create the slot text
		slottext = addTextWidget("sheetlabel", "");
		updateSlotTextPosition();
		
		-- get default values
		if slotnumber then
			slotnumbervalue = tonumber(slotnumber[1]);
			if slotnumbervalue <= 0 then
				slotnumbervalue = 1;
			end			
		end
		
		-- get the type node
		typenode = window.getDatabaseNode().getChild("sockets." .. slotnumbervalue);
		if typenode then
			typenode.onUpdate = onUpdate;
		end		

		-- get the name node
		if sourcenode.isOwner() then
			namenode = sourcenode.createChild("name", "string");
		else
			namenode = sourcenode.getChild("name");
		end
		if namenode then
			namenode.onUpdate = onUpdate;
		end
						
		-- register menu options
		registerMenuItem("Clear slot", "erase", 4);
	
	end	
end

function registerControl(control)
	rechargecontrol = control;
	update();
end

function onUpdate(source)
	update();
end

function update()
	DebugManager.logMessage("partytalentslot.update");
	if sourcenode then

		-- get the type
		local typevalue = "";
		if typenode then
			typevalue = typenode.getValue();
		end

		-- get the name
		local namevalue = "";
		if namenode then
			namevalue = namenode.getValue();
		end
		
		-- determine if the slot should be visible or not
		if typevalue ~= "" then

			-- determine if a slot value has been set
			if namevalue ~= "" then
				sloticon.setBitmap(sloticonvalue);
				slottext.setText(namevalue);			
			else
				sloticon.setBitmap(sloticonemptyvalue);
				slottext.setText("\171 Empty " .. typevalue .. " Slot \187");
			end

			-- update the slot text position
			updateSlotTextPosition();
			
			-- show the slot icon and label
			sloticon.setVisible(true);
			slottext.setVisible(true);
			if rechargecontrol then
				rechargecontrol.setVisible(true);
			end				

		else

			-- hide the slot icon and label
			sloticon.setVisible(false);
			slottext.setVisible(false);
			if rechargecontrol then
				rechargecontrol.setVisible(false);
			end				
		end
	end
end

function updateSlotTextPosition()
	if slottext then
		local slottextw, slottexth = slottext.getSize();
		slottext.setPosition("left", sloticonw + (slottextw / 2), 0);
	end
end

function onMenuSelection(...)
	clearSlot();
end

function clearSlot()
	PartySheetManager.clearPartySlot(slotnumbervalue);
end

function onDrop(x, y, draginfo)
	if draginfo.getType() == "shortcut" then
		local classvalue, recordnamevalue = draginfo.getShortcutData();
		PartySheetManager.updatePartySlot(slotnumbervalue, classvalue, recordnamevalue);
		return true;
	end
end

function onClickDown(x, y, draginfo)
	if sourcenode then
		local controlw, controlh = getSize();
		if x >= 0 and x <= sloticonw and y >= (controlh - sloticonh) / 2 and y <= (controlh + sloticonh) / 2 then
			local classnode = sourcenode.getChild("class");
			local recordnamenode = sourcenode.getChild("recordname");
			if classnode and recordnamenode then
				Interface.openWindow(classnode.getValue(), recordnamenode.getValue());
				return true;
			end
		end
	end
end