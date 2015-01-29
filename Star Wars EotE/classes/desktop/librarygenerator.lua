local sourcevalue = "library";
local sourceclass = nil;
local sourceitems = {};

local dragging = false;

function onInit()

	-- set the hover cursor
	setHoverCursor("hand");	

	-- get the source value
	if source then
		sourcevalue = source[1];
	end
	
	-- get the class value
	if class then
		sourceclass = class[1];
	end

	-- subscribe to module changes
	Module.onModuleAdded = onModuleAdded;
	Module.onModuleRemoved = onModuleRemoved;
	Module.onModuleUpdated = onModuleUpdated;
	
	-- initialize
	initialize();

end

function onModuleAdded(name)
	initialize();
end

function onModuleRemoved(name)
	initialize();
end

function onModuleUpdated(name)
	initialize();
end

function initialize()

	-- clear the existing item list
	sourceitems = {};

	-- get the source node
	if sourceclass then
		local modules = Module.getModules();
		for k, v in ipairs(modules) do
			local sourcenode = DB.findNode(sourcevalue .. "@" .. v)
			if sourcenode then
				addNode(sourcenode);
			end
		end		
	end
	
	-- show or hide the control
	if table.getn(sourceitems) > 0 then
		setVisible(true);
	else
		setVisible(false);
	end

end

function addNode(sourcenode)
	local classnode = sourcenode.getChild("classname");
	if classnode then
		local classvalue = classnode.getValue();
		if classvalue == sourceclass then
			if self.isValidNode(sourcenode) then
				local quantityvalue = 1;
				local quantitynode = sourcenode.getChild("quantity");
				if quantitynode then
					quantityvalue = tonumber(quantitynode.getValue());
				end
				for i = 1, quantityvalue do
					table.insert(sourceitems, sourcenode.getNodeName());
				end
			end
		end
	else
		for k, v in pairs(sourcenode.getChildren()) do
			addNode(v);
		end
	end
end

function isValidNode(sourcenode)
	return true;
end

function onButtonPress()
	local sourcevalue = sourceitems[math.random(table.getn(sourceitems))];
	local sourcenode = DB.findNode(sourcevalue);
	if sourcenode then
		Interface.openWindow(sourceclass, sourcenode);
	end
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		dragging = true;
		local sourcevalue = sourceitems[math.random(table.getn(sourceitems))];
		local sourcenode = DB.findNode(sourcevalue);
		if sourcenode then
			draginfo.setType("shortcut");
			draginfo.setShortcutData(sourceclass, sourcevalue);
			draginfo.setIcon("button_openwindow");
			local namenode = sourcenode.getChild("name");
			if namenode then
				draginfo.setDescription(namenode.getValue());
			end
			return true;			
		end
	end
end

function onDragEnd()
	dragging = false;
end