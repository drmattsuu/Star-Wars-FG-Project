local centervalue = false;
local advanceicononvalue = "indicator_checkon";
local advanceiconoffvalue = "indicator_checkoff";

local sourcenode = nil;
local advanceicons = {};
local masteredwidget = nil;

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
		
		-- create or remove advance icons
		while table.getn(advanceicons) ~= 3 do
			if table.getn(advanceicons) < 3 then
				local advanceicon = addBitmapWidget(advanceiconoffvalue);
				table.insert(advanceicons, advanceicon);
			else
				local advanceicon = advanceicons[table.getn(advanceicons)];
				advanceicon.destroy();
				table.insert(advanceicons, advanceicon);
			end
		end
		
		-- position the advance icons
		local iconw, iconh = advanceicons[1].getSize();
		local xpos = 0;
		if centervalue then
			xpos = (controlw / 2) - ((table.getn(advanceicons) - 1) * (iconw / 2));
		else
			xpos = (iconw / 2);
		end
		for k, v in ipairs(advanceicons) do
			v.setPosition("left", xpos, 0);
			xpos = xpos + iconw;
		end
		
		-- create the mastered widget
		if not masteredwidget then
			masteredwidget = addBitmapWidget("symbol_comet");
			masteredwidget.setPosition("center", -4, -1);
		end
		
		-- set the advance icon advances
		for k, v in ipairs(advanceicons) do
			if k > sourcevalue then
				v.setBitmap(advanceiconoffvalue);
			else
				v.setBitmap(advanceicononvalue);
			end
		end
		
		-- set visibility
		if sourcevalue > 3 then
			masteredwidget.setVisible(true);
		else
			masteredwidget.setVisible(false);
		end
		for k, v in ipairs(advanceicons) do
			if sourcevalue > 3 then
				v.setVisible(false);
			else
				v.setVisible(true);
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
					if sourcevalue > 4 then
						sourcevalue = 0;
					end
					sourcenode.setValue(sourcevalue);
				end
			end
		end
	end
end