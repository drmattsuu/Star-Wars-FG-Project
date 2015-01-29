function onInit()
	InitiativeManager.registerControl(self);
end

function onClose()
	Debug.console("initslotlist.lua: onClose.");
	InitiativeManager.unregisterControl(self);
end

function onDrop(x, y, draginfo)
	Debug.console("initslotlist.lua:onDrop.");
	local actorwindow = getWindowAt(x, y);
	if actorwindow then
		return actorwindow.onDrop(x, y, draginfo);
	else
		return InitiativeManager.onDrop(x, y, draginfo);
	end
end

function onSortCompare(w1, w2)
	if w1.initslotinitiative.getValue() ~= w2.initslotinitiative.getValue() then
		return w1.initslotinitiative.getValue() < w2.initslotinitiative.getValue();
	elseif w1.getClass() ~= w2.getClass() then
		return w1.getClass() > w2.getClass();
	elseif w1.initslotclassname.getValue() ~= w2.initslotclassname.getValue() then
		return w1.initslotclassname.getValue() > w2.initslotclassname.getValue();
	else
		return w1.initslotname.getValue() > w2.initslotname.getValue();
	end
end