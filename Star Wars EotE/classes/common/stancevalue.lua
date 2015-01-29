local alignvalue = "center";

local updating = false;

local sourcenode = nil;
local sourcelabel = nil;

function onInit()

	-- get the source node
	local windownode = window.getDatabaseNode();
	if windownode and windownode.isOwner() then
		sourcenode = windownode.createChild("stance.current", "number");
	end

	-- if the source node exists
	if sourcenode then
	
		-- get the default values
		if align then
			alignvalue = align[1];
		end
	
		-- subscribe to the sourcenode update event
		sourcenode.onUpdate = onUpdate;
		
	end
	
	-- and trigger an update
	update();
	
end

function onUpdate(source)
	update();
end

function update()
	DebugManager.logMessage("stancevalue.update");
	if not updating then
		updating = true;
		
		-- get the source label text
		local sourcelabeltext = "N";		
		if sourcenode then
			if sourcenode.getParent().getParent().getParent().getName() == "charsheet" then
				local sourcevalue = sourcenode.getValue();
				if sourcevalue > 0 then
					sourcelabeltext = "R" .. sourcevalue;
				elseif sourcevalue < 0 then
					sourcelabeltext = "C" .. math.abs(sourcevalue);
				end
			else
				local sourcevalue = sourcenode.getValue();			
				local conservativenode = sourcenode.getChild("..conservative");							
				local conservativevalue = 0;				
				local recklessnode = sourcenode.getChild("..reckless");
				local recklessvalue = 0;
				if sourcevalue == 0 then
					if conservativenode then
						conservativevalue = conservativenode.getValue();
					end
					if recklessnode then
						recklessvalue = recklessnode.getValue();
					end									
				elseif sourcevalue == 1 then
					if conservativenode then
						conservativevalue = conservativenode.getValue();
					end
				elseif sourcevalue == 2 then
					if recklessnode then
						recklessvalue = recklessnode.getValue();
					end
				end
				if conservativevalue > 0 and recklessvalue > 0 then
					sourcelabeltext = "C" .. conservativevalue .. "+R" .. recklessvalue;
				elseif conservativevalue > 0 then
					sourcelabeltext = "C" .. conservativevalue;
				elseif recklessvalue > 0 then
					sourcelabeltext = "R" .. recklessvalue;
				end
			end
		end
		
		-- create the source label if required
		if not sourcelabel then
			sourcelabel = addTextWidget("sheetlabel", sourcelabeltext);
		else
			sourcelabel.setText(sourcelabeltext);			
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

		updating = false;
	end
end
