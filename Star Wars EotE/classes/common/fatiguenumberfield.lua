local sourcenode = nil;
local strengthnode = nil;
local toughnessnode = nil;
local agilitynode = nil;
local indicatorwidget = nil;

function onInit()

	-- initialize the base class
	super.onInit();
	
	-- get the source node
	sourcenode = getDatabaseNode();
	if sourcenode then
		
		-- get the strength node
		strengthnode = sourcenode.getChild("..strength.current");
		if strengthnode then
			strengthnode.onUpdate = onUpdate;
		end
		
		-- get the toughness node
		toughnessnode = sourcenode.getChild("..toughness.current");
		if toughnessnode then
			toughnessnode.onUpdate = onUpdate;
		end
		
		-- get the agility node
		agilitynode = sourcenode.getChild("..agility.current");
		if agilitynode then
			agilitynode.onUpdate = onUpdate;
		end
		
		-- create the indicator widget
		indicatorwidget = addBitmapWidget("indicator_fatigue");
		indicatorwidget.setPosition("bottomleft", 0, -4);
	
		-- force an update now
		update();
	
	end

end

function onUpdate(source)
	update();
end

function onValueChanged()
	super.onValueChanged();
	update();
end

function update()
	if sourcenode then
		local fatiguevalue = nil;
		if strengthnode then
			if not fatiguevalue or strengthnode.getValue() < fatiguevalue then
				fatiguevalue = strengthnode.getValue();			
			end
		end
		if toughnessnode then
			if not fatiguevalue or toughnessnode.getValue() < fatiguevalue then
				fatiguevalue = toughnessnode.getValue();
			end
		end
		if agilitynode then
			if not fatiguevalue or agilitynode.getValue() < fatiguevalue then
				fatiguevalue = agilitynode.getValue();
			end
		end
		if not fatiguevalue or fatiguevalue >= getValue() then
			indicatorwidget.setVisible(false);
		else
			indicatorwidget.setVisible(true);
		end
	end
end