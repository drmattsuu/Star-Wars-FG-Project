local dragging = false;
local dicewidget = nil;
local totalnode = nil;
local spentnode = nil;

function onInit()
	super.onInit();
	setHoverCursor("hand");
	dicewidget = addBitmapWidget("textentry_die");
	dicewidget.setPosition("bottomleft", 0, -4);
local windownode = window.getDatabaseNode();
	totalnode = windownode.getChild("force.total");
	totalnode.onUpdate = onUpdate;
	spentnode = windownode.getChild("force.spent");
	spentnode.onUpdate = onUpdate;
	onUpdate(nil);
	onValueChanged();
end

function onUpdate(source)
	local totalvalue = totalnode.getValue();
	local spentvalue = spentnode.getValue();
	setValue(totalvalue - spentvalue);
	onValueChanged();
end

function onDragStart(button, x, y, draginfo)
	dragging = false;
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if not dragging then
		local sourcenode = window.getDatabaseNode();
		local dice = {};
		DicePoolManager.addForceDice(sourcenode, dice);
		if table.getn(dice) > 0 then
			draginfo.setType("dice");
			draginfo.setDieList(dice);
			draginfo.setDatabaseNode(sourcenode);
			dragging = true;
			return true;								
		end		
	end
	return false;
end

function onDragEnd(draginfo)
	dragging = false;
end

function onDoubleClick()
	local sourcenode = window.getDatabaseNode();
	local dice = {};
	local msgidentity = DB.getValue(sourcenode, "...name", "");
	DicePoolManager.addForceDice(sourcenode, dice);
	if table.getn(dice) > 0 then
		DieBoxManager.addForceDice(dice, sourcenode, msgidentity);
	end
end