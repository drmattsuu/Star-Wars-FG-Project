local sourcenode = nil;
local willpowernode = nil;
local indicatorwidget = nil;

function onInit()

	-- initialize the base class
	super.onInit();
	
	-- get the source node
	sourcenode = getDatabaseNode();
	if sourcenode then
		
		-- get the willpower node
		willpowernode = sourcenode.getChild("..willpower.current");
		if willpowernode then
			willpowernode.onUpdate = onUpdate;
		end
		
		-- create the indicator widget
		indicatorwidget = addBitmapWidget("indicator_power");
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
		local ordersnode = sourcenode.getChild("..orders");
		if ordersnode and ordersnode.getChildCount() > 0 then
			local willpowervalue = nil;
			if willpowernode then
				willpowervalue = willpowernode.getValue();
			end
			if willpowervalue and willpowervalue ~= getValue() then
				indicatorwidget.setVisible(true);
				return;
			end
		end
	end
	indicatorwidget.setVisible(false);
end