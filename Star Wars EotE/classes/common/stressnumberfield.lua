local sourcenode = nil;
local intelligencenode = nil;
local willpowernode = nil;
local fellowshipnode = nil;
local indicatorwidget = nil;

function onInit()

	-- initialize the base class
	super.onInit();
	
	-- get the source node
	sourcenode = getDatabaseNode();
	if sourcenode then
		
		-- get the intelligence node
		intelligencenode = sourcenode.getChild("..intelligence.current");
		if intelligencenode then
			intelligencenode.onUpdate = onUpdate;
		end
		
		-- get the willpower node
		willpowernode = sourcenode.getChild("..willpower.current");
		if willpowernode then
			willpowernode.onUpdate = onUpdate;
		end
		
		-- get the fellowship node
		fellowshipnode = sourcenode.getChild("..fellowship.current");
		if fellowshipnode then
			fellowshipnode.onUpdate = onUpdate;
		end
		
		-- create the indicator widget
		indicatorwidget = addBitmapWidget("indicator_stress");
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
		local stressvalue = nil;
		if intelligencenode then
			if not stressvalue or intelligencenode.getValue() < stressvalue then
				stressvalue = intelligencenode.getValue();			
			end
		end
		if willpowernode then
			if not stressvalue or willpowernode.getValue() < stressvalue then
				stressvalue = willpowernode.getValue();
			end
		end
		if fellowshipnode then
			if not stressvalue or fellowshipnode.getValue() < stressvalue then
				stressvalue = fellowshipnode.getValue();
			end
		end
		if not stressvalue or stressvalue >= getValue() then
			indicatorwidget.setVisible(false);
		else
			indicatorwidget.setVisible(true);
		end
	end
end