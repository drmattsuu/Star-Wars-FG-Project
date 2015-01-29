local careersnamevalue = "careers";
local sloticonvalue = "button_openwindow";
local sloticonemptyvalue = "button_emptytarget";
local slotnumbervalue = 1;

local updating = false;

local careersnode = nil;
local sourcenode = nil;
local classnode = nil;
local recordnamenode = nil;
local rechargecontrol = nil;
local linknode = nil;
local slotnode = nil;

local slottype = "";
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
		
		-- register menu options
		if sourcenode.isOwner() then
			registerMenuItem("Clear slot", "erase", 4);	
		end

		-- get the class node
		if sourcenode.isOwner() then
			classnode = sourcenode.createChild("class", "string");
		else
			classnode = sourcenode.getChild("class");
		end
		if classnode then
			classnode.onUpdate = onUpdate;
		end
		
		-- get the record node
		if sourcenode.isOwner() then
			recordnamenode = sourcenode.createChild("recordname", "string");
		else
			recordnamenode = sourcenode.getChild("recordname");
		end
		if recordnamenode then
			recordnamenode.onUpdate = onUpdate;
		end
		
		-- get the careers node
		if careersname then
			careersnamevalue = careersname[1];
		end
		careersnode = window.getDatabaseNode().getChild(careersnamevalue);
		if careersnode then
			careersnode.onChildUpdate = onCareerUpdate;
		end		
		
		-- get the socket node
		slotnode = getSlotNode();
		if slotnode then
			slotnode.onUpdate = onUpdate;
		end	
	end	
end

function onCareerUpdate(source)
	careerUpdate();
end

function careerUpdate()
	local tempslotnode = getSlotNode();
	if tempslotnode then
		if slotnode then
			if tempslotnode.getNodeName() ~= slotnode.getNodeName() then
				slotnode = tempslotnode;
				slotnode.onUpdate = onUpdate;
				update();			
			end
		else
			slotnode = tempslotnode;
			slotnode.onUpdate = onUpdate;
			update();				
		end	
	else
		if slotnode then
			slotnode.onUpdate = function() end;
			slotnode = nil;
			update();
		end
	end
end

function registerControl(control)
	rechargecontrol = control;
	update();
end

function onUpdate(source)
	update();
end

function onDelete(source)
	clearSlot();
end

function update()
	DebugManager.logMessage("charactertalentslot.update");
	if not updating then
		updating = true;
		if sourcenode then
				
			-- get the slot type
			if slotnode then
				slottype = slotnode.getValue();
			else
				slottype = "";
			end
			
			-- set the visibility of the slot icon and text
			if slottype ~= "" and classnode and recordnamenode then
						
				-- determine if the slot has a value set
				local recordnamevalue = recordnamenode.getValue();
				local classvalue = classnode.getValue();
				if classvalue ~="" and recordnamevalue ~= "" and DB.findNode(recordnamevalue) and (string.lower(classvalue) == string.lower(slottype) or string.lower(slottype) == "any" or string.lower(classvalue) == "disease" or string.lower(classvalue) == "insanity" or string.lower(classvalue) == "invention") then
				
					-- get the new link node
					local newlinknode = DB.findNode(recordnamevalue);
					
					-- create the link node if required
					if not linknode then
						linknode = newlinknode;
						linknode.onChildUpdate = onUpdate;
						linknode.onDelete = onDelete;
					end
					
					-- determine if the new link node matches the old
					if newlinknode.getNodeName() ~= linknode.getNodeName() then
						if linknode.isOwner() and not linknode.isStatic() then
							local socketednode = linknode.createChild("socketed", "number");
							if socketednode then
								if socketednode.getValue() ~= 0 then
									socketednode.setValue(0);
								end
							end
						end
						linknode = newlinknode;
						linknode.onChildUpdate = onUpdate;
					end
				
					-- set the slot icon and text
					sloticon.setBitmap(sloticonvalue);
					slottext.setText(linknode.getChild("name").getValue());
					
					-- update the slot text position
					updateSlotTextPosition();					
					
					-- set the socketed statis for the new link node
					if linknode.isOwner() and not linknode.isStatic() then
						local socketednode = linknode.createChild("socketed", "number");
						if socketednode then
							if socketednode.getValue() ~= 1 then
								socketednode.setValue(1);
							end
						end
					end
			
				else
				
					-- clear the current link node
					if linknode then
						if linknode.isOwner() and not linknode.isStatic() then
							local socketednode = linknode.createChild("socketed");
							if socketednode then
								if socketednode.getValue() ~= 0 then
									socketednode.setValue(0);
								end
							end
						end
						linknode = nil;				
					end
				
					-- set the slot icon and text
					sloticon.setBitmap(sloticonemptyvalue);
					slottext.setText("\171 Empty " .. slottype .. " Slot \187");
					
					-- update the slot text position
					updateSlotTextPosition();
				
				end
			
				-- show the slot icon and text
				sloticon.setVisible(true);
				slottext.setVisible(true);
				if rechargecontrol then
					rechargecontrol.setVisible(true);
				end
			else
			
				-- clear the current link node
				if linknode and not linknode.isStatic() then
					local socketednode = linknode.createChild("socketed");
					if socketednode then
						if socketednode.getValue() ~= 0 then
							socketednode.setValue(0);
						end
					end
				end

				-- clear the class node
				if classnode then
					if classnode.getValue() ~= "" then
						classnode.setValue("");
					end
				end
				
				-- clear the record name node
				if recordnamenode then
					if recordnamenode.getValue() ~= "" then
						recordnamenode.setValue("");
					end
				end
				
				-- hide the slot icon and label
				sloticon.setVisible(false);
				slottext.setVisible(false);
				if rechargecontrol then
					rechargecontrol.setVisible(false);
				end				
			end

		end
		updating = false;
	end
end

function getSlotNode()
	if careersnode then
		for k, v in pairs(careersnode.getChildren()) do
			local currentnode = v.getChild("current");
			if currentnode then
				if currentnode.getValue() == 1 then
					return v.getChild("details.sockets." .. slotnumbervalue);
				end
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
	if sourcenode then
		if sourcenode.isOwner() then
			if rechargecontrol then
				if rechargecontrol.getDatabaseNode().getValue() ~= 0 then
					return nil;
				end
			end
			classnode.setValue("");
			recordnamenode.setValue("");
		end
	end
end

function onDrop(x, y, draginfo)
	if sourcetype ~= "" then
		if sourcenode then
			if sourcenode.isOwner() then
				if rechargecontrol then
					if rechargecontrol.getDatabaseNode().getValue() == 0 then
						if draginfo.getType() == "shortcut" then			
							local class, recordname = draginfo.getShortcutData();
							if string.lower(class) == string.lower(slottype) or string.lower(slottype) == "any" or string.lower(class) == "disease" or string.lower(class) == "insanity" or string.lower(class) == "invention" then
								classnode.setValue(class);
								recordnamenode.setValue(recordname);
							end
						end
					end
				end
			end
		end
	end
	return true;
end

function onClickDown(x, y, draginfo)
	if sourcenode then
		local controlw, controlh = getSize();
		if x >= 0 and x <= sloticonw and y >= (controlh - sloticonh) / 2 and y <= (controlh + sloticonh) / 2 then
			local recordnode = DB.findNode(recordnamenode.getValue());
			if recordnode then
				Interface.openWindow(classnode.getValue(), recordnode);
				return true;
			end
		end
	end
end