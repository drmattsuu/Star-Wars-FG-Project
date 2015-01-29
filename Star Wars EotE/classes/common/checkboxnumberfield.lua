local maxvalue = 1;
local centervalue = false;
local stateicononvalue = "indicator_checkon";
local stateiconoffvalue = "indicator_checkoff";

local sourcenode = nil;
local stateicons = {};

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
	
		-- get default values
		if max then
			maxvalue = tonumber(max[1]);
		end
		if center then
			centervalue = true;
		end
		if stateicon then
			if stateicon[1].on then
				stateiconon = stateicons[1].on[1];
			end
			if stateicon[1].off then
				stateiconoff = stateicons[1].off[1];
			end
		end
	
		-- set the event listener
		sourcenode.onUpdate = onUpdate;
			
		-- and update
		update();		
	
	end

end

function onUpdate(source)
	update();
end

function update()
	if sourcenode then
		local sourcevalue = sourcenode.getValue();
		local controlw, controlh = getSize();
		
		-- create or remove state icons
		while table.getn(stateicons) ~= maxvalue do
			if table.getn(stateicons) < maxvalue then
				local stateicon = addBitmapWidget(stateiconoffvalue);
				table.insert(stateicons, stateicon);
			else
				local stateicon = stateicons[table.getn(stateicons)];
				stateicon.destroy();
				table.insert(stateicons, stateicon);
			end
		end
		
		-- position the state icons
		local iconw, iconh = stateicons[1].getSize();
		local xpos = 0;
		if centervalue then
			xpos = (controlw / 2) - ((maxvalue - 1) * (iconw / 2));
		
		else
			xpos = (iconw / 2);
		end
		for k, v in ipairs(stateicons) do
			v.setPosition("left", xpos, 0);
			xpos = xpos + iconw;
		end
		
		-- set the state icon states
		for k, v in ipairs(stateicons) do
			if k > sourcevalue then
				v.setBitmap(stateiconoffvalue);
			else
				v.setBitmap(stateicononvalue);
			end
		end
	end
end

function onClickDown(button, x, y)
	if not disabled then
		if sourcenode then
			if not sourcenode.isStatic() then
				if sourcenode.isOwner() then
					local sourcevalue = sourcenode.getValue();
					sourcevalue = sourcevalue + 1;
					if sourcevalue > maxvalue then
						sourcevalue = 0;
					end
					sourcenode.setValue(sourcevalue);
				end
			end
		end
	end
end