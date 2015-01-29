function onInit()
	InitiativeManager.registerControl(self);
end

function onClose()
	InitiativeManager.unregisterControl();
end

function onDrop(x, y, draginfo)
	--local actorwindow = getWindowAt(x, y);
	--if actorwindow then
	--	return actorwindow.onDrop(x, y, draginfo);
	--else
	--Debug.console("actorlist.lua: onDrop - drag type = " .. draginfo.getType());
	if draginfo.isType("playercharacter") or draginfo.isType("npc") or draginfo.isType("shortcut") then
		return InitiativeManager.onDrop(x, y, draginfo);
	end
	return true;
end

function onSortCompare(w1, w2)
	-- don't need to sort the initiatives in the actor list - initiatives are in the initslot list now
	
--	if w1.initiative.getValue() ~= w2.initiative.getValue() then
--		return w1.initiative.getValue() < w2.initiative.getValue();
--	elseif w1.getClass() ~= w2.getClass() then
--		return w1.getClass() > w2.getClass();
--	else
--		return w1.name.getValue() > w2.name.getValue();
--	end
end