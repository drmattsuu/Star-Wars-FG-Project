local sourcenode = nil;
local thresholdnode = nil;
local indicatorwidget = nil;

function onInit()

	-- initialize the base class
	super.onInit();
	
	-- get the source node
	sourcenode = getDatabaseNode();
	if sourcenode then
	
		-- get the threshold node
		thresholdnode = sourcenode.getChild("..threshold");
		if thresholdnode then
			thresholdnode.onUpdate = onUpdate;
		end
		
		-- create the indicator widget
		indicatorwidget = addBitmapWidget("indicator_strain");
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
		local thresholdvalue = nil;
		if thresholdnode then
			thresholdvalue = thresholdnode.getValue();
		end
		if not thresholdvalue or thresholdvalue >= getValue() then
			indicatorwidget.setVisible(false);
		else
			indicatorwidget.setVisible(true);
		end
	end
end