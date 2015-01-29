local stepheightvalue = 25;
local stepwidthvalue = 25;
local stepicononvalue = "stancetracker_on";
local stepiconoffvalue = "stancetracker_off";
local stepfontnamevalue = "sheetlabelinline";
local stepcountmaxvalue = 6;
local iconnamevalue = "button_openwindow2";
local careersnamevalue = "careers";

local updating = false;
local dragging = false;

local careersnode = nil;
local sourcenode = nil;
local conservativenode = nil;
local careerconservativenode = nil;
local recklessnode = nil;
local careerrecklessnode = nil;

local neutralstep = nil;
local conservativesteps = {};
local recklesssteps = {};
local valueicon = nil;

local conservativevalue = 0;
local recklessvalue = 0;

function onInit()

	-- get the source node
	local sourcenodename;
	if sourcename then
		sourcenodename = sourcename[1];
	else
		sourcenodename = getName();
	end
	if window.getDatabaseNode().isOwner() then
		sourcenode = window.getDatabaseNode().createChild(sourcenodename, "number");
	else
		sourcenode = window.getDatabaseNode().getChild(sourcenodename);
	end
	
	-- if the source node exists
	if sourcenode then

		-- set the event listener
		sourcenode.onUpdate = onUpdate;

		-- get the careers node
		if careersname then
			careersnode = window.getDatabaseNode().getChild(careersname[1]);
		end
		if careersnode then
			careersnode.onChildUpdate = onCareerUpdate;
		end
	
		-- get the conservative nodes
		if conservativename then
			conservativenode = window.getDatabaseNode().getChild(conservativename[1]);
		end
		if conservativenode then
			conservativenode.onUpdate = onUpdate;
		end
		careerconservativenode = getCurrentCareerConservativeNode();
		if careerconservativenode then
			careerconservativenode.onUpdate = onUpdate;
		end
		
		-- get the reckless nodes
		if recklessname then
			recklessnode = window.getDatabaseNode().getChild(recklessname[1]);
		end
		if recklessnode then
			recklessnode.onUpdate = onUpdate;
		end
		careerrecklessnode = getCurrentCareerRecklessNode();
		if careerrecklessnode then
			careerrecklessnode.onUpdate = onUpdate;
		end

		-- and perform an update
		update();
	
	end	
end

function onCareerUpdate(source)
	careerUpdate();
end

function careerUpdate()
	local updateRequired = false;

	-- get the conservative node
	local tempcareerconservativenode = getCurrentCareerConservativeNode();
	if tempcareerconservativenode then
		if careerconservativenode then
			if tempcareerconservativenode.getNodeName() ~= careerconservativenode.getNodeName() then
				careerconservativenode = tempcareerconservativenode;
				careerconservativenode.onUpdate = onUpdate;
				updateRequired = true;
			end
		else
			careerconservativenode = tempcareerconservativenode;
			careerconservativenode.onUpdate = onUpdate;
			updateRequired = true;
		end
	else
		if careerconservativenode then
			pcall(function() careerconservativenode.onUpdate = function() end; end);
			careerconservativenode = nil;
			updateRequired = true;
		end
	end
	
	-- get the reckless node
	local tempcareerrecklessnode = getCurrentCareerRecklessNode();
	if tempcareerrecklessnode then
		if careerrecklessnode then
			if tempcareerrecklessnode.getNodeName() ~= careerrecklessnode.getNodeName() then
				careerrecklessnode = tempcareerrecklessnode;
				careerrecklessnode.onUpdate = onUpdate;
				updateRequired = true;
			end
		else
			careerrecklessnode = tempcareerrecklessnode;
			careerrecklessnode.onUpdate = onUpdate;
			updateRequired = true;
		end
	else
		if careerrecklessnode then
			pcall(function() careerrecklessnode.onUpdate = function() end; end);
			careerrecklessnode = nil;
			updateRequired = true;
		end
	end
	
	-- perform an update if required
	if updateRequired then
		update();
	end
	
end

function onUpdate(source)
	update();
end	

