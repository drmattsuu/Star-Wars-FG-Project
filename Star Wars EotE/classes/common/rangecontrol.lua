local alignvalue = "center";

local updating = false;

local sourcenode = nil;
local sourcelabel = nil;

function onInit()

	-- get the source node
	local sourcenodename;
	if sourcename then
		sourcenodename = sourcename[1];
	else
		sourcenodename = getName();
	end
	if window.getDatabaseNode().isOwner() then
		sourcenode = window.getDatabaseNode().createChild(sourcenodename, "string");
	else
		sourcenode = window.getDatabaseNode().getChild(sourcenodename);
	end
	
	-- if the source node exists
	if sourcenode then
	
		-- get the default values
		if align then
			alignvalue = align[1];
		end
			
		-- subscribe to the sourcenode update event
		sourcenode.onUpdate = onUpdate;
		
		-- and trigger an update
		update();
	end

end

function onUpdate(source)
	update();
end

function update()
	DebugManager.logMessage("rangecontrol.update");
	if not updating then
		updating = true;
		if sourcenode then
		
			-- get the source value
			local sourcevalue = sourcenode.getValue();
		
			-- create the source label if required
			if not sourcelabel then
				sourcelabel = addTextWidget("sheetlabel", "");
			end

			-- set the source label
			if sourcevalue == "" then
				sourcelabel.setText("-");
			else
				sourcelabel.setText(sourcevalue);
			end
						
			-- set the label colour
			if sourcevalue == "" then
				sourcelabel.setFont("sheetlabeldisabled");
			else
				sourcelabel.setFont("sheetlabel");
			end
			
			-- get the control size
			local controlw, controlh = sourcelabel.getSize();
			
			-- position the label
			if string.lower(alignvalue) == "left" then
				sourcelabel.setPosition("left", (controlw/2), 0);
			elseif string.lower(alignvalue) == "right" then
				sourcelabel.setPosition("right", -(controlw/2), 0);
			else
				sourcelabel.setPosition("",0,0);			
			end
		end
		updating = false;
	end
end

function onClickDown(button, x, y)
	if not disabled then
		if sourcenode then
			local value = sourcenode.getValue();
			if value == "" then
				sourcenode.setValue("S");
			elseif value == "S" then
				sourcenode.setValue("M");
			elseif value == "M" then
				sourcenode.setValue("L");
			elseif value == "L" then
				sourcenode.setValue("E");
			else
				sourcenode.setValue("");
			end
		end
	end
end