function update()
	DebugManager.logMessage("stancetracker.update");
	if not updating then
		updating = true;	
		if sourcenode then
			local xpos = 0;

			-- create the neutral step
			if not neutralstep then
				neutralstep = {};
				neutralstep.icon = addBitmapWidget(stepicononvalue);
				neutralstep.label = addTextWidget(stepfontnamevalue, "N");
			end

			-- position the neutral step
			neutralstep.icon.setPosition("",0,0);
			neutralstep.label.setPosition("",-1,1);
			
			-- get the conservative value
			conservativevalue = 0;
			if conservativenode then
				conservativevalue = conservativevalue + conservativenode.getValue();
			end
			if careerconservativenode then
				conservativevalue = conservativevalue + careerconservativenode.getValue();
			end

			-- create or remove the conservative steps
			while table.getn(conservativesteps) ~= stepcountmaxvalue do
				if table.getn(conservativesteps) < stepcountmaxvalue then
					local step = {};
					step.icon = addBitmapWidget(stepiconoffvalue);
					step.label = addTextWidget(stepfontnamevalue, "C");
					table.insert(conservativesteps, step);
				else
					local step = conservativesteps[table.getn(conservativesteps)];
					step.icon.destroy();
					step.label.destroy();
					table.remove(conservativesteps);
				end
			end

			-- position the conservative steps
			xpos = -stepwidthvalue;
			for k,v in ipairs(conservativesteps) do
				v.icon.setPosition("", xpos, 0);
				v.label.setPosition("", xpos - 1, 1);
				xpos = xpos - stepwidthvalue;
			end

			-- set the conservative step state
			for k, v in ipairs(conservativesteps) do
				if conservativevalue >= k then
					v.icon.setBitmap(stepicononvalue);
					v.label.setVisible(true);
				else
					v.icon.setBitmap(stepiconoffvalue);
					v.label.setVisible(false);
				end
			end
			
			-- get the conservative value
			recklessvalue = 0;
			if recklessnode then
				recklessvalue = recklessvalue + recklessnode.getValue();
			end
			if careerrecklessnode then
				recklessvalue = recklessvalue + careerrecklessnode.getValue();
			end			
			
			-- create or remove the reckless steps
			while table.getn(recklesssteps) ~= stepcountmaxvalue do
				if table.getn(recklesssteps) < stepcountmaxvalue then
					local step = {};
					step.icon = addBitmapWidget(stepiconoffvalue);
					step.label = addTextWidget(stepfontnamevalue, "R");
					table.insert(recklesssteps, step);
				else
					local step = recklesssteps[table.getn(recklesssteps)];
					step.icon.destroy();
					step.label.destroy();
					table.remove(recklesssteps);
				end
			end

			-- position the reckless steps
			xpos = stepwidthvalue;
			for k,v in ipairs(recklesssteps) do
				v.icon.setPosition("", xpos, 0);
				v.label.setPosition("", xpos - 1, 1);
				xpos = xpos + stepwidthvalue;
			end

			-- set the reckless step state
			for k, v in ipairs(recklesssteps) do
				if recklessvalue >= k then
					v.icon.setBitmap(stepicononvalue);
					v.label.setVisible(true);
				else
					v.icon.setBitmap(stepiconoffvalue);
					v.label.setVisible(false);
				end
			end

			-- create the value icon if required
			if not valueicon then
				valueicon = addBitmapWidget(iconnamevalue);
			end

			-- position the value icon
			local sourcevalue = sourcenode.getValue();
			if sourcevalue ~= 0 then
				if sourcevalue < 0 then
					if sourcevalue < -conservativevalue then
						sourcevalue = -conservativevalue;
						sourcenode.setValue(sourcevalue);
					end
				else
					if sourcevalue > recklessvalue then
						sourcevalue = recklessvalue;
						sourcenode.setValue(sourcevalue);
					end
				end
			end
			valueicon.setPosition("", sourcevalue * stepwidthvalue, 0);
			valueicon.bringToFront();
		end
		updating = false		
	end
end

function getValueIndex(x, y)
	if sourcenode then
		local w, h = getSize();
		if y > ((h - stepheightvalue) / 2) and y < ((h + stepheightvalue) / 2) then
			return math.floor((x + (stepwidthvalue/2) - (w/2)) / stepwidthvalue);
		end
	end
	return nil;
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if sourcenode then
		if sourcenode.isOwner() then
			if not dragging then
				if valueicon then
					local valueindex = getValueIndex(x, y);
					if valueindex then
						if valueindex == sourcenode.getValue() then
							draginfo.setType("stancetracker");
							draginfo.setIcon(iconnamevalue);
							valueicon.setColor("80FFFFFF");
							dragging = true;
							return true;
						end
					end
				end
			end
		end
	end
end

function onDragEnd(draginfo)
	if sourcenode then
		if sourcenode.isOwner() then
			if dragging then
				local mousex, mousey = Input.getMousePosition();
				local windowx, windowy = window.getPosition();
				local controlx, controly = getPosition();
				local x = mousex - controlx - windowx;
				local y = mousey - controly - windowy;
				local valueindex = getValueIndex(x, y);
				if valueicon then
					valueicon.setColor("FFFFFFFF");
				end				
				if valueindex then
					if valueindex >= -conservativevalue and valueindex <= recklessvalue then
						sourcenode.setValue(valueindex)
					end
				end
				dragging = false;
			end
		end
	end
end

function getCurrentCareerNode()
	if careersnode then
		for k, v in pairs(careersnode.getChildren()) do
			local currentnode = v.getChild("current");
			if currentnode then
				if currentnode.getValue() == 1 then
					return v;
				end
			end
		end
	end
end

function getCurrentCareerConservativeNode()
	local currentcareernode = getCurrentCareerNode();
	if currentcareernode then
		return currentcareernode.getChild("details.stance.conservative");
	end
end

function getCurrentCareerRecklessNode()
	local currentcareernode = getCurrentCareerNode();
	if currentcareernode then
		return currentcareernode.getChild("details.stance.reckless");
	end
end
